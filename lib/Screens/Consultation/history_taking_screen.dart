import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:clinical_ai_app/Custom%20Widgets/Consultation/siri_waveform.dart';
import '../../Custom Widgets/custom_alert_dialog.dart';
import 'package:clinical_ai_app/Screens/Consultation/review_responses_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';
import '../../Components/layout_constants.dart';
import '../../Custom Widgets/Consultation/ai_speaking_orb.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Services/Consultation/consultation_streaming.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Components/colors.dart';

enum QnaState { idle, thinking }

enum VoiceStreamState {
  recording,
  transcribing,
  connecting,
  inactive,
  thinking,
}

class HistoryTakingScreen extends StatefulWidget {
  const HistoryTakingScreen({
    super.key,
    this.question = "This is a Question",
    required this.sessionId,
  });
  final String question;
  final String sessionId;
  static const routeName = "/history-taking";
  @override
  State<HistoryTakingScreen> createState() => _HistoryTakingScreenState();
}

class _HistoryTakingScreenState extends State<HistoryTakingScreen>
    with TickerProviderStateMixin {
  AudioRecorder recorder = AudioRecorder();
  // Using AAC-LC (best for iOS & Android streaming)
  // Backend supports: audio/aac, audio/wav, audio/mp4
  final recordConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    // Optional: customize if needed
    // sampleRate: 16000,     // 16kHz for speech (lower bandwidth)
    // bitRate: 128000,       // 128 kbps
    // numChannels: 1,        // Mono
  );
  VoiceStreamConnection? connection;
  QnaState qnaState = QnaState.idle;
  TextToSpeechState state = TextToSpeechState.idle;
  VoiceStreamState voiceStreamState = VoiceStreamState.inactive;
  late String question = widget.question;
  int questionNumber = 1;
  final TextEditingController answerController = TextEditingController();
  bool isMute = false;
  bool canAnswer = true;
  Duration recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final Random _random = Random();

  List<double> bars = List.generate(80, (_) => 0.0);

  double volume = 0.0;

  void startRecordingTimer() {
    recordingDuration = Duration.zero;

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void stopRecordingTimer() {
    _recordingTimer?.cancel();
    recordingDuration = Duration.zero;
  }

  String formatRecordingTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode focusNode = FocusNode();

  /// Writes the clip to a temp file and plays that.
  ///
  /// BytesSource cannot be used here: audioplayers' iOS implementation returns
  /// "setSourceBytes is not currently implemented on iOS", so in-memory
  /// playback fails on every Apple device. DeviceFileSource works on both
  /// platforms, so both take the same path.
  Future<void> playAudio(SpeechAudio clip) async {
    await _audioPlayer.stop();

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.${clip.fileExtension}',
    );
    await file.writeAsBytes(clip.bytes);

    // Replace the previous clip only once the new one is written, so a failure
    // here doesn't leave the screen with no audio at all.
    final previous = _currentClipFile;
    _currentClipFile = file;
    if (previous != null && await previous.exists()) {
      await previous.delete();
    }

    if (!mounted) return;
    setState(() {
      state = TextToSpeechState.active;
    });
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(DeviceFileSource(file.path));

    // Tells apart "the clip never decoded" (duration null/zero) from "it is
    // playing but routed somewhere inaudible" (duration present, state
    // playing) — the two have identical symptoms from the outside.
  }

  Future<void> playText({required String question, String? token}) async {
    setState(() {
      state = TextToSpeechState.loading;
    });
    try {
      audio = await textToSpeech(
        token: token ?? await AccessTokenService.getToken() ?? "",
        text: question,
      );
      await playAudio(audio!);
    } catch (e) {
      // Previously this threw into an unawaited future and vanished, leaving a
      // silent screen with no indication anything had gone wrong.
      if (!mounted) return;
      setState(() {
        state = TextToSpeechState.idle;
      });
      // The question still shows on screen, so without this the failure is
      // invisible and looks like the doctor simply never spoke.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice unavailable: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  File? _currentClipFile;

  SpeechAudio? audio;

  Future<void> sendAnswer() async {
    await _audioPlayer.stop();
    setState(() {
      qnaState = QnaState.thinking;
      state = TextToSpeechState.loading;
      questionNumber++;
      question = "";
    });
    try {
      String token = await AccessTokenService.getToken() ?? "";
      await for (final event in submitAnswerStream(
        token: token,
        sessionId: widget.sessionId,
        answer: answerController.text,
      )) {
        if (event.event == "token") {
          setState(() {
            question += event.data["text"];
            canAnswer = false;
          });
        }

        if (event.event == "done") {
          answerController.clear();
          if (event.data["next_question"] == null) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewResponsesScreen(
                  token: token,
                  sessionId: widget.sessionId,
                ),
              ),
            );
            return;
          }
          setState(() {
            question = event.data["next_question"];
            canAnswer = true;
            qnaState = QnaState.idle;
          });
          playText(question: event.data["next_question"], token: token);
        }
        answerController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        qnaState = QnaState.idle;
        state = TextToSpeechState.idle;
        questionNumber--; // Revert question number
        // Restore question if possible or show error
        showCustomDialog("Failed to send answer. Please try again.", context);
      });
    }
  }

  Future<void> skipQuestion() async {
    await _audioPlayer.stop();
    setState(() {
      qnaState = QnaState.thinking;
      state = TextToSpeechState.loading;
      questionNumber++;
      question = "";
    });
    try {
      String token = await AccessTokenService.getToken() ?? "";

      await for (final event in submitAnswerStream(
        token: token,
        sessionId: widget.sessionId,
        answer: "I'd prefer to skip this question.",
      )) {
        if (event.event == "token") {
          setState(() {
            question += event.data["text"];
            canAnswer = false;
          });
        }

        if (event.event == "done") {
          answerController.clear();
          if (event.data["next_question"] == null) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewResponsesScreen(
                  token: token,
                  sessionId: widget.sessionId,
                ),
              ),
            );
          }
          setState(() {
            question = event.data["next_question"];
            canAnswer = true;
            qnaState = QnaState.idle;
          });
          playText(question: event.data["next_question"], token: token);
        }
        answerController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        qnaState = QnaState.idle;
        state = TextToSpeechState.idle;
        questionNumber--;
        showCustomDialog("Failed to skip question. Please try again.", context);
      });
    }
  }

  void _updateWaveform(double db) {
    final normalized = ((db + 60) / 60).clamp(0.0, 1.0);

    setState(() {
      volume = normalized;

      for (int i = 0; i < bars.length; i++) {
        final envelope = sin((i / bars.length) * pi);
        final noise = 0.75 + _random.nextDouble() * 0.25;

        bars[i] = (normalized * envelope * noise).clamp(0.0, 1.0);
      }
    });
  }

  Future<void> startVoiceStreaming() async {
    await _audioPlayer.stop();
    setState(() {
      voiceStreamState = VoiceStreamState.connecting;
    });

    String? accessToken = await AccessTokenService.getToken();

    connection = VoiceStreamConnection.connect(
      sessionId: widget.sessionId,
      accessToken: accessToken!,
    );

    // Backend Protocol: Send START first, THEN wait for READY
    await Future.delayed(const Duration(milliseconds: 300)); // Give connection time
    connection?.start(mimeType: "audio/aac");

    // Now listen for messages
    connection?.messages.listen(
      (event) async {
        if (event.type == "ready") {
          if (await recorder.hasPermission()) {
            final stream = await recorder.startStream(recordConfig);
            recorder
                .onAmplitudeChanged(
              const Duration(milliseconds: 30),
            )
                .listen((amplitude) {
              _updateWaveform(amplitude.current);
            });

            setState(() {
              startRecordingTimer();
              voiceStreamState = VoiceStreamState.recording;
            });

            stream.listen((audioChunk) {
              connection?.sendAudioChunk(audioChunk);
            });
          } else {
          }
        }

        if (event.type == "transcript") {
          setState(() {
            voiceStreamState = VoiceStreamState.thinking;
          });
        }

        if (event.type == "done") {
          await connection?.close();

          if (event.data["next_question"] == null) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewResponsesScreen(
                  token: accessToken,
                  sessionId: widget.sessionId,
                ),
              ),
            );
            return;
          }

          setState(() {
            question = event.data["next_question"];
            voiceStreamState = VoiceStreamState.inactive;
          });

          // Play the next question audio
          playText(question: event.data["next_question"], token: accessToken);
        }

        if (event.type == "token") {
          setState(() {
            question += event.data["text"];
          });
        }

        if (event.type == "error") {
          await connection?.close();
          if (!mounted) return;
          showCustomDialog(event.data["message"], context);
          setState(() {
            voiceStreamState = VoiceStreamState.inactive;
          });
        } else {
        }
      },
      onError: (error) {
        setState(() {
          voiceStreamState = VoiceStreamState.inactive;
        });
      },
      onDone: () {
      },
    );
  }

  Future<void> sendVoiceAnswer() async {
    connection?.stopRecording();
    stopRecordingTimer();
    await recorder.stop();
    setState(() {
      voiceStreamState = VoiceStreamState.transcribing;
    });
  }

  Widget buildVoiceButton() {
    return ElevatedButton(
      onPressed: voiceStreamState == VoiceStreamState.inactive
          ? startVoiceStreaming
          : voiceStreamState == VoiceStreamState.recording
          ? sendVoiceAnswer
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonBackgroundColor(),
        foregroundColor: _buttonForegroundColor(),
      ),
      child: _buttonChild(),
    );
  }

  Color _buttonBackgroundColor() {
    final theme = Theme.of(context);
    switch (voiceStreamState) {
      case VoiceStreamState.inactive:
        return AppColors.brand;
      case VoiceStreamState.recording:
        return AppColors.error;
      default:
        return theme.dividerColor;
    }
  }

  Color _buttonForegroundColor() {
    final theme = Theme.of(context);
    switch (voiceStreamState) {
      case VoiceStreamState.inactive:
        return Colors.white;
      case VoiceStreamState.recording:
        return Colors.white;
      default:
        return theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
    }
  }

  Widget _buttonChild() {
    switch (voiceStreamState) {
      case VoiceStreamState.connecting:
        return _loadingRow("Connecting...");

      case VoiceStreamState.recording:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.square, size: 16, fill: 1),
            SizedBox(width: 8),
            Text("Recording..."),
          ],
        );

      case VoiceStreamState.transcribing:
        return _loadingRow("Transcribing...");

      case VoiceStreamState.thinking:
        return _loadingRow("AI thinking...");

      case VoiceStreamState.inactive:
        return const Text("Start Recording");
    }
  }

  Widget _loadingRow(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  void initState() {

    super.initState();
    playText(question: question);

    // Decode failures surface here rather than as a thrown exception, so
    // without this listener a bad clip is indistinguishable from silence.
    _audioPlayer.onLog.listen(
      (msg) => {},
      onError: (Object e) => {},
    );

    _audioPlayer.onPlayerStateChanged.listen((PlayerState audioState) {
      if (!mounted) return;

      setState(() {
        state = audioState == PlayerState.playing
            ? TextToSpeechState.active
            : TextToSpeechState.idle;
      });
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    _audioPlayer.dispose();
    answerController.dispose();
    _recordingTimer?.cancel();
    // Drop the last TTS clip; temp files are not cleaned up for us.
    _currentClipFile?.delete().catchError((_) => _currentClipFile!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: 10),
          child: Image.asset("assets/kuvaka_logo.png"),
        ),
        title: Text(
          "History Taking",
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyMedium?.color),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AIOrb(state: state),
                      const SizedBox(height: AppLayout.space16),
                      SiriWaveform(state: state),
                      const SizedBox(height: AppLayout.space16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          WhiteSquareIconButton(
                            onTap: () async {
                              setState(() {
                                isMute = !isMute;
                              });

                              await _audioPlayer.setVolume(isMute ? 0.0 : 1.0);
                            },
                            icon: isMute
                                ? LucideIcons.volumeX400
                                : LucideIcons.volume2,
                          ),
                          const SizedBox(width: AppLayout.space16),
                          WhiteSquareIconButton(
                            onTap: () async {
                              if (audio != null) await playAudio(audio!);
                            },
                            icon: LucideIcons.rotateCcw,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.space16),
                      Text(
                        qnaState == QnaState.thinking
                            ? "AI is thinking..."
                            : "Question $questionNumber",
                      ),
                      const SizedBox(height: AppLayout.space4),
                      QuestionBubble(question: question, state: state),
                      const SizedBox(height: AppLayout.space16),
                      //Recording Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                          border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppLayout.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(
                                            AppLayout.radius8,
                                          ),
                                        ),
                                        child: Icon(LucideIcons.mic, size: 15, color: theme.colorScheme.primary),
                                      ),
                                      const SizedBox(width: AppLayout.space8),
                                      Text(
                                        "Speak Your\nAnswer",
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "-transcribed & analyzed\ninstantly",
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppLayout.space16),
                            Row(
                              children: [
                                buildVoiceButton(),
                                const SizedBox(width: AppLayout.space16),
                                if (voiceStreamState ==
                                    VoiceStreamState.recording)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppLayout.space12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.light ? AppColors.errorContainer : AppColors.error.withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: theme.brightness == Brightness.light ? AppColors.redFlagBorder : AppColors.error.withAlpha(100),
                                        width: AppLayout.borderMedium,
                                      ),
                                    ),
                                    child: Text(
                                      formatRecordingTime(recordingDuration),
                                      style: TextStyle(
                                        color: theme.brightness == Brightness.light ? AppColors.onErrorContainer : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            RecordingCard(
                              bars: bars,
                              volume: volume,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: AppLayout.space16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              color: theme.dividerColor,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: AppLayout.space8),
                          const Text("or type"),
                          const SizedBox(width: AppLayout.space8),
                          Expanded(
                            child: Container(
                              color: theme.dividerColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.space16),
                    ],
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      controller: answerController,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: "Type your answer here...",
                      ),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space8),
                  Material(
                    borderRadius: BorderRadius.circular(AppLayout.radius8),
                    color: theme.colorScheme.secondaryContainer,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppLayout.radius8),
                      splashColor: theme.colorScheme.primary.withAlpha(50),
                      onTap: () {
                        if (answerController.text.isEmpty) {
                          showCustomDialog("Please type an answer", context);
                        }
                        if (canAnswer) {
                          if (answerController.text.isNotEmpty) sendAnswer();
                        }
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppLayout.radius8),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: AppLayout.borderThin,
                          ),
                        ),
                        width: 50,
                        height: 50,
                        child: Icon(
                          LucideIcons.send,
                          color: canAnswer
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.textTheme.bodyMedium?.color?.withAlpha(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.space16),
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Container(
                    padding: const EdgeInsets.all(AppLayout.space4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppLayout.radius8),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: AppLayout.borderThin,
                      ),
                    ),

                    child: Material(
                      borderRadius: BorderRadius.circular(AppLayout.radius8),
                      color: theme.colorScheme.surface,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppLayout.radius8),
                        splashColor: theme.colorScheme.primary.withAlpha(50),
                        onTap: () {
                          if (canAnswer) skipQuestion();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.skipForward,
                              color: canAnswer
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color?.withAlpha(100),
                              size: 15,
                            ),
                            Text(
                              "   Skip Question",
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: canAnswer
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyMedium?.color?.withAlpha(100),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({
    super.key,
    required this.question,
    required this.state,
  });

  final String question;
  final TextToSpeechState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: BubblePainter(
        backgroundColor: state == TextToSpeechState.active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderColor: state == TextToSpeechState.active
            ? theme.colorScheme.primary.withAlpha(100)
            : theme.dividerColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          28, // extra because of the arrow
          16,
          16,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: question.isNotEmpty
              ? Text(
                  question,
                  key: ValueKey(question),
                  style: Theme.of(context).textTheme.titleLarge,
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Thinking...",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class WhiteSquareIconButton extends StatelessWidget {
  const WhiteSquareIconButton({
    super.key,
    required this.onTap,
    required this.icon,
  });
  final void Function() onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppLayout.radius8),
      child: InkWell(
        splashColor: theme.colorScheme.primary.withAlpha(50),
        borderRadius: BorderRadius.circular(AppLayout.radius8),
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.radius8),
            border: Border.all(
              color: theme.dividerColor,
              width: AppLayout.borderThin,
            ),
            color: theme.colorScheme.secondaryContainer
          ),
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer, size: AppLayout.iconSmall),
        ),
      ),
    );
  }
}

