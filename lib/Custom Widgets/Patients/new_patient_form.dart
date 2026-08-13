import '../CustomAlertDialog.dart';
import '../custom_button.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/patient_list_model.dart';
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
  String? _selectedGender;
  bool male = false;
  bool female = false;
  bool other = false;

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
      _selectedGender,
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
          _Header(onClose: widget.onClose),
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
                      width: MediaQuery.widthOf(context) * 0.2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldLabel(label: 'Age', required: true),
                          const SizedBox(height: 6),
                          _InputField(
                            controller: _ageController,
                            hint: '—',
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                    label: 'Male',
                                    selected: male,
                                    onTap: () {
                                      setState(() {
                                        !male? _selectedGender = "Male" : _selectedGender = null;
                                        male = !male;
                                        female = false;
                                        other = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GenderButton(
                                    label: 'Female',
                                    selected: female,
                                    onTap: () {
                                      setState(() {
                                        !female? _selectedGender = "Female" : _selectedGender = null;
                                        male = false;
                                        female = !female;
                                        other = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GenderButton(
                                    label: 'Other',
                                    selected: other,
                                    onTap: () {
                                      setState(() {
                                        !other? _selectedGender = "Other" : _selectedGender = null;
                                        male = false;
                                        female = false;
                                        other = !other;
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
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Phone', optional: true),
                const SizedBox(height: 6),
                _InputField(
                  controller: _phoneController,
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CancelButton(
                        label: "Cancel",
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleCreate,
                        child: Text("Create") ,
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
  final VoidCallback? onClose;
  const _Header({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.greyLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('New Patient', style: Theme.of(context).textTheme.displayMedium),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 16, color: AppColors.grey),
              ),
            ),
          ),
        ],
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
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(text: label),
          if (required)
            TextSpan(
              text: ' *',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Color(0xffef4444)),
            ),
          if (optional)
            TextSpan(
              text: ' (optional)',
              style: Theme.of(context).textTheme.bodyMedium,
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
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// ---------- Gender segmented button ----------

class GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const GenderButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMuted : AppColors.greyLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.grey,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Buttons ----------

class CancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const CancelButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(AppColors.greyLight),
              foregroundColor: WidgetStateProperty.all(AppColors.grey),
              side: WidgetStateProperty.all(BorderSide(color: AppColors.grey)),
            ),
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }
}

/// ---------- Example: showing it as a dialog ----------

Future<void> showNewPatientDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(100),
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
