import 'package:clinical_ai_app/Components/layout_constants.dart';
import '../../Custom Widgets/CustomAlertDialog.dart';
import 'package:clinical_ai_app/Screens/Consultation/analysis_screen.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Adjust these import paths to match your project structure.
import '../../Custom Widgets/custom_button.dart';
import '../../Services/Consultation/consultation_functions.dart';

/// "Review Your Responses" screen, wired to the real consultation API.
///
/// Fetches the Q&A log (and any clinical flags) via `getQaLog`, lets the
/// user edit any answer via `editAnswer`, and on "Continue to Analysis"
/// calls `finalizeConsultation` before handing off via [onContinue].
enum EditAnswerStatus {
  notEditing, editing, saving
}
class ReviewResponsesScreen extends StatefulWidget {
  const ReviewResponsesScreen({
    super.key,
    required this.token,
    required this.sessionId,
  });
  final String token;
  final String sessionId;
  static const routeName = "/review-responses";

  @override
  State<ReviewResponsesScreen> createState() => _ReviewResponsesScreenState();
}

class _ReviewResponsesScreenState extends State<ReviewResponsesScreen> {
  List<Map<String, dynamic>> flags = [];
  List<Map<String, dynamic>> qaLog = [];
  List<EditAnswerStatus> isEditingIds = [];
  bool loading = true;
  bool isEditing = false;
  Future<void> loadQaLog() async {
    try {
      final res = await getQaLog(
        token: widget.token,
        sessionId: widget.sessionId,
      );
      if (!mounted) return;
      setState(() {
        qaLog = res.qaLog;
        flags = res.flags;
        loading = false;
        isEditingIds = List.generate(qaLog.length, (index) => EditAnswerStatus.notEditing);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveEdit(String questionId, String answer, int index) async {
    setState(() {
      isEditingIds[index] = EditAnswerStatus.saving;
    });
    try {
      var res = await editAnswer(
        token: widget.token,
        sessionId: widget.sessionId,
        questionId: questionId,
        answer: answer,
      );
      if (res.ok) {
        setState(() {
          isEditingIds[index] = EditAnswerStatus.notEditing;
        });
        qaLog[index]['answer'] = answer;
      }
      else {
        if (!mounted) return;
        showCustomDialog("Edit Failed", context);
        setState(() {
          isEditingIds[index] = EditAnswerStatus.notEditing;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showCustomDialog("Connection error. Failed to save edit.", context);
      setState(() {
        isEditingIds[index] = EditAnswerStatus.notEditing;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    if (loading) loadQaLog();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Image.asset("assets/kuvaka_logo.png"),
        ),
        title: Text(
          "Review Responses",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.screenPadding,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Header(),
                    const SizedBox(height: AppLayout.space16),
                    if (flags.isNotEmpty) ClinicalAlerts(flags: flags),
                    const SizedBox(height: AppLayout.space16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppLayout.radius16),
                        border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(AppLayout.space16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: AppLayout.borderMedium,
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(
                            qaLog.length,
                            (index) => QaBlock(
                              qaLog: qaLog[index],
                              onEdit: () {
                                setState(() {
                                  isEditingIds[index] = EditAnswerStatus.editing;
                                });
                              },
                              isEditing: isEditingIds[index],
                              onSave: (String answer) async {
                                  await saveEdit(qaLog[index]["question_id"], answer, index);
                              },
                              onCancel: () {
                                setState(() {
                                  isEditingIds[index] = EditAnswerStatus.notEditing;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppLayout.space16),
                    CustomButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultationPipelineScreen(
                              sessionId: widget.sessionId,
                              accessToken: widget.token,
                            ),
                          ),
                        );
                      },
                      child: Text("Go to analysis"),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class QaBlock extends StatefulWidget {
  const QaBlock({
    super.key,
    required this.qaLog,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.isEditing,
  });

  final Map<String, dynamic> qaLog;
  final EditAnswerStatus isEditing;

  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Function(String answer) onSave;

  @override
  State<QaBlock> createState() => _QaBlockState();
}

class _QaBlockState extends State<QaBlock> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.qaLog["answer"]);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Q${widget.qaLog['question_id'].substring(5)}"),

            if (widget.isEditing == EditAnswerStatus.notEditing)
              InkWell(
                onTap: () {
                  controller.text = widget.qaLog["answer"];
                  widget.onEdit();
                },
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.pencil,
                      size: 12,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Edit",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: AppLayout.space8),

        /// Question
        Text(
          widget.qaLog["question_text"],
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: AppLayout.space8),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),

          child: widget.isEditing == EditAnswerStatus.editing || widget.isEditing == EditAnswerStatus.saving
              ? Column(
                  key: const ValueKey("editing"),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppLayout.radius10),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppLayout.space12),

                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            await widget.onSave(controller.text.trim());
                          },
                          icon:  widget.isEditing == EditAnswerStatus.editing? const Icon(Icons.check, size: 16) : const SizedBox( width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5,)),
                          label:  widget.isEditing == EditAnswerStatus.editing? const Text("Save") : const Text("Saving..."),
                        ),

                        const SizedBox(width: AppLayout.space8),

                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            controller.text =
                                widget.qaLog["answer"]; // revert text
                            widget.onCancel();
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                )
              : Container(
                  key: const ValueKey("view"),
                  padding: const EdgeInsets.only(left: AppLayout.space10, top: AppLayout.space4, bottom: AppLayout.space4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Theme.of(context).dividerColor, width: 3),
                    ),
                  ),
                  child: Text(
                    widget.qaLog["answer"],
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
        ),

        const SizedBox(height: AppLayout.space8),
      ],
    );
  }
}

class ClinicalAlerts extends StatelessWidget {
  const ClinicalAlerts({super.key, required this.flags});

  final List<Map<String, dynamic>> flags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: isDark ? AppColors.error.withAlpha(100) : AppColors.redFlagBorder, width: AppLayout.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: AppLayout.space8),
              Text(
                'Clinical Alerts',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space8),
          ...flags.map((flag) => FlagContainer(flag: flag)),
        ],
      ),
    );
  }
}

class FlagContainer extends StatelessWidget {
  const FlagContainer({super.key, required this.flag});
  final Map<String, dynamic> flag;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.space16),
      padding: const EdgeInsets.all(AppLayout.space10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radius8),
        border: Border(left: BorderSide(color: isDark ? Colors.white : AppColors.amber800, width: 5)),
        color: isDark ? Colors.black.withAlpha(40) : AppColors.warningContainer,
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.onErrorContainer,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: '🔴 '),
            TextSpan(
              text: '${flag['flag_type']}: ',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : AppColors.amber800,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: flag['description'],
              style: theme.textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white.withAlpha(200) : AppColors.amber800),
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.space24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor, width: AppLayout.borderThin),
      ),
      child: Column(
        children: [
          Container(
            width: AppLayout.space48,
            height: AppLayout.space48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(AppLayout.radius12),
            ),
            child: Icon(
              Icons.check_box_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: AppLayout.space12),
          Text(
            'Review Your Responses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppLayout.space6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Check what you shared. Tap '),
                TextSpan(
                  text: 'Edit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const TextSpan(
                  text:
                      ' on any answer to correct it before we generate your clinical notes.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
