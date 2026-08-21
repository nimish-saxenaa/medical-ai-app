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
          ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: loading
              ? CircularProgressIndicator()
              : Column(
                  children: [
                    Header(),
                    const SizedBox(height: 16),
                    if (flags.isNotEmpty) ClinicalAlerts(flags: flags),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.greyLight,
                              width: 5,
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
                    const SizedBox(height: 16),
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
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Edit",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        /// Question
        Text(
          widget.qaLog["question_text"],
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 8),

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
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            await widget.onSave(controller.text.trim());
                          },
                          icon:  widget.isEditing == EditAnswerStatus.editing? const Icon(Icons.check, size: 16) : const SizedBox( width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 1.5,)),
                          label:  widget.isEditing == EditAnswerStatus.editing? Text("Save") : Text("Saving..."),
                        ),

                        const SizedBox(width: 8),

                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                          onPressed: () {
                            controller.text =
                                widget.qaLog["answer"]; // revert text
                            widget.onCancel();
                          },
                          icon: const Icon(Icons.close, size: 16, color: AppColors.black),
                          label: const Text("Cancel", style: TextStyle(color: AppColors.black)),
                        ),
                      ],
                    ),
                  ],
                )
              : Container(
                  key: const ValueKey("view"),
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.grey, width: 3),
                    ),
                  ),
                  child: Text(
                    widget.qaLog["answer"],
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.greyDark),
                  ),
                ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

class ClinicalAlerts extends StatelessWidget {
  const ClinicalAlerts({super.key, required this.flags});

  final List<Map<String, dynamic>> flags;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redFlagBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.redFlagBorder),
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
              const SizedBox(width: 8),
              Text(
                'Clinical Alerts',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redFlagText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppColors.amber800, width: 5)),
        color: AppColors.warningBg,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.redFlagText,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: '🔴 '),
            TextSpan(
              text: '${flag['flag_type']}: ',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.amber800,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: flag['description'],
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.amber800),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_box_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Review Your Responses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Check what you shared. Tap '),
                TextSpan(
                  text: 'Edit',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyDark,
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
