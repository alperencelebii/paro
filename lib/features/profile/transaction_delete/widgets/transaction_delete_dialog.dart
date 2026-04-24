// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/router/app_router.dart';
import '../bloc/transaction_delete_bloc.dart';
import '../bloc/transaction_delete_event.dart';
import '../bloc/transaction_delete_state.dart';

/// Dialog for confirming and displaying transaction deletion process
class TransactionDeleteDialog extends StatelessWidget {
  const TransactionDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionDeleteBloc, TransactionDeleteState>(
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            // Prevent back button during deletion process
            if (state.status == TransactionDeleteStatus.deleting ||
                state.status == TransactionDeleteStatus.restarting) {
              return false;
            }
            // Allow back button otherwise
            context.read<TransactionDeleteBloc>().add(const CancelDeletion());
            return true;
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildDialogContent(context, state),
          ),
        );
      },
    );
  }

  /// Build the appropriate dialog content based on the current state
  Widget _buildDialogContent(
      BuildContext context, TransactionDeleteState state) {
    switch (state.status) {
      case TransactionDeleteStatus.confirmingDelete:
        return _buildConfirmationContent(context);
      case TransactionDeleteStatus.deleting:
        return _buildDeletingContent(context, state);
      case TransactionDeleteStatus.deleted:
        return _buildSuccessContent(context);
      case TransactionDeleteStatus.error:
        return _buildErrorContent(context, state);
      case TransactionDeleteStatus.restarting:
        return _buildRestartingContent(context);
      case TransactionDeleteStatus.initial:

        // This should not happen, but just in case
        return const SizedBox.shrink();
    }
  }

  /// Build confirmation dialog content
  Widget _buildConfirmationContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Delete All Transactions?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'This will permanently delete all your expenses and incomes from both your device and the cloud. This action cannot be undone.',
            style: TextStyle(fontSize: 15.sp),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  context
                      .read<TransactionDeleteBloc>()
                      .add(const CancelDeletion());
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                icon: const Icon(Icons.delete_forever),
                label: Text(
                  'Delete All',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  context
                      .read<TransactionDeleteBloc>()
                      .add(const ConfirmDeletion());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build deleting content with progress indicators
  Widget _buildDeletingContent(
      BuildContext context, TransactionDeleteState state) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.delete_sweep,
                color: Theme.of(context).colorScheme.primary,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Deleting Transactions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 50.h,
            width: 50.h,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              strokeWidth: 4.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            state.progressMessage,
            style: TextStyle(fontSize: 15.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          _buildProgressIndicator(context, state),
          SizedBox(height: 8.h),
          Text(
            '${state.progressPercentage}%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildDeletionStatusIndicators(context, state),
        ],
      ),
    );
  }

  /// Build linear progress indicator with percentage
  Widget _buildProgressIndicator(
      BuildContext context, TransactionDeleteState state) {
    return Container(
      height: 10.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * (state.progressPercentage / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5.r),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build deletion status indicators (local and cloud)
  Widget _buildDeletionStatusIndicators(
      BuildContext context, TransactionDeleteState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusItem(
          context: context,
          title: 'Local',
          isComplete: state.localDeleted,
        ),
        Container(
          height: 32.h,
          width: 1,
          color: Colors.grey[300],
          margin: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        _buildStatusItem(
          context: context,
          title: 'Cloud',
          isComplete: state.cloudDeleted,
        ),
      ],
    );
  }

  /// Build individual status item
  Widget _buildStatusItem({
    required BuildContext context,
    required String title,
    required bool isComplete,
  }) {
    return Row(
      children: [
        isComplete
            ? Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20.r,
              )
            : Icon(
                Icons.pending_outlined,
                color: Colors.grey,
                size: 20.r,
              ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: isComplete ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build success content
  Widget _buildSuccessContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Successfully Deleted',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'All your transactions have been permanently deleted from both local storage and cloud.',
            style: TextStyle(fontSize: 15.sp),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade800,
                  size: 24.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'To ensure all data is properly refreshed, restarting the app is recommended.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Show success snackbar BEFORE popping the dialog to avoid
                  // accessing a deactivated context
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          SizedBox(width: 8.w),
                          const Expanded(
                            child:
                                Text('All transactions deleted successfully'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      margin: EdgeInsets.all(16.r),
                    ),
                  );

                  context
                      .read<TransactionDeleteBloc>()
                      .add(const ContinueWithoutRestart());
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Continue Without Restart',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Restart Now',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  context.read<TransactionDeleteBloc>().add(const RestartApp());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build error content
  Widget _buildErrorContent(
      BuildContext context, TransactionDeleteState state) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Error Deleting Transactions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'We encountered a problem while deleting your transactions:',
            style: TextStyle(fontSize: 15.sp),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    state.errorMessage ?? 'Unknown error',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onPressed: () {
                context
                    .read<TransactionDeleteBloc>()
                    .add(const AcknowledgeError());
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build restarting content
  Widget _buildRestartingContent(BuildContext context) {
    // Perform the actual restart after showing this dialog
    _performAppRestart(context);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50.h,
            width: 50.h,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              strokeWidth: 4.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Restarting app...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait while the app restarts',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Perform the actual app restart
  void _performAppRestart(BuildContext context) {
    // Add a small delay to show the restart dialog before actual restart
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) {
        // Logout and clear session to effectively "restart" the app
        context.read<AppBloc>().add(const AppLogoutRequested());
        context.read<AppBloc>().add(const AppSetFirstTime(isFirstTime: false));

        // Navigate to splash screen
        context.go(AppPaths.splash);
      }
    });
  }
}
