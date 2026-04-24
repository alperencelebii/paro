import '../models/user_category_model.dart';

abstract class CategoryRepository {
  Future<List<UserCategory>> getAllCategories({CategoryType? type});
  Stream<List<UserCategory>> watchCategories({CategoryType? type});
  Future<UserCategory> getById(String uuid);
  Future<void> upsert(UserCategory category);
  Future<void> softDelete(String uuid);
}


