import '../CustomAlertDialog.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Services/PatientData/patient_service.dart';

/// Full "New Patient" sheet/dialog: header + form.
/// Wrap in a Dialog / showModalBottomSheet / Card as needed.
class NewPatientForm extends StatefulWidget {
  final VoidCallback? onClose;
  final Future<void> Function(String name, int age, String? gender, String? phone)?
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
  String? errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      errorMessage = null;
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _ageController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => errorMessage = "Name is required");
      return false;
    }

    if (name.length < 3) {
      setState(() => errorMessage = "Name must be at least 3 characters");
      return false;
    }

    if (ageStr.isEmpty) {
      setState(() => errorMessage = "Age is required");
      return false;
    }

    final age = int.tryParse(ageStr);
    if (age == null) {
      setState(() => errorMessage = "Age must be a number");
      return false;
    }

    if (age <= 5) {
      setState(() => errorMessage = "Age must be more than 5");
      return false;
    }

    if (age >= 200) {
      setState(() => errorMessage = "Enter a valid Age");
      return false;
    }

    if (phone.length > 15) {
      setState(() => errorMessage = "Phone number cannot exceed 15 characters");
      return false;
    }

    return true;
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 3 || ageStr.isEmpty) return false;

    final age = int.tryParse(ageStr);
    if (age == null || age <= 5 || age >= 200) return false;

    if (phone.length > 15) return false;

    return true;
  }

  Future<void> _handleCreate() async {
    if (!_validateForm()) return;
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
      errorMessage = null;
    });

    try {
      await widget.onCreate?.call(
        _nameController.text.trim(),
        int.parse(_ageController.text.trim()),
        _selectedGender?.label,
        _phoneController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height *0.6),
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppLayout.space24, vertical: AppLayout.space20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(label: 'Full name', required: true),
                            const SizedBox(height: AppLayout.space8),
                            _InputField(
                              controller: _nameController,
                              hint: 'e.g. Rahul Verma',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: AppLayout.space16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const _FieldLabel(label: 'Age', required: true),
                                      const SizedBox(height: AppLayout.space8),
                                      _InputField(
                                        controller: _ageController,
                                        hint: 'YY',
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppLayout.space16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const _FieldLabel(label: 'Gender', required: false),
                                      const SizedBox(height: AppLayout.space8),
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
                                            const SizedBox(width: AppLayout.space8),
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
                                            const SizedBox(width: AppLayout.space8),
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
                            const SizedBox(height: AppLayout.space20),
                            const _FieldLabel(label: 'Phone Number', optional: true),
                            const SizedBox(height: AppLayout.space8),
                            _InputField(
                              controller: _phoneController,
                              hint: '+91 98765 43210',
                              keyboardType: TextInputType.phone,
                              maxLength: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppLayout.space24),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.textTheme.bodyMedium?.color,
                              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12 + 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppLayout.radius10),
                                side: BorderSide(color: theme.dividerColor, width: AppLayout.borderThin),
                              ),
                              elevation: 0,
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: AppLayout.space12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _handleCreate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid
                                  ? null
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? AppDarkColors.outlineVariant
                                      : AppColors.outlineVariant),
                              foregroundColor: _isFormValid
                                  ? null
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? AppDarkColors.textDisabled
                                      : AppColors.textDisabled),
                              disabledBackgroundColor: _isCreating
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? AppDarkColors.brand
                                      : AppColors.brand)
                                  : null,
                              disabledForegroundColor: _isCreating
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? AppDarkColors.textPrimary
                                      : AppColors.surface)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12 + 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppLayout.radius10),
                              ),
                              elevation: 0,
                            ),
                            child: _isCreating
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text("Creating...", style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                : const Text("Create", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Header ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.space24, vertical: AppLayout.space16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: AppLayout.borderThin)),
      ),
      child: Text(
        'New Patient',
        style: theme.textTheme.displayMedium,
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
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color?.withAlpha(204),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
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
  final int? maxLength;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      maxLength: maxLength,
      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        fillColor: theme.colorScheme.surface,
        counterText: "",
        contentPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space12 + 2),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg = isDark ? gender.primaryColor.withAlpha(40) : gender.secondaryColor;
    final selectedText = isDark ? Colors.white : gender.primaryColor;

    return Material(
      color: selected ? selectedBg : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppLayout.radius12),
      child: InkWell(
        onTap: onTap,
        splashColor: selectedBg,
        highlightColor: selectedBg.withAlpha(20),
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.radius12),
            border: Border.all(
              color: selected ? gender.primaryColor : theme.dividerColor,
              width: selected ? AppLayout.borderThin + 1.0 : AppLayout.borderThin + 0.25,
            ),
          ),
          child: Text(
            gender.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? selectedText : theme.textTheme.bodyMedium?.color,
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
  final theme = Theme.of(context);
  return showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(127),
    builder: (context) {
      return Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space20),
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