class CenterCircleSnakeEmoji extends StatelessWidget {
  const CenterCircleSnakeEmoji({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Column(
                children: [
                  Container(width: 100, height: 70, color: theme.colorScheme.surface),
                  Container(width: 100, height: 30, color: theme.dividerColor),
                ],
              ),
            ),
          ),
        ),
        Center(child: Text("⚕️", style: TextStyle(fontSize: 40))),
      ],
    );
  }
}

class BubblePainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;

  BubblePainter({required this.backgroundColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 24.0;

    const arrowWidth = 20.0;
    const arrowHeight = 12.0;
    const arrowLeft = 24.0;

    final path = Path();

    path.moveTo(radius, arrowHeight);

    path.lineTo(arrowLeft, arrowHeight);
    path.lineTo(arrowLeft + arrowWidth / 2, 0);
    path.lineTo(arrowLeft + arrowWidth, arrowHeight);

    path.lineTo(size.width - radius, arrowHeight);

    path.arcToPoint(
      Offset(size.width, arrowHeight + radius),
      radius: const Radius.circular(radius),
    );

    path.lineTo(size.width, size.height - radius);

    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );

    path.lineTo(radius, size.height);

    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );

    path.lineTo(0, arrowHeight + radius);

    path.arcToPoint(
      Offset(radius, arrowHeight),
      radius: const Radius.circular(radius),
    );

    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor;
  }
}

