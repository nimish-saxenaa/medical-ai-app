import 'package:clinical_ai_app/Custom%20Widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Custom Widgets/Patients/custom_name_initial.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Location/location_service.dart';
import '../../Components/colors.dart';
import '../../test_screen.dart';
import 'history_taking_screen.dart';

class NewConsultationScreen extends StatefulWidget {
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientId;

  static const routeName = "/new-consultation";

  const NewConsultationScreen({
    super.key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender, required this.patientId,
  });

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  TypesOfSpeciality _selected = TypesOfSpeciality.general_medicine;
  final _complaintController = TextEditingController();
  final _languageController = TextEditingController();
  bool isTapped = false;

  @override
  void dispose() {
    _complaintController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.arrow_back),
                  Text(
                    "Back  /  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              "New Consultation",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Image.asset("assets/kuvaka_logo.png"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PatientBox(
                name: widget.patientName,
                age: widget.patientAge,
                gender: widget.patientGender,
              ),
              const SizedBox(height: 16),
              TypeOfConsultation(
                selected: _selected,
                onSelect: (type) => setState(() => _selected = type),
              ),
              const SizedBox(height: 16),

              LabeledTextField(
                label: 'Chief complaint',
                optionalText: '(optional)',
                child: _InputField(
                  controller: _complaintController,
                  hint: 'e.g. chest pain for 2 days, fever since yesterday…',
                ),
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Language preference',
                optionalText: '(leave blank for English)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InputField(
                      controller: _languageController,
                      hint: 'e.g. Hindi, Arabic, French, Spanish, etc.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The AI will speak and understand your preferred language.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () async {
                  setState(() {
                    isTapped = true;
                  });

                  String? token = await AccessTokenService.getToken();
                  var response = await startConsultation(
                    patientId: widget.patientId,
                    token: token!,
                    specialty: _selected.name.toString(),
                    patientLanguage: _languageController.text.isNotEmpty?_languageController.text:null,
                    chiefComplaint: _complaintController.text.isNotEmpty?_complaintController.text:null,
                  );
                  // Record where this consultation is taking place. Stored
                  // locally against the session id — never blocks the flow.
                  await ConsultationLocationService.captureAndSaveForSession(
                    response.sessionId,
                  );

                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryTakingScreen(sessionId: response.sessionId, question: response.openingQuestion!)
                    ),
                  );

                  setState(() {
                    isTapped = false;
                  });
                },
                child: isTapped
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Starting Consultation'),
                        ],
                      )
                    : Text('Begin Consultation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientBox extends StatelessWidget {
  final String name;
  final int age;
  final String gender;

  const PatientBox({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomNameInitial(name: name),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                '$age yrs · $gender',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum TypesOfSpeciality { general_medicine, psychotherapy, gynecology }

class SingleSpeciality {
  final TypesOfSpeciality type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const SingleSpeciality({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

const specialities = [
  SingleSpeciality(
    type: TypesOfSpeciality.general_medicine,
    title: 'General Medicine',
    subtitle: 'Primary care & internal medicine',
    icon: LucideIcons.stethoscope,
    iconBg: Color(0xFFDBEAFE),
    iconColor: Color(0xFF2563EB),
  ),
  SingleSpeciality(
    type: TypesOfSpeciality.psychotherapy,
    title: 'Mental Health',
    subtitle: 'Psychotherapy & psychiatric assessment',
    icon: LucideIcons.brain,
    iconBg: Color(0xFFEDE9FE),
    iconColor: Color(0xFF7C3AED),
  ),
  SingleSpeciality(
    type: TypesOfSpeciality.gynecology,
    title: "Women's Health",
    subtitle: 'Gynaecology & obstetrics',
    icon: LucideIcons.heart,
    iconBg: Color(0xFFFFE4E6),
    iconColor: Color(0xFFE11D48),
  ),
];

class TypeOfConsultation extends StatelessWidget {
  final TypesOfSpeciality selected;
  final ValueChanged<TypesOfSpeciality> onSelect;

  const TypeOfConsultation({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TYPE OF CONSULTATION',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...specialities.map((option) {
            final isSelected = option.type == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SpecialitySelectTile(
                option: option,
                isSelected: isSelected,
                onTap: () => onSelect(option.type),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SpecialitySelectTile extends StatelessWidget {
  final SingleSpeciality option;
  final bool isSelected;
  final VoidCallback onTap;

  const SpecialitySelectTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.greyLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option.icon, size: 20, color: option.iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.greyLight,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? optionalText;
  final Widget child;

  const LabeledTextField({
    super.key,
    required this.label,
    this.optionalText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: label.toUpperCase()),
                if (optionalText != null)
                  TextSpan(
                    text: ' $optionalText',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.greyLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.grey),
        ),
      ),
    );
  }
}
