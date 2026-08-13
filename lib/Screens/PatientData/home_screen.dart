import 'package:clinical_ai_app/Custom%20Widgets/custom_confirmation_alert.dart';
import 'package:clinical_ai_app/functions.dart';
import 'package:clinical_ai_app/Models/patient_list_model.dart';
import 'package:clinical_ai_app/Models/patient_model.dart';
import 'package:clinical_ai_app/Screens/PatientData/patient_data_screen.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Custom Widgets/Patients/custom_name_initial.dart';
import '../../Custom Widgets/Patients/new_patient_form.dart';
import '../../Services/Authentication/navigation_service.dart';
import '../../Services/PatientData/patient_service.dart';
import '../../Services/Authentication/access_token.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    searchController.clear();
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsProvider = context.watch<PatientListProvider>();
    final List<Patient> patientList = patientsProvider.patients!;
    List<Patient> filteredPatientList = patientList
        .where(
          (patient) => patient.name.toLowerCase().contains(
            searchController.text.trim().toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset("assets/kuvaka_logo.png"),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              showCustomConfirmationAlert(
                "Do you want to Logout?",
                context,
                () async {
                  await AccessTokenService.clear();
                  logout();
                },
              );
            },
            icon: const Icon(LucideIcons.logOut, color: AppColors.grey),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showNewPatientDialog(context);
        },
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "Patients  ",
                  style: Theme.of(context).textTheme.headlineLarge,
                  children: [
                    TextSpan(
                      text: "${patientList.length}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Manage and view your patient records",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.search, color: AppColors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.grey.withAlpha(50),
                      width: 0.3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.grey.withAlpha(50),
                      width: 0.3,
                    ),
                  ),
                  hintText: "Search Patients...",
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
                ),
              ),
              const SizedBox(height: 16),
              filteredPatientList.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: filteredPatientList.length,
                        itemBuilder: (context, index) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomPatientBubble(
                                patient: filteredPatientList[index],
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    )
                  : Expanded(
                      child: Center(
                        child: patientList.isNotEmpty
                            ? Text(
                                "No Patients found with '${searchController.text}'",
                                style: Theme.of(context).textTheme.bodyLarge,
                              )
                            : Text(
                                "No Patients Records Found",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomPatientBubble extends StatefulWidget {
  const CustomPatientBubble({super.key, required this.patient});

  final Patient patient;

  @override
  State<CustomPatientBubble> createState() => _CustomPatientBubbleState();
}

class _CustomPatientBubbleState extends State<CustomPatientBubble> {
  bool isTapped = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isTapped
              ? AppColors.primary.withAlpha(100)
              : AppColors.grey.withAlpha(50),
          width: 0.5,
        ),
      ),
      color: Colors.white,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: InkWell(
          splashColor: AppColors.primary.withAlpha(25),
          highlightColor: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() {
              isTapped = true;
            });

            try {
              var history = await getPatientHistory(
                patientId: widget.patient.patientId,
              );
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDataScreen(patientHistory: history),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Failed to fetch patient history. Please try again."),
                ),
              );
            } finally {
              if (mounted) {
                setState(() {
                  isTapped = false;
                });
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CustomNameInitial(name: widget.patient.name),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: RichText(
                          text: TextSpan(
                            text: widget.patient.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text:
                                    "\n${widget.patient.age} Yrs · ${widget.patient.gender ?? ""}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    isTapped
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: AppColors.grey,
                          ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GenderLabel(patient: widget.patient),
                    Expanded(child: SizedBox()),
                    Text(
                      DateFormat(
                        'd MMM yy',
                      ).format(parseServerDate(widget.patient.createdAt)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GenderLabel extends StatelessWidget {
  const GenderLabel({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    if (patient.gender == null) {
      return const SizedBox.shrink();
    }

    final Color primaryColor;
    final Color secondaryColor;

    switch (patient.gender) {
      case "Male":
        primaryColor = AppColors.primaryMale;
        secondaryColor = AppColors.secondaryMale;
        break;

      case "Female":
        primaryColor = AppColors.primaryFemale;
        secondaryColor = AppColors.secondaryFemale;
        break;

      default:
        primaryColor = AppColors.primaryOther;
        secondaryColor = AppColors.secondaryOther;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: primaryColor),
      ),
      child: Text(
        patient.gender!,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: primaryColor),
      ),
    );
  }
}
