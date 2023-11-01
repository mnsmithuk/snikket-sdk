// This example persistence driver is written in JavaScript
// so that SDK users can easily see how to write their own

exports.xmpp.persistence = {
	browser: (dbname) => {
		var db = null;
		function openDb(version) {
			var dbOpenReq = indexedDB.open(dbname, version);
			dbOpenReq.onerror = console.error;
			dbOpenReq.onupgradeneeded = (event) => {
				const upgradeDb = event.target.result;
				if (!db.objectStoreNames.contains("messages")) {
					const messages = upgradeDb.createObjectStore("messages", { keyPath: ["account", "serverIdBy", "serverId", "localId"] });
					messages.createIndex("chats", ["account", "chatId", "timestamp"]);
					messages.createIndex("localId", ["account", "chatId", "localId"]);
				}
				if (!db.objectStoreNames.contains("keyvaluepairs")) {
					upgradeDb.createObjectStore("keyvaluepairs");
				}
				if (!db.objectStoreNames.contains("chats")) {
					upgradeDb.createObjectStore("chats", { keyPath: ["account", "chatId"] });
				}
			};
			dbOpenReq.onsuccess = (event) => {
				db = event.target.result;
				if (!db.objectStoreNames.contains("messages") || !db.objectStoreNames.contains("keyvaluepairs") || !db.objectStoreNames.contains("chats")) {
					db.close();
					openDb(db.version + 1);
				}
			};
		}
		openDb();

		var cache = null;
		caches.open(dbname).then((c) => cache = c);

		function mkNiUrl(hashAlgorithm, hashBytes) {
			const b64url = btoa(Array.from(new Uint8Array(hashBytes), (x) => String.fromCodePoint(x)).join("")).replace(/\+/, "-").replace(/\//, "_").replace(/=/, "");
			return "/.well-known/ni/" + hashAlgorithm + "/" + b64url;
		}

		function promisifyRequest(request) {
			return new Promise((resolve, reject) => {
				request.oncomplete = request.onsuccess = () => resolve(request.result);
				request.onabort = request.onerror = () => reject(request.error);
			});
		}

		function hydrateMessage(value) {
			const message = new xmpp.ChatMessage();
			message.localId = value.localId ? value.localId : null;
			message.serverId = value.serverId ? value.serverId : null;
			message.serverIdBy = value.serverIdBy ? value.serverIdBy : null;
			message.timestamp = value.timestamp && value.timestamp.toISOString();
			message.to = value.to && xmpp.JID.parse(value.to);
			message.from = value.from && xmpp.JID.parse(value.from);
			message.sender = value.sender && xmpp.JID.parse(value.sender);
			message.recipients = value.recipients.map((r) => xmpp.JID.parse(r));
			message.replyTo = value.replyTo.map((r) => xmpp.JID.parse(r));
			message.threadId = value.threadId;
			message.attachments = value.attachments;
			message.text = value.text;
			message.lang = value.lang;
			message.direction = value.direction == "MessageReceived" ? xmpp.MessageDirection.MessageReceived : xmpp.MessageDirection.MessageSent;
			return message;
		}

		return {
			lastId: function(account, jid, callback) {
				const tx = db.transaction(["messages"], "readonly");
				const store = tx.objectStore("messages");
				var cursor = null;
				if (jid === null) {
					cursor = store.index("chats").openCursor(
						IDBKeyRange.bound([account], [account, [], []]),
						"prev"
					);
				} else {
					cursor = store.index("chats").openCursor(
						IDBKeyRange.bound([account, jid], [account, jid, []]),
						"prev"
					);
				}
				cursor.onsuccess = (event) => {
					if (!event.target.result || (event.target.result.value.serverId && (jid || event.target.result.value.serverIdBy === account))) {
						callback(event.target.result ? event.target.result.value.serverId : null);
					} else {
						event.target.result.continue();
					}
				}
				cursor.onerror = (event) => {
					console.error(event);
					callback(null);
				}
			},

			storeChat: function(account, chat) {
				const tx = db.transaction(["chats"], "readwrite");
				const store = tx.objectStore("chats");

				store.put({
					account: account,
					chatId: chat.chatId,
					trusted: chat.trusted,
					avatarSha1: chat.avatarSha1,
					presence: chat.presence,
					displayName: chat.displayName,
					uiState: chat.uiState?.toString(),
					extensions: chat.extensions?.toString(),
					disco: chat.disco,
					class: chat instanceof xmpp.DirectChat ? "DirectChat" : (chat instanceof xmpp.Channel ? "Channel" : "Chat")
				});
			},

			getChats: function(account, callback) {
				const tx = db.transaction(["chats"], "readonly");
				const store = tx.objectStore("chats");
				const range = IDBKeyRange.bound([account], [account, []]);
				promisifyRequest(store.getAll(range)).then((result) => callback(result.map((r) => new xmpp.SerializedChat(
					r.chatId,
					r.trusted,
					r.avatarSha1,
					r.presence,
					r.displayName,
					r.uiState,
					r.extensions,
					r.disco,
					r.class
				))));
			},

			getChatsUnreadDetails: function(account, chatsArray, callback) {
				const tx = db.transaction(["messages"], "readonly");
				const store = tx.objectStore("messages");

				const cursor = store.index("chats").openCursor(
					IDBKeyRange.bound([account], [account, [], []]),
					"prev"
				);
				const chats = {};
				chatsArray.forEach((chat) => chats[chat.chatId] = chat);
				const result = {};
				var rowCount = 0;
				cursor.onsuccess = (event) => {
					if (event.target.result && rowCount < 1000) {
						rowCount++;
						const value = event.target.result.value;
						if (result[value.chatId]) {
							if (!result[value.chatId].foundAll) {
								const readUpTo = chats[value.chatId]?.readUpTo();
								if (readUpTo === value.serverId || readUpTo === value.localId || value.direction == "MessageSent") {
									result[value.chatId].foundAll = true;
								} else {
									result[value.chatId].unreadCount++;
								}
							}
						} else {
							const readUpTo = chats[value.chatId]?.readUpTo();
							const haveRead = readUpTo === value.serverId || readUpTo === value.localId || value.direction == "MessageSent";
							result[value.chatId] = { chatId: value.chatId, message: hydrateMessage(value), unreadCount: haveRead ? 0 : 1, foundAll: haveRead };
						}
						event.target.result.continue();
					} else {
						callback(Object.values(result));
					}
				}
				cursor.onerror = (event) => {
					console.error(event);
					callback([]);
				}
			},

			storeMessage: function(account, message) {
				const tx = db.transaction(["messages"], "readwrite");
				const store = tx.objectStore("messages");
				if (!message.serverId && !message.localId) throw "Cannot store a message with no id";
				if (!message.serverId && message.isIncoming()) throw "Cannot store an incoming message with no server id";
				promisifyRequest(store.index("localId").get([account, message.chatId(), message.localId || []])).then((result) => {
					if (result && !message.isIncoming() && result.direction === "MessageSent") return; // duplicate, we trust our own stanza ids

					store.put({
						...message,
						serverId: message.serverId || "",
						serverIdBy: message.serverIdBy || "",
						localId: message.localId || "",
						account: account,
						chatId: message.chatId(),
						to: message.to?.asString(),
						from: message.from?.asString(),
						sender: message.sender?.asString(),
						recipients: message.recipients.map((r) => r.asString()),
						replyTo: message.replyTo.map((r) => r.asString()),
						timestamp: new Date(message.timestamp),
						direction: message.direction.toString()
					});
				});
			},

			getMessages: function(account, chatId, beforeId, beforeTime, callback) {
				const beforeDate = beforeTime ? new Date(beforeTime) : [];
				const tx = db.transaction(["messages"], "readonly");
				const store = tx.objectStore("messages");
				const cursor = store.index("chats").openCursor(
					IDBKeyRange.bound([account, chatId], [account, chatId, beforeDate]),
					"prev"
				);
				const result = [];
				cursor.onsuccess = (event) => {
					if (event.target.result && result.length < 50) {
						const value = event.target.result.value;
						if (value.serverId === beforeId || (value.timestamp && value.timestamp.getTime() === (beforeDate instanceof Date && beforeDate.getTime()))) {
							event.target.result.continue();
							return;
						}

						result.unshift(hydrateMessage(value));
						event.target.result.continue();
					} else {
						callback(result);
					}
				}
				cursor.onerror = (event) => {
					console.error(event);
					callback([]);
				}
			},

			getMediaUri: function(hashAlgorithm, hash, callback) {
				var niUrl;
				if (hashAlgorithm == "sha-256") {
					niUrl = mkNiUrl(hashAlgorithm, hash);
				} else {
					niUrl = localStorage.getItem(mkNiUrl(hashAlgorithm, hash));
					if (!niUrl) {
						callback(null);
						return;
					}
				}
				cache.match(niUrl).then((response) => {
					if (response) {
						response.blob().then((blob) => {
							callback(URL.createObjectURL(blob));
						});
					} else {
						callback(null);
					}
				});
			},

			storeMedia: function(mime, buffer, callback) {
				(async function() {
					const sha256 = await crypto.subtle.digest("SHA-256", buffer);
					const sha512 = await crypto.subtle.digest("SHA-512", buffer);
					const sha1 = await crypto.subtle.digest("SHA-1", buffer);
					const sha256NiUrl = mkNiUrl("sha-256", sha256);
					await cache.put(sha256NiUrl, new Response(buffer, { headers: { "Content-Type": mime } }));
					localStorage.setItem(mkNiUrl("sha-1", sha1), sha256NiUrl);
					localStorage.setItem(mkNiUrl("sha-512", sha512), sha256NiUrl);
				})().then(callback);
			},

			storeCaps: function(caps) {
				localStorage.setItem("caps:" + caps.ver(), JSON.stringify(caps));
			},

			getCaps: function(ver, callback) {
				const raw = JSON.parse(localStorage.getItem("caps:" + ver));
				if (raw) {
					callback(new xmpp.Caps(raw.node, raw.identities.map((identity) => new xmpp.Identity(identity.category, identity.type, identity.name)), raw.features));
				} else {
					callback(null);
				}
			},

			storeLogin: function(login, clientId, token) {
				const tx = db.transaction(["keyvaluepairs"], "readwrite");
				const store = tx.objectStore("keyvaluepairs");
				store.put(clientId, "login:clientId:" + login).onerror = console.error;
				if (token != null) store.put(token, "login:token:" + login).onerror = console.error;
			},

			getLogin: function(login, callback) {
				const tx = db.transaction(["keyvaluepairs"], "readonly");
				const store = tx.objectStore("keyvaluepairs");
				Promise.all([
					promisifyRequest(store.get("login:clientId:" + login)),
					promisifyRequest(store.get("login:token:" + login))
				]).then((result) => {
					callback({
						clientId: result[0],
						token: result[1]
					});
				}).catch((e) => {
					callback({});
				});
			}
		}
	}
};
