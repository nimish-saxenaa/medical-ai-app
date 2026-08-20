import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Components/colors.dart';
import '../../Custom Widgets/Patients/custom_name_initial.dart';
import '../../Custom Widgets/Patients/new_patient_form.dart';
import '../../Custom Widgets/custom_confirmation_alert.dart';
import '../../functions.dart';
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Authentication/navigation_service.dart';
import '../../Services/PatientData/patient_service.dart';
import 'patient_data_screen.dart';
import 'patient_history_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  Patient? _selectedPatient;
  PatientHistoryResponse? _selectedHistory;
  bool _isLoadingHistory = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _handlePatientSelection(Patient patient, bool isTablet) async {
    if (!isTablet) {
      // Phone behavior: Show loader on card then navigate
      setState(() {
        _selectedPatient = patient;
        _isLoadingHistory = true;
      });
      try {
        var history = await getPatientHistory(patientId: patient.patientId);
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDataScreen(patientHistory: history),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch patient history.")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _selectedPatient = null;
          });
        }
      }
    } else {
      // Tablet behavior: Update right panel state
      if (_selectedPatient?.patientId == patient.patientId) return;

      setState(() {
        _selectedPatient = patient;
        _isLoadingHistory = true;
        _selectedHistory = null;
      });

      try {
        var history = await getPatientHistory(patientId: patient.patientId);
        if (!mounted) return;
        setState(() {
          _selectedHistory = history;
          _isLoadingHistory = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch patient history.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsProvider = context.watch<PatientListProvider>();
    final List<Patient> patientList = patientsProvider.patients ?? [];
    List<Patient> filteredPatientList = patientList
        .where(
          (patient) => patient.name.toLowerCase().contains(
                searchController.text.trim().toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNewPatientDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isTablet = constraints.maxWidth > 800;

          if (isTablet) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // 1/3 Master Panel
                  Expanded(
                    flex: 1,
                    child: _buildFloatingPanel(
                      backgroundColor: AppColors.greyLight,
                      child: _buildPatientList(filteredPatientList, patientList, isTablet),
                    ),
                  ),
                  const SizedBox(width: 24), // Space between panels
                  // 2/3 Detail Panel
                  Expanded(
                    flex: 2,
                    child: _buildFloatingPanel(
                      backgroundColor: AppColors.greyLight,
                      child: Stack(
                        children: [
                          _buildDetailContent(),
                          if (_selectedHistory != null || _isLoadingHistory)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.white.withAlpha(200),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPatient = null;
                                      _selectedHistory = null;
                                      _isLoadingHistory = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close, size: 20, color: AppColors.greyDark),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile View
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPatientList(filteredPatientList, patientList, isTablet),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Image.asset("assets/kuvaka_logo.png"),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            showCustomConfirmationAlert(
              detail: "Do you want to Logout?",
              context: context,
              onPressed: () async {
                await AccessTokenService.clear();
                logout();
              },
            );
          },
          icon: const Icon(LucideIcons.logOut, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildFloatingPanel({required Widget child, Color backgroundColor = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildPatientList(List<Patient> filtered, List<Patient> full, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: isTablet ? const EdgeInsets.all(24.0) : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "Patients  ",
                  style: Theme.of(context).textTheme.headlineLarge,
                  children: [
                    TextSpan(
                      text: "${full.length}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Manage your patient records",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  fillColor: AppColors.greyLight,
                  filled: true,
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Search...",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isNotEmpty
              ? ListView.builder(
                  padding: isTablet ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final patient = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomPatientBubble(
                        patient: patient,
                        isSelected: isTablet && _selectedPatient?.patientId == patient.patientId,
                        isLoading: !isTablet && _isLoadingHistory && _selectedPatient?.patientId == patient.patientId,
                        onTap: () => _handlePatientSelection(patient, isTablet),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    full.isNotEmpty ? "No results found" : "No patient records",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailContent() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedHistory == null) {
      return const SizedBox.expand(); // Blank black space if background is black
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: PatientClinicalHistoryView(
        key: ValueKey(_selectedHistory!.patient.patientId),
        patientHistory: _selectedHistory!,
      ),
    );
  }
}

class CustomPatientBubble extends StatelessWidget {
  const CustomPatientBubble({
    super.key,
    required this.patient,
    this.isSelected = false,
    this.isLoading = false,
    required this.onTap,
  });

  final Patient patient;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey.withAlpha(50),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CustomNameInitial(name: patient.name),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: RichText(
                        text: TextSpan(
                          text: patient.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: "\n${patient.age} Yrs · ${patient.gender ?? ""}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: isSelected ? AppColors.primary : AppColors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (patient.gender != null)
                    GenderLabel(gender: GenderExtension.fromString(patient.gender)),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM yy').format(parseServerDate(patient.createdAt)),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenderLabel extends StatelessWidget {
  const GenderLabel({super.key, required this.gender});

  final Gender gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: gender.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: gender.primaryColor),
      ),
      child: Text(
        gender.label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: gender.primaryColor),
      ),
    );
  }
}
