import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../Components/colors.dart';
import '../../Components/layout_constants.dart';
import '../../functions.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Models/cabin_models.dart';
import '../../Custom Widgets/custom_confirmation_alert.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Authentication/auth_service.dart';
import '../../Services/Cabin/cabin_service.dart';
import '../../Services/Cabin/cabin_streaming.dart';
import 'cabin_record_screen.dart';

class CabinConsultationScreen extends StatefulWidget {
  const CabinConsultationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.sessionId,
  });

  final String patientId;
  final String patientName;
  final String sessionId;

  static const routeName = "/cabin-consultation";

  @override
  State<CabinConsultationScreen> createState() => _CabinConsultationScreenState();
}

class _CabinConsultationScreenState extends State<CabinConsultationScreen> {
  final PageController _pageController = PageController();
  final PageController _questionsPageController = PageController();
  final TextEditingController _noteController = TextEditingController();
  int _currentPage = 0;
  int _currentQuestionIndex = 0;
  int _selectedPanelTab = 0; // 0: Symptoms, 1: Diagnoses, 2: Tests, 3: Meds
  bool _hasNewInsights = false;
  bool _hasNewPanel = false;

  final AudioRecorder _recorder = AudioRecorder();
  CabinStreamConnection? _connection;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _amplitudeSubscription;

  bool _isStreaming = false;
  bool _isEnding = false;
  String _partialTranscript = "";
  double _currentAmplitude = -60.0;

  List<CabinUtterance> _utterances = [];
  CabinSuggestions? _suggestions;
  CabinPanel? _panel;

  final _recordConfig = const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  @override
  void dispose() {
    _pageController.dispose();
    _questionsPageController.dispose();
    _noteController.dispose();
    _messageSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _connection?.close();
    super.dispose();
  }

  Future<void> _toggleStreaming() async {
    if (_isStreaming) {
      await _stopStreaming();
    } else {
      await _startStreaming();
    }
  }

  Future<void> _startStreaming() async {
    try {
      if (await _recorder.hasPermission()) {
        // Proactively refresh/validate token before starting long-running stream
        final accessToken = await getValidAccessToken();
        if (accessToken == null) throw Exception("No access token");

        // 1. Connect WebSocket
        _connection = CabinStreamConnection.connect(
          sessionId: widget.sessionId,
          accessToken: accessToken,
        );

        // 2. Listen for WebSocket messages
        _messageSubscription = _connection!.messages.listen((message) {
          _handleWsMessage(message);
        }, onError: (err) {
          _stopStreaming();
        });

        // 3. Initiate protocol
        _connection!.start(
          secondaryLanguages: ["hi", "en", "mr", "gu"],
          // Add keyterms here if needed
        );
      }
    } catch (e) {
    }
  }

  void _handleWsMessage(CabinStreamMessage message) async {
    switch (message.type) {
      case "ready":
        _startAudioRecording();
        break;

      case "partial":
        setState(() {
          _partialTranscript = message.data["text"] ?? "";
        });
        break;

      case "utterance":
        setState(() {
          _utterances.add(CabinUtterance.fromJson(message.data));
          _partialTranscript = ""; // Clear partial when finalized
        });
        break;

      case "utterance_role":
        final id = message.data["utterance_id"];
        final role = message.data["role"];
        final conf = message.data["confidence"];
        setState(() {
          final index = _utterances.indexWhere((u) => u.id == id);
          if (index != -1) {
            _utterances[index] = _utterances[index].copyWith(
              role: role,
              confidence: (conf as num?)?.toDouble(),
            );
          }
        });
        break;

      case "panel":
        setState(() {
          _panel = CabinPanel.fromJson(message.data);
          if (_currentPage != 2) _hasNewPanel = true;
        });
        break;

      case "suggestions":
        setState(() {
          _suggestions = CabinSuggestions.fromJson(message.data);
          if (_currentPage != 1) _hasNewInsights = true;
        });
        break;

      case "snapshot":
        final snapshot = CabinSnapshot.fromJson(message.data);
        setState(() {
          _utterances = snapshot.utterances;
          _panel = snapshot.panel;
          _suggestions = snapshot.suggestions;
          // Don't set notification for initial snapshot
        });
        break;

      case "error":
        if (message.data['fatal'] == true) _stopStreaming();
        break;

      case "ended":
        _stopStreaming();
        break;
    }
  }

