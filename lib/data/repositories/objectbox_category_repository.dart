import '../models/user_category_model.dart';
import '../objectbox.dart';
// Avoid relying on generated query meta to keep compile green before codegen
import 'category_repository.dart';

class ObjectBoxCategoryRepository implements CategoryRepository {
  final ObjectBox _objectBox;

  ObjectBoxCategoryRepository(this._objectBox);

  @override
  Future<List<UserCategory>> getAllCategories({CategoryType? type}) async {
    final list = _objectBox.categoryBox.getAll();
    // Deduplicate by uuid to avoid duplicates from previous dev iterations
    final seen = <String>{};
    final filtered = list.where((c) {
      final pass = !seen.contains(c.uuid);
      seen.add(c.uuid);
      return pass;
    }).toList();
    return filtered
        .where((c) => c.isDeleted == false && (type == null || c.type == type))
        .toList();
  }

  @override
  Stream<List<UserCategory>> watchCategories({CategoryType? type}) {
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => getAllCategories(type: type),
    ).asyncMap((f) => f);
  }

  @override
  Future<UserCategory> getById(String uuid) async {
    final list = _objectBox.categoryBox.getAll();
    final match = list.firstWhere(
      (c) => c.uuid == uuid,
      orElse: () => throw Exception('Category not found: $uuid'),
    );
    return match;
  }

  @override
  Future<void> upsert(UserCategory category) async {
    // Find existing by uuid and preserve id
    final existing = _objectBox.categoryBox.getAll().firstWhere(
          (c) => c.uuid == category.uuid,
          orElse: () => UserCategory(),
        );
    final toSave = category.copyWith()
      ..id = existing.id ?? category.id
      ..updatedAt = DateTime.now();
    _objectBox.categoryBox.put(toSave);
  }

  @override
  Future<void> softDelete(String uuid) async {
    final list = _objectBox.categoryBox.getAll();
    for (final existing in list) {
      if (existing.uuid == uuid) {
        _objectBox.categoryBox
            .put(existing.copyWith(isDeleted: true, updatedAt: DateTime.now()));
        break;
      }
    }
  }
}
