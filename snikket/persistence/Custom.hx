package snikket.persistence;

#if cpp
import HaxeCBridge;
#end
import haxe.io.BytesData;
import snikket.Caps;
import snikket.Chat;
import snikket.Message;

@:expose
#if cpp
@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
#end
class Custom implements Persistence {
	private final backing: Persistence;
	private var _storeMessage: Null<(String, ChatMessage, Callback<ChatMessage>)->Bool> = null;

	/**
		Create a persistence layer that wraps another with optional overrides

		@returns new persistence layer
	**/
	public function new(backing: Persistence) {
		this.backing = backing;
	}

	@HaxeCBridge.noemit
	public function lastId(accountId: String, chatId: Null<String>, callback:(Null<String>)->Void):Void {
		backing.lastId(accountId, chatId, callback);
	}

	@HaxeCBridge.noemit
	public function storeChat(accountId: String, chat: Chat) {
		backing.storeChat(accountId, chat);
	}

	@HaxeCBridge.noemit
	public function getChats(accountId: String, callback: (Array<SerializedChat>)->Void) {
		backing.getChats(accountId, callback);
	}

	/**
		Override the storeMessage method of the underlying persistence layer

		@param f takes three arguments, the account ID, the ChatMessage to store, and the Callback to call when done
		       return false to pass control to the wrapped layer (do not call the Callback in this case)
	**/
	public function overrideStoreMessage(f: (String, ChatMessage, Callback<ChatMessage>)->Bool) {
		_storeMessage = f;
	}

	@HaxeCBridge.noemit
	public function storeMessage(accountId: String, message: ChatMessage, callback: (ChatMessage)->Void) {
		if (_storeMessage == null || !_storeMessage(accountId, message, new Callback(callback))) {
			backing.storeMessage(accountId, message, callback);
		}
	}

	@HaxeCBridge.noemit
	public function getMessagesBefore(accountId: String, chatId: String, beforeId: Null<String>, beforeTime: Null<String>, callback: (Array<ChatMessage>)->Void) {
		backing.getMessagesBefore(accountId, chatId, beforeId, beforeTime, callback);
	}

	@HaxeCBridge.noemit
	public function getMessagesAfter(accountId: String, chatId: String, afterId: Null<String>, afterTime: Null<String>, callback: (Array<ChatMessage>)->Void) {
		backing.getMessagesAfter(accountId, chatId, afterId, afterTime, callback);
	}

	@HaxeCBridge.noemit
	public function getMessagesAround(accountId: String, chatId: String, aroundId: Null<String>, aroundTime: Null<String>, callback: (Array<ChatMessage>)->Void) {
		backing.getMessagesAround(accountId, chatId, aroundId, aroundTime, callback);
	}

	@HaxeCBridge.noemit
	public function getChatsUnreadDetails(accountId: String, chats: Array<Chat>, callback: (Array<{ chatId: String, message: ChatMessage, unreadCount: Int }>)->Void) {
		backing.getChatsUnreadDetails(accountId, chats, callback);
	}

	@HaxeCBridge.noemit
	public function storeReaction(accountId: String, update: ReactionUpdate, callback: (Null<ChatMessage>)->Void) {
		backing.storeReaction(accountId, update, callback);
	}

	@HaxeCBridge.noemit
	public function updateMessageStatus(accountId: String, localId: String, status:MessageStatus, callback: (ChatMessage)->Void) {
		backing.updateMessageStatus(accountId, localId, status, callback);
	}

	@HaxeCBridge.noemit
	public function getMediaUri(hashAlgorithm:String, hash:BytesData, callback: (Null<String>)->Void) {
		backing.getMediaUri(hashAlgorithm, hash, callback);
	}

	@HaxeCBridge.noemit
	public function storeMedia(mime:String, bd:BytesData, callback: ()->Void) {
		backing.storeMedia(mime, bd, callback);
	}

	@HaxeCBridge.noemit
	public function storeCaps(caps:Caps) {
		backing.storeCaps(caps);
	}

	@HaxeCBridge.noemit
	public function getCaps(ver:String, callback: (Caps)->Void) {
		backing.getCaps(ver, callback);
	}

	@HaxeCBridge.noemit
	public function storeLogin(login:String, clientId:String, displayName:String, token:Null<String>) {
		backing.storeLogin(login, clientId, displayName, token);
	}

	@HaxeCBridge.noemit
	public function getLogin(login:String, callback:(Null<String>, Null<String>, Int, Null<String>)->Void) {
		backing.getLogin(login, callback);
	}

	@HaxeCBridge.noemit
	public function storeStreamManagement(accountId:String, sm:BytesData) {
		backing.storeStreamManagement(accountId, sm);
	}

	@HaxeCBridge.noemit
	public function removeAccount(accountId:String, completely:Bool) {
		backing.removeAccount(accountId, completely);
	}

	@HaxeCBridge.noemit
	public function getStreamManagement(accountId:String, callback: (BytesData)->Void) {
		backing.getStreamManagement(accountId, callback);
	}

	@HaxeCBridge.noemit
	public function storeService(accountId:String, serviceId:String, name:Null<String>, node:Null<String>, caps:Caps) {
		backing.storeService(accountId, serviceId, name, node, caps);
	}

	@HaxeCBridge.noemit
	public function findServicesWithFeature(accountId:String, feature:String, callback:(Array<{serviceId:String, name:Null<String>, node:Null<String>, caps: Caps}>)->Void) {
		backing.findServicesWithFeature(accountId, feature, callback);
	}
}

@:expose
#if cpp
@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
#end
class Callback<T> {
	private final f: T->Void;

	@:allow(snikket)
	private function new(f: T->Void) {
		this.f = f;
	}

	public function call(v: Any) {
		f(v);
	}
}
