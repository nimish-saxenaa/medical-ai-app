import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Models/cabin_models.dart';
import 'cabin_consultation_screen.dart'; // To reuse TranscriptBubble and other helper widgets if possible or just redefine

class CabinRecordScreen extends StatefulWidget {
  final CabinRecord record;
  final String patientName;

  const CabinRecordScreen({
    super.key,
    required this.record,
    required this.patientName,
  });

  @override
  State<CabinRecordScreen> createState() => _CabinRecordScreenState();
}

class _CabinRecordScreenState extends State<CabinRecordScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedPanelTab = 0; // 0: Symptoms, 1: Diagnoses, 2: Tests, 3: Meds

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              "Consultation Record",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppLayout.screenPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageIndicator(0, "Transcript", LucideIcons.listMusic),
                  const SizedBox(width: AppLayout.space16),
                  _buildPageIndicator(1, "Clinical Panel", LucideIcons.clipboardList),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildTranscriptPage(),
                  _buildPanelPage(),
                ],
              ),
            ),
            // Final Action
            Padding(
              padding: AppLayout.screenPadding,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppLayout.space16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius12)),
                  ),
                  child: const Text("Save & Close", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index, String label, IconData icon) {
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
        child: Row(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptPage() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppLayout.radius16),
          border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppLayout.space16),
              child: Row(
                children: [
                  Icon(LucideIcons.listMusic, size: AppLayout.iconSmall, color: theme.colorScheme.primary),
                  const SizedBox(width: AppLayout.space8),
                  Text(
                    "Full Transcript",
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
                itemCount: widget.record.utterances.length,
                itemBuilder: (context, index) {
                  return TranscriptBubble(utterance: widget.record.utterances[index]);
                },
              ),
            ),
            const SizedBox(height: AppLayout.space16),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelPage() {
    final panel = widget.record.panel;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Selector
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppLayout.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppLayout.radius16),
              border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedPanelTab == 0) ...[
                  if (panel.symptoms.isEmpty)
                    Center(child: Text("No symptoms recorded", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)))
                  else
                    ...panel.symptoms.map((s) => _buildSymptomItem(s.name, s.description ?? "", s.reportedBy ?? "unknown")),
                ] else if (_selectedPanelTab == 1) ...[
                  if (panel.diagnoses.isEmpty)
                    Center(child: Text("No diagnoses recorded", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)))
                  else
                    ...panel.diagnoses.map((d) => _buildDifferentialItem(d.condition, d.likelihood ?? "Confirmed", d.reasoning ?? "")),
                ] else if (_selectedPanelTab == 2) ...[
                  if (panel.tests.isEmpty)
                    Center(child: Text("No tests recorded", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)))
                  else
                    ...panel.tests.map((t) => _buildSimplePanelItem(t)),
                ] else if (_selectedPanelTab == 3) ...[
                  if (panel.medications.isEmpty)
                    Center(child: Text("No medications recorded", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)))
                  else
                    ...panel.medications.map((m) => _buildSimplePanelItem(m.drugName)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),
        ],
      ),
    );
  }

  Widget _buildPanelTab(int index, String label) {
    final theme = Theme.of(context);
    bool isActive = _selectedPanelTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPanelTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppLayout.space8),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppLayout.radius8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // Re-implementing helper widgets for the record screen
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
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppLayout.space4),
            Text(description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
          ],
          const SizedBox(height: AppLayout.space8),
          Text("Reported by: $reportedBy", style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildDifferentialItem(String condition, String likelihood, String reasoning) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isHigh = likelihood.toLowerCase() == 'high';
    
    final Color accentColor = isHigh ? AppColors.error : AppColors.success;
    final Color bgColor = isHigh 
        ? (isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer)
        : (isDark ? AppColors.success.withAlpha(40) : AppColors.statusFinalizedContainer);

    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.space12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      padding: const EdgeInsets.all(AppLayout.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(condition, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color))),
              Text(likelihood, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: AppLayout.space8 - 2),
            Text(reasoning, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
          ],
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
      child: Text(text, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
    );
  }
}

