import 'package:finance_track/data/models/user_category_model.dart';
import 'package:finance_track/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'manage_categories_cubit.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ManageCategoriesCubit(context.read<CategoryRepository>())..load(),
      child: Builder(
        builder: (context) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('My Categories'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                centerTitle: true,
                bottom: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.6),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14.sp,
                  ),
                  tabs: const [
                    Tab(text: 'Expense'),
                    Tab(text: 'Income'),
                  ],
                ),
              ),
              floatingActionButton: Builder(
                builder: (innerCtx) {
                  return FloatingActionButton.extended(
                    onPressed: () async {
                      final idx = DefaultTabController.of(innerCtx).index;
                      final created = await _showBottomSheet(
                        innerCtx,
                        existing: UserCategory.create(
                          uuid:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: '',
                          type: idx == 0
                              ? CategoryType.expense
                              : CategoryType.income,
                          colorValue: Colors.blueGrey.value,
                        ),
                      );
                      if (created != null) {
                        await innerCtx
                            .read<ManageCategoriesCubit>()
                            .upsert(created);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  );
                },
              ),
              body: const _CategoriesBody(),
            ),
          );
        },
      ),
    );
  }

  Future<UserCategory?> _showBottomSheet(BuildContext context,
      {UserCategory? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    CategoryType type = existing?.type ??
        (DefaultTabController.of(context).index == 0
            ? CategoryType.expense
            : CategoryType.income);
    final colors = <Color>[
      Colors.redAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.teal,
      Colors.amber,
      Colors.blueGrey,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.indigo,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.grey,
    ];
    Color selectedColor = existing?.color ?? colors.first;
    final allIcons = <IconData>[
      Icons.restaurant,
      Icons.directions_car,
      Icons.movie,
      Icons.home,
      Icons.shopping_bag,
      Icons.medical_services,
      Icons.school,
      Icons.flight,
      Icons.category,
      Icons.coffee,
      Icons.local_pizza,
      Icons.fastfood,
      Icons.lunch_dining,
      Icons.icecream,
      Icons.local_gas_station,
      Icons.train,
      Icons.directions_bus,
      Icons.directions_bike,
      Icons.pedal_bike,
      Icons.sports_esports,
      Icons.music_note,
      Icons.theaters,
      Icons.tv,
      Icons.devices,
      Icons.phone_iphone,
      Icons.electric_bolt,
      Icons.water_drop,
      Icons.wifi,
      Icons.home_work,
      Icons.shopping_cart,
      Icons.shopping_basket,
      Icons.store,
      Icons.health_and_safety,
      Icons.monitor_heart,
      Icons.healing,
      Icons.book,
      Icons.menu_book,
      Icons.cast_for_education,
      Icons.work,
      Icons.payments,
      Icons.attach_money,
      Icons.savings,
      Icons.card_giftcard,
      Icons.pets,
      Icons.baby_changing_station,
      Icons.cleaning_services,
      Icons.construction,
      Icons.handyman,
      Icons.fitness_center,
      Icons.sports_soccer,
      Icons.spa,
      Icons.airplanemode_active,
      Icons.beach_access,
      Icons.local_taxi,
      Icons.park,
      Icons.kitchen,
      Icons.local_florist,
    ];
    IconData? selectedIcon = existing?.icon ?? allIcons.first;

    final result = await showModalBottomSheet<UserCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Create Category' : 'Edit Category',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Text('Type', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: type == CategoryType.expense,
                          onSelected: (_) =>
                              setState(() => type = CategoryType.expense),
                        ),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: type == CategoryType.income,
                          onSelected: (_) =>
                              setState(() => type = CategoryType.income),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Color', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 96,
                      child: GridView.count(
                        crossAxisCount: 8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: colors
                            .map((c) => GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedColor = c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c,
                                      border: Border.all(
                                        color: selectedColor == c
                                            ? Theme.of(ctx)
                                                .colorScheme
                                                .onSurface
                                            : c,
                                        width: selectedColor == c ? 2 : 0,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Icon', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: GridView.count(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: allIcons
                            .map((ic) => InkWell(
                                  borderRadius: BorderRadius.circular(12).r,
                                  onTap: () =>
                                      setState(() => selectedIcon = ic),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(12).r,
                                      border: Border.all(
                                        color: selectedIcon == ic
                                            ? Theme.of(ctx).colorScheme.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      ic,
                                      color: selectedIcon == ic
                                          ? Theme.of(ctx).colorScheme.primary
                                          : Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final uuid = existing?.uuid ??
                              DateTime.now().millisecondsSinceEpoch.toString();
                          Navigator.pop(
                            ctx,
                            UserCategory.create(
                              id: existing?.id,
                              uuid: uuid,
                              name: name,
                              type: type,
                              iconCodePoint: selectedIcon?.codePoint,
                              iconFontFamily:
                                  selectedIcon == null ? null : 'MaterialIcons',
                              colorValue: selectedColor.value,
                              isDeleted: false,
                              createdAt: existing?.createdAt,
                              updatedAt: DateTime.now(),
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }
}

class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManageCategoriesCubit, ManageCategoriesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          children: [
            _CategoryList(items: state.expenseCategories),
            _CategoryList(items: state.incomeCategories),
          ],
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<UserCategory> items;
  const _CategoryList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No categories'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 200),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final c = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: ListTile(
            tileColor: Theme.of(context).colorScheme.onSurface.withAlpha(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            leading: CircleAvatar(
              backgroundColor: c.color.withValues(alpha: 0.15),
              child: Icon(c.icon ?? Icons.category, color: c.color),
            ),
            title: Text(c.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              c.type == CategoryType.expense ? 'Expense' : 'Income',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                final cubit = context.read<ManageCategoriesCubit>();
                if (value == 'edit') {
                  final edited = await const ManageCategoriesScreen()
                      ._showBottomSheet(context, existing: c);
                  if (edited != null) {
                    await cubit.upsert(edited);
                  }
                } else if (value == 'delete') {
                  await cubit.delete(c.uuid);
                }
              },
              color: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.zero,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}
