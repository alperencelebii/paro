import 'dart:async';
import 'dart:developer' as dev;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/subscription_management_repository.dart';
import '../models/subscription_details_model.dart';
import '../services/subscription_service.dart';

part 'subscription_management_event.dart';
part 'subscription_management_state.dart';

/// Bloc for managing subscription details and information
class SubscriptionManagementBloc
    extends Bloc<SubscriptionManagementEvent, SubscriptionManagementState> {
  final SubscriptionManagementRepository _repository;

  SubscriptionManagementBloc({
    required SubscriptionManagementRepository repository,
  })  : _repository = repository,
        super(const SubscriptionManagementState()) {
    on<LoadSubscriptionDetails>(_onLoadSubscriptionDetails);
    on<RefreshSubscriptionDetails>(_onRefreshSubscriptionDetails);
    on<CheckActiveSubscription>(_onCheckActiveSubscription);
    on<TestSubscriptionRestore>(_onTestSubscriptionRestore);
  }

  Future<void> _onLoadSubscriptionDetails(
    LoadSubscriptionDetails event,
    Emitter<SubscriptionManagementState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionManagementStatus.loading));

    try {
      // CRITICAL: Ensure user is identified in RevenueCat first
      await SubscriptionService.identifyUser(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      
      final subscriptionDetails = await _repository.getSubscriptionDetails();

      if (subscriptionDetails == null) {
        emit(state.copyWith(
          status: SubscriptionManagementStatus.noSubscription,
          errorMessage: null,
        ));
        return;
      }

      emit(state.copyWith(
        status: SubscriptionManagementStatus.loaded,
        subscriptionDetails: subscriptionDetails,
        errorMessage: null,
      ));
    } catch (e, stackTrace) {
      dev.log(
        'Error loading subscription details: $e',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: SubscriptionManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshSubscriptionDetails(
    RefreshSubscriptionDetails event,
    Emitter<SubscriptionManagementState> emit,
  ) async {
    // Don't show loading if we already have data
    if (state.status == SubscriptionManagementStatus.loaded) {
      emit(state.copyWith(isRefreshing: true));
    } else {
      emit(state.copyWith(status: SubscriptionManagementStatus.loading));
    }

    try {
      // CRITICAL: Ensure user is identified in RevenueCat first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await SubscriptionService.identifyUser(user.uid);
      }
      
      // Refresh customer info from RevenueCat
      await _repository.refreshCustomerInfo();
      
      // Reload subscription details
      final subscriptionDetails = await _repository.getSubscriptionDetails();

      if (subscriptionDetails == null) {
        emit(state.copyWith(
          status: SubscriptionManagementStatus.noSubscription,
          errorMessage: null,
          isRefreshing: false,
        ));
        return;
      }

      emit(state.copyWith(
        status: SubscriptionManagementStatus.loaded,
        subscriptionDetails: subscriptionDetails,
        errorMessage: null,
        isRefreshing: false,
      ));
    } catch (e, stackTrace) {
      dev.log(
        'Error refreshing subscription details: $e',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: SubscriptionManagementStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  Future<void> _onCheckActiveSubscription(
    CheckActiveSubscription event,
    Emitter<SubscriptionManagementState> emit,
  ) async {
    try {
      // CRITICAL: Ensure user is identified in RevenueCat first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await SubscriptionService.identifyUser(user.uid);
      }
      
      final hasActive = await _repository.hasActiveSubscription();
      final hasPas = await _repository.hasActivePasSubscription();

      emit(state.copyWith(
        hasActiveSubscription: hasActive,
        hasPasSubscription: hasPas,
      ));
    } catch (e) {
      dev.log('Error checking active subscription: $e');
      emit(state.copyWith(
        hasActiveSubscription: false,
        hasPasSubscription: false,
      ));
    }
  }

  Future<void> _onTestSubscriptionRestore(
    TestSubscriptionRestore event,
    Emitter<SubscriptionManagementState> emit,
  ) async {
    try {
      dev.log('=== TESTING SUBSCRIPTION RESTORE ===');
      final result = await SubscriptionService.testSubscriptionRestore(event.userId);
      
      if (result['success'] == true) {
        dev.log('Test successful! Is Premium: ${result['isPremium']}');
        dev.log('Active entitlements: ${result['activeEntitlements']}');
        
        // Reload subscription details after test
        add(const LoadSubscriptionDetails());
      } else {
        dev.log('Test failed: ${result['error']}');
      }
    } catch (e) {
      dev.log('Error during subscription restore test: $e');
    }
  }
}

