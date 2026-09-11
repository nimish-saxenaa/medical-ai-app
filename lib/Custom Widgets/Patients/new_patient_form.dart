import '../custom_alert_dialog.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Services/PatientData/patient_service.dart';

/// A form widget for creating a new patient record.
///
/// Encapsulates inputs for full name, age, gender, and optional phone number,
/// handling input validation, error presentation, and submission loading states.
/// Can be presented inside a dialog, bottom sheet, or card container.
class NewPatientForm extends StatefulWidget {
  /// Callback triggered when the form is dismissed or cancelled.
  final VoidCallback? onClose;

  /// Asynchronous callback invoked when the user submits a valid form.
  ///
  /// Passes the sanitized [name], parsed [age], optional [gender] label,
  /// and optional [phone] number string.
  final Future<void> Function(
    String name,
    int age,
    String? gender,
    String? phone,
  )? onCreate;

  /// Creates a [NewPatientForm] instance.
  const NewPatientForm({super.key, this.onClose, this.onCreate});

  @override
  State<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends State<NewPatientForm> {
  // Text editing controllers for patient details
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected gender option; null if none selected
  Gender? _selectedGender;

  // Inline error message displayed when validation or creation fails
  String? errorMessage;

  // Indicates whether an asynchronous patient creation operation is in progress
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Clear validation error message whenever the user modifies any field
    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  /// Resets the visible error message upon user interaction.
  void _onFieldChanged() {
    if (errorMessage != null) {
      setState(() {
        errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    // Unregister field listeners before disposing controllers to avoid memory leaks
    _nameController.removeListener(_onFieldChanged);
    _ageController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validates all form inputs and updates [errorMessage] on failure.
  ///
  /// Returns `true` if all validations pass; otherwise `false`.
  bool _validateForm() {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate full name presence and minimum length
    if (name.isEmpty) {
      setState(() => errorMessage = "Name is required");
      return false;
    }

    if (name.length < 3) {
      setState(() => errorMessage = "Name must be at least 3 characters");
      return false;
    }

    // Validate age presence, numeric format, and reasonable bounds
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

    // Validate optional phone number length limit
    if (phone.length > 15) {
      setState(() => errorMessage = "Phone number cannot exceed 15 characters");
      return false;
    }

    return true;
  }

  /// Whether all form inputs currently satisfy basic validity checks.
  ///
  /// Used to dynamically enable or style the submission button.
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

  /// Handles form submission by validating inputs and executing [widget.onCreate].
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
      // Cap maximum modal height to prevent overflowing smaller screens
      constraints: BoxConstraints(maxHeight: height * 0.6),
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal dialog title header
            const _Header(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.space24,
                  vertical: AppLayout.space20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scrollable form fields section
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name field
                            const _FieldLabel(label: 'Full name', required: true),
                            const SizedBox(height: AppLayout.space8),
                            _InputField(
                              controller: _nameController,
                              hint: 'e.g. Rahul Verma',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: AppLayout.space16),

                            // Age and Gender row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Age input column
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

                                // Gender selection buttons
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
                                                    // Toggle selection if tapped again
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
                                                    // Toggle selection if tapped again
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
                                                    // Toggle selection if tapped again
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

                            // Phone Number field (optional)
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

                    // Inline validation error message banner
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

                    // Action buttons (Cancel / Create)
                    Row(
                      children: [
                        // Cancel button
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

                        // Create / Submit button
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

/// Header banner displaying the "New Patient" title.
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

/// Form field label with optional required asterisk or optional tag.
class _FieldLabel extends StatelessWidget {
  /// The text content of the label.
  final String label;

  /// Whether to display a red asterisk indicating a mandatory field.
  final bool required;

  /// Whether to display an "(OPTIONAL)" badge alongside the label.
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

/// Standard text input field styled for patient form entries.
class _InputField extends StatelessWidget {
  /// Controller managing the text being edited.
  final TextEditingController controller;

  /// Placeholder hint text shown when the input is empty.
  final String hint;

  /// Type of keyboard to display for editing.
  final TextInputType keyboardType;

  /// Alignment of the text within the input field.
  final TextAlign textAlign;

  /// Maximum character length limit.
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

/// Segmented option button representing a patient [Gender] choice.
///
/// Toggles selection state with smooth color and border animations.
class GenderButton extends StatelessWidget {
  /// The gender category represented by this button.
  final Gender gender;

  /// Whether this button is currently selected.
  final bool selected;

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  /// Creates a [GenderButton] instance.
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

/// Displays the [NewPatientForm] in a modal dialog.
///
/// Handles patient creation via [createPatient], updates the [PatientListProvider]
/// state upon success, and displays error dialog feedback if the network request fails.
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
                // Send patient creation request to the API
                await createPatient(
                  name: name,
                  gender: gender,
                  age: age,
                  phone: phone,
                );
                if (!context.mounted) return;

                // Refresh the global patient list provider to reflect the new record
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
