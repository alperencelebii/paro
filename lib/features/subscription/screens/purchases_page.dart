
import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/localization/localization.dart';
import 'package:finance_track/features/subscription/cubits/purchases_cubit/purchases_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Scaffold(
      body: BlocBuilder<PurchasesCubit, PurchasesState>(
        builder: (context, state) {
          switch (state.offeringStatus) {
            case OfferingStatus.initial:
            case OfferingStatus.loading:
              return const _PremiumLoadingView();
            case OfferingStatus.success:
              return _PremiumSuccessView(
                onPrimaryTap: () => context.read<PurchasesCubit>().showPaywall(),
                onRefreshTap: () => context
                    .read<PurchasesCubit>()
                    .loadOfferings(autoPresentPaywall: false),
              );
            case OfferingStatus.failure:
              return _PremiumErrorView(
                message: state.errorMesssage.isNotEmpty
                    ? state.errorMesssage
                    : 'Premium planlar yüklenemedi.',
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

class _PremiumLoadingView extends StatelessWidget {
  const _PremiumLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/paro_logo.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 18),
              LocalizedText(
                'Premium planlar hazırlanıyor',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumErrorView extends StatelessWidget {
  const _PremiumErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.cloud_off_rounded,
              size: 78,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 22),
            LocalizedText(
              'Planlar yüklenemedi',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            LocalizedText(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const LocalizedText('Tekrar dene'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _PremiumSuccessView extends StatelessWidget {
  const _PremiumSuccessView({
    required this.onPrimaryTap,
    required this.onRefreshTap,
  });

  final VoidCallback onPrimaryTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          right: -70,
          top: -40,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onRefreshTap,
                      child: const LocalizedText(
                        'Yenile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/paro_logo.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    LocalizedText(
                      'PARO Premium',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(
                      'Paranı daha akıllı yönet. Analizleri, hedefleri ve gelişmiş araçları aç.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Column(
                        children: _benefits
                            .map(
                              (benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: LocalizedText(
                                        benefit,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton(
                      onPressed: onPrimaryTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const LocalizedText('Premium’a Geç'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const LocalizedText(
                        'Şimdilik geç',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocalizedText(
                      'Satın alma ve abonelik yönetimi RevenueCat üzerinden yapılır.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> get _benefits => const [
        'Gelişmiş gelir-gider analizleri',
        'Akıllı harcama içgörüleri',
        'Birikim hedefleri ve ilerleme takibi',
        'Tekrarlayan gider / abonelik takibi',
        'CSV dışa aktarma ve raporlar',
        'Fiş tarama deneyimini sınırsız kullanma',
      ];
}