class RecordingCard extends StatefulWidget {
  final List<double> bars;
  final double volume;
  final double phase = 0;

  const RecordingCard({
    super.key,
    required this.bars,
    required this.volume,
  });

  @override
  State<RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<RecordingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;



  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.dividerColor,
          width: AppLayout.borderThin,
        ),
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withAlpha(10),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Header
          Row(
            children: [

              FadeTransition(
                opacity: Tween(
                  begin: .35,
                  end: 1.0,
                ).animate(_blinkController),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              const SizedBox(width: AppLayout.space8),

              Text(
                "Recording",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppLayout.space12 + 2),

          /// Waveform placeholder
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: LiveAudioPainter(
                volume: widget.volume,
                phase: widget.phase,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: AppLayout.space12),

          /// Loudness meter placeholder
          Container(
            height: 4,
            color: theme.dividerColor,
          ),
        ],
      ),
    );
  }
}

class LiveAudioPainter extends CustomPainter {
  final double volume;
  final double phase;
  final Color color;

  LiveAudioPainter({
    required this.volume,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    final centerY = size.height / 2;

    final amplitude =
    lerpDouble(3, size.height * 0.38, volume)!;

    const points = 180;

    for (int i = 0; i <= points; i++) {
      final x = i / points * size.width;

      final progress = i / points;

      // Fade toward the edges like ChatGPT/React
      final envelope = sin(progress * pi);

      // Multiple waves mixed together
      final y = centerY -
          envelope *
              amplitude *
              (
                  sin(progress * 10 * pi + phase) * .55 +
                      sin(progress * 21 * pi + phase * 1.7) * .25 +
                      sin(progress * 36 * pi + phase * .6) * .12
              );

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiveAudioPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.volume != volume;
  }
}