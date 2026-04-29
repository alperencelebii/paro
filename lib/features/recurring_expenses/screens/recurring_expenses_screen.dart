
import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/localization/localization.dart';
import 'package:finance_track/core/utils/currency_formatter.dart';
import 'package:finance_track/core/widgets/paro_empty_state.dart';
import 'package:finance_track/features/recurring_expenses/models/recurring_expense_model.dart';
import 'package:finance_track/features/recurring_expenses/services/recurring_expense_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  final RecurringExpenseService _service = RecurringExpenseService();
  late Future<List<RecurringExpenseModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getRecurringExpenses();
  }

  void _reload() {
    setState(() {
      _future = _service.getRecurringExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Tekrarlayan Giderler'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const LocalizedText('Ekle'),
      ),
      body: FutureBuilder<List<RecurringExpenseModel>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <RecurringExpenseModel>[];
          final monthlyTotal = items
              .where((item) => item.isActive)
              .fold<double>(0, (sum, item) => sum + item.monthlyEstimate);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.repeat_rounded,
                          color: Colors.white,
                          size: 28.r,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              'Aylık tahmini yük',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              CurrencyFormatter.format(monthlyTotal, currency),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                if (items.isEmpty)
                  ParoEmptyState(
                    icon: Icons.subscriptions_rounded,
                    title: 'Tekrarlayan gider yok',
                    subtitle:
                        'Netflix, Spotify, kira veya aidat gibi tekrar eden ödemelerini ekle.',
                    actionLabel: 'İlk gideri ekle',
                    onAction: () => _showEditor(context),
                  )
                else ...[
                  Text(
                    'Yaklaşan ödemeler',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...items.map((item) {
                    return _RecurringExpenseTile(
                      item: item,
                      amount: CurrencyFormatter.format(item.amount, currency),
                      monthlyAmount:
                          CurrencyFormatter.format(item.monthlyEstimate, currency),
                      onToggle: (value) async {
                        await _service.updateRecurringExpense(
                          item.copyWith(isActive: value),
                        );
                        _reload();
                      },
                      onEdit: () => _showEditor(context, item: item),
                      onDelete: () async {
                        await _service.deleteRecurringExpense(item.id);
                        _reload();
                      },
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context, {
    RecurringExpenseModel? item,
  }) async {
    final titleController = TextEditingController(text: item?.title ?? '');
    final amountController = TextEditingController(
      text: item == null ? '' : item.amount.toStringAsFixed(2),
    );
    final categoryController =
        TextEditingController(text: item?.category ?? 'Subscription');
    String frequency = item?.frequency ?? 'Monthly';
    DateTime nextDate = item?.nextPaymentDate ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 18.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    LocalizedText(
                      item == null ? 'Tekrarlayan gider ekle' : 'Gideri düzenle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 18.h),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        prefixIcon: Icon(Icons.edit_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        prefixIcon: Icon(Icons.payments_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(
                        labelText: 'Sıklık',
                        prefixIcon: Icon(Icons.repeat_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Weekly', child: Text('Haftalık')),
                        DropdownMenuItem(value: 'Monthly', child: Text('Aylık')),
                        DropdownMenuItem(value: 'Yearly', child: Text('Yıllık')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => frequency = value);
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_rounded),
                      title: const LocalizedText('Sonraki ödeme tarihi'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(nextDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSheetState(() => nextDate = picked);
                        }
                      },
                    ),
                    SizedBox(height: 18.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(
                            amountController.text.replaceAll(',', '.'),
                          );
                          if (titleController.text.trim().isEmpty ||
                              amount == null ||
                              amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: LocalizedText('Lütfen geçerli bilgi gir.'),
                              ),
                            );
                            return;
                          }

                          if (item == null) {
                            await _service.addRecurringExpense(
                              title: titleController.text,
                              amount: amount,
                              frequency: frequency,
                              nextPaymentDate: nextDate,
                              category: categoryController.text,
                            );
                          } else {
                            await _service.updateRecurringExpense(
                              item.copyWith(
                                title: titleController.text.trim(),
                                amount: amount,
                                frequency: frequency,
                                nextPaymentDate: nextDate,
                                category: categoryController.text.trim(),
                              ),
                            );
                          }

                          if (mounted) {
                            Navigator.of(sheetContext).pop();
                            _reload();
                          }
                        },
                        child: LocalizedText(item == null ? 'Kaydet' : 'Güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecurringExpenseTile extends StatelessWidget {
  const _RecurringExpenseTile({
    required this.item,
    required this.amount,
    required this.monthlyAmount,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpenseModel item;
  final String amount;
  final String monthlyAmount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = item.daysUntilDue < 0
        ? 'geçti'
        : item.daysUntilDue == 0
            ? 'bugün'
            : '${item.daysUntilDue} gün';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.subscriptions_rounded,
              color: AppColors.primary,
              size: 24.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$amount • ${item.frequency} • $dueText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Aylık etki: $monthlyAmount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle') onToggle(!item.isActive);
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(item.isActive ? 'Pasifleştir' : 'Aktifleştir'),
              ),
              const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
              const PopupMenuItem(value: 'delete', child: Text('Sil')),
            ],
          ),
        ],
      ),
    );
  }
}
