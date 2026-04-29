import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/subscription_management_bloc.dart';
import '../repository/subscription_management_repository.dart';
import '../models/subscription_details_model.dart';
import '../services/subscription_service.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Screen for managing and viewing subscription details
class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionManagementBloc(
        repository: SubscriptionManagementRepository(),
      )..add(const LoadSubscriptionDetails()),
      child: const _SubscriptionManagementView(),
    );
  }
}

class _SubscriptionManagementView extends StatelessWidget {
  const _SubscriptionManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const LocalizedText('Subscription Management'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<SubscriptionManagementBloc, SubscriptionManagementState>(
            builder: (context, state) {
              return IconButton(
                icon: state.isRefreshing
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: state.isRefreshing
                    ? null
                    : () {
                        context
                            .read<SubscriptionManagementBloc>()
                            .add(const RefreshSubscriptionDetails());
                      },
                tooltip: AppLocalizations.tr('Refresh'),
              );
            },
          ),
        ],
      ),
      body:
          BlocBuilder<SubscriptionManagementBloc, SubscriptionManagementState>(
        builder: (context, state) {
          if (state.status == SubscriptionManagementStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == SubscriptionManagementStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.r,
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16.h),
                  LocalizedText('Error loading subscription details',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: LocalizedText(
                      state.errorMessage ?? 'Unknown error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<SubscriptionManagementBloc>()
                          .add(const LoadSubscriptionDetails());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const LocalizedText('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.status == SubscriptionManagementStatus.noSubscription) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subscriptions_outlined,
                    size: 64.r,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  LocalizedText('No Active Subscription',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  LocalizedText('You don\'t have an active subscription',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.pushNamed('purchasesPage');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const LocalizedText('View Plans'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.status == SubscriptionManagementStatus.loaded &&
              state.subscriptionDetails != null) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<SubscriptionManagementBloc>()
                    .add(const RefreshSubscriptionDetails());
                // Wait a bit for the refresh to complete
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrimarySubscriptionCard(
                      context,
                      state.subscriptionDetails!.primarySubscription,
                    ),
                    SizedBox(height: 16.h),
                    if (state.subscriptionDetails!.allActiveSubscriptions
                            .length >
                        1)
                      _buildAllSubscriptionsSection(
                        context,
                        state.subscriptionDetails!.allActiveSubscriptions,
                      ),
                    SizedBox(height: 16.h),
                    _buildAccountInfoSection(
                      context,
                      state.subscriptionDetails!,
                    ),
                    if (state
                        .subscriptionDetails!.allTransactions.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildTransactionsSection(
                        context,
                        state.subscriptionDetails!.allTransactions,
                      ),
                    ],
                    SizedBox(height: 16.h),
                    _buildManagementActions(
                        context, state.subscriptionDetails!),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPrimarySubscriptionCard(
    BuildContext context,
    SubscriptionInfo subscription,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isExpired = subscription.expirationDate != null &&
        subscription.expirationDate!.isBefore(DateTime.now());
    final daysRemaining =
        subscription.expirationDate?.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D4ED8),
            const Color(0xFF1E40AF),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText('Active Subscription',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    LocalizedText(
                      subscription.productIdentifier.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: subscription.isActive && !isExpired
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: LocalizedText(
                  subscription.isActive && !isExpired ? 'ACTIVE' : 'EXPIRED',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            context,
            'Entitlement',
            subscription.identifier.toUpperCase(),
            Icons.verified,
          ),
          SizedBox(height: 12.h),
          if (subscription.purchaseDate != null)
            _buildInfoRow(
              context,
              'Purchase Date',
              dateFormat.format(subscription.purchaseDate!),
              Icons.calendar_today,
            ),
          if (subscription.purchaseDate != null) SizedBox(height: 12.h),
          if (subscription.expirationDate != null)
            _buildInfoRow(
              context,
              'Expiration Date',
              dateFormat.format(subscription.expirationDate!),
              Icons.event,
            ),
          if (subscription.expirationDate != null) SizedBox(height: 12.h),
          if (daysRemaining != null)
            _buildInfoRow(
              context,
              'Days Remaining',
              daysRemaining > 0 ? '$daysRemaining days' : 'Expired',
              Icons.access_time,
            ),
          if (daysRemaining != null) SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            'Period Type',
            subscription.periodType,
            Icons.repeat,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            'Store',
            subscription.store,
            Icons.store,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            'Auto-Renew',
            subscription.willRenew ? 'Yes' : 'No',
            subscription.willRenew ? Icons.autorenew : Icons.cancel,
          ),
          if (subscription.isSandbox) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  LocalizedText('Sandbox Environment',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.r,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        SizedBox(width: 12.w),
        LocalizedText(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        LocalizedText(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAllSubscriptionsSection(
    BuildContext context,
    List<SubscriptionInfo> subscriptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('All Active Subscriptions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12.h),
        ...subscriptions.map((subscription) => _buildSubscriptionCard(
              context,
              subscription,
            )),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionInfo subscription,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subscriptions,
                color: const Color(0xFF1D4ED8),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: LocalizedText(
                  subscription.productIdentifier,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: subscription.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: LocalizedText(
                  subscription.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: subscription.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Entitlement', subscription.identifier),
          if (subscription.purchaseDate != null)
            _buildDetailRow(
              'Purchase Date',
              dateFormat.format(subscription.purchaseDate!),
            ),
          if (subscription.expirationDate != null)
            _buildDetailRow(
              'Expiration Date',
              dateFormat.format(subscription.expirationDate!),
            ),
          _buildDetailRow('Store', subscription.store),
          _buildDetailRow('Period', subscription.periodType),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LocalizedText(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          LocalizedText(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(
    BuildContext context,
    SubscriptionDetails details,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                color: const Color(0xFF1D4ED8),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              LocalizedText('Account Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('User ID', details.originalAppUserId),
          _buildDetailRow(
            'First Seen',
            dateFormat.format(details.firstSeen),
          ),
          _buildDetailRow(
            'Last Updated',
            dateFormat.format(details.requestDate),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(
    BuildContext context,
    List<TransactionInfo> transactions,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: const Color(0xFF1D4ED8),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              LocalizedText('Transaction History',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...transactions.map((transaction) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      transaction.productIdentifier,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    LocalizedText('Date: ${dateFormat.format(transaction.purchaseDate)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    LocalizedText('Transaction ID: ${transaction.transactionIdentifier}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildManagementActions(
    BuildContext context,
    SubscriptionDetails details,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: const Color(0xFF1D4ED8),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              LocalizedText('Manage Subscription',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (details.managementURL != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(details.managementURL!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText('Could not open management URL'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const LocalizedText('Open Subscription Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context
                    .read<SubscriptionManagementBloc>()
                    .add(const RefreshSubscriptionDetails());
              },
              icon: const Icon(Icons.refresh),
              label: const LocalizedText('Refresh Subscription Info'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                side: const BorderSide(color: Color(0xFF1D4ED8)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('Restoring purchases...'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );

                  // Restore purchases
                  final restoredInfo =
                      await SubscriptionService.restorePurchases();

                  if (context.mounted) {
                    if (restoredInfo != null &&
                        restoredInfo.entitlements.active.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: LocalizedText('Purchases restored! Found ${restoredInfo.entitlements.active.length} active subscription(s)'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      // Reload subscription details
                      context.read<SubscriptionManagementBloc>().add(
                            const RefreshSubscriptionDetails(),
                          );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText('No purchases found to restore'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('No user logged in'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.restore),
              label: const LocalizedText('Restore Purchases'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  context.read<SubscriptionManagementBloc>().add(
                        TestSubscriptionRestore(user.uid),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const LocalizedText('Testing subscription restore... Check logs for details'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('No user logged in'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const LocalizedText('Test Subscription Restore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
