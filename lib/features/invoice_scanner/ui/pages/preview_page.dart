import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/scanner_bloc.dart';
import '../../bloc/scanner_event.dart';
import '../../bloc/scanner_state.dart';
import '../../data/models/invoice_model.dart';
import '../widgets/field_chip.dart';
import '../../../expense_list/screens/add_expense_bottom_sheet.dart';
import '../../../expense_list/add_expense_bloc/add_expense_bloc.dart';
import '../../../expense_list/add_expense_bloc/add_expense_event.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../core/router/app_router.dart';

/// Page for previewing parsed invoice data and editing before saving
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerSaved) {
          if (state.success) {
            context.go(AppPaths.home);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save: ${state.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Invoice'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<ScannerBloc>().add(const CancelScan());
                context.go(AppPaths.home);
              },
            ),
          ],
        ),
        body: BlocBuilder<ScannerBloc, ScannerState>(
          builder: (context, state) {
            if (state is ScannerProcessing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.progress != null)
                      CircularProgressIndicator(value: state.progress),
                    if (state.progress == null)
                      const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(state.message ?? 'Processing...'),
                  ],
                ),
              );
            }

            if (state is ScannerParsed) {
              return _buildPreviewContent(context, state.invoice);
            }

            if (state is ScannerError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ScannerBloc>().add(const RetryScan());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('No data to display'));
          },
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (invoice.imagePath != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(invoice.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.receipt_long, size: 64),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Parsed fields
          Text(
            'Parsed Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Merchant
          FieldChip(
            label: 'Merchant',
            value: invoice.merchant,
            confidence: invoice.getFieldConfidence('merchant'),
            isLowConfidence: invoice.isLowConfidence('merchant'),
            onTap: () => _editField(context, 'merchant', invoice.merchant),
          ),
          const SizedBox(height: 12),

          // Date
          FieldChip(
            label: 'Date',
            value: invoice.date != null
                ? DateFormat('MMM dd, yyyy').format(invoice.date!)
                : 'Not found',
            confidence: invoice.getFieldConfidence('date'),
            isLowConfidence: invoice.isLowConfidence('date'),
            onTap: invoice.date != null
                ? () => _editDate(context, invoice.date!)
                : null,
          ),
          const SizedBox(height: 12),

          // Total
          FieldChip(
            label: 'Total',
            value: invoice.total != null
                ? '${invoice.currency} ${invoice.total!.toStringAsFixed(2)}'
                : 'Not found',
            confidence: invoice.getFieldConfidence('total'),
            isLowConfidence: invoice.isLowConfidence('total'),
            onTap: invoice.total != null
                ? () => _editAmount(context, invoice.total!)
                : null,
          ),
          const SizedBox(height: 12),

          // Tax
          if (invoice.tax != null)
            FieldChip(
              label: 'Tax',
              value: '${invoice.currency} ${invoice.tax!.toStringAsFixed(2)}',
              confidence: invoice.getFieldConfidence('tax'),
              isLowConfidence: invoice.isLowConfidence('tax'),
            ),
          if (invoice.tax != null) const SizedBox(height: 12),

          // Invoice Number
          if (invoice.invoiceNumber != null)
            FieldChip(
              label: 'Invoice #',
              value: invoice.invoiceNumber!,
              confidence: invoice.getFieldConfidence('invoiceNumber'),
              isLowConfidence: invoice.isLowConfidence('invoiceNumber'),
            ),
          if (invoice.invoiceNumber != null) const SizedBox(height: 24),

          // Warning for low confidence fields
          if (invoice.confidence.values.any((c) => c < 0.70))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some fields have low confidence. Please verify before saving.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Save button - show review bottom sheet
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showReviewBottomSheet(context, invoice);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Review & Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Alternative: Save directly
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<ScannerBloc>().add(const SaveInvoice());
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Directly'),
            ),
          ),
        ],
      ),
    );
  }

  void _editField(BuildContext context, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScannerBloc>().add(
                    FieldEdited(
                      fieldKey: field,
                      newValue: controller.text,
                    ),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDate(BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      context.read<ScannerBloc>().add(
            FieldEdited(
              fieldKey: 'date',
              newValue: picked,
            ),
          );
    }
  }

  void _editAmount(BuildContext context, double currentAmount) {
    final controller = TextEditingController(
      text: currentAmount.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                context.read<ScannerBloc>().add(
                      FieldEdited(
                        fieldKey: 'total',
                        newValue: value,
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context, InvoiceModel invoice) {
    // Get the expense repository
    final expenseRepository = RepositoryProvider.of<ExpenseRepository>(context);
    final expenseBloc = AddExpenseBloc(expenseRepository);

    // Pre-fill the expense bloc with invoice data
    if (invoice.total != null) {
      expenseBloc.add(UpdateAmount(invoice.total!));
    }
    if (invoice.date != null) {
      expenseBloc.add(UpdateDate(invoice.date!));
    }
    
    // Use merchant as notes (which will become title)
    final notes = invoice.invoiceNumber != null
        ? '${invoice.merchant}\nInvoice #${invoice.invoiceNumber}'
        : invoice.merchant;
    expenseBloc.add(UpdateNotes(notes));

    // Show the existing expense bottom sheet
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BlocProvider<AddExpenseBloc>.value(
        value: expenseBloc,
        child: const AddExpenseBottomSheet(),
      ),
    ).then((result) {
      expenseBloc.close();
      if (result == true) {
        // Expense was saved successfully
        if (context.mounted) {
          // Close scanner flow
          context.read<ScannerBloc>().add(const CancelScan());
          // Navigate back to home
          context.go(AppPaths.home);
        }
      }
    });
  }
}
