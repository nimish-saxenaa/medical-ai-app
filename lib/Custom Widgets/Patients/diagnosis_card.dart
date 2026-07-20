import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../Components/colors.dart';

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
    required this.show,
  });

  @override
  State<DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<DiagnosisCard> {
  bool _expanded = false;

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'pm' : 'am';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
 late Color primaryColor;
  late Color lightColor;



  @override
  Widget build(BuildContext context) {
    switch (widget.status) {
      case "Diagnosed":
        primaryColor = AppColors.diagnosedPrimary;
        lightColor = AppColors.diagnosedLight;
        break;

      case "In Progress":
        primaryColor = AppColors.progressPrimary;
        lightColor = AppColors.progressLight;
        break;
    case "Finalized":
      primaryColor = AppColors.finalizedPrimary;
      lightColor = AppColors.finalizedLight;
      case "Prescribed":
        primaryColor = AppColors.prescribedPrimary;
        lightColor = AppColors.prescribedLight;
      default:
        primaryColor = AppColors.grey;
        lightColor = AppColors.greyLight;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)), // gray-100
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              hoverColor: const Color(0xFFF9FAFB),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    width: 0.75,
                                    color: primaryColor,
                                  ),
                                ),
                                child: Text(
                                  widget.status,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: primaryColor,
                                    fontWeight: FontWeight.w600
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                size: 12,
                                color: Color(0xFFD1D5DB),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(widget.date),
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '· ${widget.description}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.location != null &&
                              widget.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 12,
                                  color: Color(0xFFD1D5DB),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.location!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
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
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0, // flips chevron down <-> up
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
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
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB), // gray-50/60 approximation
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No diagnosis recorded yet.",
                style: Theme.of(context).textTheme.bodyMedium,
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // gray-50/60 approximation
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Diagnosis'),
          const SizedBox(height: 12),
          // Red flag alerts
          Column(
            children: redFlags
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RedFlagAlert(text: f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Diagnosis rows
          ...diagnoses.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DiagnosisRow(item: d),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workup,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Clinical Summary'),
          const SizedBox(height: 20),
          _SoapSection(letter: 'S', title: 'Subjective', fields: subjective),
          const SizedBox(height: 20),
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
      style: const TextStyle(
        color: Color(0xFF9CA3AF),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // red-50
        border: Border.all(color: const Color(0xFFFEE2E2)), // red-100
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_rounded,
              size: 14,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB91C1C), // red-700
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
    final isHigh = item.severity.toLowerCase() == 'high';
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.severity,
            style: TextStyle(
              color: isHigh ? const Color(0xFFB91C1C) : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '(${item.code})',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE), // brand-light approx
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Color(0xFF7C3AED), // brand approx
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            f.label,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (f.value == null) ? 'Not recorded' : f.value!,
                            style: TextStyle(
                              color: (f.value == null)
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF374151),
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
