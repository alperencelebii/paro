import 'package:finance_track/data/models/budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../objectbox.g.dart'; // This will be generated after running build_runner
import 'models/expense_model.dart';
import 'models/income_model.dart';
import 'models/user_category_model.dart';

/// Provides access to the ObjectBox Store throughout the app
class ObjectBox {
  /// Singleton instance
  static late ObjectBox instance;

  /// Flag to track if initialization is complete
  static bool _initialized = false;

  /// The Store of this app
  late final Store _store;

  /// The Box for Expense objects
  late final Box<Expense> expenseBox;
  late final Box<Budget> budgetBox;

  /// The Box for Income objects
  late final Box<Income> incomeBox;

  /// The Box for UserCategory objects
  late final Box<UserCategory> categoryBox;

  /// Create a new instance of ObjectBox
  ObjectBox._create(this._store) {
    expenseBox = _store.box<Expense>();
    incomeBox = _store.box<Income>();
    budgetBox = _store.box<Budget>();
    categoryBox = _store.box<UserCategory>();
    // Optional: Log the model for debugging
    if (kDebugMode) {
      print('ObjectBox initialized successfully');
    }
  }

  /// Initialize the singleton instance
  static Future<void> initialize() async {
    if (_initialized) return;

    instance = await create();
    _initialized = true;

    if (kDebugMode) {
      print('ObjectBox singleton initialized');
    }
  }

  /// Create an instance of ObjectBox
  static Future<ObjectBox> create() async {
    try {
      // Get a suitable directory for storing the database files
      final docsDir = await getApplicationDocumentsDirectory();

      // Create a directory for our database files
      final dbDir = p.join(docsDir.path, "objectbox");

      // Create the store using the generated function
      final store = await openStore(directory: dbDir);

      return ObjectBox._create(store);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing ObjectBox: $e');
      }
      // If there is a schema mismatch (often happens in dev when model changed),
      // clear the local DB and try again. WARNING: this wipes local data.
      final isSchemaError = e.toString().contains("SchemaException") ||
          e.toString().contains("DB's last entity ID") ||
          e.toString().contains('Unknown entity');
      if (isSchemaError) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final dbDir = p.join(docsDir.path, "objectbox");
          final dir = Directory(dbDir);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
          if (kDebugMode) {
            print(
                'Cleared ObjectBox directory due to schema mismatch. Retrying...');
          }
          final store = await openStore(directory: dbDir);
          return ObjectBox._create(store);
        } catch (e2) {
          if (kDebugMode) {
            print('Retry after clearing ObjectBox failed: $e2');
          }
        }
      }
      rethrow; // Rethrow if not recoverable
    }
  }

  /// Check if ObjectBox is initialized
  static bool get isInitialized => _initialized;

  /// Close the store when the app is shut down
  void dispose() {
    _store.close();
    _initialized = false;
  }
}
