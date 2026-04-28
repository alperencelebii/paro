import 'dart:developer' as developer;
import 'package:finance_track/data/models/budget_model.dart';
import 'package:finance_track/data/repositories/composite_budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/currency_context_extension.dart';
import '../bloc/budget_bloc/budget_bloc.dart';
import '../bloc/budget_form_bloc/budget_form_bloc.dart';
import 'package:finance_track/core/localization/localization.dart';

Future<void> budgetFormDialog(BuildContext context, {Budget? budget}) async {
  return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Capture the dialog's navigator from within the builder
        // Use the dialog context directly, not rootNavigator to avoid GoRouter conflicts
        final dialogNavigator =
            Navigator.of(dialogContext, rootNavigator: false);
        return BlocProvider(
          create: (providerContext) => BudgetFormBloc(
            budgetRepository: providerContext.read<CompositeBudgetRepository>(),
            budget: budget,
          ),
          child: _BudgetFormDialogContent(
            dialogContext: dialogContext,
            dialogNavigator: dialogNavigator,
          ),
        );
      });
}

class _BudgetFormDialogContent extends StatefulWidget {
  final BuildContext dialogContext;
  final NavigatorState dialogNavigator;
  const _BudgetFormDialogContent({
    required this.dialogContext,
    required this.dialogNavigator,
  });

  @override
  State<_BudgetFormDialogContent> createState() =>
      _BudgetFormDialogContentState();
}

