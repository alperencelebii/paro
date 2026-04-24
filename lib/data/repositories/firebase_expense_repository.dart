import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/expense_model.dart';
import 'expense_repository.dart';

/// Firebase implementation of ExpenseRepository
class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  /// Constructor taking FirebaseFirestore and FirebaseAuth instances
  FirebaseExpenseRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  /// Collection reference for expenses
  CollectionReference<Map<String, dynamic>> get _expensesCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('expenses');
  }

  Stream<List<Expense>> getExpensesStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _expensesCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => _expenseFromFirestore(doc.data(), doc.id))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot =
          await _expensesCollection.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => _expenseFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    try {
      final doc = await _expensesCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Expense not found: $id');
      }
      return _expenseFromFirestore(doc.data()!, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      await _expensesCollection
          .doc(expense.uuid)
          .set(_expenseToFirestore(expense));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesCollection
          .doc(expense.uuid)
          .update(_expenseToFirestore(expense));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String uuid) async {
    try {
      await _expensesCollection.doc(uuid).delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _expensesCollection
          .where('category_index', isEqualTo: category.index)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _expenseFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot =
          await _expensesCollection.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => _expenseFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    // Nothing to dispose
  }

  /// Convert Expense object to Firestore document data
  Map<String, dynamic> _expenseToFirestore(Expense expense) {
    return {
      'uuid': expense.uuid,
      'title': expense.title,
      'amount': expense.amount,
      'date': Timestamp.fromDate(expense.date),
      'category_index': expense.categoryIndex,
      'notes': expense.notes,
      'payment_method': expense.paymentMethod,
      'created_at': Timestamp.fromDate(expense.createdAt),
      // Optional custom category fields
      'customCategoryUuid': expense.customCategoryUuid,
      'customCategoryName': expense.customCategoryName,
      'customCategoryColorValue': expense.customCategoryColorValue,
      'customCategoryIconCodePoint': expense.customCategoryIconCodePoint,
      'customCategoryIconFontFamily': expense.customCategoryIconFontFamily,
    };
  }

  /// Create Expense object from Firestore document data
  Expense _expenseFromFirestore(Map<String, dynamic> data, String docId) {
    final expense = Expense();
    expense.uuid = data['uuid'] as String;
    expense.title = data['title'] as String;
    expense.amount = (data['amount'] as num).toDouble();
    expense.date = (data['date'] as Timestamp).toDate();
    expense.categoryIndex = data['category_index'] as int;
    expense.notes = data['notes'] as String?;
    expense.paymentMethod = data['payment_method'] as String;

    // Handle created_at field which might be missing in older records
    if (data.containsKey('created_at')) {
      expense.createdAt = (data['created_at'] as Timestamp).toDate();
    } else {
      expense.createdAt = DateTime.now();
    }

    // Optional custom category fields
    expense.customCategoryUuid = data['customCategoryUuid'] as String?;
    expense.customCategoryName = data['customCategoryName'] as String?;
    expense.customCategoryColorValue =
        (data['customCategoryColorValue'] as int?);
    expense.customCategoryIconCodePoint =
        (data['customCategoryIconCodePoint'] as int?);
    expense.customCategoryIconFontFamily =
        data['customCategoryIconFontFamily'] as String?;

    return expense;
  }
}
