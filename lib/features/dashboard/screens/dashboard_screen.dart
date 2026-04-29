// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/localization/localization.dart';

import 'package:finance_track/features/dashboard/widgets/widgets.dart';
import '../../../core/extensions/currency_context_extension.dart';
import '../../../core/models/currency_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../../features/expense_list/bloc/expense_list_bloc.dart';
import '../../../features/expense_list/bloc/expense_list_state.dart';
import '../../../features/income_list/bloc/income_list_bloc.dart';
import '../../../features/income_list/bloc/income_list_state.dart';
import '../bloc/category_analysis_bloc.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

/// Dashboard screen showing finance overview and analytics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasPlayedAnimation = false;



  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Load dashboard data when the screen first loads
    context.read<DashboardCubit>().loadDashboardData();

    // Load budget data
    context.read<BudgetBloc>().add(const LoadBudget());

    // Delay to ensure expenses are loaded before calculating budget stats
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateBudgetStats();
    });

    // Start animation only on first load
    if (!_hasPlayedAnimation) {
      _animationController.forward();
      _hasPlayedAnimation = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateBudgetStats() {
    final state = context.read<DashboardCubit>().state;
    if (state is DashboardLoaded) {
      // Calculate budget stats based on expenses
      context.read<BudgetBloc>().add(CalculateBudgetStats(state.expenses));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocProvider(
      providers: [
        // Add CategoryAnalysisBloc provider
        BlocProvider<CategoryAnalysisBloc>(
          create: (context) => CategoryAnalysisBloc(
            expenseRepository: context.read<ExpenseRepository>(),
            incomeRepository: context.read<IncomeRepository>(),
          )..add(const LoadCategoryAnalysis()),
        ),
      ],
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            // Listen for expense list changes
            BlocListener<ExpenseListBloc, ExpenseListState>(
              listener: (context, state) {
                if (state is ExpenseListLoaded) {
                  // Refresh dashboard data when expenses change
                  context.read<DashboardCubit>().loadDashboardData();
                  // Refresh category analysis data
                  context
                      .read<CategoryAnalysisBloc>()
                      .add(const LoadCategoryAnalysis());
                }
              },
            ),
            // Listen for income list changes
            BlocListener<IncomeListBloc, IncomeListState>(
              listener: (context, state) {
                // Refresh dashboard data when incomes change
                if (state.status == IncomeListStatus.loaded) {
                  context.read<DashboardCubit>().loadDashboardData();
                  // Refresh category analysis data
                  context
                      .read<CategoryAnalysisBloc>()
                      .add(const LoadCategoryAnalysis());
                }
              },
            ),
          ],
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<DashboardCubit>().loadDashboardData();
                  _updateBudgetStats();

                  // Refresh category analysis data
                  context
                      .read<CategoryAnalysisBloc>()
                      .add(const LoadCategoryAnalysis());
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildAppBar(context),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildDashboardContent(
                              context, context.selectedCurrency, state),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, Currency currency, DashboardState state) {
    if (state is DashboardError) {
      return _buildErrorView(state.message);
    }

    // For initial or loading state, show placeholder content
    if (state is DashboardInitial || state is DashboardLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // Placeholder balance card with shimmer effect
          const PlaceHolderBalanceCard(),

          SizedBox(height: 12.h),

          // Placeholder budget card
          PlaceholderBudgetCard(context: context),

          SizedBox(height: 16.h),

          // Placeholder categories section
          const PlaceholderCategoriesSection(),
        ],
      );
    }

    // For loaded state, show actual content
    if (state is DashboardLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // Balance summary card
          BalanceSummaryCard(
            balance: state.balance,
            totalIncome: state.totalIncomes,
            totalExpense: state.totalExpenses,
            incomeChange: state.incomeChange,
            expenseChange: state.expenseChange,
          ),

          SizedBox(height: 12.h),

          // BudgetTrackingCard
          BudgetTrackingCardWidget(state: state, currency: currency),

          SizedBox(height: 12.h),

          // Category
          const CategoriesAnalysisCard(),
          SizedBox(height: 12.h),

          // Monthly summary card
          CurrentMonthSummaryCard(
            thisMonthIncome: state.thisMonthIncomes,
            thisMonthExpense: state.thisMonthExpenses,
            thisMonthBalance: state.thisMonthBalance,
            topExpenseCategories: state.topExpenseCategories,
            topIncomeCategories: state.topIncomeCategories,
          ),

          SizedBox(height: 32.h),
        ],
      );
    }

    return Container();
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            LocalizedText('Error Loading Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 8.h),
            LocalizedText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardCubit>().loadDashboardData();
              },
              child: const LocalizedText('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1D4ED8),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20.w, bottom: 16.h),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
              ),
            ),
            // IconButton(
            //     onPressed: () {
            //       context.read<PurchasesCubit>().loadOfferings();

            //       // context.push(AppPaths.purchasesPage);
            //     },
            //     icon: const Icon(
            //       Icons.price_change,
            //       color: Colors.white,
            //     ))
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            // color: Color(0xFF1D4ED8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1D4ED8),
                Color(0xFF1E40AF),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30.w,
                top: -10.h,
                child: Container(
                  height: 100.r,
                  width: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -20.w,
                bottom: 30.h,
                child: Container(
                  height: 60.r,
                  width: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
