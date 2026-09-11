import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Components/colors.dart';
import '../../Components/layout_constants.dart';
import '../../Custom%20Widgets/Patients/cabin_diagnosis_card.dart';
import '../../Custom%20Widgets/Patients/custom_name_initial.dart';
import '../../Custom%20Widgets/Patients/diagnosis_card.dart';
import '../../Custom%20Widgets/custom_confirmation_alert.dart';
import '../../Custom%20Widgets/custom_refresh_indicator.dart';
import '../../Models/consultation_location_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Models/session_model.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Cabin/cabin_service.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Services/Location/location_service.dart';
import '../../Services/PDF/pdf_generator.dart';
import '../../Services/PatientData/patient_service.dart';
import '../../functions.dart';
import '../Consultation/new_cabin_consultation_screen.dart';
import '../Consultation/new_consultation_screen.dart';
import 'package:open_file/open_file.dart';

class PatientHistoryIconText extends StatelessWidget {
  const PatientHistoryIconText({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: AppLayout.iconSmall - 2),
        const SizedBox(width: AppLayout.space8),
        Text(text),
      ],
    );
  }
}

class PatientHistoryEmptyState extends StatelessWidget {
  const PatientHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.space48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(
          color: theme.dividerColor,
          width: AppLayout.borderThick,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppLayout.space48,
            height: AppLayout.space48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(AppLayout.radius16),
            ),
            child: Icon(
              LucideIcons.stethoscope,
              size: AppLayout.iconMedium,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppLayout.space16),
          Text(
            'No consultations yet',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppLayout.space4),
          Text(
            'Start the first one using the button below.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class PatientClinicalHistoryView extends StatefulWidget {
  final PatientHistoryResponse patientHistory;
  final VoidCallback? onHistoryUpdated;

  const PatientClinicalHistoryView({
    super.key,
    required this.patientHistory,
    this.onHistoryUpdated,
  });

  @override
  State<PatientClinicalHistoryView> createState() => _PatientClinicalHistoryViewState();
}

class _PatientClinicalHistoryViewState extends State<PatientClinicalHistoryView> {
  late PatientHistoryResponse history;
  bool isDownloading = false;
  String? downloadingSessionId;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Set<String> _selectedSessionIds = {};
  final Set<String> _selectedCabinIds = {};
  bool _isBulkDeleting = false;

  Map<String, ConsultationLocation> sessionLocations = {};

  @override
  void initState() {
    super.initState();
    history = widget.patientHistory;
    _loadSessionLocations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PatientClinicalHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientHistory != oldWidget.patientHistory) {
      setState(() {
        history = widget.patientHistory;
      });
      _loadSessionLocations();
    }
  }

