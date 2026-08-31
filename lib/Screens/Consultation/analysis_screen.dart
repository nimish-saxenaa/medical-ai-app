import 'dart:async';

import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Models/complete_analysis_model.dart';
import 'package:flutter/material.dart';

import '../../Custom Widgets/Consultation/ai_speaking_orb.dart';
import '../../Services/Consultation/consultation_streaming.dart';
import '../../Services/Authentication/navigation_service.dart';
import '../../Components/colors.dart';
import 'final_screen.dart';

// Wire these up to your project's existing files:
// import 'package:clinical_ai_app/Screens/final_screen.dart';
// import 'package:clinical_ai_app/Services/navigation_service.dart';
// import '../Services/consultation_streaming.dart'; // provides consultationPipeline() + SseEvent

class ConsultationPipelineScreen extends StatefulWidget {
  final String sessionId;
  final String accessToken;

  const ConsultationPipelineScreen({
    super.key,
    required this.sessionId,
    required this.accessToken,
  });

  @override
  State<ConsultationPipelineScreen> createState() =>
      _ConsultationPipelineScreenState();
}

class _PipelineStep {
  final String id;
  final String title;
  String status; // 'pending' | 'running' | 'done'
  String? label;

  _PipelineStep({
    required this.id,
    required this.title,
    String? status,
    this.label,
  }) : status = status ?? 'pending';
}

class _ConsultationPipelineScreenState extends State<ConsultationPipelineScreen>
    with TickerProviderStateMixin {
  StreamSubscription<SseEvent>? _subscription;

  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  final List<_PipelineStep> _steps = [
    _PipelineStep(id: 'translate', title: 'Detecting language & translating'),
    _PipelineStep(id: 'completeness', title: 'Checking completeness'),
    _PipelineStep(id: 'summarize', title: 'Generating clinical note (SOAP)'),
    _PipelineStep(id: 'diagnose', title: 'Running AI diagnosis'),
  ];

  static Color brand = AppColors.brand; // indigo-500
  static Color brandLight = AppColors.brandHighlight; // indigo-50

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _subscription = consultationPipeline(
      sessionId: widget.sessionId,
      accessToken: widget.accessToken,
    ).listen(_onEvent);
  }

  void _onEvent(SseEvent event) {
    if (!mounted) return;

    if (event.event == 'step') {
      final step = event.data['step'];
      final status = event.data['status'];
      final label = event.data['label'];

      final index = _steps.indexWhere((e) => e.id == step);
      if (index != -1) {
        setState(() {
          _steps[index].status = status ?? _steps[index].status;
          _steps[index].label = label;
        });
      }
    }

    if (event.event == 'complete') {
      CompleteResponse response = CompleteResponse.fromJson(event.data);

      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => FinalScreen(
            token: widget.accessToken,
            sessionId: widget.sessionId,
            response: response,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
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
          "Analysis",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppLayout.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppLayout.space24),
                AIOrb(state: TextToSpeechState.active),
                const SizedBox(height: AppLayout.space28),
                _buildHeader(),
                const SizedBox(height: AppLayout.space32),
                _buildStepsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Analysing your responses…',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppLayout.space4),
        Text(
          'This takes 15–30 seconds. Please wait.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------- Steps list ----------------

  Widget _buildStepsList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            _buildStepCard(_steps[i]),
            if (i != _steps.length - 1) const SizedBox(height: AppLayout.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard(_PipelineStep step) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    late Color bg;
    late Color border;
    late Color iconBg;
    late Color textColor;
    FontWeight fontWeight = FontWeight.w500;

    switch (step.status) {
      case 'done':
        bg = isDark ? AppColors.success.withAlpha(40) : AppColors.stepSuccessBg;
        border = isDark ? AppColors.success.withAlpha(100) : AppColors.stepSuccessBorder;
        iconBg = AppColors.success;
        textColor = isDark ? Colors.white : AppColors.stepSuccessText;
        break;
      case 'running':
        bg = isDark ? theme.colorScheme.primary.withAlpha(40) : brandLight;
        border = isDark ? theme.colorScheme.primary.withAlpha(100) : brand.withOpacity(0.3);
        iconBg = brand;
        textColor = isDark ? Colors.white : brand;
        fontWeight = FontWeight.w600;
        break;
      default:
        bg = isDark ? theme.dividerColor.withAlpha(40) : theme.colorScheme.surface;
        border = isDark ? theme.dividerColor : theme.dividerColor;
        iconBg = isDark ? theme.dividerColor : AppColors.outline;
        textColor = theme.textTheme.bodyMedium?.color ?? AppColors.textDisabled;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        border: Border.all(color: border, width: AppLayout.borderMedium),
        boxShadow: step.status == 'running'
            ? [
                BoxShadow(
                  color: AppColors.textPrimary.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _buildStepIcon(step, iconBg),
          const SizedBox(width: AppLayout.space16),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 14,
                fontWeight: fontWeight,
                color: textColor,
              ),
              child: Text(step.label ?? step.title),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(_PipelineStep step, Color iconBg) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: AppLayout.iconExtraLarge,
      height: AppLayout.iconExtraLarge,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(AppLayout.radius8),
      ),
      alignment: Alignment.center,
      child: step.status == 'done'
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : step.status == 'running'
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.circle_outlined, color: Colors.white, size: 18),
    );
  }
}

/// Small pulsing green "live" dot in the corner of the orb.
class _StatusDot extends StatefulWidget {
  const _StatusDot();

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success, // green-400
              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
