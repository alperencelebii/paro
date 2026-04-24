import 'dart:async';
import 'package:flutter/material.dart';

import '../services/data_fetching_service.dart';

/// A beautiful loading bar widget that shows the data loading progress
class DataLoadingBar extends StatefulWidget {
  /// The stream of data fetch status to listen to
  final Stream<DataFetchStatus> statusStream;

  /// Optional callback when loading completes
  final VoidCallback? onComplete;

  /// Optional callback when there's an error
  final Function(String)? onError;

  /// Optional callback when no data is found
  final VoidCallback? onEmpty;

  /// Constructor
  const DataLoadingBar({
    super.key,
    required this.statusStream,
    this.onComplete,
    this.onError,
    this.onEmpty,
  });

  @override
  State<DataLoadingBar> createState() => _DataLoadingBarState();
}

class _DataLoadingBarState extends State<DataLoadingBar>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  bool _isVisible = true;
  String _message = 'Loading your data...';
  bool _isError = false;
  bool _isSuccess = false;
  bool _isEmpty = false;
  StreamSubscription<DataFetchStatus>? _subscription;

  // For shimmer effect and pulse animation
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start pulse animation
    _animationController.repeat(reverse: true);

    // Listen to the status updates
    _listenToStatusUpdates();
  }

  void _listenToStatusUpdates() {
    _subscription = widget.statusStream.listen((status) {
      if (!mounted) return;

      setState(() {
        if (status is DataFetchLoading) {
          _progress = status.progress;
          _message = status.message;
        } else if (status is DataFetchSuccess) {
          _isSuccess = true;
          _progress = 1.0;
          _message = 'Data loaded successfully!';
          _hideAfterDelay();
        } else if (status is DataFetchError) {
          _isError = true;
          _progress = 1.0;
          _message = 'Error loading data: ${status.errorMessage}';
        } else if (status is DataFetchEmpty) {
          _isEmpty = true;
          _progress = 1.0;
          _message = 'No transactions found yet.';
        }
      });

      // Handle success, error or empty states
      if (status is DataFetchSuccess) {
        widget.onComplete?.call();
      } else if (status is DataFetchError) {
        widget.onError?.call(status.errorMessage);
      } else if (status is DataFetchEmpty) {
        widget.onEmpty?.call();
      }
    });
  }

  void _hideAfterDelay() {
    // When successful, play a fade out animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _animationController.stop();
        _animationController.duration = const Duration(milliseconds: 800);
        _animationController.forward().then((_) {
          setState(() {
            _isVisible = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _isSuccess ? _fadeOutAnimation.value : 1.0,
          child: Transform.scale(
            scale: _isError || _isEmpty ? 1.0 : _pulseAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _isError
                        ? Colors.red.withValues(alpha: 0.3)
                        : _isSuccess
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : _isEmpty
                                ? Colors.amber.withValues(alpha: 0.3)
                                : colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: _isError
                      ? Colors.red.shade50
                      : _isSuccess
                          ? colorScheme.primaryContainer
                          : _isEmpty
                              ? Colors.amber.shade50
                              : colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicator
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: _isError
                            ? Colors.red.shade100
                            : _isSuccess
                                ? colorScheme.primary.withValues(alpha: 0.3)
                                : _isEmpty
                                    ? Colors.amber.shade100
                                    : colorScheme.primary
                                        .withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isError
                              ? Colors.red
                              : _isSuccess
                                  ? colorScheme.primary
                                  : _isEmpty
                                      ? Colors.amber
                                      : colorScheme.primary,
                        ),
                        minHeight: 6,
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            // Status icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _isError
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : _isSuccess
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.1)
                                        : _isEmpty
                                            ? Colors.amber
                                                .withValues(alpha: 0.1)
                                            : colorScheme.primary
                                                .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: _isError
                                    ? const Icon(Icons.error_outline,
                                        color: Colors.red)
                                    : _isSuccess
                                        ? Icon(Icons.check_circle_outline,
                                            color: colorScheme.primary)
                                        : _isEmpty
                                            ? const Icon(Icons.info_outline,
                                                color: Colors.amber)
                                            : SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Status message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isError
                                        ? 'Error Loading Data'
                                        : _isSuccess
                                            ? 'Success!'
                                            : _isEmpty
                                                ? 'No Transactions Found'
                                                : 'Loading Your Data',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _isError
                                              ? Colors.red
                                              : _isSuccess
                                                  ? colorScheme.primary
                                                  : _isEmpty
                                                      ? Colors.amber.shade800
                                                      : colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: _isError
                                              ? Colors.red.shade700
                                              : _isSuccess
                                                  ? colorScheme
                                                      .onPrimaryContainer
                                                  : _isEmpty
                                                      ? Colors.amber.shade900
                                                      : colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
