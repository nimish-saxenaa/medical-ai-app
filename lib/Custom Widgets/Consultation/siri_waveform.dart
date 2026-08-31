import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../Components/colors.dart';
import 'ai_speaking_orb.dart';

class SiriWaveform extends StatefulWidget {
  const SiriWaveform({super.key, required this.state});

  final TextToSpeechState state;

  @override
  State<SiriWaveform> createState() => _SiriWaveformState();
}

class _SiriWaveformState extends State<SiriWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _speed = 0.4;
  double _opacityMultiplier = 0.35;

  /// Continuous wave phase.
  double _phase = 0;

  Duration? _lastElapsed;

  // Current amplitudes (smooth interpolation)
  final List<double> _amps = [2, 1.5, 2.5];

  static const List<double> _activeAmp = [18, 12, 22];
  static const List<double> _idleAmp = [2, 1.5, 2.5];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final isSpeaking = widget.state == TextToSpeechState.active;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final targetAmp = isSpeaking ? _activeAmp : _idleAmp;

        final targetSpeed = isSpeaking ? 2.4 : 1.5;
        _speed += (targetSpeed - _speed) * 0.06;

        final targetOpacity = isSpeaking ? 1.0 : 0.35;
        _opacityMultiplier +=
            (targetOpacity - _opacityMultiplier) * 0.06;

        for (int i = 0; i < _amps.length; i++) {
          _amps[i] += (targetAmp[i] - _amps[i]) * 0.06;
        }

        final elapsed = _controller.lastElapsedDuration;

        if (elapsed != null) {
          if (_lastElapsed != null) {
            final dt =
                (elapsed - _lastElapsed!).inMicroseconds / 1e6;

            // Advance phase using current speed.
            _phase += dt * _speed;
          }

          _lastElapsed = elapsed;
        }

        return CustomPaint(
          size: const Size(280, 56),
          painter: _WavePainter(
            phase: _phase,
            amplitudes: _amps,
            opacityMultiplier: _opacityMultiplier,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.phase,
    required this.amplitudes,
    required this.opacityMultiplier,
  });

  final double phase;
  final List<double> amplitudes;
  final double opacityMultiplier;

  static final List<_WaveData> _waves = [
    _WaveData(
      color: AppColors.vizAccent1,
      alpha: 0.9,
      phase: 0,
      frequency: 1.2,
    ),
    _WaveData(
      color: AppColors.vizAccent2,
      alpha: 0.65,
      phase: math.pi / 2.5,
      frequency: 2.1,
    ),
    _WaveData(
      color: AppColors.vizAccent3,
      alpha: 0.5,
      phase: math.pi * 0.7,
      frequency: 0.85,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    for (int i = 0; i < _waves.length; i++) {
      final wave = _waves[i];

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color =
        wave.color.withOpacity(wave.alpha * opacityMultiplier);

      final path = Path();

      for (double x = 0; x <= size.width; x++) {
        final nx =
            (x / size.width) * math.pi * 4 * wave.frequency;

        final y = centerY +
            math.sin(nx + wave.phase + phase) *
                amplitudes[i];

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return true;
  }
}

class _WaveData {
  const _WaveData({
    required this.color,
    required this.alpha,
    required this.phase,
    required this.frequency,
  });

  final Color color;
  final double alpha;
  final double phase;
  final double frequency;
}