import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/CustomAlertDialog.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Cabin/cabin_service.dart';
import '../../Services/Location/location_service.dart';
import 'cabin_consultation_screen.dart';
import 'new_consultation_screen.dart';

class NewCabinConsultationScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const NewCabinConsultationScreen({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<NewCabinConsultationScreen> createState() => _NewCabinConsultationScreenState();
}

class _NewCabinConsultationScreenState extends State<NewCabinConsultationScreen> {
  TypesOfSpeciality _selected = TypesOfSpeciality.general_medicine;
  final _nameController = TextEditingController();
  final _complaintController = TextEditingController();
  bool _consent = true;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.patientName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back),
                  Text("Back  /  ", style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            const Text("New Cabin Flow", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: 10),
            child: Image.asset("assets/kuvaka_logo.png"),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Patient Name Input
                      LabeledTextField(
                        label: 'Patient Name',
                        child: _SimpleInputField(
                          controller: _nameController,
                          hint: 'Full name of the patient',
                        ),
                      ),
                      const SizedBox(height: AppLayout.space16),

                      // Specialty Selection
                      TypeOfConsultation(
                        selected: _selected,
                        onSelect: (type) => setState(() => _selected = type),
                      ),
                      const SizedBox(height: AppLayout.space16),

                      // Chief Complaint
                      LabeledTextField(
                        label: 'Chief complaint',
                        optionalText: '(optional)',
                        child: _SimpleInputField(
                          controller: _complaintController,
                          hint: 'e.g. chronic back pain, fever...',
                        ),
                      ),
                      const SizedBox(height: AppLayout.space16),

                      // Consent Checkbox
                      Container(
                        padding: const EdgeInsets.all(AppLayout.space16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppLayout.radius16),
                          border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
                        ),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: _consent,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (val) => setState(() => _consent = val ?? false),
                              ),
                            ),
                            const SizedBox(width: AppLayout.space8),
                            const Expanded(
                              child: Text(
                                "Patient has provided explicit consent for audio recording and clinical processing.",
                                style: TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppLayout.space16),
                    ],
                  ),
                ),
              ),

              // Begin Button
              CustomButton(
                onPressed: _startCabinFlow,
                child: _isTapped
                    ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: AppLayout.borderThick)),
                            SizedBox(width: AppLayout.space8),
                            Text('Initializing...'),
                          ],
                        )
                      : const Text('Begin Consultation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startCabinFlow() async {
    if (!_consent) {
      showCustomDialog("Patient consent is required to proceed.", context);
      return;
    }

    setState(() => _isTapped = true);

    try {
      final session = await createCabinSession(
        specialty: _selected.name,
        patientId: widget.patientId,
        patientName: _nameController.text.trim(),
        consent: true,
      );

      await ConsultationLocationService.captureAndSaveForSession(session.sessionId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CabinConsultationScreen(
            patientId: widget.patientId,
            patientName: _nameController.text.trim(),
            sessionId: session.sessionId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCustomDialog("Failed to start cabin flow. Please check your connection.", context);
    } finally {
      if (mounted) setState(() => _isTapped = false);
    }
  }
}

class _SimpleInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SimpleInputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space12),
      ),
    );
  }
}