  Future<void> _loadSessionLocations() async {
    final locations = await ConsultationLocationService.getForSessions(
      history.sessions.map((s) => s.sessionId).toList(),
    );
    if (!mounted) return;
    setState(() {
      sessionLocations = locations;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: AppColors.surface, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshHistory() async {
    try {
      final newHistory = await getPatientHistory(patientId: history.patient.patientId);
      if (!mounted) return;
      setState(() {
        history = newHistory;
      });
      _loadSessionLocations();
      widget.onHistoryUpdated?.call();
    } catch (_) {
      // Ignored: silent refresh failure
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    showCustomConfirmationAlert(
      detail: "Do you want to delete this consultation?",
      context: context,
      loadingText: "Deleting...",
      onPressed: () async {
        try {
          String? token = await AccessTokenService.getToken();
          if (token == null) return;
          setState(() {
            history.sessions.removeWhere((s) => s.sessionId == sessionId);
          });
          await deleteConsultation(token: token, sessionId: sessionId);
          await ConsultationLocationService.removeForSession(sessionId);
          _showMessage('Consultation deleted successfully');
          _refreshHistory();
        } catch (e) {
          _showMessage('Failed to delete consultation', isError: true);
          _refreshHistory();
        }
      },
    );
  }

  Future<void> _deleteCabinSession(String sessionId) async {
    showCustomConfirmationAlert(
      detail: "Do you want to delete this cabin consultation?",
      context: context,
      loadingText: "Deleting...",
      onPressed: () async {
        try {
          setState(() {
            history.cabinSessions.removeWhere((s) => s.sessionId == sessionId);
            _selectedCabinIds.remove(sessionId);
          });
          await deleteCabinSession(sessionId);
          _showMessage('Cabin consultation deleted successfully');
          _refreshHistory();
        } catch (e) {
          _showMessage('Failed to delete cabin consultation', isError: true);
          _refreshHistory();
        }
      },
    );
  }

  Future<void> _deleteSelectedSessions() async {
    final totalSelected = _selectedSessionIds.length + _selectedCabinIds.length;
    if (totalSelected == 0) return;

    showCustomConfirmationAlert(
      detail: "Delete $totalSelected selected sessions?",
      context: context,
      loadingText: "Deleting...",
      onPressed: () async {
        setState(() => _isBulkDeleting = true);

        final sessionIdsToDelete = List.from(_selectedSessionIds);
        final cabinIdsToDelete = List.from(_selectedCabinIds);
        
        try {
          setState(() {
            history.sessions.removeWhere((s) => sessionIdsToDelete.contains(s.sessionId));
            history.cabinSessions.removeWhere((s) => cabinIdsToDelete.contains(s.sessionId));
            _selectedSessionIds.clear();
            _selectedCabinIds.clear();
          });

          String? token = await AccessTokenService.getToken();
          for (final id in sessionIdsToDelete) {
            if (token != null) await deleteConsultation(token: token, sessionId: id);
            await ConsultationLocationService.removeForSession(id);
          }
          for (final id in cabinIdsToDelete) {
            await deleteCabinSession(id);
          }

          _showMessage('$totalSelected sessions deleted successfully');
          _refreshHistory();
        } catch (e) {
          _showMessage('Error during bulk deletion', isError: true);
          _refreshHistory();
        } finally {
          if (mounted) setState(() => _isBulkDeleting = false);
        }
      },
    );
  }

  void _toggleSessionSelection(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  void _toggleCabinSelection(String sessionId) {
    setState(() {
      if (_selectedCabinIds.contains(sessionId)) {
        _selectedCabinIds.remove(sessionId);
      } else {
        _selectedCabinIds.add(sessionId);
      }
    });
  }

  Future<void> downloadConsultationReport(Session consultation) async {
    setState(() {
      isDownloading = true;
      downloadingSessionId = consultation.sessionId;
    });

    try {
      final pdfFile = await PatientPdfGenerator.generateConsultationReport(
        consultation: consultation,
        patient: history.patient,
        location: sessionLocations[consultation.sessionId],
      );
      setState(() {
        isDownloading = false;
        downloadingSessionId = null;
      });
      _showPdfSavedNotification(pdfFile.path);
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadingSessionId = null;
      });
      _showMessage('Error generating consultation PDF: $e', isError: true);
    }
  }

  void _showPdfSavedNotification(String filePath) {
    if (!mounted) return;
    final fileName = filePath.split('/').last;
    final savedIn = filePath.contains('/storage/emulated/0/Download') ? 'Downloads folder' : 'App storage';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.surface, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('PDF saved', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 4),
            Text(fileName, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text('Saved to: $savedIn', style: const TextStyle(fontSize: 10, color: AppColors.surface)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: AppColors.surface,
          onPressed: () => OpenFile.open(filePath),
        ),
      ),
    );
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
                  color: AppColors.brandHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.stethoscope, color: AppColors.brand, size: 20),
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
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.monitor, color: AppColors.warning, size: 20),
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

  Widget _buildPageIndicator(int index, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isActive = _currentPage == index;
    
    final activeBg = theme.colorScheme.primary;
    final activeFg = theme.colorScheme.onPrimary;
    
    final inactiveFg = theme.colorScheme.onSurface;
    final inactiveBg = theme.colorScheme.surface;
    final borderColor = isActive 
        ? activeBg 
        : (isDark ? Colors.white.withAlpha(60) : theme.dividerColor);

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: AppLayout.space4 + 2),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(AppLayout.radius20),
          border: Border.all(
            color: borderColor,
            width: AppLayout.borderThin + 0.25,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppLayout.iconSmall,
              color: isActive ? activeFg : inactiveFg,
            ),
            const SizedBox(width: AppLayout.space8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeFg : inactiveFg,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationHistoryPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: "Consultation History  ",
              style: Theme.of(context).textTheme.displaySmall,
              children: [
                TextSpan(
                  text: "${history.sessions.length}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),
          Expanded(
            child: CustomPullToRefresh(
              onRefresh: _refreshHistory,
              child: history.sessions.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: history.sessions.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppLayout.space16),
                        child: DiagnosisCard(
                          key: ValueKey(history.sessions[index].sessionId),
                          index: index,
                          patientHistory: history,
                          isSelected: _selectedSessionIds.contains(history.sessions[index].sessionId),
                          selectionModeActive: _selectedSessionIds.isNotEmpty || _selectedCabinIds.isNotEmpty,
                          onSelect: () => _toggleSessionSelection(history.sessions[index].sessionId),
                          isDownloading: downloadingSessionId == history.sessions[index].sessionId,
                          onDelete: () => _deleteSession(history.sessions[index].sessionId),
                          onDownload: (session) => downloadConsultationReport(session),
                          title: getSpecialtyName(history.sessions[index].specialty ?? ""),
                          status: getDiagnosisStatus(history.sessions[index].currentStage ?? ""),
                          date: parseServerDate(history.sessions[index].createdAt),
                          description: history.sessions[index].chiefComplaint ?? "",
                          location: sessionLocations[history.sessions[index].sessionId]?.fullLocation,
                          redFlags: history.sessions[index].diagnosis?.urgentConcerns ?? [],
                          diagnoses: List.generate(
                            (history.sessions[index].diagnosis?.differentialDiagnoses.length ?? 0) > 3
                                ? 3
                                : history.sessions[index].diagnosis?.differentialDiagnoses.length ?? 0,
                            (diffDia) => DiagnosisItem(
                              severity: history.sessions[index].diagnosis?.differentialDiagnoses[diffDia].likelihood ?? "",
                              name: history.sessions[index].diagnosis?.differentialDiagnoses[diffDia].condition ?? "",
                              code: history.sessions[index].diagnosis?.differentialDiagnoses[diffDia].icdCode ?? "",
                            ),
                          ),
                          workup: "Workup: ${history.sessions[index].diagnosis?.suggestedWorkup.take(2).join("\n") ?? ""} + ${history.sessions[index].diagnosis?.suggestedWorkup.length ?? 2 - 2} more",
                          subjective: [
                            SoapField(
                              label: 'Chief complaint',
                              value: history.sessions[index].chiefComplaint ?? history.sessions[index].summary.subjective.chiefComplaint,
                            ),
                            SoapField(label: 'HPI', value: history.sessions[index].summary.subjective.historyOfPresentingIllness),
                            SoapField(label: 'Past medical history', value: history.sessions[index].summary.subjective.pastMedicalHistory),
                            SoapField(label: 'Surgical history', value: history.sessions[index].summary.subjective.surgicalHistory),
                            SoapField(label: 'Medications', value: history.sessions[index].summary.subjective.medications),
                            SoapField(label: 'Allergies', value: history.sessions[index].summary.subjective.allergies),
                            SoapField(label: 'Family history', value: history.sessions[index].summary.subjective.familyHistory),
                            SoapField(label: 'Social history', value: history.sessions[index].summary.subjective.socialHistory),
                            SoapField(label: 'Review of systems', value: history.sessions[index].summary.subjective.reviewOfSystems),
                          ],
                          objective: [
                            SoapField(label: 'Vital signs', value: history.sessions[index].summary.objective.vitalSigns),
                            SoapField(label: 'Physical exam', value: history.sessions[index].summary.objective.physicalExamination),
                          ],
                          show: history.sessions[index].diagnosis != null ? true : false,
                        ),
                      ),
                    )
                  : const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: PatientHistoryEmptyState(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinHistoryPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: "Cabin Sessions  ",
              style: Theme.of(context).textTheme.displaySmall,
              children: [
                TextSpan(
                  text: "${history.cabinSessions.length}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space16),
          Expanded(
            child: CustomPullToRefresh(
              onRefresh: _refreshHistory,
              child: history.cabinSessions.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: history.cabinSessions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppLayout.space16),
                          child: CabinDiagnosisCard(
                            key: ValueKey(history.cabinSessions[index].sessionId),
                            session: history.cabinSessions[index],
                            index: index,
                            isSelected: _selectedCabinIds.contains(history.cabinSessions[index].sessionId),
                            selectionModeActive: _selectedSessionIds.isNotEmpty || _selectedCabinIds.isNotEmpty,
                            onSelect: () => _toggleCabinSelection(history.cabinSessions[index].sessionId),
                            onDelete: () => _deleteCabinSession(history.cabinSessions[index].sessionId),
                          ),
                        );
                      },
                    )
                  : const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: PatientHistoryEmptyState(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppLayout.space16),
                child: Material(
                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomNameInitial(name: history.patient.name, size: 60),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppLayout.space8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(history.patient.name,style: theme.textTheme.headlineMedium,maxLines: 2,
                                  overflow: TextOverflow.ellipsis,),
                                Text("${history.patient.age} Yrs · ${history.patient.gender ?? ""}", style: theme.textTheme.bodyMedium,),
                                const SizedBox(height: AppLayout.space8),
                                Wrap(
                                  spacing: AppLayout.space8,
                                  children: [
                                    PatientHistoryIconText(
                                      icon: LucideIcons.calendar,
                                      text: DateFormat('d MMM yy').format(
                                        parseServerDate(history.patient.createdAt),
                                      ),
                                    ),
                                    PatientHistoryIconText(
                                      icon: LucideIcons.stethoscope,
                                      text: '${history.sessions.length + history.cabinSessions.length} Sessions',
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
                ),
              ),
              const SizedBox(height: AppLayout.space16),

              // Page Selector or Selection Bar
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: (_selectedSessionIds.isNotEmpty || _selectedCabinIds.isNotEmpty)
                          ? Container(
                              key: const ValueKey('selection_bar'),
                              padding: const EdgeInsets.symmetric(horizontal: AppLayout.space12, vertical: AppLayout.space8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(AppLayout.radius20),
                                border: Border.all(color: theme.colorScheme.primary, width: AppLayout.borderThin + 0.25),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => setState(() {
                                      _selectedSessionIds.clear();
                                      _selectedCabinIds.clear();
                                    }),
                                    child: Icon(Icons.close, size: AppLayout.iconSmall, color: theme.colorScheme.onSurface),
                                  ),
                                  const SizedBox(width: AppLayout.space8),
                                  Text(
                                    "${_selectedSessionIds.length + _selectedCabinIds.length} Selected",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: AppLayout.space16),
                                  if (_isBulkDeleting)
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: AppLayout.borderThick))
                                  else
                                    InkWell(
                                      onTap: _deleteSelectedSessions,
                                      child: const Icon(LucideIcons.trash2, color: AppColors.error, size: AppLayout.iconSmall),
                                    ),
                                ],
                              ),
                            )
                          : Row(
                                key: const ValueKey('page_selector'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPageIndicator(0, "History", LucideIcons.history),
                                  const SizedBox(width: AppLayout.space16),
                                  _buildPageIndicator(1, "Cabin", LucideIcons.monitor),
                                  if (MediaQuery.of(context).size.width > 800) ...[
                                    const SizedBox(width: AppLayout.space16),
                                    InkWell(
                                      onTap: _showConsultationTypeDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(AppLayout.space8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: AppLayout.iconSmall),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayout.space16),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildConsultationHistoryPage(),
                    _buildCabinHistoryPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
