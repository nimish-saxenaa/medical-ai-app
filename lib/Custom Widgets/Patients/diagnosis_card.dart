import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Components/layout_constants.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Models/session_model.dart';

/// ---------- Data models ----------

class DiagnosisItem {
  final String severity; // High / Moderate / Low
  final String name;
  final String code;

  const DiagnosisItem({
    required this.severity,
    required this.name,
    required this.code,
  });
}

class SoapField {
  final String label;
  final String? value; // null / empty => "Not recorded"

  const SoapField({required this.label, this.value});
}

/// ---------- Main expandable card ----------

class DiagnosisCard extends StatefulWidget {
  final String title;
  final String status;
  final DateTime date;
  final String description;

  final List<String> redFlags;
  final List<DiagnosisItem> diagnoses;
  final String workup;

  final List<SoapField> subjective;
  final List<SoapField> objective;
  final bool show;
  final PatientHistoryResponse patientHistory;
  final int index;
  final VoidCallback? onDelete;
  final Function(Session)? onDownload;
  final bool isDownloading;
  final bool isSelected;
  final bool selectionModeActive;
  final VoidCallback? onSelect;


  /// Where the consultation was recorded. Null for consultations captured
  /// before location tracking existed — the row is hidden in that case.
  final String? location;

  const DiagnosisCard({
    super.key,
    required this.title,
    required this.status,
    required this.date,
    required this.description,
    this.location,
    required this.redFlags,
    required this.diagnoses,
    required this.workup,
    required this.subjective,
    required this.objective,
    required this.show, required this.patientHistory, required this.index,
    this.onDelete,
    this.onDownload,
    this.isDownloading = false,
    this.isSelected = false,
    this.selectionModeActive = false,
    this.onSelect,
  });

