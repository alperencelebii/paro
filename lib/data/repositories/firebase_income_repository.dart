import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/income_model.dart';
import 'income_repository.dart';

/// Firebase implementation of IncomeRepository
class FirebaseIncomeRepository implements IncomeRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  /// Constructor taking FirebaseFirestore and FirebaseAuth instances
  FirebaseIncomeRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  /// Collection reference for incomes
  CollectionReference<Map<String, dynamic>> get _incomesCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('incomes');
  }

  @override
  Stream<List<Income>> getIncomesStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _incomesCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => _incomeFromFirestore(doc.data(), doc.id))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<Income>> getIncomes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot =
          await _incomesCollection.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => _incomeFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Income> getIncomeById(String id) async {
    try {
      final doc = await _incomesCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Income not found: $id');
      }
      return _incomeFromFirestore(doc.data()!, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addIncome(Income income) async {
    try {
      await _incomesCollection.doc(income.uuid).set(_incomeToFirestore(income));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateIncome(Income income) async {
    try {
      await _incomesCollection
          .doc(income.uuid)
          .update(_incomeToFirestore(income));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String uuid) async {
    try {
      await _incomesCollection.doc(uuid).delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncomesByCategory(IncomeCategory category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _incomesCollection
          .where('category_index', isEqualTo: category.index)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _incomeFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Income>> getAllIncomes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot =
          await _incomesCollection.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => _incomeFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    // Nothing to dispose
  }

  /// Convert Income object to Firestore document data
  Map<String, dynamic> _incomeToFirestore(Income income) {
    return {
      'uuid': income.uuid,
      'title': income.title,
      'amount': income.amount,
      'date': Timestamp.fromDate(income.date),
      'category_index': income.categoryIndex,
      'notes': income.notes,
      'source': income.source,
      'created_at': Timestamp.fromDate(income.createdAt),
    };
  }

  /// Create Income object from Firestore document data
  Income _incomeFromFirestore(Map<String, dynamic> data, String docId) {
    final income = Income();
    income.uuid = data['uuid'] as String;
    income.title = data['title'] as String;
    income.amount = (data['amount'] as num).toDouble();
    income.date = (data['date'] as Timestamp).toDate();
    income.categoryIndex = data['category_index'] as int;
    income.notes = data['notes'] as String?;
    income.source = data['source'] as String;

    // Handle created_at field which might be missing in older records
    if (data.containsKey('created_at')) {
      income.createdAt = (data['created_at'] as Timestamp).toDate();
    } else {
      income.createdAt = DateTime.now();
    }

    return income;
  }
}
