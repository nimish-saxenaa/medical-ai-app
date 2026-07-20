import 'package:audioplayers/audioplayers.dart';

/// Audio routing for Dr AI's voice.
///
/// This app records (mic) and plays back (TTS) in the same audio session. The
/// `record` package puts iOS into the `playAndRecord` category, and under that
/// category output defaults to the earpiece *receiver* rather than the
/// loudspeaker. Playback then reports success — no exception, no error event,
/// the player state even goes to `playing` — while being inaudible unless the
/// phone is held to the ear. `defaultToSpeaker` is what forces it back out to
/// the loudspeaker.
///
/// Applied once at startup and again before each clip, because recording can
/// take the session back at any point during a consultation.
final AudioContext speakerAudioContext = AudioContext(
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playAndRecord,
    options: const {
      AVAudioSessionOptions.defaultToSpeaker,
      AVAudioSessionOptions.allowBluetooth,
      AVAudioSessionOptions.allowBluetoothA2DP,
    },
  ),
  android: AudioContextAndroid(
    isSpeakerphoneOn: true,
    stayAwake: true,
    contentType: AndroidContentType.speech,
    usageType: AndroidUsageType.assistant,
    audioFocus: AndroidAudioFocus.gainTransientMayDuck,
  ),
);
