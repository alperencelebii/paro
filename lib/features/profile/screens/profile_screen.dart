import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/features/profile/widgets/profile_item_tile_widget.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:finance_track/features/subscription/bloc/subscription_management_bloc.dart';
import 'package:finance_track/features/subscription/repository/subscription_management_repository.dart';
import 'package:flutter/material.dart';
import 'package:finance_track/core/widgets/data_loading_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/data/objectbox.dart';
import 'package:finance_track/data/repositories/objectbox_expense_repository.dart';
import 'package:finance_track/data/repositories/objectbox_income_repository.dart';
import 'package:finance_track/core/services/data_fetching_service.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_bloc.dart';
import 'package:user_repository/user_repository.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_state.dart';
import 'package:finance_track/features/profile/currency/screens/currency_selection_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/currency_context_extension.dart';
import 'dart:async';
import 'package:finance_track/core/localization/localization.dart';

/// Profile screen showing user information and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  final bool _isDeleting = false;
  Stream<DataFetchStatus>? _refreshStatusStream;
  int _transactionCount = 0;
  double _totalBalance = 0;

  // Get instance after initialization in app_initializer
  late final ObjectBox _objectBox;
  late final ObjectBoxExpenseRepository _expenseRepository;
  late final ObjectBoxIncomeRepository _incomeRepository;

  @override
  void initState() {
    super.initState();
    _objectBox = ObjectBox.instance;
    // Initialize repositories directly
    _expenseRepository = ObjectBoxExpenseRepository(_objectBox);
    _incomeRepository = ObjectBoxIncomeRepository(_objectBox);
    // Get transaction service instance
    // Initialize transaction stats
    _loadTransactionStats();
  }

  Future<void> _loadTransactionStats() async {
    final expenses = await _expenseRepository.getExpenses();
    final incomes = await _incomeRepository.getIncomes();

    setState(() {
      final expenseTotal =
          expenses.fold<double>(0, (sum, expense) => sum + (expense.amount));
      final incomeTotal =
          incomes.fold<double>(0, (sum, income) => sum + (income.amount));

      _transactionCount = expenses.length + incomes.length;
      _totalBalance = incomeTotal - expenseTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _refreshDataFromObjectBox(context);
            },
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _buildProfileStats(context),
                      SizedBox(height: 24.h),
                      _buildAccountSection(context),
                      SizedBox(height: 16.h),
                      _buildDataManagementSection(context),
                      SizedBox(height: 16.h),
                      _buildPreferencesSection(context),
                      SizedBox(height: 16.h),
                      _buildSupportSection(context),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing && _refreshStatusStream != null)
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: DataLoadingBar(
                statusStream: _refreshStatusStream!,
                onComplete: () {
                  setState(() {
                    _isRefreshing = false;
                    _refreshStatusStream = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('Data refreshed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTransactionStats();
                },
                onError: (errorMessage) {
                  setState(() {
                    _isRefreshing = false;
                    _refreshStatusStream = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: LocalizedText('Error refreshing data: $errorMessage'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                onEmpty: () {
                  setState(() {
                    _isRefreshing = false;
                    _refreshStatusStream = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('No transactions found in the cloud.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1D4ED8),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20.w, bottom: 16.h),
        title: LocalizedText('Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStats(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final user = state.status == AppStatus.authenticated
            ? state.user
            : User.anonymous;

        // Use a nested BlocBuilder for CurrencyBloc to react to currency changes
        return BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, currencyState) {
            final currency = currencyState is CurrencyLoaded
                ? currencyState.selectedCurrency
                : context.selectedCurrency;

            final formatter = NumberFormat.currency(
              symbol: currency.symbol,
              decimalDigits: 0,
            );

            return Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor:
                        const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                    child: LocalizedText(
                      user.name?.substring(0, 1).toUpperCase() ?? 'G',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  LocalizedText(
                    user.name ?? 'Guest User',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText(
                    user.email ?? 'Not logged in',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        title: 'Transactions',
                        value: _transactionCount.toString(),
                        icon: Icons.receipt_outlined,
                      ),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
                      ),
                      _buildStatItem(
                        title: 'Balance',
                        value: formatter.format(_totalBalance),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1D4ED8),
          size: 24.r,
        ),
        SizedBox(height: 8.h),
        LocalizedText(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        LocalizedText(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionManagementBloc(
        repository: SubscriptionManagementRepository(),
      )..add(const CheckActiveSubscription()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: LocalizedText('Account',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ProfileItemTileWidget(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Change your name and password',
            iconColor: Colors.blue,
            onTap: () {
              // Navigate to the profile edit screen using GoRouter
              context.pushNamed(AppRoutes.profileEdit);
            },
          ),
          BlocBuilder<SubscriptionManagementBloc, SubscriptionManagementState>(
            builder: (context, state) {
              // Only show subscription management if user has active pas subscription
              if (state.hasPasSubscription) {
                return ProfileItemTileWidget(
                  icon: Icons.subscriptions,
                  title: 'Subscription Management',
                  subtitle: 'View and manage your subscription details',
                  iconColor: const Color(0xFF1D4ED8),
                  trailing: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: LocalizedText('Active',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  onTap: () {
                    context.pushNamed(AppRoutes.subscriptionManagement);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ProfileItemTileWidget(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings and account security',
            iconColor: Colors.green,
            onTap: () {
              // Navigate to the privacy settings screen using GoRouter
              context.pushNamed(AppRoutes.privacySecurity);
            },
          ),
          ProfileItemTileWidget(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Secure your app with fingerprint or face recognition',
            iconColor: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 10.w),
                      const Expanded(
                        child: LocalizedText('Biometric authentication coming soon!'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.amber.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void requirePremium(VoidCallback onAllowed) {
    final subscriptionCubit = context.read<SubscriptionCubit>();
    subscriptionCubit.ensureProStatus().then((isPro) {
      if (!context.mounted) return;
      if (isPro) {
        onAllowed();
      } else {
        context.pushNamed(AppRoutes.purchasesPage);
      }
    });
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: LocalizedText('Data Management',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        ProfileItemTileWidget(
          icon: Icons.file_download_outlined,
          title: 'Export Data',
          subtitle: 'Export your transactions to CSV',
          iconColor: Colors.orange,
          onTap: () {
            // requirePremium(() {
            //   context.pushNamed(AppRoutes.exportData);
            // });
            context.pushNamed(AppRoutes.exportData);
          },
        ),
        ProfileItemTileWidget(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account and all data',
          iconColor: Colors.red,
          onTap: _showDeleteAccountConfirmationDialog,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: LocalizedText('Preferences',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, state) {
            return ProfileItemTileWidget(
              icon: Icons.currency_exchange,
              title: 'Currency',
              subtitle: 'Select your preferred currency for transactions',
              trailing: state is CurrencyLoaded
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: LocalizedText('${state.currency.symbol} ${state.currency.code}',
                        style: TextStyle(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
              iconColor: const Color(0xFF1D4ED8),
              onTap: () => showCurrencySelectionDialog(context),
            );
          },
        ),
        BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, state) {
            return ProfileItemTileWidget(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'Change app language',
              trailing: LocalizedText(
                languageLabel(state.language),
                style: TextStyle(
                  color: const Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              iconColor: const Color(0xFF1D4ED8),
              onTap: () => showLanguageSelectionDialog(context),
            );
          },
        ),
        ProfileItemTileWidget(
          icon: Icons.category_outlined,
          title: 'My Categories',
          subtitle: 'Add, edit, or delete your custom categories',
          iconColor: const Color(0xFF1D4ED8),
          onTap: () => context.pushNamed(AppRoutes.manageCategories),
        ),
        ProfileItemTileWidget(
          icon: Icons.flag_rounded,
          title: 'Birikim Hedefleri',
          subtitle: 'Hedeflerini ve ilerlemeni yönet',
          iconColor: AppColors.accent,
          onTap: () => context.pushNamed(AppRoutes.savingsGoals),
        ),
        ProfileItemTileWidget(
          icon: Icons.repeat_rounded,
          title: 'Tekrarlayan Giderler',
          subtitle: 'Abonelik ve düzenli ödemelerini takip et',
          iconColor: AppColors.warning,
          onTap: () => context.pushNamed(AppRoutes.recurringExpenses),
        ),
        ProfileItemTileWidget(
          icon: Icons.notifications_active_outlined,
          title: 'Akıllı Hatırlatıcılar',
          subtitle: 'Bütçe, abonelik ve günlük uyarı tercihleri',
          iconColor: AppColors.primary,
          onTap: () => context.pushNamed(AppRoutes.reminderSettings),
        ),
        // ProfileItemTileWidget(
        //   icon: Icons.brightness_6_outlined,
        //   title: 'Theme',
        //   subtitle: 'Choose light or dark theme',
        //   trailing: Container(
        //     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        //     decoration: BoxDecoration(
        //       color: const Color(0xFF1D4ED8).withValues(alpha:0.1),
        //       borderRadius: BorderRadius.circular(16.r),
        //     ),
        //     child: LocalizedText(
        //       'Light',
        //       style: TextStyle(
        //         color: const Color(0xFF1D4ED8),
        //         fontWeight: FontWeight.w600,
        //         fontSize: 14.sp,
        //       ),
        //     ),
        //   ),
        //   iconColor: Colors.purple,
        //   onTap: () {
        //     // Show a snackbar informing users that dark mode is not yet implemented
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Row(
        //           children: [
        //             const Icon(Icons.info_outline, color: Colors.white),
        //             SizedBox(width: 10.w),
        //             const Expanded(
        //               child: LocalizedText('Dark mode is coming soon!'),
        //             ),
        //           ],
        //         ),
        //         backgroundColor: const Color(0xFF1D4ED8),
        //         duration: const Duration(seconds: 2),
        //         behavior: SnackBarBehavior.floating,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(10.r),
        //         ),
        //         margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: LocalizedText('Support',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        ProfileItemTileWidget(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with using the app',
          iconColor: Colors.teal,
          onTap: () {
            context.pushNamed(AppRoutes.helpSupport);
          },
        ),
        ProfileItemTileWidget(
          icon: Icons.feedback_outlined,
          title: 'Send Feedback',
          subtitle: 'Share your thoughts and suggestions',
          iconColor: const Color(0xFF1D4ED8),
          onTap: () {
            context.pushNamed(AppRoutes.sendMessage);
          },
        ),
        // ProfileItemTileWidget(
        //   icon: Icons.info_outline,
        //   title: 'About',
        //   subtitle: 'Learn more about this app',
        //   iconColor: Colors.indigo,
        //   onTap: () {
        //     context.pushNamed(AppRoutes.about);
        //   },
        // ),
        SizedBox(height: 16.h),
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: _showLogoutConfirmationDialog,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText('Logout',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      LocalizedText('Sign out from your account',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
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
    );
  }

  // Refresh data from ObjectBox
  Future<void> _refreshDataFromObjectBox(BuildContext context) async {
    if (_isRefreshing || _isDeleting) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get fresh data from ObjectBox
      final expenses = await _expenseRepository.getExpenses();
      final incomes = await _incomeRepository.getIncomes();

      // Update transaction stats
      final expenseTotal =
          expenses.fold<double>(0, (sum, expense) => sum + (expense.amount));
      final incomeTotal =
          incomes.fold<double>(0, (sum, income) => sum + (income.amount));

      setState(() {
        _transactionCount = expenses.length + incomes.length;
        _totalBalance = incomeTotal - expenseTotal;
        _isRefreshing = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('Data refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show confirmation dialog for refreshing data

  // Show confirmation dialog for deleting all transactions

  // Show confirmation dialog for logging out
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Logout'),
        content: const LocalizedText('Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const LocalizedText('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Logout
              context.read<AppBloc>().add(const AppLogoutRequested());
              // Reset first time flag
              context
                  .read<AppBloc>()
                  .add(const AppSetFirstTime(isFirstTime: true));
            },
            child: const LocalizedText('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Delete Account'),
        content: const LocalizedText('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const LocalizedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const LocalizedText('Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
