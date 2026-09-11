import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../Components/colors.dart';
import '../../Custom Widgets/custom_confirmation_alert.dart';
import '../../Models/cabin_models.dart';
import '../../Screens/Consultation/cabin_record_screen.dart';
import '../Authentication/auth_service.dart';
import 'cabin_service.dart';
import 'cabin_streaming.dart';

/// ---------------------------------------------------------------------------
/// STATE DATA CLASS
/// ---------------------------------------------------------------------------

class CabinConsultationState {
  final int currentPage;
  final int currentQuestionIndex;
  final int selectedPanelTab;
  final bool hasNewInsights;
  final bool hasNewPanel;
  final bool isStreaming;
  final bool isConnecting;
  final bool isEnding;
  final double currentAmplitude;
  final String partialTranscript;
  final List<CabinUtterance> utterances;
  final CabinSuggestions? suggestions;
  final CabinPanel? panel;

  const CabinConsultationState({
    this.currentPage = 0,
    this.currentQuestionIndex = 0,
    this.selectedPanelTab = 0,
    this.hasNewInsights = false,
    this.hasNewPanel = false,
    this.isStreaming = false,
    this.isConnecting = false,
    this.isEnding = false,
    this.currentAmplitude = -60.0,
    this.partialTranscript = "",
    this.utterances = const [],
    this.suggestions,
    this.panel,
  });

  CabinConsultationState copyWith({
    int? currentPage,
    int? currentQuestionIndex,
    int? selectedPanelTab,
    bool? hasNewInsights,
    bool? hasNewPanel,
    bool? isStreaming,
    bool? isConnecting,
    bool? isEnding,
    double? currentAmplitude,
    String? partialTranscript,
    List<CabinUtterance>? utterances,
    CabinSuggestions? suggestions,
    CabinPanel? panel,
  }) {
    return CabinConsultationState(
      currentPage: currentPage ?? this.currentPage,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedPanelTab: selectedPanelTab ?? this.selectedPanelTab,
      hasNewInsights: hasNewInsights ?? this.hasNewInsights,
      hasNewPanel: hasNewPanel ?? this.hasNewPanel,
      isStreaming: isStreaming ?? this.isStreaming,
      isConnecting: isConnecting ?? this.isConnecting,
      isEnding: isEnding ?? this.isEnding,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      utterances: utterances ?? this.utterances,
      suggestions: suggestions ?? this.suggestions,
      panel: panel ?? this.panel,
    );
  }
}

/// ---------------------------------------------------------------------------
/// SERVICE & STATE NOTIFIER
/// ---------------------------------------------------------------------------

class CabinConsultationService extends StateNotifier<CabinConsultationState> {
  final String sessionId;
  final AudioRecorder _recorder = AudioRecorder();
  CabinStreamConnection? _connection;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _amplitudeSubscription;

