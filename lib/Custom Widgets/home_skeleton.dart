import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.6);
        return Opacity(
          opacity: opacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isTablet = constraints.maxWidth > 800;

              if (isTablet) {
                return Padding(
                  padding: AppLayout.screenPaddingTab,
                  child: Row(
                    children: [
                      // 1/3 Master Panel Skeleton
                      Expanded(
                        flex: 1,
                        child: _buildSkeletonPanel(context, baseColor),
                      ),
                      const SizedBox(width: AppLayout.space24),
                      // 2/3 Detail Panel Skeleton
                      Expanded(
                        flex: 2,
                        child: _buildSkeletonPanel(context, baseColor, isDetail: true),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: AppLayout.screenPadding,
                child: _buildListSkeleton(baseColor, isTablet: false),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonPanel(BuildContext context, Color color, {bool isDetail = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.panelRadius),
        border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
      ),
      padding: const EdgeInsets.all(AppLayout.space24),
      child: isDetail ? _buildDetailSkeleton(color) : _buildListSkeleton(color, isTablet: true),
    );
  }

  Widget _buildListSkeleton(Color color, {required bool isTablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: "Patients [Count]"
        Row(
          children: [
            Container(width: 100, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.radius8))),
            const SizedBox(width: 8),
            Container(width: 30, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.radius8))),
          ],
        ),
        const SizedBox(height: AppLayout.space8),
        // Subtitle
        Container(width: 180, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
        const SizedBox(height: AppLayout.space16),
        // Search Bar (matching TextField height and radius)
        Container(
          height: 56, 
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppLayout.inputRadius),
          ),
        ),
        const SizedBox(height: AppLayout.space16),
        // Patient Bubbles
        Expanded(
          child: ListView.builder(
            itemCount: 6,
            padding: EdgeInsets.zero,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: AppLayout.space12),
              child: _PatientBubbleSkeleton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSkeleton(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient Header Card
        Container(
          padding: const EdgeInsets.all(AppLayout.space16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppLayout.radius16),
          ),
          child: Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
                  const SizedBox(height: AppLayout.space8),
                  Container(width: 100, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.space16),
        // Page Indicators (History/Cabin)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 100, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.radius20))),
            const SizedBox(width: 16),
            Container(width: 100, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.radius20))),
          ],
        ),
        const SizedBox(height: AppLayout.space24),
        // List of Diagnosis Cards
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            padding: EdgeInsets.zero,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.space16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppLayout.radius12),
                  border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientBubbleSkeleton extends StatelessWidget {
  const _PatientBubbleSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);
    
    return Container(
      padding: const EdgeInsets.all(AppLayout.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // CustomNameInitial circle
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppLayout.space8),
              // Name and age lines
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
                  const SizedBox(height: AppLayout.space4 + 2),
                  Container(width: 80, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
                ],
              ),
              const Spacer(),
              // Arrow icon placeholder
              Container(width: 18, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: AppLayout.space12),
          Row(
            children: [
              // Gender label placeholder
              Container(width: 60, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.radius12))),
              const Spacer(),
              // Date placeholder
              Container(width: 70, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppLayout.space4))),
            ],
          ),
        ],
      ),
    );
  }
}
