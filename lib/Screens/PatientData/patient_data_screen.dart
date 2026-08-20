import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Components/colors.dart';
import 'patient_history_view.dart';
import '../Consultation/new_consultation_screen.dart';
import '../Consultation/new_cabin_consultation_screen.dart';

class PatientDataScreen extends StatefulWidget {
  const PatientDataScreen({super.key, required this.patientHistory});
  static const routeName = "/patient-data";
  final PatientHistoryResponse patientHistory;

  @override
  State<PatientDataScreen> createState() => _PatientDataScreenState();
}

class _PatientDataScreenState extends State<PatientDataScreen> {
  late PatientHistoryResponse history;

  @override
  void initState() {
    super.initState();
    history = widget.patientHistory;
  }

  @override
  void didUpdateWidget(PatientDataScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientHistory != oldWidget.patientHistory) {
      setState(() {
        history = widget.patientHistory;
      });
    }
  }

  void _showConsultationTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Start New Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.stethoscope, color: AppColors.primary, size: 20),
              ),
              title: const Text("Medical Consultation"),
              subtitle: const Text("Standard AI-assisted history taking"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewConsultationScreen(
                      patientName: history.patient.name,
                      patientAge: history.patient.age,
                      patientGender: history.patient.gender ?? "",
                      patientId: history.patient.patientId,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.monitor, color: Colors.orange, size: 20),
              ),
              title: const Text("Cabin Flow"),
              subtitle: const Text("Doctor-led live consultation"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewCabinConsultationScreen(
                      patientId: history.patient.patientId,
                      patientName: history.patient.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showConsultationTypeDialog,
        child: const Icon(LucideIcons.clipboardPlus),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back),
                  Text(
                    "Patients  /  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              history.patient.name,
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
      body: Container(
        color: AppColors.greyLight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PatientClinicalHistoryView(
              patientHistory: history,
              onHistoryUpdated: () {
                // Handle any state sync if needed
              },
            ),
          ),
        ),
      ),
    );
  }
}
