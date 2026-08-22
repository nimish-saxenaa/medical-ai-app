import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Models/cabin_models.dart';
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isSelected ? theme.colorScheme.primary.withAlpha(40) : theme.colorScheme.surface,
        border: Border.all(
          color: widget.isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: 0.75,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor, width: 0.75),
                                ),
                                child: Text(
                                  session.status ?? "unknown",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.brightness == Brightness.light ? primaryColor : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, size: 18, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          splashRadius: 10,
                          child: Icon(
                            LucideIcons.moreVertical,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Options',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              if (widget.onDelete != null) {
                                widget.onDelete!();
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 12, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 6),
                        Text(_formatDate(date), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${session.panel?.symptoms.isNotEmpty == true ? session.panel!.symptoms.first.name : "No symptoms recorded"}',
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
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PANEL DATA", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  if (session.panel == null)
                    Text("No data recorded during session.", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))
                  else ...[
                    // Symptoms
                    if (session.panel!.symptoms.isNotEmpty) ...[
                      const Text("Symptoms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ...session.panel!.symptoms.map((s) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("• ${s.name} (${s.reportedBy ?? 'unknown'})", style: const TextStyle(fontSize: 12)),
                      )),
                      const SizedBox(height: 12),
                    ],
                    // Diagnoses
                    if (session.panel!.diagnoses.isNotEmpty) ...[
                      const Text("Diagnoses:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ...session.panel!.diagnoses.map((d) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("• ${d.condition} - ${d.likelihood ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                      )),
                      const SizedBox(height: 12),
                    ],
                    // Tests
                    if (session.panel!.tests.isNotEmpty) ...[
                      const Text("Tests Considered:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(session.panel!.tests.join(", "), style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 12),
                    ],
                    // Meds
                    if (session.panel!.medications.isNotEmpty) ...[
                      const Text("Medications:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ...session.panel!.medications.map((m) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("• ${m.drugName} - ${m.dose ?? ''}", style: const TextStyle(fontSize: 12)),
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