  @override
  State<DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<DiagnosisCard> {
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
    final history = widget.patientHistory;
    Color primaryColor;
    Color lightColor;

    switch (widget.status) {
      case "Diagnosed":
        primaryColor = AppColors.statusDiagnosed;
        lightColor = theme.brightness == Brightness.light ? AppColors.statusDiagnosedContainer : primaryColor.withAlpha(40);
        break;

      case "In Progress":
        primaryColor = AppColors.statusInProgress;
        lightColor = theme.brightness == Brightness.light ? AppColors.statusInProgressContainer : primaryColor.withAlpha(40);
        break;
    case "Finalized":
      primaryColor = AppColors.statusFinalized;
      lightColor = theme.brightness == Brightness.light ? AppColors.statusFinalizedContainer : primaryColor.withAlpha(40);
      case "Prescribed":
        primaryColor = AppColors.statusPrescribed;
        lightColor = theme.brightness == Brightness.light ? AppColors.statusPrescribedContainer : primaryColor.withAlpha(40);
      default:
        primaryColor = theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
        lightColor = theme.dividerColor;
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: AppLayout.space8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppLayout.space8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                                  border: Border.all(
                                    color: primaryColor,
                                    width: AppLayout.borderThin + 0.25,
                                  ),
                                ),
                                child: Text(
                                  widget.status,
                                  style: theme
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
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
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: AppLayout.iconSmall + 2,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(width: AppLayout.space8),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          splashRadius: 10,
                          child: widget.isDownloading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: AppLayout.borderThick),
                          )
                              : Icon(
                            LucideIcons.moreVertical,
                            size: AppLayout.iconSmall + 2,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Options',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppLayout.radius10),
                          ),
                          onSelected: (value) {
                            if (value == 'download') {
                              if (widget.onDownload != null) {
                                widget.onDownload!(history.sessions[widget.index]);
                              }
                            } else if (value == 'delete') {
                              if (widget.onDelete != null) {
                                widget.onDelete!();
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'download',
                              enabled: !widget.isDownloading,
                              child: Row(
                                children: const [
                                  Icon(LucideIcons.download, size: 18),
                                  SizedBox(width: 10),
                                  Text('Download PDF'),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.space4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: AppLayout.iconSmall - 4,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(widget.date),
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${widget.description}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.location != null &&
                        widget.location!.isNotEmpty) ...[
                      const SizedBox(height: AppLayout.space4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: AppLayout.iconSmall - 4,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.location!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_expanded && widget.show)
            _ExpandedBody(
              redFlags: widget.redFlags,
              diagnoses: widget.diagnoses,
              workup: widget.workup,
              subjective: widget.subjective,
              objective: widget.objective,
              show: widget.show,
            ),
          if (_expanded && !widget.show)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor, width: AppLayout.borderThin + 0.5)),
              ),
              padding: const EdgeInsets.all(AppLayout.space20),
              child: Text(
                "No diagnosis recorded yet.",
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/*

 */
/// ---------- Expanded body ----------

class _ExpandedBody extends StatelessWidget {
  final List<String> redFlags;
  final List<DiagnosisItem> diagnoses;
  final String workup;
  final List<SoapField> subjective;
  final List<SoapField> objective;
  final bool show;
  const _ExpandedBody({
    required this.redFlags,
    required this.diagnoses,
    required this.workup,
    required this.subjective,
    required this.objective,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: AppLayout.borderThin + 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space20, vertical: AppLayout.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Diagnosis'),
          const SizedBox(height: AppLayout.space12),
          // Red flag alerts
          Column(
            children: redFlags
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppLayout.space8),
                    child: _RedFlagAlert(text: f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppLayout.space4),
          // Diagnosis rows
          ...diagnoses.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.space8),
              child: _DiagnosisRow(item: d),
            ),
          ),
          const SizedBox(height: AppLayout.space4),
          Text(
            workup,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppLayout.space20),
          _SectionLabel('Clinical Summary'),
          const SizedBox(height: AppLayout.space20),
          _SoapSection(letter: 'S', title: 'Subjective', fields: subjective),
          const SizedBox(height: AppLayout.space20),
          _SoapSection(letter: 'O', title: 'Objective', fields: objective),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _RedFlagAlert extends StatelessWidget {
  final String text;
  const _RedFlagAlert({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space12, vertical: AppLayout.space10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer,
        border: Border.all(color: isDark ? AppColors.error.withAlpha(100) : AppColors.redFlagBorder, width: AppLayout.borderMedium),
        borderRadius: BorderRadius.circular(AppLayout.radius8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_rounded,
              size: 14,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppLayout.space10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onErrorContainer,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisRow extends StatelessWidget {
  final DiagnosisItem item;
  const _DiagnosisRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHigh = item.severity.toLowerCase() == 'high';
    return Wrap(
      spacing: AppLayout.space8,
      runSpacing: AppLayout.space4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isHigh 
                ? (isDark ? AppColors.error.withAlpha(100) : AppColors.redFlagBorder) 
                : (isDark ? theme.dividerColor : AppColors.divider),
            borderRadius: BorderRadius.circular(AppLayout.space4),
          ),
          child: Text(
            item.severity,
            style: TextStyle(
              color: isHigh 
                  ? (isDark ? Colors.white : AppColors.onErrorContainer)
                  : theme.textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          item.name,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '(${item.code})',
          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
        ),
      ],
    );
  }
}

class _SoapSection extends StatelessWidget {
  final String letter;
  final String title;
  final List<SoapField> fields;

  const _SoapSection({
    required this.letter,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: AppLayout.space20,
              height: AppLayout.space20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppLayout.space8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.space10),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppLayout.space8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            f.label,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppLayout.space12),
                        Expanded(
                          child: Text(
                            (f.value == null) ? 'Not recorded' : f.value!,
                            style: TextStyle(
                              color: (f.value == null)
                                  ? theme.disabledColor
                                  : theme.textTheme.bodyLarge?.color,
                              fontSize: 12,
                              height: 1.5,
                              fontStyle: (f.value == null)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
