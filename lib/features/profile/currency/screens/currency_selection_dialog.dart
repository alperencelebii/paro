import 'package:finance_track/features/profile/currency/bloc/currency/currency_bloc.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_event.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_state.dart';
import 'package:finance_track/core/models/currency_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Currency selection dialog with beautiful UI
class CurrencySelectionDialog extends StatelessWidget {
  const CurrencySelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF), // Match the app's primary color
                    Color(0xFF574ED7), // Darker variant for gradient
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background patterns for visual interest (similar to other app UI)
                  Positioned(
                    right: -15.w,
                    top: -5.h,
                    child: Container(
                      height: 40.r,
                      width: 40.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -10.w,
                    bottom: 0,
                    child: Container(
                      height: 25.r,
                      width: 25.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),

                  // Header content
                  Row(
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        color: Colors.white,
                        size: 24.r,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'Select Currency',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: 24.r,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Currency list
            BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, state) {
                if (state is CurrencyLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (state is CurrencyError) {
                  return Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 48.r,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error: ${state.message}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (state is CurrencyLoaded) {
                  return Flexible(
                    child: _buildCurrencyList(context, state),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyList(BuildContext context, CurrencyLoaded state) {
    final theme = Theme.of(context);
    final selectedCurrency = state.selectedCurrency;

    return ListView.builder(
      itemCount: Currencies.all.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemBuilder: (context, index) {
        final currency = Currencies.all[index];
        final isSelected = currency.code == selectedCurrency.code;

        return Material(
          color: isSelected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                context.read<CurrencyBloc>().add(ChangeCurrency(currency));
                Navigator.of(context).pop();
              }
            },
            splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 14.h,
              ),
              child: Row(
                children: [
                  // Currency info (no flag avatar)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${currency.code} (${currency.symbol})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
