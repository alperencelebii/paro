// ignore_for_file: use_build_context_synchronously

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories/objectbox_expense_repository.dart';
import '../../data/repositories/objectbox_income_repository.dart';
import '../app_bloc/app_bloc.dart';
import 'auth_service.dart';
import 'data_fetching_service.dart';

/// Service to handle transaction operations like fetching from Firebase and clearing data
class TransactionService {
  static final TransactionService _instance = TransactionService._internal();

  /// Singleton instance
  static TransactionService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOperationInProgress = false;

  /// Private constructor
  TransactionService._internal();

  /// Refresh all transaction data from Firebase
  Future<Stream<DataFetchStatus>> refreshDataFromFirebase(
      BuildContext context) async {
    if (_isOperationInProgress) {
      return Stream.value(
          const DataFetchError('Another operation is in progress'));
    }

    try {
      _isOperationInProgress = true;

      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        _isOperationInProgress = false;
        return Stream.value(const DataFetchError('No user logged in'));
      }

      // Clear the "data loaded" flag so data will be reloaded
      await AuthService.instance.clearDataLoadedFlag();

      // Start fetching data from Firebase again
      final statusStream = AuthService.instance.loadUserDataAfterLogin(context);

      // Reset flag when done
      statusStream.listen(
        (status) {
          if (status is DataFetchSuccess ||
              status is DataFetchError ||
              status is DataFetchEmpty) {
            _isOperationInProgress = false;
          }
        },
        onDone: () {
          _isOperationInProgress = false;
        },
        onError: (_) {
          _isOperationInProgress = false;
        },
      );

      return statusStream;
    } catch (e) {
      _isOperationInProgress = false;
      dev.log('Error refreshing data: $e');
      return Stream.value(DataFetchError(e.toString()));
    }
  }

  /// Delete all transactions from local storage only
  Future<bool> deleteAllTransactions(
    BuildContext context, {
    required ObjectBoxExpenseRepository expenseRepository,
    required ObjectBoxIncomeRepository incomeRepository,
  }) async {
    if (_isOperationInProgress) {
      return false;
    }

    try {
      _isOperationInProgress = true;

      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        _isOperationInProgress = false;
        return false;
      }

      // Delete all expenses and incomes from local storage
      await expenseRepository.clearAllExpenses();
      await incomeRepository.clearAllIncomes();

      // Clear the "data loaded" flag
      await AuthService.instance.clearDataLoadedFlag();

      // Reset the app state to indicate no data
      if (context.mounted) {
        context.read<AppBloc>().add(const AppDataLoaded(hasData: false));
      }

      _isOperationInProgress = false;
      return true;
    } catch (e) {
      _isOperationInProgress = false;
      dev.log('Error deleting all transactions: $e');
      return false;
    }
  }

  /// Delete all transactions from both local storage and Firebase
  /// Shows progress updates in the UI during the operation
  Future<bool> deleteAllTransactionsEverywhere(
    BuildContext context, {
    required ObjectBoxExpenseRepository expenseRepository,
    required ObjectBoxIncomeRepository incomeRepository,
    required void Function(String) updateProgress,
  }) async {
    if (_isOperationInProgress) {
      return false;
    }

    try {
      _isOperationInProgress = true;

      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        _isOperationInProgress = false;
        return false;
      }

      // 1. Delete from local storage first
      updateProgress('Deleting local expenses...');
      await expenseRepository.clearAllExpenses();

      updateProgress('Deleting local incomes...');
      await incomeRepository.clearAllIncomes();

      // 2. Delete from Firebase
      updateProgress('Connecting to cloud database...');

      // Get reference to user collections
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Delete all expenses from Firebase
      updateProgress('Deleting cloud expenses...');
      final expensesQuery = await userDoc.collection('expenses').get();

      int count = 0;
      final totalExpenses = expensesQuery.docs.length;

      for (final doc in expensesQuery.docs) {
        await doc.reference.delete();
        count++;
        if (count % 10 == 0 || count == totalExpenses) {
          updateProgress('Deleting cloud expenses: $count/$totalExpenses');
        }
      }

      // Delete all incomes from Firebase
      updateProgress('Deleting cloud incomes...');
      final incomesQuery = await userDoc.collection('incomes').get();

      count = 0;
      final totalIncomes = incomesQuery.docs.length;

      for (final doc in incomesQuery.docs) {
        await doc.reference.delete();
        count++;
        if (count % 10 == 0 || count == totalIncomes) {
          updateProgress('Deleting cloud incomes: $count/$totalIncomes');
        }
      }

      // Clear the "data loaded" flag
      updateProgress('Finalizing...');
      await AuthService.instance.clearDataLoadedFlag();

      // Reset the app state to indicate no data
      if (context.mounted) {
        context.read<AppBloc>().add(const AppDataLoaded(hasData: false));
      }

      _isOperationInProgress = false;
      return true;
    } catch (e) {
      _isOperationInProgress = false;
      dev.log('Error deleting all transactions everywhere: $e');
      return false;
    }
  }

  /// Reset operation flag (in case of errors)
  void resetOperationFlag() {
    _isOperationInProgress = false;
  }
}
