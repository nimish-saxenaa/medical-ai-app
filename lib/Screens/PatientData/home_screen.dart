import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Components/layout_constants.dart';
import '../../Custom Widgets/Patients/custom_name_initial.dart';
import '../../Custom Widgets/Patients/new_patient_form.dart';
import '../../Custom Widgets/custom_confirmation_alert.dart';
import '../../Custom Widgets/custom_refresh_indicator.dart';
import '../../functions.dart';
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Custom Widgets/home_skeleton.dart';
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
  late bool _isInitialLoading;
  String? _userName;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PatientListProvider>();
    _isInitialLoading = provider.patients == null;
    _loadInitialData();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final name = await AccessTokenService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<PatientListProvider>();
    if (provider.patients == null) {
      try {
        final list = await listPatients();
        provider.setPatients(list.patients!);
      } finally {
        if (mounted) setState(() => _isInitialLoading = false);
      }
    }
  }

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
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDataScreen(patientHistory: history),
          ),
        );
      } catch (e) {
        if (!mounted) return;
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

  Future<void> _refreshPatients() async {
    final provider = context.read<PatientListProvider>();
    try {
      final list = await listPatients();
      provider.setPatients(list.patients!);
    } catch (_) {
      // Ignored: silent refresh failure
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
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNewPatientDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: _isInitialLoading 
          ? const HomeSkeleton()
          : LayoutBuilder(
              builder: (context, constraints) {
          bool isTablet = constraints.maxWidth > 800;

          if (isTablet) {
            return Padding(
              padding: AppLayout.screenPaddingTab,
              child: Row(
                children: [
                  // 1/3 Master Panel (List)
                  Expanded(
                    flex: 1,
                    child: _buildFloatingPanel(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: _buildPatientList(filteredPatientList, patientList, isTablet),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space24), // Space between panels
                  // 2/3 Detail Panel
                  Expanded(
                    flex: 2,
                    child: _buildFloatingPanel(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: Stack(
                        children: [
                          _buildDetailContent(),
                          if (_selectedHistory != null || _isLoadingHistory)
                            Positioned(
                              top: AppLayout.space12,
                              right: AppLayout.space12,
                              child: Material(
                                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPatient = null;
                                      _selectedHistory = null;
                                      _isLoadingHistory = false;
                                    });
                                  },
                                  icon: Icon(Icons.close, size: AppLayout.iconMedium, color: Theme.of(context).colorScheme.onSurface),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(AppLayout.space8),
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
            padding: AppLayout.screenPadding,
            child: _buildPatientList(filteredPatientList, patientList, isTablet),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: AppLayout.space16),
        child: Image.asset("assets/kuvaka_logo.png"),
      ),
      actions: [
        if (_userName != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppLayout.space8),
              child: Text(
                "Logged in: $_userName",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,

                      fontStyle: FontStyle.italic
                    ),
              ),
            ),
          ),
        IconButton(
          onPressed: () async {
            showCustomConfirmationAlert(
              detail: "Do you want to Logout?",
              confirmText: "Logout",
              loadingText: "Logging out...",
              context: context,
              onPressed: () async {
                await AccessTokenService.clear();
                logout();
              },
            );
          },
          icon: Icon(LucideIcons.logOut, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildFloatingPanel({required Widget child, Color? backgroundColor}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.panelRadius),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primaryContainer.withAlpha(theme.brightness == Brightness.light ? 150 : 50),
            blurRadius: 20,
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
          padding: isTablet ? const EdgeInsets.all(AppLayout.space24) : EdgeInsets.zero,
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
              const SizedBox(height: AppLayout.space8),
              Text(
                "Manage your patient records",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
              ),
              const SizedBox(height: AppLayout.space16),
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppLayout.inputRadius),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Search...",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.space16),
        Expanded(
          child: CustomPullToRefresh(
            onRefresh: _refreshPatients,
            child: filtered.isNotEmpty
                ? ListView.builder(
                    padding: EdgeInsets.only(
                      left: isTablet ? AppLayout.space16 : 0,
                      right: isTablet ? AppLayout.space16 : 0,
                      bottom: 100, // Extra space at bottom to avoid FAB overlap
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppLayout.space12),
                        child: CustomPatientBubble(
                          patient: patient,
                          isSelected: isTablet && _selectedPatient?.patientId == patient.patientId,
                          isLoading: !isTablet && _isLoadingHistory && _selectedPatient?.patientId == patient.patientId,
                          onTap: () => _handlePatientSelection(patient, isTablet),
                        ),
                      );
                    },
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Text(
                          full.isNotEmpty ? "No results found" : "No patient records",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
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
      padding: const EdgeInsets.all(AppLayout.space24),
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
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      child: InkWell(
        onTap: isLoading==false? onTap: null,
        splashColor: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.cardRadius),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? AppLayout.borderThick - AppLayout.borderThin : AppLayout.borderThin,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CustomNameInitial(name: toTitleCase(patient.name)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppLayout.space8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(toTitleCase(patient.name),style: theme.textTheme.bodyLarge,maxLines: 1,
                        overflow: TextOverflow.ellipsis,),
                          Text("${patient.age} Yrs · ${patient.gender ?? ""}", style: theme.textTheme.bodyMedium,)
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: AppLayout.borderThick,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                ],
              ),
              const SizedBox(height: AppLayout.space12),
              Row(
                children: [
                  if (patient.gender != null)
                    GenderLabel(gender: GenderExtension.fromString(patient.gender)),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM yy').format(parseServerDate(patient.createdAt)),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = gender.primaryColor;
    // Adjust colors for dark mode to maintain legibility
    final background = isDark ? primary.withAlpha(40) : gender.secondaryColor;
    final borderColor = isDark ? primary.withAlpha(100) : primary;
    final textColor = isDark ? Color.lerp(primary, Colors.white, 0.4) : primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: borderColor),
      ),
      child: Text(
        gender.label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontSize: 12,
            ),
      ),
    );
  }
}