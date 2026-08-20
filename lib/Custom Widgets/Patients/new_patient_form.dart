import '../CustomAlertDialog.dart';
import '../custom_button.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Services/PatientData/patient_service.dart';

/// Full "New Patient" sheet/dialog: header + form.
/// Wrap in a Dialog / showModalBottomSheet / Card as needed.
class NewPatientForm extends StatefulWidget {
  final VoidCallback? onClose;
  final void Function(String name, int age, String? gender, String? phone)?
  onCreate;

  const NewPatientForm({super.key, this.onClose, this.onCreate});

  @override
  State<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends State<NewPatientForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }
    widget.onCreate?.call(
      _nameController.text.trim(),
      int.tryParse(_ageController.text.trim()) ?? 0,
      _selectedGender?.label,
      _phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel(label: 'Full name', required: true),
                const SizedBox(height: 8),
                _InputField(
                  controller: _nameController,
                  hint: 'e.g. Rahul Verma',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _FieldLabel(label: 'Age', required: true),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _ageController,
                            hint: 'YY',
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _FieldLabel(label: 'Gender', required: false),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GenderButton(
                                    gender: Gender.male,
                                    selected: _selectedGender == Gender.male,
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = (_selectedGender == Gender.male) ? null : Gender.male;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GenderButton(
                                    gender: Gender.female,
                                    selected: _selectedGender == Gender.female,
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = (_selectedGender == Gender.female) ? null : Gender.female;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GenderButton(
                                    gender: Gender.other,
                                    selected: _selectedGender == Gender.other,
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = (_selectedGender == Gender.other) ? null : Gender.other;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _FieldLabel(label: 'Phone Number', optional: true),
                const SizedBox(height: 8),
                _InputField(
                  controller: _phoneController,
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greyLight,
                          foregroundColor: AppColors.greyDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Create", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Header ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.greyLight,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.75)),
      ),
      child: Text(
        'New Patient',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
      ),
    );
  }
}

/// ---------- Field label ----------

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  final bool optional;

  const _FieldLabel({
    required this.label,
    this.required = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.black.withOpacity(0.8),
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: label.toUpperCase()),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
          if (optional)
            TextSpan(
              text: ' (OPTIONAL)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------- Text input ----------

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextAlign textAlign;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.black,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.grey.withOpacity(0.6),
        ),
        filled: true,
        fillColor: AppColors.greyLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.75),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.75),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
        ),
      ),
    );
  }
}

/// ---------- Gender segmented button ----------

class GenderButton extends StatelessWidget {
  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  const GenderButton({
    super.key,
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? gender.secondaryColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? gender.primaryColor : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 0.75,
            ),
          ),
          child: Text(
            gender.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? gender.primaryColor : AppColors.greyDark,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}


Future<void> showNewPatientDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: NewPatientForm(
            onClose: () => Navigator.of(context).pop(),
            onCreate: (name, age, gender, phone) async {
              try {
                await createPatient(
                  name: name,
                  gender: gender,
                  age: age,
                  phone: phone,
                );
                if (!context.mounted) return;
                final patientsProvider = context.read<PatientListProvider>();
                PatientListProvider patientList = await listPatients();
                patientsProvider.setPatients(patientList.patients!);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                showCustomDialog(
                  "Failed to create patient. Please check your connection.",
                  context,
                );
              }
            },
          ),
        ),
      );
    },
  );
}
