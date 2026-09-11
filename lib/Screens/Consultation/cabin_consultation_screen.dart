import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../Components/colors.dart';
import '../../Components/layout_constants.dart';
import '../../Models/cabin_models.dart';
import '../../Models/consultation_models.dart';
import '../../Services/Cabin/cabin_consultation_service.dart';
import '../../functions.dart';

class CabinConsultationScreen extends ConsumerStatefulWidget {
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
  ConsumerState<CabinConsultationScreen> createState() =>
      _CabinConsultationScreenState();
}

class _CabinConsultationScreenState
    extends ConsumerState<CabinConsultationScreen> {
  final PageController _pageController = PageController();
  final PageController _questionsPageController = PageController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _questionsPageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSendNote() {
    final service =
        ref.read(cabinConsultationServiceProvider(widget.sessionId).notifier);
    service.sendNote(_noteController.text);
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(cabinConsultationServiceProvider(widget.sessionId));
    final service =
        ref.read(cabinConsultationServiceProvider(widget.sessionId).notifier);

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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        actions: [
          if (state.isStreaming)
            Container(
              margin: const EdgeInsets.symmetric(
                  vertical: AppLayout.space12, horizontal: AppLayout.space8),
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.space12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppLayout.radius20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle,
                      color: AppColors.error, size: AppLayout.space8),
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
          state.isEnding
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.space16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: AppLayout.borderThick,
                          color: AppColors.error)),
                ))
              : TextButton(
                  onPressed: () => service.endSession(
                    context: context,
                    patientName: widget.patientName,
                  ),
                  child: const Text("End Session",
                      style: TextStyle(color: AppColors.error)),
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
                  _buildPageIndicator(0, "Consult", LucideIcons.mic, state),
                  const SizedBox(width: AppLayout.space8),
                  _buildPageIndicator(1, "Insights", LucideIcons.brainCircuit,
                      state,
                      hasNotification: state.hasNewInsights),
                  const SizedBox(width: AppLayout.space8),
                  _buildPageIndicator(
                      2, "Panel", LucideIcons.clipboardList, state,
                      hasNotification: state.hasNewPanel),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.space16),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  service.setCurrentPage(index);
                },
                children: [
                  _buildConsultationPage(state, service),
                  _buildAnalysisPage(state),
                  _buildPanelPage(state, service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(
      int index, String label, IconData icon, CabinConsultationState state,
      {bool hasNotification = false}) {
    final theme = Theme.of(context);
    bool isActive = state.currentPage == index;
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.space16, vertical: AppLayout.space8),
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
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: AppLayout.space8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyMedium?.color,
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

  Widget _buildConsultationPage(
      CabinConsultationState state, CabinConsultationService service) {
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
              border:
                  Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.messageSquareText,
                        size: AppLayout.iconSmall, color: AppColors.brand),
                    const SizedBox(width: AppLayout.space8),
                    Text(
                      "Questions to Ask",
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (state.suggestions?.questionsToAsk != null &&
                        state.suggestions!.questionsToAsk.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        "${state.currentQuestionIndex + 1}/${state.suggestions!.questionsToAsk.length}",
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
                  height: 110,
                  child: state.suggestions?.questionsToAsk == null ||
                          state.suggestions!.questionsToAsk.isEmpty
                      ? const Center(
                          child: Text("No data to show",
                              style: TextStyle(
                                  color: AppColors.textDisabled, fontSize: 13)))
                      : PageView.builder(
                          controller: _questionsPageController,
                          onPageChanged: (index) {
                            service.setCurrentQuestionIndex(index);
                          },
                          itemCount: state.suggestions!.questionsToAsk.length,
                          itemBuilder: (context, index) {
                            final q = state.suggestions!.questionsToAsk[index];
                            return _buildDetailedQuestionCard(
                                q.question, q.reason);
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),

          // 2. Live Transcript Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: AppLayout.borderThin),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.space16),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.listMusic,
                            size: AppLayout.iconSmall, color: AppColors.brand),
                        const SizedBox(width: AppLayout.space8),
                        Text(
                          "Live Transcript",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.space16),
                      itemCount: state.utterances.length,
                      itemBuilder: (context, index) {
                        return TranscriptBubble(
                            utterance: state.utterances[index]);
                      },
                    ),
                  ),
                  if (state.isStreaming)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.space16,
                          vertical: AppLayout.space8),
                      child: PartialTranscriptBubble(
                          text: state.partialTranscript),
                    ),
                  const SizedBox(height: AppLayout.space8),
                ],
              ),
            ),
          ),

          // 3. Note Input & Controls
          const SizedBox(height: AppLayout.space16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  onSubmitted: (_) => _handleSendNote(),
                  decoration: InputDecoration(
                      hintText: "Type a clinical note...",
                      fillColor: Theme.of(context).colorScheme.surface),
                ),
              ),
              const SizedBox(width: AppLayout.space12),
              SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: PulsatingMicButton(
                    isRecording: state.isStreaming,
                    isConnecting: state.isConnecting,
                    amplitude: state.currentAmplitude,
                    onTap: () => service.toggleStreaming(),
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.space8),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brand,
                child: IconButton(
                  onPressed: _handleSendNote,
                  icon: const Icon(LucideIcons.send,
                      color: AppColors.surface, size: 18),
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

  Widget _buildAnalysisPage(CabinConsultationState state) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          left: AppLayout.space16,
          right: AppLayout.space16,
          bottom: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection(
            "Red Flags",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: state.suggestions?.redFlags == null ||
                    state.suggestions!.redFlags.isEmpty
                ? [
                    Text("No data to show",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 13))
                  ]
                : state.suggestions!.redFlags
                    .map((f) => _buildRedFlagItem(f))
                    .toList(),
          ),
          const SizedBox(height: AppLayout.space16),
          _buildAnalysisSection(
            "Differentials",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: state.suggestions?.differentials == null ||
                    state.suggestions!.differentials.isEmpty
                ? [
                    Text("No data to show",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 13))
                  ]
                : state.suggestions!.differentials
                    .map((d) => _buildDifferentialItem(
                        d.condition,
                        d.likelihood ?? "Unknown",
                        d.reasoning ?? ""))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelPage(
      CabinConsultationState state, CabinConsultationService service) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          left: AppLayout.space16,
          right: AppLayout.space16,
          bottom: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppLayout.space4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppLayout.radius12),
              border: Border.all(
                  color: theme.dividerColor, width: AppLayout.borderThin),
            ),
            child: Row(
              children: [
                _buildPanelTab(0, "Symptoms", state, service),
                _buildPanelTab(1, "Diagnoses", state, service),
                _buildPanelTab(2, "Tests", state, service),
                _buildPanelTab(3, "Meds", state, service),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),
          _buildAnalysisSection(
            "Clinical Panel",
            theme.colorScheme.surface,
            theme.colorScheme.primary,
            children: [
              if (state.selectedPanelTab == 0) ...[
                if (state.panel?.symptoms == null ||
                    state.panel!.symptoms.isEmpty)
                  Text("No data to show",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13))
                else
                  ...state.panel!.symptoms.map((s) => _buildSymptomItem(
                      s.name, s.detail ?? "", s.reportedBy ?? "unknown")),
              ] else if (state.selectedPanelTab == 1) ...[
                if (state.panel?.diagnoses == null ||
                    state.panel!.diagnoses.isEmpty)
                  Text("No data to show",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13))
                else
                  ...state.panel!.diagnoses.map((d) => _buildDifferentialItem(
                      d.condition,
                      d.likelihood ?? "Confirmed",
                      d.reasoning ?? "")),
              ] else if (state.selectedPanelTab == 2) ...[
                if (state.panel?.tests == null ||
                    state.panel!.tests.isEmpty)
                  Text("No data to show",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13))
                else
                  ...state.panel!.tests.map((t) => _buildTestItem(t)),
              ] else if (state.selectedPanelTab == 3) ...[
                if (state.panel?.medications == null ||
                    state.panel!.medications.isEmpty)
                  Text("No data to show",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13))
                else
                  ...state.panel!.medications.map((m) => _buildMedicationItem(m)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelTab(int index, String label, CabinConsultationState state,
      CabinConsultationService service) {
    bool isActive = state.selectedPanelTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => service.setSelectedPanelTab(index),
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

  Widget _buildSymptomItem(String title, String detail, String reportedBy) {
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
            detail,
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

  Widget _buildTestItem(CabinTest test) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color accentColor = AppColors.brand;
    final Color lightColor =
        isDark ? AppColors.brand.withAlpha(40) : AppColors.brandHighlight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppLayout.space8),
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              test.name,
              style: TextStyle(
                  fontSize: 13, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          if (test.status != null && test.status!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(AppLayout.radius16),
                border: Border.all(
                    color: accentColor.withAlpha(100),
                    width: AppLayout.borderThin),
              ),
              child: Text(
                test.status!,
                style: TextStyle(
                  color: isDark ? Colors.white : accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Medication med) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color accentColor = AppColors.brand;
    final Color lightColor =
        isDark ? AppColors.brand.withAlpha(40) : AppColors.brandHighlight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppLayout.space8),
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toTitleCase(med.drugName),
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold),
                ),
                if (med.dose != null && med.dose!.isNotEmpty)
                  Text(
                    med.dose!,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color),
                  ),
              ],
            ),
          ),
          if (med.action != null && med.action!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(AppLayout.radius16),
                border: Border.all(
                    color: accentColor.withAlpha(100),
                    width: AppLayout.borderThin),
              ),
              child: Text(
                toTitleCase(med.action!),
                style: TextStyle(
                  color: isDark ? Colors.white : accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, Color bgColor, Color accentColor,
      {List<Widget>? children}) {
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
                title == "Red Flags"
                    ? LucideIcons.alertTriangle
                    : (title == "Differentials"
                        ? LucideIcons.brainCircuit
                        : LucideIcons.clipboardList),
                size: AppLayout.iconSmall + 2,
                color: accentColor,
              ),
              const SizedBox(width: AppLayout.space8),
              Text(
                title,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space12),
          if (children != null && children.isNotEmpty)
            ...children
          else
            Text(
              "Detailed insights will appear here live...",
              style:
                  TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildRedFlagItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.space8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.space12, vertical: AppLayout.space8 + 2),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(
            color: AppColors.redFlagBorder, width: AppLayout.borderThin),
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

  Widget _buildDifferentialItem(
      String condition, String likelihood, String reasoning) {
    final theme = Theme.of(context);
    final bool isHigh = likelihood.toLowerCase() == 'high';
    final Color accentColor = isHigh ? AppColors.error : AppColors.success;

    final bool isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isHigh
        ? (isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer)
        : (isDark
            ? AppColors.success.withAlpha(40)
            : AppColors.statusFinalizedContainer);

    final Color lightColor = isHigh
        ? (isDark ? AppColors.error.withAlpha(60) : AppColors.redFlagBorder)
        : (isDark
            ? AppColors.success.withAlpha(60)
            : AppColors.statusFinalizedContainer);

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: accentColor, width: AppLayout.borderThin),
                ),
                child: Text(
                  likelihood,
                  style: TextStyle(
                    color: theme.brightness == Brightness.light
                        ? accentColor
                        : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
    Color iconColor =
        theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
    String label = "U";

    if (isDoctor) {
      bgColor = isDark
          ? theme.colorScheme.primary.withAlpha(40)
          : AppColors.brandHighlight;
      iconColor = theme.colorScheme.primary;
      label = "D";
    } else if (isPatient) {
      bgColor = isDark
          ? AppColors.bubblePatientText.withAlpha(40)
          : AppColors.bubblePatient;
      iconColor =
          isDark ? AppColors.bubblePatientText : AppColors.bubblePatientText;
      label = "P";
    } else if (isAttendee) {
      bgColor = isDark
          ? AppColors.bubbleAttendeeText.withAlpha(40)
          : AppColors.bubbleAttendee;
      iconColor =
          isDark ? AppColors.bubbleAttendeeText : AppColors.bubbleAttendeeText;
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
              style: TextStyle(
                  color: iconColor, fontSize: 12, fontWeight: FontWeight.bold),
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
                        isDoctor
                            ? "Doctor"
                            : (isPatient ? "Patient" : "Attendee"),
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getUtteranceTime(utterance),
                        style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    utterance.text,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14),
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
            child: Icon(LucideIcons.loader,
                size: 12, color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(127),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(25) ??
                        Colors.transparent,
                    style: BorderStyle.solid),
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
  final bool isConnecting;
  final double amplitude;
  final VoidCallback onTap;
  final double size;

  const PulsatingMicButton({
    super.key,
    required this.isRecording,
    required this.isConnecting,
    required this.amplitude,
    required this.onTap,
    this.size = 65.0,
  });

  @override
  State<PulsatingMicButton> createState() => _PulsatingMicButtonState();
}

class _PulsatingMicButtonState extends State<PulsatingMicButton>
    with SingleTickerProviderStateMixin {
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
    final double volumeFactor = ((widget.amplitude + 50) / 40).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size * 2,
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
                    final double progress =
                        (_controller.value + (index / 3)) % 1.0;
                    final double spread =
                        progress * (widget.size * 0.9) * volumeFactor;
                    final double opacity = (1.0 - progress) * volumeFactor;

                    return Container(
                      width: widget.size + spread,
                      height: widget.size + spread,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppColors.error.withAlpha((180 * opacity).toInt()),
                      ),
                    );
                  },
                );
              }),
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
              child: widget.isConnecting
                  ? Padding(
                      padding: EdgeInsets.all(widget.size * 0.25),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
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
