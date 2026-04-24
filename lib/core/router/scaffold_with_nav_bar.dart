import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/expense_list/bloc/expense_list_bloc.dart';
import '../../features/expense_list/bloc/expense_list_event.dart';
import '../../features/income_list/bloc/income_list_bloc.dart';
import '../../features/income_list/bloc/income_list_event.dart';
import '../../features/navigation/notifications/bottom_sheet_visibility_notification.dart';
import '../../features/transactions/utils/transaction_utils.dart';
import 'app_router.dart';

/// Scaffold with a persistent bottom navigation bar that works with GoRouter
class ScaffoldWithNavBar extends StatefulWidget {
  /// The child widget to display in the body
  final Widget child;

  /// The navigation cubit
  final NavigationCubit navigationCubit;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.navigationCubit,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  // Track bottom sheet visibility
  bool _isBottomSheetVisible = false;

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when navigation state changes
    return BlocBuilder<NavigationCubit, NavigationState>(
      bloc: widget.navigationCubit,
      builder: (context, state) {
        return NotificationListener<BottomSheetVisibilityNotification>(
          onNotification: (notification) {
            setState(() {
              _isBottomSheetVisible = notification.visible;
            });
            return true;
          },
          child: Scaffold(
            body: IndexedStack(
              index: state.currentTab == NavigationTab.home ? 0 : 1,
              children: [
                widget.child,
                const Center(child: Text('Income List')),
              ],
            ),
            bottomNavigationBar: _isBottomSheetVisible
                ? null
                : _NavigationBar(
                    currentTab: state.currentTab,
                    onTabSelected: (tab) {
                      final String path = AppPaths.getPathForTab(tab);
                      context.go(path);
                      widget.navigationCubit.changeTab(tab);
                    },
                    onAddTransaction: () async {
                      await TransactionUtils.showAddTransactionSheet(
                        context: context,
                      );

                      // Refresh data
                      if (context.mounted) {
                        context
                            .read<ExpenseListBloc>()
                            .add(const LoadExpenses());
                        context.read<IncomeListBloc>().add(const LoadIncomes());
                      }
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Custom navigation bar with minimal design
class _NavigationBar extends StatelessWidget {
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onTabSelected;
  final VoidCallback onAddTransaction;

  const _NavigationBar({
    required this.currentTab,
    required this.onTabSelected,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Main navigation bar
        Container(
          height: 60,
          // margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home icon
              _buildNavItem(
                context,
                NavigationTab.home,
                Icons.home_rounded,
                Icons.home_rounded,
                Colors.grey.shade400,
              ),
              // Dashboard icon
              _buildNavItem(
                context,
                NavigationTab.dashboard,
                Icons.grid_view_rounded,
                Icons.grid_view_rounded,
                Colors.grey.shade400,
              ),
              // Center space for FAB
              const SizedBox(width: 60),
              // Analytics icon
              _buildNavItem(
                context,
                NavigationTab.analytics,
                Icons.analytics_rounded,
                Icons.analytics_rounded,
                Colors.grey.shade400,
              ),
              // Profile icon
              _buildNavItem(
                context,
                NavigationTab.profile,
                Icons.person_rounded,
                Icons.person_rounded,
                Colors.grey.shade400,
              ),
            ],
          ),
        ),

        // Add transaction button
        Positioned(
          top: -15,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddTransaction,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavigationTab tab,
    IconData icon,
    IconData activeIcon,
    Color iconColor,
  ) {
    final bool isSelected = currentTab == tab;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTabSelected(tab),
        child: SizedBox(
          height: 48,
          width: 48,
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFF6C5CE7) : iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
