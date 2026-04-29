// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/navigation/notifications/bottom_sheet_visibility_notification.dart';
import '../../features/transactions/utils/transaction_utils.dart';
import '../../features/expense_list/bloc/expense_list_bloc.dart';
import '../../features/expense_list/bloc/expense_list_event.dart';
import '../../features/income_list/bloc/income_list_bloc.dart';
import '../../features/income_list/bloc/income_list_event.dart';

/// Scaffold with a persistent bottom navigation bar that works with GoRouter StatefulShellRoute
class ScaffoldWithBottomNav extends StatefulWidget {
  /// The navigation shell
  final StatefulNavigationShell navigationShell;

  /// The navigation cubit
  final NavigationCubit navigationCubit;

  const ScaffoldWithBottomNav({
    super.key,
    required this.navigationShell,
    required this.navigationCubit,
  });

  @override
  State<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends State<ScaffoldWithBottomNav> {
  // Track bottom sheet visibility
  bool _isBottomSheetVisible = false;

  @override
  Widget build(BuildContext context) {
    // Update the NavigationCubit when branch index changes
    final currentIndex = widget.navigationShell.currentIndex;
    final tab = _indexToTab(currentIndex);

    // Only update cubit if needed to avoid unnecessary rebuilds
    if (widget.navigationCubit.state.currentTab != tab) {
      widget.navigationCubit.changeTab(tab);
    }

    return NotificationListener<BottomSheetVisibilityNotification>(
      onNotification: (notification) {
        setState(() {
          _isBottomSheetVisible = notification.visible;
        });
        return true;
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: _isBottomSheetVisible
            ? null
            : _NavigationBar(
                currentIndex: currentIndex,
                onTabSelected: _onTabSelected,
                onAddTransaction: _onAddTransaction,
              ),
      ),
    );
  }

  void _onTabSelected(int index) {
    // This will change the shell branch index
    widget.navigationShell.goBranch(
      index,
      // This will perform a navigation without rebuilding the shell route
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Update the tab in the cubit
    widget.navigationCubit.changeTab(_indexToTab(index));
  }

  Future<void> _onAddTransaction() async {
    await TransactionUtils.showAddTransactionSheet(
      context: context,
    );

    // Refresh data
    if (context.mounted) {
      context.read<ExpenseListBloc>().add(const LoadExpenses());
      context.read<IncomeListBloc>().add(const LoadIncomes());
    }
  }

  // Convert index to NavigationTab
  NavigationTab _indexToTab(int index) {
    switch (index) {
      case 0:
        return NavigationTab.home;
      case 1:
        return NavigationTab.dashboard;
      case 2:
        return NavigationTab.analytics;
      case 3:
        return NavigationTab.profile;
      default:
        return NavigationTab.home;
    }
  }
}

/// Custom navigation bar with minimal design
class _NavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddTransaction;

  const _NavigationBar({
    required this.currentIndex,
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
                0,
                Icons.home_rounded,
                Icons.home_rounded,
                Colors.grey.shade400,
              ),
              // Dashboard icon
              _buildNavItem(
                context,
                1,
                Icons.grid_view_rounded,
                Icons.grid_view_rounded,
                Colors.grey.shade400,
              ),
              // Center space for FAB
              const SizedBox(width: 60),
              // Analytics icon
              _buildNavItem(
                context,
                2,
                Icons.analytics_rounded,
                Icons.analytics_rounded,
                Colors.grey.shade400,
              ),
              // Profile icon
              _buildNavItem(
                context,
                3,
                Icons.person_rounded,
                Icons.person_rounded,
                Colors.grey.shade400,
              ),
            ],
          ),
        ),

        // Add transaction button
        Positioned(
          top: -20,
          child: InkWell(
            onTap: onAddTransaction,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8),
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
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.primary,
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
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    Color iconColor,
  ) {
    final bool isSelected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTabSelected(index),
        child: SizedBox(
          height: 48,
          width: 48,
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFF1D4ED8) : iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
