import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/about_cubit.dart';
import '../bloc/about_state.dart';
import '../widgets/feature_card.dart';
import '../../../navigation/cubit/navigation_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/localization/localization.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationCubit = context.read<NavigationCubit>();

    return BlocProvider(
      create: (_) => AboutCubit(),
      child: BlocProvider<NavigationCubit>.value(
        value: navigationCubit,
        child: const _AboutScreenContent(),
      ),
    );
  }
}

class _AboutScreenContent extends StatelessWidget {
  const _AboutScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<AboutCubit, AboutState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const WidgetSpan(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                    TextSpan(text: AppLocalizations.tr('  ')),
                    TextSpan(
                      text: state.errorMessage,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Header with logo and title
                SliverAppBar(
                  expandedHeight: 235,
                  floating: false,
                  pinned: true,
                  backgroundColor: theme.colorScheme.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context
                            .read<NavigationCubit>()
                            .changeTab(NavigationTab.home);
                        context.go('/');
                      }
                    },
                  ),
                  title: innerBoxIsScrolled ? const LocalizedText('App Features') : null,
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // App logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.folder,
                                color: theme.colorScheme.primary,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // App name
                          const LocalizedText('Expense Manager Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _SearchBar(
                              onChanged: (value) {
                                context
                                    .read<AboutCubit>()
                                    .searchFeatures(value);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            // Main white content area
            body: Container(
              color: Colors.white,
              child: Column(
                children: [
                  10.verticalSpace,

                  // Feature list
                  Expanded(
                    child: state.filteredFeatures.isEmpty
                        ? _EmptySearchResults(
                            onClearSearch: () =>
                                context.read<AboutCubit>().resetSearch(),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.filteredFeatures.length,
                            itemBuilder: (context, index) {
                              final feature = state.filteredFeatures[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: FeatureCard(feature: feature),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.tr('Search features...'),
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.search,
              color: Colors.grey[400],
              size: 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _EmptySearchResults extends StatelessWidget {
  final VoidCallback onClearSearch;

  const _EmptySearchResults({required this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const LocalizedText('No features found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const LocalizedText('Try a different search term',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onClearSearch,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const LocalizedText('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}