  final _recordConfig = const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  CabinConsultationService(this.sessionId)
      : super(const CabinConsultationState());

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _connection?.close();
    super.dispose();
  }

  // Navigation & Tab Controls
  void setCurrentPage(int page) {
    state = state.copyWith(
      currentPage: page,
      hasNewInsights: page == 1 ? false : state.hasNewInsights,
      hasNewPanel: page == 2 ? false : state.hasNewPanel,
    );
  }

  void setSelectedPanelTab(int tab) {
    state = state.copyWith(selectedPanelTab: tab);
  }

  void setCurrentQuestionIndex(int index) {
    state = state.copyWith(currentQuestionIndex: index);
  }

  // Audio Streaming Controls
  Future<void> toggleStreaming() async {
    if (state.isStreaming) {
      await stopStreaming();
    } else {
      await startStreaming();
    }
  }

  Future<void> startStreaming() async {
    try {
      if (await _recorder.hasPermission()) {
        state = state.copyWith(isConnecting: true);

        final accessToken = await getValidAccessToken();
        if (accessToken == null) throw Exception("No access token");

        _connection = CabinStreamConnection.connect(
          sessionId: sessionId,
          accessToken: accessToken,
        );

        _messageSubscription = _connection!.messages.listen((message) {
          _handleWsMessage(message);
        }, onError: (err) {
          stopStreaming();
        });

        _connection!.start(
          secondaryLanguages: ["hi", "en", "mr", "gu"],
        );
      }
    } catch (e) {
      state = state.copyWith(isConnecting: false);
    }
  }

  void _handleWsMessage(CabinStreamMessage message) async {
    switch (message.type) {
      case "ready":
        _startAudioRecording();
        break;

      case "partial":
        state = state.copyWith(
          partialTranscript: message.data["text"] ?? "",
        );
        break;

      case "utterance":
        final newUtterance = CabinUtterance.fromJson(message.data);
        final updatedList = List<CabinUtterance>.from(state.utterances)
          ..add(newUtterance);
        state = state.copyWith(
          utterances: updatedList,
          partialTranscript: "",
        );
        break;

      case "utterance_role":
        final id = message.data["utterance_id"];
        final role = message.data["role"];
        final conf = message.data["confidence"];
        final updatedList = List<CabinUtterance>.from(state.utterances);
        final index = updatedList.indexWhere((u) => u.id == id);
        if (index != -1) {
          updatedList[index] = updatedList[index].copyWith(
            role: role,
            confidence: (conf as num?)?.toDouble(),
          );
          state = state.copyWith(utterances: updatedList);
        }
        break;

      case "panel":
        final newPanel = CabinPanel.fromJson(message.data);
        state = state.copyWith(
          panel: newPanel,
          hasNewPanel: state.currentPage != 2 ? true : state.hasNewPanel,
        );
        break;

      case "suggestions":
        final newSuggestions = CabinSuggestions.fromJson(message.data);
        state = state.copyWith(
          suggestions: newSuggestions,
          hasNewInsights: state.currentPage != 1 ? true : state.hasNewInsights,
        );
        break;

      case "snapshot":
        final snapshot = CabinSnapshot.fromJson(message.data);
        state = state.copyWith(
          utterances: snapshot.utterances,
          panel: snapshot.panel,
          suggestions: snapshot.suggestions,
        );
        break;

      case "error":
        if (message.data['fatal'] == true) stopStreaming();
        break;

      case "ended":
        stopStreaming();
        break;
    }
  }

  Future<void> _startAudioRecording() async {
    final stream = await _recorder.startStream(_recordConfig);

    state = state.copyWith(
      isStreaming: true,
      isConnecting: false,
    );

    stream.listen((chunk) {
      _connection?.sendAudioChunk(chunk);
    });

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 40))
        .listen((amp) {
      state = state.copyWith(currentAmplitude: amp.current);
    });
  }

  Future<void> stopStreaming() async {
    try {
      _connection?.stop();
      await _recorder.stop();
      _messageSubscription?.cancel();
      _amplitudeSubscription?.cancel();
      await _connection?.close();

      state = state.copyWith(
        isStreaming: false,
        isConnecting: false,
        currentAmplitude: -60.0,
        partialTranscript: "",
      );
      _connection = null;
    } catch (_) {
      // Ignored: cleanup errors can be safely bypassed
    }
  }

  Future<void> stopStreamingAndCloseSession() async {
    try {
      if (_connection != null) {
        _connection!.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await stopStreaming();
      } else {
        final accessToken = await getValidAccessToken();
        if (accessToken != null) {
          final conn = CabinStreamConnection.connect(
            sessionId: sessionId,
            accessToken: accessToken,
          );

          final readyCompleter = Completer<void>();
          StreamSubscription? sub;

          sub = conn.messages.listen((msg) {
            if (msg.type == "ready") {
              if (!readyCompleter.isCompleted) {
                readyCompleter.complete();
              }
            }
          }, onError: (err) {
            if (!readyCompleter.isCompleted) {
              readyCompleter.completeError(err);
            }
          });

          conn.start(secondaryLanguages: ["hi", "en", "mr", "gu"]);

          try {
            await readyCompleter.future.timeout(const Duration(seconds: 5));
            conn.stop();
            await Future.delayed(const Duration(milliseconds: 300));
          } catch (_) {
            // Ignored: ready timeout or stop error
          } finally {
            await sub.cancel();
            await conn.close();
          }
        }
      }
    } finally {
      await stopStreaming();
    }
  }

  void sendNote(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty && _connection != null) {
      _connection!.sendNote(trimmed);

      final newNote = CabinUtterance(
        id: "note_${DateTime.now().millisecondsSinceEpoch}",
        text: trimmed,
        role: "doctor",
        ts: DateTime.now().millisecondsSinceEpoch / 1000,
      );
      final updatedList = List<CabinUtterance>.from(state.utterances)
        ..add(newNote);
      state = state.copyWith(utterances: updatedList);
    }
  }

  // End Session Action
  Future<void> endSession({
    required BuildContext context,
    required String patientName,
  }) async {
    showCustomConfirmationAlert(
      title: "End Session?",
      detail:
          "This will finalize the consultation and generate the medical record.",
      confirmText: "End Session",
      confirmColor: AppColors.error,
      context: context,
      onPressed: () async {
        Navigator.pop(context); // Close dialog
        state = state.copyWith(isEnding: true);
        try {
          // 1. Stop streaming and close session on backend
          await stopStreamingAndCloseSession();

          // 2. Fetch final record
          final record = await getCabinRecord(sessionId);

          if (!context.mounted) return;

          // 3. Navigate to Record Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CabinRecordScreen(
                record: record,
                patientName: patientName,
              ),
            ),
          );
        } catch (e) {
          state = state.copyWith(isEnding: false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to finalize session: $e"),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// RIVERPOD PROVIDER
/// ---------------------------------------------------------------------------

final cabinConsultationServiceProvider = StateNotifierProvider.family<
    CabinConsultationService,
    CabinConsultationState,
    String>((ref, sessionId) {
  return CabinConsultationService(sessionId);
});
