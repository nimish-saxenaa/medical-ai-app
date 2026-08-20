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
    final session = widget.session;
    final date = session.createdAt != null ? DateTime.parse(session.createdAt!) : DateTime.now();
    
    // Status styling
    Color primaryColor = AppColors.grey;
    Color lightColor = AppColors.greyLight;
    
    switch (session.status?.toLowerCase()) {
      case "ended":
        primaryColor = AppColors.finalizedPrimary;
        lightColor = AppColors.finalizedLight;
        break;
      case "active":
        primaryColor = AppColors.progressPrimary;
        lightColor = AppColors.progressLight;
        break;
      default:
        primaryColor = AppColors.grey;
        lightColor = AppColors.greyLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isSelected ? AppColors.primaryLight : Colors.white,
        border: Border.all(
          color: widget.isSelected ? AppColors.primary.withAlpha(100) : AppColors.dividerLight,
          width: 0.75,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              splashColor: AppColors.primaryLight,
              highlightColor: AppColors.primaryLight.withAlpha(100),
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
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                          ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  getSpecialtyName(session.specialty ?? ""),
                                  style: Theme.of(context).textTheme.bodyLarge,
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: primaryColor,
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
                          child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          splashRadius: 10,
                          child: const Icon(
                            LucideIcons.moreVertical,
                            size: 18,
                            color: AppColors.primary,
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
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
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
                        const Icon(LucideIcons.calendar, size: 12, color: Color(0xFFD1D5DB)),
                        const SizedBox(width: 6),
                        Text(_formatDate(date), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${session.panel?.symptoms.isNotEmpty == true ? session.panel!.symptoms.first.name : "No symptoms recorded"}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
              decoration: const BoxDecoration(
                color: AppColors.greyLight,
                border: Border(top: BorderSide(color: AppColors.dividerLight)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PANEL DATA", style: TextStyle(color: AppColors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  if (session.panel == null)
                    const Text("No data recorded during session.", style: TextStyle(color: AppColors.grey, fontSize: 13))
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
