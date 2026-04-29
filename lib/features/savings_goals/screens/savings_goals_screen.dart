
import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/localization/localization.dart';
import 'package:finance_track/core/utils/currency_formatter.dart';
import 'package:finance_track/core/widgets/paro_empty_state.dart';
import 'package:finance_track/features/savings_goals/models/savings_goal_model.dart';
import 'package:finance_track/features/savings_goals/services/savings_goal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final SavingsGoalService _service = SavingsGoalService();
  late Future<List<SavingsGoalModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getGoals();
  }

  void _reload() {
    setState(() {
      _future = _service.getGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Birikim Hedefleri'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const LocalizedText('Hedef'),
      ),
      body: FutureBuilder<List<SavingsGoalModel>>(
        future: _future,
        builder: (context, snapshot) {
          final goals = snapshot.data ?? const <SavingsGoalModel>[];
          final targetTotal =
              goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
          final savedTotal =
              goals.fold<double>(0, (sum, goal) => sum + goal.savedAmount);
          final totalProgress =
              targetTotal <= 0 ? 0.0 : (savedTotal / targetTotal).clamp(0.0, 1.0).toDouble();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.24),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'Toplam birikim',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        CurrencyFormatter.format(savedTotal, currency),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${CurrencyFormatter.format(targetTotal, currency)} hedefe karşılık',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: totalProgress,
                          minHeight: 9.h,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                if (goals.isEmpty)
                  ParoEmptyState(
                    icon: Icons.flag_rounded,
                    title: 'Henüz hedef yok',
                    subtitle:
                        'Telefon, tatil, acil durum fonu gibi hedeflerini ekleyip ilerlemeyi takip et.',
                    actionLabel: 'İlk hedefi oluştur',
                    onAction: () => _showGoalEditor(context),
                  )
                else ...[
                  Text(
                    'Hedeflerim',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...goals.map((goal) {
                    return _SavingsGoalCard(
                      goal: goal,
                      saved: CurrencyFormatter.format(goal.savedAmount, currency),
                      target: CurrencyFormatter.format(goal.targetAmount, currency),
                      remaining:
                          CurrencyFormatter.format(goal.remainingAmount, currency),
                      onAddMoney: () => _showAddMoneySheet(context, goal),
                      onEdit: () => _showGoalEditor(context, goal: goal),
                      onDelete: () async {
                        await _service.deleteGoal(goal.id);
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

  Future<void> _showGoalEditor(
    BuildContext context, {
    SavingsGoalModel? goal,
  }) async {
    final titleController = TextEditingController(text: goal?.title ?? '');
    final targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(2),
    );
    final savedController = TextEditingController(
      text: goal == null ? '' : goal.savedAmount.toStringAsFixed(2),
    );
    DateTime? deadline = goal?.deadline;

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
                      goal == null ? 'Hedef oluştur' : 'Hedefi düzenle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 18.h),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Hedef adı',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: targetController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Hedef tutar',
                        prefixIcon: Icon(Icons.savings_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: savedController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Şu ana kadar biriken',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_rounded),
                      title: const LocalizedText('Hedef tarihi'),
                      subtitle: Text(
                        deadline == null
                            ? 'Opsiyonel'
                            : DateFormat('dd MMM yyyy').format(deadline!),
                      ),
                      trailing: deadline == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                setSheetState(() => deadline = null);
                              },
                            ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline ??
                              DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSheetState(() => deadline = picked);
                        }
                      },
                    ),
                    SizedBox(height: 18.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final target = double.tryParse(
                            targetController.text.replaceAll(',', '.'),
                          );
                          final saved = double.tryParse(
                                savedController.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          if (titleController.text.trim().isEmpty ||
                              target == null ||
                              target <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: LocalizedText('Lütfen geçerli bilgi gir.'),
                              ),
                            );
                            return;
                          }

                          if (goal == null) {
                            await _service.addGoal(
                              title: titleController.text,
                              targetAmount: target,
                              savedAmount: saved.clamp(0.0, target).toDouble(),
                              deadline: deadline,
                            );
                          } else {
                            await _service.updateGoal(
                              goal.copyWith(
                                title: titleController.text.trim(),
                                targetAmount: target,
                                savedAmount: saved.clamp(0.0, target).toDouble(),
                                deadline: deadline,
                                clearDeadline: deadline == null,
                              ),
                            );
                          }

                          if (mounted) {
                            Navigator.of(sheetContext).pop();
                            _reload();
                          }
                        },
                        child: LocalizedText(goal == null ? 'Kaydet' : 'Güncelle'),
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

  Future<void> _showAddMoneySheet(
    BuildContext context,
    SavingsGoalModel goal,
  ) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 18.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalizedText(
                '${goal.title} için ekle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 18.h),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Eklenecek tutar',
                  prefixIcon: Icon(Icons.add_card_rounded),
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(controller.text.replaceAll(',', '.'));
                    if (amount == null || amount <= 0) return;
                    await _service.addMoney(goal.id, amount);
                    if (mounted) {
                      Navigator.of(sheetContext).pop();
                      _reload();
                    }
                  },
                  child: const LocalizedText('Ekle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.saved,
    required this.target,
    required this.remaining,
    required this.onAddMoney,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoalModel goal;
  final String saved;
  final String target;
  final String remaining;
  final VoidCallback onAddMoney;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = goal.daysRemaining;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gradientStart.withValues(alpha: 0.18),
                      AppColors.accent.withValues(alpha: 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: AppColors.accent,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      days == null
                          ? '$saved / $target'
                          : '$saved / $target • $days gün kaldı',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 9.h,
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '%${(goal.progress * 100).toStringAsFixed(0)} tamamlandı',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                'Kalan: $remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddMoney,
              icon: const Icon(Icons.add_rounded),
              label: const LocalizedText('Birikim ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
