import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../connectivity/connectivity_cubit.dart';
import 'package:finance_track/core/localization/localization.dart';

/// A widget that displays a floating notification when the device is offline
class ConnectivityBanner extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Constructor
  const ConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide animation from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    ));

    // Fade animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state.status == ConnectivityStatus.disconnected) {
          _controller.forward();
        } else if (state.status == ConnectivityStatus.connected) {
          _controller.reverse();
        }
      },
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.bottomCenter,
          children: [
            widget.child,
            if (state.status == ConnectivityStatus.disconnected)
              _buildOfflineNotification(context),
          ],
        );
      },
    );
  }

  /// Build the offline floating notification
  Widget _buildOfflineNotification(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).padding.bottom +
        70.h; // Account for bottom nav + safe area

    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: bottom,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade800.withValues(alpha: 0.9),
                  Colors.red.shade900.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: const ColorFilter.mode(
                  Colors.black12,
                  BlendMode.srcOver,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () {
                      // Optional: Add an action when tapping on the notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText('Working offline. Your data is being saved locally.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          // Left icon with pulsing animation
                          _buildPulsingIcon(Icons.wifi_off_rounded),
                          SizedBox(width: 12.w),

                          // Message
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocalizedText('You are offline',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                LocalizedText('Data will be synced automatically when reconnected',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right action icon
                          Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a pulsing icon for better visibility
  Widget _buildPulsingIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        onEnd: () {
          setState(() {}); // Restart the animation
        },
        child: Icon(
          icon,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }
}
