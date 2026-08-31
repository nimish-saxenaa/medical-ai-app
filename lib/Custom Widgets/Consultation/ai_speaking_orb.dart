import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import '../../Components/colors.dart';

enum TextToSpeechState {
  idle,
  loading,
  active,
}

class AIOrb extends StatefulWidget {
  const AIOrb({
    super.key,
    required this.state,
    this.size = 115,
    this.icon = "⚕️",
  });

  final TextToSpeechState state;
  final double size;
  final String icon;
  static const routeName = "/ai-orb";

  @override
  State<AIOrb> createState() => _AIOrbState();
}

class _AIOrbState extends State<AIOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late Animation<double> ring1;
  late Animation<double> ring2;



  @override
  void initState() {
    super.initState();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    ring1 = Tween(
      begin: 1.0,
      end: 1.75,
    ).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 1.0),
      ),
    );

    ring2 = Tween(
      begin: 0.65,
      end: 1.75,
    ).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 1.0),
      ),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Color get _indicatorColor {
    switch (widget.state) {
      case TextToSpeechState.active:
        return AppColors.success;
      case TextToSpeechState.loading:
        return AppColors.warning;
      case TextToSpeechState.idle:
        return AppColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Padding(
      padding: const EdgeInsets.only(top: AppLayout.space40),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breatheController,
            _pulseController,
          ]),
          builder: (_, _) {
            final breathe =
                1 + (_breatheController.value * 0.075);

            final pulse =
                1 + (_pulseController.value * 0.075);

            final loading = 1 + (_pulseController.value * 0.075);

            final orbScale = widget.state == TextToSpeechState.idle
                ? breathe
                : widget.state == TextToSpeechState.loading
                ? loading
                : pulse;

            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Speaking glow rings
                  if (widget.state == TextToSpeechState.active) ...[
                    _GlowRing(
                      size: size,
                      opacity: (180 * (1 - _ringController.value)).round(),
                      scale: ring1.value, width: 1.5,
                    ),
                    _GlowRing(
                      size: size,
                      opacity: (180 * (1 - _ringController.value)).round(),
                      scale: ring2.value, width: 3,
                    ),
                  ],

                  Transform.scale(
                    scale: orbScale,
                    child: Stack(
                      alignment: AlignmentGeometry.center,
                      children: [
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withAlpha(50),
                                blurRadius: 28,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppLayout.radiusCircular),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: size, height: size*2/3, color: Theme.of(context).colorScheme.surface),
                                  Container(width: size, height: size*1/3, color: Theme.of(context).dividerColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text("⚕️", style: TextStyle(fontSize: size*0.36),)
                      ],
                    ),
                  ),
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Transform.scale(
                      scale: widget.state == TextToSpeechState.idle
                          ? 1
                          : pulse,
                      child: Container(
                        width: size * .13,
                        height: size * .13,
                        decoration: BoxDecoration(
                          color: _indicatorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: AppLayout.borderThick,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _indicatorColor.withAlpha(150),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

  }
}
/*

 */

class _GlowRing extends StatelessWidget {
  const _GlowRing({
    required this.size,
    required this.opacity,
    required this.scale, required this.width,
  });

  final double size;
  final int opacity;
  final double scale;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.vizAccent3.withAlpha(opacity),
              width: width
          ),
        ),
      ),
    );
  }
}