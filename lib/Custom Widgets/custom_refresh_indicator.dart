import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../Components/colors.dart';

class CustomPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomRefreshIndicator(
      durations: const RefreshIndicatorDurations(
        finalizeDuration: Duration(milliseconds: 300),
      ),
      onRefresh: onRefresh,
      builder: (context, child, controller) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Transform.translate(
              offset: Offset(
                0,
                controller.isFinalizing
                    ? Curves.ease.transform(controller.value.clamp(0.0, 1.0)) * 60
                    : controller.value * 60,
              ),
              child: child,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: controller.value.clamp(0.0, 1.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildIndicatorContent(controller, theme),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }

  Widget _buildIndicatorContent(IndicatorController controller, ThemeData theme) {
    switch (controller.state) {
      case IndicatorState.dragging:
        return Column(
          key: const ValueKey(IndicatorState.dragging),
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "Pull Down to Refresh",
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Icon(
              LucideIcons.arrowDown,
              color: AppColors.brand,
              size: 20,
            ),
          ],
        );
      case IndicatorState.armed:
        return Column(
          key: const ValueKey(IndicatorState.armed),
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "Release to Refresh",
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const AnimatedRotation(
              duration: Duration(milliseconds: 200),
              turns: 0.5,
              child: Icon(
                LucideIcons.arrowDown,
                color: AppColors.brand,
                size: 20,
              ),
            ),
          ],
        );
      case IndicatorState.loading:
        return Column(
          key: const ValueKey(IndicatorState.loading),
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "Refreshing...",
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        );
      default:
        return SizedBox.shrink(key: ValueKey(controller.state));
    }
  }
}
