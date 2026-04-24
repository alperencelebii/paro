import 'package:flutter/material.dart';

/// A shimmer loading effect widget for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer container for skeleton loading
class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: shape != null
          ? ShapeDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: shape!,
            )
          : BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
    );
  }
}

/// Shimmer loading for dashboard content
class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width - 32; // Accounting for padding

    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main card shimmer
            ShimmerContainer(
              width: cardWidth,
              height: 180,
              borderRadius: 24,
            ),
            const SizedBox(height: 24),

            // Section title
            const ShimmerContainer(
              width: 150,
              height: 24,
              borderRadius: 4,
            ),
            const SizedBox(height: 16),

            // Category grid
            SizedBox(
              width: cardWidth,
              child: const Row(
                children: [
                  Expanded(
                    child: ShimmerContainer(
                      width: double.infinity,
                      height: 120,
                      borderRadius: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShimmerContainer(
                      width: double.infinity,
                      height: 120,
                      borderRadius: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section title
            const ShimmerContainer(
              width: 120,
              height: 24,
              borderRadius: 4,
            ),
            const SizedBox(height: 16),

            // Chart
            ShimmerContainer(
              width: cardWidth,
              height: 200,
              borderRadius: 16,
            ),
            const SizedBox(height: 24),

            // Section title with action
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerContainer(
                  width: 150,
                  height: 24,
                  borderRadius: 4,
                ),
                ShimmerContainer(
                  width: 60,
                  height: 24,
                  borderRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions list
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerContainer(
                  width: cardWidth,
                  height: 80,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
