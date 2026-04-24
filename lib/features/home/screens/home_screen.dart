import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_state.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_bloc.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
// Now using Tesseract OCR (supports 16KB page sizes)
import 'package:go_router/go_router.dart';
import '../../../core/extensions/currency_context_extension.dart';
import '../../../core/router/app_router.dart';
import '../widgets/widgets.dart';

/// Main home screen showing expense and income summary
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasPlayedAnimation = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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

    // Start the animation only once when component is first created
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

  Future<void> _refreshData() async {
    // Implement the logic to refresh data
    // This is a placeholder and should be replaced with the actual implementation
    await Future.delayed(const Duration(seconds: 1)); // Simulating a delay
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // Listen for expense list changes
          BlocListener<ExpenseListBloc, ExpenseListState>(
            listener: (context, state) {
              if (state is ExpenseListLoaded) {
                // Calculate budget stats based on expenses
                context
                    .read<BudgetBloc>()
                    .add(CalculateBudgetStats(state.expenses));
              }
            },
          ),
          // Listen for income list changes
          BlocListener<IncomeListBloc, IncomeListState>(
            listener: (context, state) {
              // Refresh budget stats when incomes change (in case they affect budget calculations)
              if (state.status == IncomeListStatus.loaded) {
                // Budget stats are primarily based on expenses, but we can trigger recalculation
                // if needed when income changes
                final expenseBloc = context.read<ExpenseListBloc>();
                if (expenseBloc.state is ExpenseListLoaded) {
                  final expenseState = expenseBloc.state as ExpenseListLoaded;
                  context
                      .read<BudgetBloc>()
                      .add(CalculateBudgetStats(expenseState.expenses));
                }
              }
            },
          ),
        ],
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: BlocBuilder<CurrencyBloc, CurrencyState>(
                  builder: (context, currencyState) {
                    final currency = currencyState is CurrencyLoaded
                        ? currencyState.selectedCurrency
                        : context.selectedCurrency;

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HomePageBalanceCard(currency: currency),
                              15.verticalSpace,
                              // const HomeQuickActionButton(),
                              // 15.verticalSpace,
                              const HomeActiveBudgetCard(),
                              15.verticalSpace,
                              const HomeDateWiseExpenseChartWidget(days: 10),
                              15.verticalSpace,
                              const HomeQuickActionButtonWidget(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    // Get current date for display
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');
    final formattedDate = dateFormat.format(now);

    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true, collapsedHeight: 70.h,
      elevation: 0,

      backgroundColor: const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(bottom: 16.h, left: 20.w, right: 20.w),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Finance Tracker',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22.sp,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF574ED7),
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
      // Scan button now using Tesseract OCR (supports 16KB page sizes)
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16.w),
          child: IconButton(
            icon: const Icon(
              Icons.document_scanner,
              color: Colors.white,
            ),
            onPressed: () {
              context.push(AppPaths.invoiceScanner);
            },
            tooltip: 'Scan Receipt',
          ),
        ),
      ],
    );
  }
}
