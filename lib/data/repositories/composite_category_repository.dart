import 'dart:async';

import '../models/user_category_model.dart';
import 'category_repository.dart';
import 'objectbox_category_repository.dart';
import 'firebase_category_repository.dart';
import '../../core/services/sync_service.dart';

class CompositeCategoryRepository implements CategoryRepository {
  final ObjectBoxCategoryRepository _local;
  final FirebaseCategoryRepository _cloud;
  final SyncService _syncService;

  CompositeCategoryRepository({
    required ObjectBoxCategoryRepository local,
    required FirebaseCategoryRepository cloud,
  })  : _local = local,
        _cloud = cloud,
        _syncService = SyncService.instance;

  @override
  Future<List<UserCategory>> getAllCategories({CategoryType? type}) async {
    // Always return local first for responsiveness
    final local = await _local.getAllCategories(type: type);
    // Hydrate local from cloud when online (no unnecessary writes on every call)
    if (_syncService.isOnline) {
      try {
        final remote = await _cloud.getAllCategories(type: type);
        // Upsert remote into local if needed; prevent duplicates by uuid
        for (final c in remote) {
          await _local.upsert(c);
        }
        return _local.getAllCategories(type: type);
      } catch (_) {
        // Ignore cloud failures; fall back to local
      }
    }
    return local;
  }

  @override
  Stream<List<UserCategory>> watchCategories({CategoryType? type}) {
    // Watch local box; separate load() will hydrate once from cloud
    return _local.watchCategories(type: type);
  }

  @override
  Future<UserCategory> getById(String uuid) async {
    try {
      return await _local.getById(uuid);
    } catch (e) {
      if (_syncService.isOnline) {
        final remote = await _cloud.getById(uuid);
        await _local.upsert(remote);
        return remote;
      }
      rethrow;
    }
  }

  @override
  Future<void> upsert(UserCategory category) async {
    await _local.upsert(category.copyWith(updatedAt: DateTime.now()));
    if (_syncService.isOnline) {
      try {
        await _cloud.upsert(category);
      } catch (_) {
        // Ignore; will be handled by manual sync later if needed
      }
    }
  }

  @override
  Future<void> softDelete(String uuid) async {
    await _local.softDelete(uuid);
    if (_syncService.isOnline) {
      try {
        await _cloud.softDelete(uuid);
      } catch (_) {}
    }
  }
}
