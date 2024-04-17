package snikket.jingle;

import snikket.ID;
import HaxeCBridge;

typedef Transceiver = {
	receiver: Null<{ track: MediaStreamTrack }>,
	sender: Null<{ track: MediaStreamTrack, dtmf: DTMFSender }>
}

@:buildXml("
<target id='haxe'>
  <lib name='-lopus'/>
</target>
")
@:include("opus/opus.h")
@:native("OpusDecoder*")
extern class OpusDecoder {
	@:native("opus_decoder_create")
	public static function create(clockRate: cpp.Int32, channels: Int, error: cpp.Pointer<Int>): OpusDecoder;
	@:native("opus_decoder_destroy")
	public static function destroy(decoder: OpusDecoder): Void;
	@:native("opus_decode")
	public static function decode(decoder: OpusDecoder, data: cpp.Pointer<cpp.UInt8>, len: cpp.Int32, pcm: cpp.Pointer<cpp.Int16>, frameSize: Int, decodeFec: Bool): Int;
}

@:buildXml("
<target id='haxe'>
  <lib name='-lopus'/>
</target>
")
@:include("opus/opus.h")
@:native("OpusEncoder*")
extern class OpusEncoder {
	@:native("opus_encoder_create")
	public static function create(clockRate: cpp.Int32, channels: Int, application: Int, error: cpp.Pointer<Int>): OpusEncoder;
	@:native("opus_encoder_destroy")
	public static function destroy(encoder: OpusEncoder): Void;
	@:native("opus_encode")
	public static function encode(encoder: OpusEncoder, pcm: cpp.Pointer<cpp.Int16>, frameSize: Int, data: cpp.Pointer<cpp.UInt8>, maxDataBytes: cpp.Int32): cpp.Int32;
}

@:include("fstream")
@:native("std::byte")
@:unreflective
extern class Byte {}

abstract CppByte(Byte) {
	@:to
	inline public function toInt(): cpp.UInt8 {
		return (untyped __cpp__("static_cast<const char>({0})", this) : cpp.Char);
	}
}

@:native("std::optional")
@:unreflective
@:structAccess
extern class StdOptional<T> {
	public function new(v:T);
	public function has_value():Bool;
	public function value():T;
}

@:native("std::vector")
@:unreflective
@:structAccess
extern class StdVector<T> {
	public function size(): cpp.SizeT;
	public function at(idx: cpp.SizeT): T;
	public function data(): cpp.Pointer<T>;
}

@:native("std::string")
@:unreflective
@:structAccess
extern class RawStdString {}

abstract StdString(RawStdString) {
	@:to
	inline public function toString(): String {
		return (untyped __cpp__("::hx::StdString({0})", this) : cpp.StdString).toString();
	}
}

@:native("std::shared_ptr")
@:unreflective
extern class SharedPtr<T> {
	public var ref (get, never): cpp.Reference<T>;

	inline public function get_ref() {
		return cast this;
	}
}

@:native("rtc::Description::Type")
extern class DescriptionType {}

extern enum abstract SdpType(cpp.Struct<DescriptionType>) from cpp.Struct<DescriptionType> {
	@:native("cpp::Struct(rtc::Description::Type::Unspec)")
	var UNSPEC;
	@:native("cpp::Struct(rtc::Description::Type::Offer)")
	var OFFER;
	@:native("cpp::Struct(rtc::Description::Type::Answer)")
	var ANSWER;
	@:native("cpp::Struct(rtc::Description::Type::PrAnswer)")
	var PRANSWER;
	@:native("cpp::Struct(rtc::Description::Type::Rollback)")
	var ROLLBACK;

	@:to
	inline function toNative() {
		return cast (this, cpp.Struct<DescriptionType>);
	}
}

@:native("rtc::Description::Direction")
extern class DescriptionDirection {}

extern enum abstract Direction(cpp.Struct<DescriptionDirection>) from cpp.Struct<DescriptionDirection> {
	@:native("cpp::Struct(rtc::Description::Direction::SendOnly)")
	var SendOnly;
	@:native("cpp::Struct(rtc::Description::Direction::RecvOnly)")
	var RecvOnly;
	@:native("cpp::Struct(rtc::Description::Direction::SendRecv)")
	var SendRecv;
	@:native("cpp::Struct(rtc::Description::Direction::Inactive)")
	var Inactive;
	@:native("cpp::Struct(rtc::Description::Direction::Unknown)")
	var Unknown;

	@:to
	inline function toNative() {
		return cast (this, cpp.Struct<DescriptionDirection>);
	}
}

@:native("rtc::Description::Media::RtpMap")
@:unreflective
@:structAccess
extern class RtpMap {
	public var format: StdString;
	public var clockRate: Int;
	public var encParams: StdString;
}

@:include("rtc/rtc.hpp")
@:native("rtc::Description::Media")
@:unreflective
@:structAccess
extern class DescriptionMedia {
	public function mid():StdString;
	public function type():StdString;
	public function payloadTypes(): StdVector<Int>;
	public function rtpMap(payloadType: Int): cpp.RawPointer<RtpMap>;
	public function addSSRC(ssrc: cpp.UInt32, cname: cpp.StdString): Void;
}

@:native("rtc::Description::Audio")
@:unreflective
@:structAccess
extern class DescriptionAudio extends DescriptionMedia {
	public function new(mid: cpp.StdString, direction: cpp.Struct<DescriptionDirection>):Void;
	public function addAudioCodec(payloadType: Int, codec: cpp.StdString):Void;
	public function addOpusCodec(payloadType: Int):Void;
	public function addPCMUCodec(payloadType: Int):Void;
}

@:include("rtc/frameinfo.hpp")
@:native("rtc::FrameInfo")
@:unreflective
@:structAccess
extern class FrameInfo {
	public var payloadType: cpp.UInt8;
	public var timestamp: cpp.UInt32;
}

@:include("rtc/rtc.hpp")
@:native("rtc::Track")
@:unreflective
@:structAccess
extern class Track {
	public function new(sdp: cpp.StdString, sdpType: cpp.Struct<DescriptionType>):Void;
	public function description(): DescriptionMedia;
	public function mid(): StdString;
	public function close(): Void;
	public function isOpen(): Bool;
	public function isClosed(): Bool;
	public function setMediaHandler<T>(handler: SharedPtr<T>): Void;
	public function send(data: cpp.Pointer<Byte>, size: cpp.SizeT): Void;
}

@:include("rtc/rtc.hpp")
@:native("rtc::RtpPacketizationConfig")
@:unreflective
@:structAccess
extern class RtpPacketizationConfig {
	public var payloadType: cpp.UInt8;
	public var clockRate: cpp.UInt32;
	public var timestamp: cpp.UInt32;

	@:native("std::make_shared<rtc::RtpPacketizationConfig>")
	public static function makeShared(ssrc: cpp.UInt32, cname: cpp.StdString, payloadType: cpp.UInt8, clockRate: cpp.UInt32): SharedPtr<RtpPacketizationConfig>;
}

@:include("rtc/rtc.hpp")
@:native("rtc::RtpPacketizer")
@:unreflective
@:structAccess
extern class RtpPacketizer {
	@:native("std::make_shared<rtc::RtpPacketizer>")
	public static function makeShared(config: SharedPtr<RtpPacketizationConfig>): SharedPtr<RtpPacketizer>;
}

@:include("rtc/rtc.hpp")
@:native("rtc::RtpDepacketizer")
@:unreflective
@:structAccess
extern class RtpDepacketizer {
	@:native("std::make_shared<rtc::RtpDepacketizer>")
	public static function makeShared(): SharedPtr<RtpDepacketizer>;
	public function addToChain<T>(handler: SharedPtr<T>): Void;
}

@:include("rtc/rtc.hpp")
@:native("rtc::RtcpReceivingSession")
@:unreflective
@:structAccess
extern class RtcpReceivingSession {
	@:native("std::make_shared<rtc::RtcpReceivingSession>")
	public static function makeShared(): SharedPtr<RtcpReceivingSession>;
}

@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
class DTMFSender {
	public function new(track: MediaStreamTrack) {

	}
}

@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
class AudioFormat {
	@:allow(snikket)
	private final format: String;
	@:allow(snikket)
	private final payloadType: cpp.UInt8;
	public final clockRate: Int;
	public final channels: Int;
	public function new(format: String, payloadType: cpp.UInt8, clockRate: Int, channels: Int) {
		this.format = format;
		this.payloadType = payloadType;
		this.clockRate = clockRate;
		this.channels = channels;
	}
}

@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
class MediaStreamTrack {
	public var id (get, never): String;
	public var muted (get, never): Bool;
	public var kind (get, never): String;
	public var supportedAudioFormats (get, never): Array<AudioFormat>;
	private var pcmCallback: Null<(Array<cpp.Int16>,Int,Int)->Void> = null;
	private var readyForPCMCallback: Null<()->Void> = null;
	private var opus: cpp.Struct<OpusDecoder>;
	private var opusEncoder: cpp.Struct<OpusEncoder>;
	private var rtpPacketizationConfig: SharedPtr<RtpPacketizationConfig>;
	private var eventLoop: Null<sys.thread.EventLoop> = null;
	private var alive = true;

	@:allow(snikket)
	private var media(get, default): StdOptional<DescriptionMedia>;

	@:allow(snikket)
	private var track(default, set): SharedPtr<Track>;

	@:allow(snikket)
	private static function fromTrack(t: SharedPtr<Track>): MediaStreamTrack {
		final media = new MediaStreamTrack();
		media.track = t;
		return media;
	}

	@:allow(snikket)
	private function new() { }

	private function get_media() {
		if (untyped __cpp__("!track")) {
			return media;
		}

		final d = track.ref.description();
		return new StdOptional(untyped __cpp__("d"));
	}
	private function get_id() {
		if (untyped __cpp__("!track")) {
			return media.value().mid();
		}

		return track.ref.mid();
	}
	private function get_kind() { return get_media().value().type(); }
	private function get_muted() { return false; }

	private function get_supportedAudioFormats() {
		final maybeMedia = media;
		if (!maybeMedia.has_value()) return [];
		final m = maybeMedia.value();
		final codecs = [];
		final payloadTypes = m.payloadTypes();
		for (i in 0...payloadTypes.size()) {
			final rtp: RtpMap = cpp.Pointer.fromRaw(m.rtpMap(payloadTypes.at(i))).ref;
			codecs.push(new AudioFormat(rtp.format, payloadTypes.at(i), rtp.clockRate, rtp.encParams == "" ? 1 : Std.parseInt(rtp.encParams)));
			if (rtp.format == "opus") { // We can encode opus from 8k or 16k too, it's just 48k internal
				codecs.push(new AudioFormat(rtp.format, payloadTypes.at(i), 16000, rtp.encParams == "" ? 1 : Std.parseInt(rtp.encParams)));
				codecs.push(new AudioFormat(rtp.format, payloadTypes.at(i), 8000, rtp.encParams == "" ? 1 : Std.parseInt(rtp.encParams)));
			}
		}

		return codecs;
	}

	private function set_track(newTrack: SharedPtr<Track>) {
		if (untyped __cpp__("!track")) {
			if (kind == "audio") {
				track = newTrack;
				final depacket = RtpDepacketizer.makeShared();
				final rtcp = RtcpReceivingSession.makeShared();
				depacket.ref.addToChain(rtcp);
				rtpPacketizationConfig = RtpPacketizationConfig.makeShared(
					0, // TODO: allocate an SSRC
					cpp.StdString.ofString("audio"),
					0,
					8000
				);
				final packet = RtpPacketizer.makeShared(rtpPacketizationConfig);
				depacket.ref.addToChain(packet);
				track.ref.setMediaHandler(depacket);
				untyped __cpp__("{0}->onFrame([this](rtc::binary msg, rtc::FrameInfo frame_info) { this->onFrame(msg, frame_info); });", track);
				alive = true;
				eventLoop = sys.thread.Thread.createWithEventLoop(() -> while(alive) { sys.thread.Thread.processEvents(); sys.thread.Thread.current().events.wait(); }).events;
				untyped __cpp__("{0}->onOpen([this]() { this->notifyReadyForData(true); });", track);
			}
			untyped __cpp__("{0}->onClosed([this]() { this->stop(); });", track);
		} else {
			throw "Track already set";
		}

		return track;
	}

	/**
		Event fired for new inbound audio frame

		@param callback takes three arguments, the Signed 16-bit PCM data, the clock rate, and the number of channels
	**/
	public function addPCMListener(callback: (Array<cpp.Int16>,Int,Int)->Void) {
		pcmCallback = callback;
	}

	static final ULAW_DECODE: Array<cpp.Int16> = [-32124, -31100, -30076, -29052, -28028, -27004, -25980, -24956, -23932, -22908, -21884, -20860, -19836, -18812, -17788, -16764, -15996, -15484, -14972, -14460, -13948, -13436, -12924, -12412, -11900, -11388, -10876, -10364, -9852, -9340, -8828, -8316, -7932, -7676, -7420, -7164, -6908, -6652, -6396, -6140, -5884, -5628, -5372, -5116, -4860, -4604, -4348, -4092, -3900, -3772, -3644, -3516, -3388, -3260, -3132, -3004, -2876, -2748, -2620, -2492, -2364, -2236, -2108, -1980, -1884, -1820, -1756, -1692, -1628, -1564, -1500, -1436, -1372, -1308, -1244, -1180, -1116, -1052, -988, -924, -876, -844, -812, -780, -748, -716, -684, -652, -620, -588, -556, -524, -492, -460, -428, -396, -372, -356, -340, -324, -308, -292, -276, -260, -244, -228, -212, -196, -180, -164, -148, -132, -120, -112, -104, -96, -88, -80, -72, -64, -56, -48, -40, -32, -24, -16, -8, 0, 32124, 31100, 30076, 29052, 28028, 27004, 25980, 24956, 23932, 22908, 21884, 20860, 19836, 18812, 17788, 16764, 15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412, 11900, 11388, 10876, 10364, 9852, 9340, 8828, 8316, 7932, 7676, 7420, 7164, 6908, 6652, 6396, 6140, 5884, 5628, 5372, 5116, 4860, 4604, 4348, 4092, 3900, 3772, 3644, 3516, 3388, 3260, 3132, 3004, 2876, 2748, 2620, 2492, 2364, 2236, 2108, 1980, 1884, 1820, 1756, 1692, 1628, 1564, 1500, 1436, 1372, 1308, 1244, 1180, 1116, 1052, 988, 924, 876, 844, 812, 780, 748, 716, 684, 652, 620, 588, 556, 524, 492, 460, 428, 396, 372, 356, 340, 324, 308, 292, 276, 260, 244, 228, 212, 196, 180, 164, 148, 132, 120, 112, 104, 96, 88, 80, 72, 64, 56, 48, 40, 32, 24, 16, 8, 0];
	static final ULAW_EXP: Array<cpp.UInt8> = [0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7];

	private static function pcmToUlaw(sample: cpp.Int16): cpp.UInt8 {
		final sign = if (sample < 0) {
			sample = -sample;
			0x80;
		} else {
			0;
		}

		// Clip the sample if it exceeds the maximum value
		if (sample > 32635) {
			sample = 32635;
		}

		sample += 0x84; // ulaw bias
		final exponent = ULAW_EXP[(sample >> 8) & 0x7F];
		final mantissa = (sample >> (exponent + 3)) & 0x0F;
		return ~(sign | (exponent << 4) | mantissa);
	}

	private function onFrame(msg: StdVector<CppByte>, frameInfo: FrameInfo) {
		untyped __cpp__("int base = 0; hx::SetTopOfStack(&base, true);"); // allow running haxe code on foreign thread
		final rtp: RtpMap = cpp.Pointer.fromRaw(track.ref.description().rtpMap(frameInfo.payloadType)).ref;
		final format: String = rtp.format;
		final channels = rtp.encParams == "" ? 1 : Std.parseInt(rtp.encParams);
		if (format == "PCMU") {
			final s16 = new haxe.ds.Vector(msg.size());
			for (i in 0...msg.size()) {
				s16[i] = ULAW_DECODE[cast msg.at(i)];
			}
			if (pcmCallback != null) pcmCallback(s16.toData(), rtp.clockRate, channels);
		} else if (format == "opus") {
			final s16 = new haxe.ds.Vector(5760).toData(); // 5760 is the max size needed for 48khz
			if (untyped __cpp__("!opus")) opus = OpusDecoder.create(rtp.clockRate, channels, null); // assume only one opus clockRate+channels for this track
			// TODO: Pass data of NULL to mean lost packet. In the case of PLC (data==NULL) or FEC (decode_fec=1), then frame_size needs to be exactly the duration of audio that is missing, otherwise the decoder will not be in the optimal state to decode the next incoming packet. For the PLC and FEC cases, frame_size must be a multiple of 2.5 ms.
			final decoded = OpusDecoder.decode(opus, cast msg.data(), msg.size(), cpp.Pointer.ofArray(s16), Std.int(s16.length / channels), false);
			s16.resize(decoded * channels);
			if (pcmCallback != null) pcmCallback(s16, rtp.clockRate, channels);
		} else {
			trace("Ignoring audio frame with format", format);
		}
		untyped __cpp__("hx::SetTopOfStack((int*)0, true);"); // unregister with GC
	}

	/**
		Event fired when ready for next outbound audio frame

		@param callback
	**/
	public function addReadyForPCMListener(callback: ()->Void) {
		readyForPCMCallback = callback;
		if (untyped __cpp__("track") && track.ref.isOpen()) {
			notifyReadyForData(false);
		}
	}

	private function notifyReadyForData(fromCPP: Bool) {
		untyped __cpp__("if (fromCPP) { int base = 0; hx::SetTopOfStack(&base, true); }"); // allow running haxe code on foreign thread
		if (readyForPCMCallback != null) {
			eventLoop.run(() -> readyForPCMCallback());
		}
		untyped __cpp__("if (fromCPP) { hx::SetTopOfStack((int*)0, true); }"); // unregister with GC
	}

	/**
		Send new audio to this track

		@param pcm 16-bit signed linear PCM data (interleaved)
		@param clockRate the sampling rate of the data
		@param channels the number of audio channels
	**/
	public function writePCM(pcm: Array<cpp.Int16>, clockRate: Int, channels: Int) {
		final format = Lambda.find(supportedAudioFormats, format -> format.clockRate == clockRate && format.channels == channels);
		if (format == null) throw "Unsupported audo format: " + clockRate + "/" + channels;
		eventLoop.run(() -> {
			if (track.ref.isClosed()) return;
			rtpPacketizationConfig.ref.payloadType = format.payloadType;
			rtpPacketizationConfig.ref.clockRate = clockRate;
			if (format.format == "PCMU") {
				track.ref.send(cpp.Pointer.ofArray(pcm.map(pcmToUlaw)).reinterpret(), pcm.length);
			} else if (format.format == "opus") {
				if (untyped __cpp__("!{0}", opusEncoder)) {
					opusEncoder = OpusEncoder.create(clockRate, channels, untyped __cpp__("OPUS_APPLICATION_VOIP"), null); // assume only one opus clockRate+channels for this track
					untyped __cpp__("opus_encoder_ctl({0}, OPUS_SET_BITRATE(24))", opusEncoder);
					untyped __cpp__("opus_encoder_ctl({0}, OPUS_SET_PACKET_LOSS_PERC(5))", opusEncoder);
					untyped __cpp__("opus_encoder_ctl({0}, OPUS_SET_INBAND_FEC(1))", opusEncoder);
				}
				final rawOpus = new haxe.ds.Vector(pcm.length * 2).toData(); // Shoudn't be bigger than the input
				final encoded = OpusEncoder.encode(opusEncoder, cpp.Pointer.ofArray(pcm), Std.int(pcm.length / channels), cpp.Pointer.ofArray(rawOpus), rawOpus.length);
				rawOpus.resize(encoded);
				track.ref.send(cpp.Pointer.ofArray(rawOpus).reinterpret(), rawOpus.length);
			} else {
				trace("Ignoring audio meant to go out as", format.format, format.clockRate, format.channels);
			}
			rtpPacketizationConfig.ref.timestamp = rtpPacketizationConfig.ref.timestamp + Std.int(pcm.length / channels); // timestamp is in samples
			notifyReadyForData(false);
		});
	}

	public function stop() {
		alive = false;
		if (!track.ref.isClosed()) track.ref.close();
		if (untyped __cpp__("opus")) {
			OpusDecoder.destroy(opus);
			opus = null;
		}
	}
}

@:build(HaxeCBridge.expose())
@:build(HaxeSwiftBridge.expose())
class MediaStream {
	private final tracks = [];

	/**
		Create default bidirectional audio track
	**/
	public static function makeAudio(): MediaStream {
		final audio = new DescriptionAudio(cpp.StdString.ofString(ID.tiny()), SendRecv);
		audio.addOpusCodec(107); // May need to get from rtpmap?
		audio.addPCMUCodec(0);
		audio.addAudioCodec(101, cpp.StdString.ofString("telephone-event/8000")); // May need to get from rtpmap?
		final media = new MediaStreamTrack();
		media.media = new StdOptional(untyped __cpp__("audio"));
		final stream = new MediaStream();
		stream.addTrack(media);
		return stream;
	}

	public function new() {}

	public function addTrack(track: MediaStreamTrack) {
		tracks.push(track);
	}

	public function getTracks(): Array<MediaStreamTrack> {
		return tracks;
	}
}

typedef SessionDescriptionInit = {
	var ?sdp : String;
	var type : SdpType;
}

typedef Configuration = {
	//var ?bundlePolicy : BundlePolicy;
	//var ?certificates : Array<Certificate>;
	var ?iceServers : Array<IceServer>;
	//var ?iceTransportPolicy : IceTransportPolicy;
	var ?peerIdentity : String;
}

@:native("rtc::Description")
@:unreflective
@:structAccess
extern class Description {
	public function new(sdp: cpp.StdString, sdpType: cpp.Struct<DescriptionType>):Void;
	public function generateSdp(): StdString;
}

@:native("rtc::Candidate")
@:unreflective
@:structAccess
extern class Candidate {
	public function new(candidate: cpp.StdString, mid: cpp.StdString):Void;
	public function candidate(): StdString;
	public function mid(): StdString;
}

@:buildXml("
<target id='haxe'>
  <lib name='-ldatachannel'/>
</target>
")
@:include("rtc/rtc.hpp")
@:native("rtc::PeerConnection")
@:structAccess
@:unreflective
extern class PC {
	@:native("std::make_shared<rtc::PeerConnection>")
	public static function makeShared(): SharedPtr<PC>; // TODO: config option
	public function localDescription():StdOptional<Description>;
	public function setLocalDescription(sdpType: DescriptionType):Void;
	public function onLocalDescription(callback: cpp.Callable<Description->Void>):Void;
	public function setRemoteDescription(description: Description):Void;
	public function addRemoteCandidate(candidate: Candidate):Void;
	public function addTrack(media: DescriptionMedia):SharedPtr<Track>;
	public function onTrack(callback: cpp.Callable<SharedPtr<Track>->Void>):Void;
	public function onLocalCandidate(callback: cpp.Callable<Candidate->Void>):Void;
	public function close():Void;
}

class PeerConnection {
	public var localDescription(get, null): { sdp: Null<String> };

	var _pc: SharedPtr<PC>;
	var pc: cpp.Pointer<PC>;
	var waitingOnLocal: Null<Any->Void> = null;
	final tracks: Map<String, MediaStreamTrack> = [];
	final trackListeners = [];
	final localCandidateListeners = [];
	final mainLoop: sys.thread.EventLoop;

	public function new(?configuration : Configuration, ?constraints : Dynamic){
		if (Sys.getEnv("SNIKKET_WEBRTC_DEBUG") != null) {
			untyped __cpp__("rtc::InitLogger(rtc::LogLevel::Verbose);");
		}
		mainLoop = sys.thread.Thread.current().events;
		_pc = PC.makeShared();
		pc = cpp.Pointer.fromRaw(untyped __cpp__("{0}.get()", _pc));
		pc.ref.onLocalDescription(cast untyped __cpp__("[this](auto d) { this->onLocalDescription(); }"));
		pc.ref.onTrack(cast untyped __cpp__("[this](auto t) { this->onTrack(t); }"));
		pc.ref.onLocalCandidate(cast untyped __cpp__("[this](auto c) { this->onLocalCandidate(c); }"));
	}

	private function onLocalDescription() {
		untyped __cpp__("int base = 0; hx::SetTopOfStack(&base, true);"); // allow running haxe code on foreign thread
		mainLoop.run(() -> {
			if (waitingOnLocal != null) waitingOnLocal(null);
			waitingOnLocal = null;
		});
		untyped __cpp__("hx::SetTopOfStack((int*)0, true);"); // unregister with GC
	}

	private function onLocalCandidate(candidate: Candidate) {
		untyped __cpp__("int base = 0; hx::SetTopOfStack(&base, true);"); // allow running haxe code on foreign thread
		mainLoop.run(() -> {
			for (cb in localCandidateListeners) {
				cb({ candiate: {
					candidate: (candidate.candidate() : String),
					sdpMid: (candidate.mid() : String),
					usernameFragment: null // TODO?
				}});
			}
		});
		untyped __cpp__("hx::SetTopOfStack((int*)0, true);"); // unregister with GC
	}

	private function onTrack(track: SharedPtr<Track>) {
		untyped __cpp__("int base = 0; hx::SetTopOfStack(&base, true);"); // allow running haxe code on foreign thread
		mainLoop.run(() -> {
			final media = MediaStreamTrack.fromTrack(track);
			tracks[media.id] = media;
			for (cb in trackListeners) {
				cb({ track: media, streams: [] });
			}
		});
		untyped __cpp__("hx::SetTopOfStack((int*)0, true);"); // unregister with GC
	}

	public function get_localDescription() {
		final desc = pc.ref.localDescription();
		if (desc.has_value()) {
			return { sdp: desc.value().generateSdp() };
		} else {
				return null;
		}
	}

	public function setLocalDescription(sdpType: Null<SdpType>): Promise<Any> {
		return new Promise((resolve, reject) -> {
			waitingOnLocal = resolve;
			pc.ref.setLocalDescription(sdpType ?? SdpType.UNSPEC);
		});
	}

	public function setRemoteDescription(description : SessionDescriptionInit): Promise<Any> {
		pc.ref.setRemoteDescription(new Description(cpp.StdString.ofString(description.sdp), description.type));
		return Promise.resolve(null);
	}

	public function addIceCandidate(candidate : { candidate: String, sdpMid: String, sppMLineIndex: Int, usernameFragment: String }): Promise<Any> {
		pc.ref.addRemoteCandidate(new Candidate(cpp.StdString.ofString(candidate.candidate), cpp.StdString.ofString(candidate.sdpMid)));
		return Promise.resolve(null);
	}

	public function addTrack(track : MediaStreamTrack, stream : MediaStream) {
		track.track = pc.ref.addTrack(track.media.value());
		tracks[track.id] = track;
	}

	public function getTransceivers(): Array<Transceiver> {
		// TODO: check direction and set receiver or sender to null
		final ts = [];
		for (mid => track in tracks) {
			ts.push({
				receiver: { track: track },
				sender: { track: track, dtmf: new DTMFSender(track) }
			});
		}
		return ts;
	}

	public function close() {
		pc.ref.close();
	}

	public function addEventListener(event: String, callback: Dynamic->Void) {
		if (event == "track") trackListeners.push(callback);
		if (event == "icecandidate") localCandidateListeners.push(callback);
	}
}

typedef Promise<T> = thenshim.Promise<T>;
