import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/budget_model.dart';

/// Firebase implementation for Budget persistence
class FirebaseBudgetRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  FirebaseBudgetRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _budgetsCol {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('budgets');
  }

  Future<List<Budget>> getAll() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snap = await _budgetsCol.orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => _fromMap(d.data(), d.id)).toList();
  }

  Future<void> upsert(Budget b) async {
    await _budgetsCol.doc(b.uuid).set(_toMap(b), SetOptions(merge: true));
  }

  Future<void> remove(String uuid) async {
    await _budgetsCol.doc(uuid).delete();
  }

  Budget _fromMap(Map<String, dynamic> map, String id) {
    final budget = Budget()
      ..uuid = id
      ..title = (map['title'] as String?) ?? ''
      ..amount = (map['amount'] as num).toDouble()
      ..periodIndex = (map['periodIndex'] as num).toInt()
      ..startDate = (map['startDate'] as Timestamp).toDate()
      ..endDate = (map['endDate'] as Timestamp).toDate()
      ..createdAt = (map['createdAt'] as Timestamp).toDate()
      ..updatedAt = (map['updatedAt'] as Timestamp).toDate()
      ..isActive = (map['isActive'] as bool?) ?? false;
    return budget;
  }

  Map<String, dynamic> _toMap(Budget b) => {
        'title': b.title,
        'amount': b.amount,
        'periodIndex': b.periodIndex,
        'startDate': Timestamp.fromDate(b.startDate),
        'endDate': Timestamp.fromDate(b.endDate),
        'createdAt': Timestamp.fromDate(b.createdAt),
        'updatedAt': Timestamp.fromDate(b.updatedAt),
        'isActive': b.isActive,
      };
}
