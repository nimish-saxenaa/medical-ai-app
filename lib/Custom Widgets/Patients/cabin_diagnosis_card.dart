import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Components/layout_constants.dart';
import '../../Models/cabin_models.dart';
import '../../Screens/Consultation/cabin_consultation_screen.dart';
import '../../Screens/Consultation/cabin_record_screen.dart';
import '../../Services/Cabin/cabin_service.dart';
import '../../functions.dart';

class CabinDiagnosisCard extends StatefulWidget {
  final CabinSession session;
  final int index;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool selectionModeActive;
  final VoidCallback? onSelect;

  const CabinDiagnosisCard({
    super.key,
    required this.session,
    required this.index,
    this.onDelete,
    this.isSelected = false,
    this.selectionModeActive = false,
    this.onSelect,
  });

  @override
  State<CabinDiagnosisCard> createState() => _CabinDiagnosisCardState();
}

class _CabinDiagnosisCardState extends State<CabinDiagnosisCard> {
  bool _expanded = false;
  bool _isLoadingRecord = false;

  Future<void> _viewRecord() async {
    setState(() => _isLoadingRecord = true);
    try {
      final record = await getCabinRecord(widget.session.sessionId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CabinRecordScreen(
            record: record,
            patientName: widget.session.patientName ?? "Patient",
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load record: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRecord = false);
    }
  }

  void _rejoinSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CabinConsultationScreen(
          patientId: widget.session.patientId ?? "",
          patientName: widget.session.patientName ?? "Patient",
          sessionId: widget.session.sessionId,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'pm' : 'am';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final date = session.createdAt != null ? DateTime.parse(session.createdAt!) : DateTime.now();
    
    // Status styling
    Color primaryColor = theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
    Color lightColor = theme.dividerColor;
    
    switch (session.status?.toLowerCase()) {
      case "ended":
        primaryColor = AppColors.statusFinalized;
        lightColor = theme.brightness == Brightness.light ? AppColors.statusFinalizedContainer : primaryColor.withAlpha(40);
        break;
      case "active":
        primaryColor = AppColors.statusInProgress;
        lightColor = theme.brightness == Brightness.light ? AppColors.statusInProgressContainer : primaryColor.withAlpha(40);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        border: Border.all(
          color: widget.isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: AppLayout.borderThin + 0.25,
        ),
        borderRadius: BorderRadius.circular(AppLayout.radius12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radius12)),
              splashColor: theme.colorScheme.primary.withAlpha(40),
              highlightColor: theme.colorScheme.primary.withAlpha(20),
              onLongPress: widget.onSelect,
              onTap: () {
                if (widget.selectionModeActive) {
                  widget.onSelect?.call();
                } else {
                  setState(() => _expanded = !_expanded);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: AppLayout.space12),
                            child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: AppLayout.iconMedium),
                          ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  getSpecialtyName(session.specialty ?? ""),
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppLayout.space8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppLayout.space8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                                  border: Border.all(color: primaryColor, width: AppLayout.borderThin + 0.25),
                                ),
                                child: Text(
                                  toTitleCase(session.status ?? "unknown"),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.brightness == Brightness.light ? primaryColor : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (session.status?.toLowerCase() == 'active') ...[
                                const SizedBox(width: AppLayout.space8),
                                InkWell(
                                  onTap: _rejoinSession,
                                  borderRadius: BorderRadius.circular(AppLayout.radius12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusInProgress,
                                      borderRadius: BorderRadius.circular(AppLayout.radius12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.radio, size: 11, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          "Re-join",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, size: AppLayout.iconSmall + 2, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: AppLayout.space8),
                        _isLoadingRecord
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                splashRadius: 10,
                                tooltip: 'Options',
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppLayout.radius10),
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    if (widget.onDelete != null) {
                                      widget.onDelete!();
                                    }
                                  } else if (value == 'record') {
                                    _viewRecord();
                                  } else if (value == 'rejoin') {
                                    _rejoinSession();
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (session.status?.toLowerCase() == 'active')
                                    PopupMenuItem<String>(
                                      value: 'rejoin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.radio,
                                            size: 18,
                                            color: AppColors.statusInProgress,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Re-join Session',
                                            style: TextStyle(
                                              color: AppColors.statusInProgress,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem<String>(
                                    value: 'record',
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.fileText,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('View Detailed Record'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                        const SizedBox(width: 10),
                                        const Text('Delete', style: TextStyle(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Icon(
                                  LucideIcons.moreVertical,
                                  size: AppLayout.iconSmall + 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.space4),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: AppLayout.iconSmall - 4, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 6),
                        Text(_formatDate(date), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${session.panel?.symptoms.isNotEmpty == true ? toTitleCase(session.panel!.symptoms.first.name) : "No symptoms recorded"}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor, width: AppLayout.borderThin + 0.5)),
              ),
              padding: const EdgeInsets.all(AppLayout.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PANEL DATA", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: AppLayout.space12),
                  if (session.panel == null)
                    Text("No data recorded during session.", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                  else ...[
                    // Symptoms
                    if (session.panel!.symptoms.isNotEmpty) ...[
                      const Text("Symptoms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ...session.panel!.symptoms.map((s) => Padding(
                        padding: const EdgeInsets.only(top: AppLayout.space4),
                        child: Text("• ${toTitleCase(s.name)} (${toTitleCase(s.reportedBy ?? 'unknown')})", style: const TextStyle(fontSize: 12)),
                      )),
                      const SizedBox(height: AppLayout.space12),
                    ],
                    // Diagnoses
                    if (session.panel!.diagnoses.isNotEmpty) ...[
                      const Text("Diagnoses:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ...session.panel!.diagnoses.map((d) {
                        final bool isHigh = d.likelihood?.toLowerCase() == 'high' || d.likelihood?.toLowerCase() == 'suspected';
                        final Color accentColor = isHigh ? AppColors.error : AppColors.success;
                        final Color lightColor = isHigh
                            ? (theme.brightness == Brightness.dark ? AppColors.error.withAlpha(60) : AppColors.redFlagBorder)
                            : (theme.brightness == Brightness.dark ? AppColors.success.withAlpha(60) : AppColors.statusFinalizedContainer);

                        return Padding(
                          padding: const EdgeInsets.only(top: AppLayout.space8),
                          child: Row(
                            children: [
                              Text("• ${toTitleCase(d.condition)}", style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                                  border: Border.all(color: accentColor, width: AppLayout.borderThin),
                                ),
                                child: Text(
                                  toTitleCase(d.likelihood ?? 'N/A'),
                                  style: TextStyle(
                                    color: theme.brightness == Brightness.light ? accentColor : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppLayout.space12),
                    ],
                    // Tests
                    if (session.panel!.tests.isNotEmpty) ...[
                      const Text("Tests Considered:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ...session.panel!.tests.map((t) => Padding(
                        padding: const EdgeInsets.only(top: AppLayout.space4),
                        child: Text("• ${toTitleCase(t.name)}", style: const TextStyle(fontSize: 12)),
                      )),
                      const SizedBox(height: AppLayout.space12),
                    ],
                    // Meds
                    if (session.panel!.medications.isNotEmpty) ...[
                      const Text("Medications:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ...session.panel!.medications.map((m) => Padding(
                        padding: const EdgeInsets.only(top: AppLayout.space4),
                        child: Text("• ${toTitleCase(m.drugName)} - ${m.dose ?? ''}", style: const TextStyle(fontSize: 12)),
                      )),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
