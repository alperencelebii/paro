import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user_category_model.dart';
import 'category_repository.dart';

class FirebaseCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  FirebaseCategoryRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories');
  }

  @override
  Future<List<UserCategory>> getAllCategories({CategoryType? type}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    Query<Map<String, dynamic>> q =
        _collection.where('isDeleted', isEqualTo: false);
    if (type != null) {
      q = q.where('typeIndex', isEqualTo: type.index);
    }
    final snap = await q.get();
    return snap.docs.map((d) => _fromDoc(d.data())).toList();
  }

  @override
  Stream<List<UserCategory>> watchCategories({CategoryType? type}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query<Map<String, dynamic>> q =
        _collection.where('isDeleted', isEqualTo: false);
    if (type != null) {
      q = q.where('typeIndex', isEqualTo: type.index);
    }
    return q
        .snapshots()
        .map((s) => s.docs.map((d) => _fromDoc(d.data())).toList());
  }

  @override
  Future<UserCategory> getById(String uuid) async {
    final doc = await _collection.doc(uuid).get();
    if (!doc.exists) throw Exception('Category not found: $uuid');
    return _fromDoc(doc.data()!);
  }

  @override
  Future<void> upsert(UserCategory category) async {
    await _collection
        .doc(category.uuid)
        .set(_toDoc(category), SetOptions(merge: true));
  }

  @override
  Future<void> softDelete(String uuid) async {
    await _collection.doc(uuid).set(
        {'isDeleted': true, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  Map<String, dynamic> _toDoc(UserCategory c) => {
        'uuid': c.uuid,
        'name': c.name,
        'typeIndex': c.typeIndex,
        'iconCodePoint': c.iconCodePoint,
        'iconFontFamily': c.iconFontFamily,
        'colorValue': c.colorValue,
        'isDeleted': c.isDeleted,
        'createdAt': Timestamp.fromDate(c.createdAt),
        'updatedAt': Timestamp.fromDate(c.updatedAt),
      };

  UserCategory _fromDoc(Map<String, dynamic> m) {
    return UserCategory.create(
      uuid: m['uuid'] as String,
      name: m['name'] as String,
      type: CategoryType.values[(m['typeIndex'] as num).toInt()],
      iconCodePoint: (m['iconCodePoint'] as num?)?.toInt(),
      iconFontFamily: m['iconFontFamily'] as String?,
      colorValue: (m['colorValue'] as num).toInt(),
      isDeleted: (m['isDeleted'] as bool?) ?? false,
      createdAt: (m['createdAt'] is Timestamp)
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (m['updatedAt'] is Timestamp)
          ? (m['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