  Future<void> _startAudioRecording() async {
    // Using startStream to pipe directly to WebSocket
    final stream = await _recorder.startStream(_recordConfig);
    
    setState(() {
      _isStreaming = true;
    });

    stream.listen((chunk) {
      _connection?.sendAudioChunk(chunk);
    });

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 40))
        .listen((amp) {
      setState(() {
        _currentAmplitude = amp.current;
      });
    });

  }

  Future<void> _stopStreaming() async {
    try {
      _connection?.stop();
      await _recorder.stop();
      _messageSubscription?.cancel();
      _amplitudeSubscription?.cancel();
      await _connection?.close();

      setState(() {
        _isStreaming = false;
        _connection = null;
        _currentAmplitude = -60.0;
        _partialTranscript = "";
      });
    } catch (e) {
    }
  }

  Future<void> _endSession() async {
    showCustomConfirmationAlert(
      title: "End Session?",
      detail: "This will finalize the consultation and generate the medical record.",
      confirmText: "End Session",
      confirmColor: AppColors.error,
      context: context,
      onPressed: () async {
        Navigator.pop(context); // Close dialog
        setState(() => _isEnding = true);

        try {
          // 1. Stop streaming
          await _stopStreaming();

          // 2. Fetch final record
          final record = await getCabinRecord(widget.sessionId);

          if (!mounted) return;

          // 3. Navigate to Record Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CabinRecordScreen(
                record: record,
                patientName: widget.patientName,
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isEnding = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to finalize session: $e"), backgroundColor: AppColors.error),
            );
          }
        }
      },
    );
  }

  void _sendNote() {
    final text = _noteController.text.trim();
    if (text.isNotEmpty && _connection != null) {
      // 1. Send to server
      _connection!.sendNote(text);
      
      // 2. Optimistic UI update: Add to local list immediately
      // Use a temp ID "note_temp" to identify it; the server will replace/append with a real one
      setState(() {
        _utterances.add(CabinUtterance(
          id: "note_${DateTime.now().millisecondsSinceEpoch}",
          text: text,
          role: "doctor",
          ts: DateTime.now().millisecondsSinceEpoch / 1000,
        ));
      });
      
      _noteController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Live Consultation",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        actions: [
          if (_isStreaming)
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppLayout.space12, horizontal: AppLayout.space8),
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.space12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppLayout.radius20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.error, size: AppLayout.space8),
                  const SizedBox(width: AppLayout.space8),
                  Text(
                    "LIVE",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          _isEnding 
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.space16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: AppLayout.borderThick, color: AppColors.error)),
              ))
            : TextButton(
                onPressed: _endSession,
                child: const Text("End Session", style: TextStyle(color: AppColors.error)),
              ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPageIndicator(0, "Consult", LucideIcons.mic),
                    const SizedBox(width: AppLayout.space8),
                    _buildPageIndicator(1, "Insights", LucideIcons.brainCircuit, hasNotification: _hasNewInsights),
                    const SizedBox(width: AppLayout.space8),
                    _buildPageIndicator(2, "Panel", LucideIcons.clipboardList, hasNotification: _hasNewPanel),
                  ],
                ),
              ),
              const SizedBox(height: AppLayout.space16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      if (index == 1) _hasNewInsights = false;
                      if (index == 2) _hasNewPanel = false;
                    });
                  },
                  children: [
                    _buildConsultationPage(),
                    _buildAnalysisPage(),
                    _buildPanelPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPageIndicator(int index, String label, IconData icon, {bool hasNotification = false}) {
    final theme = Theme.of(context);
    bool isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppLayout.radius20),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            width: AppLayout.borderThin + 0.25,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: AppLayout.iconSmall,
                  color: isActive ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: AppLayout.space8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (hasNotification && !isActive)
              Positioned(
                top: -AppLayout.space4,
                right: -AppLayout.space8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationPage() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
      child: Column(
        children: [
          // 1. Questions to Ask Section
          Container(
            padding: const EdgeInsets.all(AppLayout.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppLayout.cardRadius),
              border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.messageSquareText, size: AppLayout.iconSmall, color: AppColors.brand),
                    const SizedBox(width: AppLayout.space8),
                    Text(
                      "Questions to Ask",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_suggestions?.questionsToAsk != null && _suggestions!.questionsToAsk.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        "${_currentQuestionIndex + 1}/${_suggestions!.questionsToAsk.length}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textDisabled,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppLayout.space12),
                SizedBox(
                  height: 110, // Keep fixed height for PageView
                  child: _suggestions?.questionsToAsk == null || _suggestions!.questionsToAsk.isEmpty
                      ? const Center(child: Text("No data to show", style: TextStyle(color: AppColors.textDisabled, fontSize: 13)))
                      : PageView.builder(
                          controller: _questionsPageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentQuestionIndex = index;
                            });
                          },
                          itemCount: _suggestions!.questionsToAsk.length,
                          itemBuilder: (context, index) {
                            final q = _suggestions!.questionsToAsk[index];
                            return _buildDetailedQuestionCard(q.question, q.reason);
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),

          // 2. Live Transcript Container (Expanded to take max available space)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.space16),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.listMusic, size: AppLayout.iconSmall, color: AppColors.brand),
                        const SizedBox(width: AppLayout.space8),
                        Text(
                          "Live Transcript",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
                      itemCount: _utterances.length,
                      itemBuilder: (context, index) {
                        return TranscriptBubble(utterance: _utterances[index]);
                      },
                    ),
                  ),
                  if (_isStreaming)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space8),
                      child: PartialTranscriptBubble(text: _partialTranscript),
                    ),
                  const SizedBox(height: AppLayout.space8),
                ],
              ),
            ),
          ),

          // 3. Note Input & Controls (Sticky Bottom)
          const SizedBox(height: AppLayout.space16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  onSubmitted: (_) => _sendNote(),
                  decoration: const InputDecoration(
                    hintText: "Type a clinical note...",
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.space12),
              // Compact Pulsating Mic Button
              SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: PulsatingMicButton(
                    isRecording: _isStreaming,
                    amplitude: _currentAmplitude,
                    onTap: _toggleStreaming,
                    size: 44, // Smaller size for row
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.space8),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brand,
                child: IconButton(
                  onPressed: _sendNote,
                  icon: const Icon(LucideIcons.send, color: AppColors.surface, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space8),
        ],
      ),
    );
  }

  Widget _buildDetailedQuestionCard(String question, String reasoning) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppLayout.space4),
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (reasoning.isNotEmpty) ...[
              const SizedBox(height: AppLayout.space8 - 2),
              Text(
                reasoning,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisPage() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppLayout.space16, right: AppLayout.space16, bottom: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection(
            "Red Flags",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: _suggestions?.redFlags == null || _suggestions!.redFlags.isEmpty
                ? [Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))]
                : _suggestions!.redFlags.map((f) => _buildRedFlagItem(f)).toList(),
          ),
          const SizedBox(height: AppLayout.space16),
          _buildAnalysisSection(
            "Differentials",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: _suggestions?.differentials == null || _suggestions!.differentials.isEmpty
                ? [Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))]
                : _suggestions!.differentials.map((d) => 
                    _buildDifferentialItem(d.condition, d.likelihood ?? "Unknown", d.reasoning ?? "")
                  ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelPage() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppLayout.space16, right: AppLayout.space16, bottom: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Selector for Clinical Panel
          Container(
            padding: const EdgeInsets.all(AppLayout.space4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppLayout.radius12),
              border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
            ),
            child: Row(
              children: [
                _buildPanelTab(0, "Symptoms"),
                _buildPanelTab(1, "Diagnoses"),
                _buildPanelTab(2, "Tests"),
                _buildPanelTab(3, "Meds"),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),
          
          // Panel Content
          _buildAnalysisSection(
            "Clinical Panel",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: [
              if (_selectedPanelTab == 0) ...[
                if (_panel?.symptoms == null || _panel!.symptoms.isEmpty)
                  Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                else
                  ..._panel!.symptoms.map((s) => _buildSymptomItem(s.name, s.description ?? "", s.reportedBy ?? "unknown")),
              ] else if (_selectedPanelTab == 1) ...[
                if (_panel?.diagnoses == null || _panel!.diagnoses.isEmpty)
                  Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                else
                  ..._panel!.diagnoses.map((d) => _buildDifferentialItem(d.condition, d.likelihood ?? "Confirmed", d.reasoning ?? "")),
              ] else if (_selectedPanelTab == 2) ...[
                if (_panel?.tests == null || _panel!.tests.isEmpty)
                  Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                else
                  ..._panel!.tests.map((t) => _buildSimplePanelItem(t)),
              ] else if (_selectedPanelTab == 3) ...[
                if (_panel?.medications == null || _panel!.medications.isEmpty)
                  Text("No data to show", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                else
                  ..._panel!.medications.map((m) => _buildSimplePanelItem(m.drugName)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelTab(int index, String label) {
    bool isActive = _selectedPanelTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPanelTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandHighlight : AppColors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.brand : AppColors.textDisabled,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomItem(String title, String description, String reportedBy) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppLayout.space12),
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppLayout.space4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppLayout.space8),
          Row(
            children: [
              Text(
                "Reported by: ",
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                reportedBy,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePanelItem(String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppLayout.space8),
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, Color bgColor, Color accentColor, {List<Widget>? children}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == "Red Flags" ? LucideIcons.alertTriangle : 
                (title == "Differentials" ? LucideIcons.brainCircuit : LucideIcons.clipboardList),
                size: AppLayout.iconSmall + 2,
                color: accentColor,
              ),
              const SizedBox(width: AppLayout.space8),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space12),
          if (children != null && children.isNotEmpty)
            ...children
          else
            Text(
              "Detailed insights will appear here live...",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildRedFlagItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.space8),
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space12, vertical: AppLayout.space8 + 2),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: AppColors.redFlagBorder, width: AppLayout.borderThin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: AppLayout.iconSmall,
            color: AppColors.error,
          ),
          const SizedBox(width: AppLayout.space10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.onErrorContainer,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferentialItem(String condition, String likelihood, String reasoning) {
    final theme = Theme.of(context);
    final bool isHigh = likelihood.toLowerCase() == 'high';
    final Color accentColor = isHigh ? AppColors.error : AppColors.success;
    
    // In dark mode, use lower opacity backgrounds for semantic cards
    final bool isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isHigh 
        ? (isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer)
        : (isDark ? AppColors.success.withAlpha(40) : AppColors.statusFinalizedContainer);
    
    final Color chipBg = isHigh 
        ? (isDark ? AppColors.error.withAlpha(60) : AppColors.redFlagBorder)
        : (isDark ? AppColors.success.withAlpha(60) : AppColors.statusFinalizedContainer);
    
    final Color chipText = isHigh 
        ? (isDark ? Colors.white : AppColors.onErrorContainer)
        : (isDark ? Colors.white : AppColors.stepSuccessText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  condition,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  likelihood,
                  style: TextStyle(color: chipText, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class TranscriptBubble extends StatelessWidget {
  final CabinUtterance utterance;

  const TranscriptBubble({super.key, required this.utterance});

  String _getUtteranceTime(CabinUtterance utterance) {
    if (utterance.ts != null) {
      return DateFormat('hh:mm a').format(
        DateTime.fromMillisecondsSinceEpoch((utterance.ts! * 1000).toInt()),
      );
    }
    if (utterance.createdAt != null) {
      try {
        final dt = parseServerDate(utterance.createdAt);
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {
        return "Live";
      }
    }
    return "Live";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isDoctor = utterance.role == 'doctor';
    final bool isPatient = utterance.role == 'patient';
    final bool isAttendee = utterance.role == 'attendee';

    Color bgColor = theme.colorScheme.surface;
    Color iconColor = theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
    String label = "U";

    if (isDoctor) {
      bgColor = isDark ? theme.colorScheme.primary.withAlpha(40) : AppColors.brandHighlight;
      iconColor = theme.colorScheme.primary;
      label = "D";
    } else if (isPatient) {
      bgColor = isDark ? AppColors.bubblePatientText.withAlpha(40) : AppColors.bubblePatient;
      iconColor = isDark ? AppColors.bubblePatientText : AppColors.bubblePatientText;
      label = "P";
    } else if (isAttendee) {
      bgColor = isDark ? AppColors.bubbleAttendeeText.withAlpha(40) : AppColors.bubbleAttendee;
      iconColor = isDark ? AppColors.bubbleAttendeeText : AppColors.bubbleAttendeeText;
      label = "A";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: iconColor.withAlpha(25),
            child: Text(
              label,
              style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withAlpha(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDoctor ? "Doctor" : (isPatient ? "Patient" : "Attendee"),
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getUtteranceTime(utterance),
                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    utterance.text,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PartialTranscriptBubble extends StatelessWidget {
  final String text;

  const PartialTranscriptBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.textTheme.bodyMedium?.color?.withAlpha(25),
            child: Icon(LucideIcons.loader, size: 12, color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(127),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.textTheme.bodyMedium?.color?.withAlpha(25) ?? Colors.transparent, style: BorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Transcribing...",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text.isEmpty ? "..." : text,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulsatingMicButton extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  final VoidCallback onTap;
  final double size;

  const PulsatingMicButton({
    super.key,
    required this.isRecording,
    required this.amplitude,
    required this.onTap,
    this.size = 65.0,
  });

  @override
  State<PulsatingMicButton> createState() => _PulsatingMicButtonState();
}

class _PulsatingMicButtonState extends State<PulsatingMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulsatingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Normalize amplitude (-50 to -10) to 0.0 to 1.0 for high sensitivity
    // This drives the INTENSITY of the entire animation
    final double volumeFactor = ((widget.amplitude + 50) / 40).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size * 2, // Allow room for rings
      height: widget.size * 2,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.isRecording)
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double progress = (_controller.value + (index / 3)) % 1.0;

                    // Spread relative to button size
                    final double spread = progress * (widget.size * 0.9) * volumeFactor;
                    final double opacity = (1.0 - progress) * volumeFactor;

                    return Container(
                      width: widget.size + spread,
                      height: widget.size + spread,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withAlpha((180 * opacity).toInt()),
                      ),
                    );
                  },
                );
              }),

            // The Main Button (Static size, only shadow reacts to intensity)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? AppColors.error : AppColors.brand,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording ? AppColors.error : AppColors.brand)
                        .withAlpha((100 * volumeFactor).toInt().clamp(20, 100)),
                    blurRadius: (widget.size / 6) + (volumeFactor * 10),
                    spreadRadius: 1 + (volumeFactor * 4),
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? LucideIcons.square : LucideIcons.mic,
                color: AppColors.surface,
                size: widget.size * 0.43,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