class _BudgetFormDialogContentState extends State<_BudgetFormDialogContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isClosing = false;

  void _closeDialog() {
    if (_isClosing || !mounted) return;
    _isClosing = true;

    developer.log('Closing dialog using dialog navigator');
    try {
      // Use the dialog context navigator directly - this is the safe way
      if (widget.dialogContext.mounted) {
        Navigator.of(widget.dialogContext).pop();
      }
    } catch (e) {
      developer.log('Error closing dialog with context: $e');
      // Fallback: try the stored navigator
      try {
        if (widget.dialogNavigator.canPop()) {
          widget.dialogNavigator.pop();
        }
      } catch (e2) {
        developer.log('Fallback navigator close also failed: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BudgetFormBloc, BudgetFormState>(
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.submitted != current.submitted ||
          previous.errorMessage != current.errorMessage ||
          previous.budget?.id != current.budget?.id,
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520.w,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: MultiBlocListener(
              listeners: [
                // Listen for successful form submission (create/update)
                BlocListener<BudgetFormBloc, BudgetFormState>(
                  listenWhen: (previous, current) {
                    // Only trigger once when submitted becomes true
                    final shouldListen = !previous.submitted &&
                        current.submitted &&
                        !current.isLoading &&
                        current.errorMessage == null;
                    return shouldListen;
                  },
                  listener: (context, state) {
                    // Prevent multiple executions - check if already closing
                    final currentDialogState = context.findAncestorStateOfType<
                        _BudgetFormDialogContentState>();
                    if (currentDialogState?._isClosing == true) {
                      developer
                          .log('Dialog already closing, skipping listener');
                      return;
                    }

                    // Show success message
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: LocalizedText(
                            state.isEditing
                                ? 'Budget updated successfully'
                                : 'Budget created successfully',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          margin: EdgeInsets.only(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                          ),
                        ),
                      );

                    // Reload budgets (do this first before closing dialog)
                    context.read<BudgetBloc>().add(const LoadBudget());

                    // Use a slight delay to ensure the snackbar shows, then close dialog
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (!context.mounted) return;
                      final dialogState = context.findAncestorStateOfType<
                          _BudgetFormDialogContentState>();
                      if (dialogState != null &&
                          dialogState.mounted &&
                          !dialogState._isClosing) {
                        developer.log(
                            'Closing dialog after successful budget operation');
                        dialogState._closeDialog();
                      }
                    });
                  },
                ),

                // Listen for deletion success (separate, specific condition)
                BlocListener<BudgetFormBloc, BudgetFormState>(
                  listenWhen: (previous, current) =>
                      previous.isLoading &&
                      !current.isLoading &&
                      current.errorMessage == null &&
                      previous.budget?.id != null &&
                      current.budget?.id == null,
                  listener: (context, state) {
                    // Show deletion success message
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: const LocalizedText('Budget deleted successfully'),
                          backgroundColor: theme.colorScheme.tertiary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          margin: EdgeInsets.only(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                          ),
                        ),
                      );

                    // Reload budgets and navigate to list
                    context.read<BudgetBloc>().add(const LoadBudget());

                    // Small delay so the snackbar can be seen briefly, then go to list
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (!context.mounted) return;
                      final dialogState = context.findAncestorStateOfType<
                          _BudgetFormDialogContentState>();
                      if (dialogState != null &&
                          dialogState.mounted &&
                          !dialogState._isClosing) {
                        // Close dialog first
                        dialogState._closeDialog();
                        // Navigate after ensuring dialog is closed
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (context.mounted) {
                            context.goNamed(AppRoutes.budgetSettings);
                          }
                        });
                      }
                    });
                  },
                ),

                // Listen for error messages
                BlocListener<BudgetFormBloc, BudgetFormState>(
                  listenWhen: (previous, current) =>
                      current.errorMessage != null &&
                      previous.errorMessage != current.errorMessage,
                  listener: (context, state) {
                    if (state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: LocalizedText(state.errorMessage!),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          margin: EdgeInsets.only(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
              child: _buildDialogContent(context, theme, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    ThemeData theme,
    BudgetFormState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dialog Header
        Padding(
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              Expanded(
                child: LocalizedText(
                  state.isEditing ? 'Edit Budget' : 'Create Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _closeDialog,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Dialog Content
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title field
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: TextFormField(
                      controller: state.titleController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.tr('Budget Title'),
                        prefixIcon: CircleAvatar(
                          radius: 3.r,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.title,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 18.r,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter a budget title'
                          : null,
                    ),
                  ),

                  // Amount field
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: TextFormField(
                      controller: state.amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      textAlign: TextAlign.start,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.tr('Enter amount'),
                        prefixIcon: CircleAvatar(
                          radius: 3.r,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: LocalizedText(
                            context.currencySymbol,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.tr('Please enter a budget amount');
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null)
                          return AppLocalizations.tr('Please enter a valid number');
                        if (parsed <= 0) {
                          return AppLocalizations.tr('Budget amount must be greater than zero');
                        }
                        return null;
                      },
                    ),
                  ),

                  // Period info (read-only display)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 20.r,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 12.w),
                          LocalizedText('Monthly (Auto)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Dialog Actions
        Padding(
          padding: EdgeInsets.all(20.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.isEditing && state.budget?.id != null)
                TextButton(
                  onPressed: () => _showDeleteConfirmation(
                    context,
                    state.budget!.id!,
                  ),
                  child: LocalizedText('Delete',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(width: 8.w),
              TextButton(
                onPressed: _closeDialog,
                child: const LocalizedText('Cancel'),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          context
                              .read<BudgetFormBloc>()
                              .add(BudgetFormSubmitted());
                        }
                      },
                child: state.isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : LocalizedText(state.isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, int budgetId) {
    final theme = Theme.of(context);
    final dialogState =
        context.findAncestorStateOfType<_BudgetFormDialogContentState>();

    showDialog(
      context: context,
      builder: (deleteDialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: theme.colorScheme.surface,
        title: LocalizedText('Delete Budget',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        content: LocalizedText('Are you sure you want to delete this budget? This action cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(deleteDialogContext).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: LocalizedText('Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Capture dependencies before popping to avoid using a deactivated context
              final messenger = ScaffoldMessenger.of(context);
              final budgetBloc = context.read<BudgetBloc>();

              // Close the delete confirmation dialog
              Navigator.of(deleteDialogContext).pop();

              // Show loading indicator using the captured messenger
              messenger.showSnackBar(
                const SnackBar(
                  content: LocalizedText('Deleting budget...'),
                  duration: Duration(seconds: 1),
                ),
              );

              // Delete the budget using the captured bloc
              budgetBloc.add(DeleteBudget(budgetId));

              // Post-frame: reload, show success, and close dialog
              WidgetsBinding.instance.addPostFrameCallback((_) {
                budgetBloc.add(const LoadBudget());
                messenger.showSnackBar(
                  const SnackBar(
                    content: LocalizedText('Budget deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Close the budget form dialog using the captured dialog state
                if (dialogState != null && dialogState.mounted) {
                  Navigator.of(dialogState.widget.dialogContext,
                          rootNavigator: true)
                      .pop();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: LocalizedText('Delete',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
