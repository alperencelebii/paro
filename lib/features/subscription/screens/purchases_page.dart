import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/core/localization/localization.dart';
// import 'package:purchases_flutter/models/package_wrapper.dart';

import 'package:finance_track/features/subscription/cubits/purchases_cubit/purchases_cubit.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PurchasesCubit>();
      if (cubit.state.offeringStatus == OfferingStatus.initial ||
          cubit.state.offeringStatus == OfferingStatus.failure) {
        cubit.loadOfferings(autoPresentPaywall: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const LocalizedText('Go Premium'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<PurchasesCubit, PurchasesState>(
        builder: (context, state) {
          switch (state.offeringStatus) {
            case OfferingStatus.initial:
            case OfferingStatus.loading:
              return _LoadingView(theme: theme);
            case OfferingStatus.success:
              if (state.offerings == null) {
                return _EmptyOfferingView(onRetry: () {
                  context
                      .read<PurchasesCubit>()
                      .loadOfferings(autoPresentPaywall: false);
                });
              }
              return _SuccessView(
                state: state,
                onPrimaryTap: () =>
                    context.read<PurchasesCubit>()..showPaywall(),
                onRefreshTap: () => context
                    .read<PurchasesCubit>()
                    .loadOfferings(autoPresentPaywall: false),
              );
            case OfferingStatus.failure:
              return _ErrorView(
                message: state.errorMesssage.isNotEmpty
                    ? state.errorMesssage
                    : 'Something went wrong while loading purchase options.',
                onRetry: () => context
                    .read<PurchasesCubit>()
                    .loadOfferings(autoPresentPaywall: false),
              );
          }
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          LocalizedText('Fetching premium plans…',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LocalizedText('Hang tight while we prepare the best offers for you.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 72,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          LocalizedText('We couldn’t load the purchase options',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LocalizedText(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const LocalizedText('Try again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const LocalizedText('Maybe later'),
          ),
        ],
      ),
    );
  }
}

class _EmptyOfferingView extends StatelessWidget {
  const _EmptyOfferingView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          LocalizedText('Plans are getting ready',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LocalizedText('We couldn’t find any plans right now. Check back in a moment or refresh.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const LocalizedText('Refresh plans'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.state,
    required this.onPrimaryTap,
    required this.onRefreshTap,
  });

  final PurchasesState state;
  final VoidCallback onPrimaryTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final Package? highlightedPackage =
    //     state.packages.isNotEmpty ? state.packages.first : null;
    // final String primaryCtaLabel = highlightedPackage != null
    //     ? 'Unlock for ${highlightedPackage.storeProduct.priceString}'
    //     : 'View subscription plans';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                LocalizedText('Upgrade to Premium Budgeting',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LocalizedText('Unlock unlimited budget planning, smart insights, and more ways to stay on top of your finances.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          LocalizedText('What you’ll get',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LocalizedText(
                      benefit,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // if (state.packages.isNotEmpty) ...[
          //   const SizedBox(height: 24),
          //   LocalizedText(
          //     'Available plans',
          //     style: theme.textTheme.titleMedium?.copyWith(
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          //   const SizedBox(height: 12),
          //   ...state.packages.map(
          //     (package) => Container(
          //       margin: const EdgeInsets.only(bottom: 12),
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(16),
          //         border: Border.all(
          //             color: theme.dividerColor.withValues(alpha: 0.4)),
          //       ),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 LocalizedText(
          //                   package.storeProduct.title,
          //                   style: theme.textTheme.titleSmall?.copyWith(
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //                 const SizedBox(height: 4),
          //                 LocalizedText(
          //                   package.storeProduct.description,
          //                   style: theme.textTheme.bodySmall?.copyWith(
          //                     color: theme.colorScheme.onSurfaceVariant,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           const SizedBox(width: 12),
          //           LocalizedText(
          //             package.storeProduct.priceString,
          //             style: theme.textTheme.titleMedium?.copyWith(
          //               fontWeight: FontWeight.w700,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onPrimaryTap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: LocalizedText('Unlock Premium'),
          ),
          // const SizedBox(height: 12),
          // OutlinedButton(
          //   onPressed: onRefreshTap,
          //   style: OutlinedButton.styleFrom(
          //     padding: const EdgeInsets.symmetric(vertical: 14),
          //   ),
          //   child: const LocalizedText('Refresh plans'),
          // ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const LocalizedText('Maybe later'),
          ),
        ],
      ),
    );
  }

  List<String> get _benefits => const [
        'Set and manage monthly budgets with premium analytics.',
        'Get proactive insights before you overspend.',
        'Unlock budgeting history and advanced reports.',
        'Sync budgets seamlessly across your devices.',
        'View detailed analysis with graphs and charts.',
        'Export your data to Excel or CSV.',
      ];
}
