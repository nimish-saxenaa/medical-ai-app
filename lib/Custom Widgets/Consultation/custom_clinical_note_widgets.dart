import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';

import '../../functions.dart';


class ClinicalNotePage extends StatelessWidget {
  const ClinicalNotePage({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummarySection(
          title: "Subjective",
          data: data["subjective"] ?? const {},
        ),
        SummarySection(title: "Objective", data: data["objective"] ?? const {}),
        SingleValueTitle(title: "Assessment", value: data["assessment"]),
        SingleValueTitle(title: "Plan", value: data["plan"]),
      ],
    );
  }
}

class SingleValueTitle extends StatelessWidget {
  const SingleValueTitle({super.key, required this.title, required this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleText(title: title),
        if (value != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.space8),
            child: Text(
              value!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return TitleText(title: title.toUpperCase());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleText(title: title.toUpperCase()),

        const SizedBox(height: AppLayout.space8),

        Container(
          padding: const EdgeInsets.only(left: AppLayout.space16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: AppLayout.borderThick),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppLayout.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleText(title: formatKey(entry.key)),

                    const SizedBox(height: AppLayout.space4),

                    Text(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class TitleText extends StatelessWidget {
  const TitleText({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}