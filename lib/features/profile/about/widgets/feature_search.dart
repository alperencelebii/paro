import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/about_cubit.dart';
import 'package:finance_track/core/localization/localization.dart';

class FeatureSearch extends StatefulWidget {
  const FeatureSearch({super.key});

  @override
  State<FeatureSearch> createState() => _FeatureSearchState();
}

class _FeatureSearchState extends State<FeatureSearch>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Setup animation for subtle pulsing effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _clearSearch() {
    _controller.clear();
    context.read<AboutCubit>().resetSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hasFocus ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          color: _hasFocus
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hasFocus
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: _hasFocus ? 2 : 1,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) =>
              context.read<AboutCubit>().searchFeatures(value),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            hintText: AppLocalizations.tr('Search features...'),
            border: InputBorder.none,
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: _hasFocus
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? InkWell(
                    onTap: _clearSearch,
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _hasFocus
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5)
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: _hasFocus
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                  )
                : null,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
