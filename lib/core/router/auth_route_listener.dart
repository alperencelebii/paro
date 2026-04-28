// ignore_for_file: use_build_context_synchronously

import 'dart:developer' as dev;
import 'package:finance_track/core/localization/localization.dart';

import 'package:finance_track/core/services/data_fetching_service.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc/app_bloc.dart';
import '../services/auth_service.dart';
import '../widgets/data_loading_bar.dart';
import 'app_router.dart';

// Keep track of whether data loading has been triggered
// Make this public so it can be accessed from other files
bool isDataLoadingTriggered = false;

/// A listener that handles authentication-related navigation and triggers data loading
class AuthRouteListener extends NavigatorObserver {
  // Stream controller for data loading status
  Stream<DataFetchStatus>? _statusStream;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Check if we're navigating to the home screen from auth page
    final isNavigatingToHome =
        route.settings.name?.contains(AppPaths.home) ?? false;
    final isComingFromAuth =
        previousRoute?.settings.name?.contains(AppPaths.auth) ?? false;

    if (isNavigatingToHome && isComingFromAuth && !isDataLoadingTriggered) {
      // Mark that we've triggered data loading to prevent duplicates
      isDataLoadingTriggered = true;

      // Wait for navigation to fully complete before attempting any UI work
      // Use a significantly longer delay for login (2000ms)
      Future.delayed(const Duration(milliseconds: 2000), () {
        _handleAuthToHomeNavigation(route);
      });
    }
  }

  /// Handle navigation from authentication to home screen
  void _handleAuthToHomeNavigation(Route<dynamic> route) {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      dev.log('No authenticated user found in route listener');
      isDataLoadingTriggered = false; // Reset flag if no user
      return;
    }

    // Check if the navigator is still active and can be used
    final navigator = route.navigator;
    if (navigator == null || !navigator.mounted) {
      dev.log('Navigator is no longer available');
      isDataLoadingTriggered = false; // Reset flag
      return;
    }

    final context = navigator.context;
    if (!context.mounted) {
      dev.log('Navigator context is not available');
      isDataLoadingTriggered = false; // Reset flag if context is not valid
      return;
    }

    // Add a longer post-frame callback to ensure we're not in a build or layout phase
    // This is safer than using a microtask
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Double-check mounted state after frame is drawn
      if (navigator.mounted && context.mounted) {
        // Add one more delay to be absolutely sure navigation is done
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            _prepareDataLoading(context);
          } else {
            isDataLoadingTriggered = false;
          }
        });
      } else {
        isDataLoadingTriggered = false;
      }
    });
  }

  /// Prepare data loading with the loading bar
  Future<void> _prepareDataLoading(BuildContext context) async {
    try {
      // Get the AppBloc instance
      final appBloc = context.read<AppBloc>();

      // Check if data is already loading or loaded
      if (appBloc.state.isDataLoading || appBloc.state.hasData) {
        isDataLoadingTriggered = false; // Reset flag
        return;
      }

      // Get the current user and check if it's a new user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if this is a new user by comparing creation and last sign-in times
        final isNewUser = user.metadata.creationTime?.isAtSameMomentAs(
                user.metadata.lastSignInTime ?? DateTime.now()) ??
            false;

        if (isNewUser) {
          dev.log('New user detected in route listener, skipping data fetch');
          // For new users, just mark data as loaded and update app state
          await AuthService.instance.markDataLoadedForCurrentUser();
          appBloc.add(const AppDataLoaded(hasData: true));
          isDataLoadingTriggered = false; // Reset flag
          return;
        }
      }

      // Check if data has already been loaded for this user
      final hasLoadedData =
          await AuthService.instance.hasLoadedDataForCurrentUser();
      if (hasLoadedData) {
        dev.log('Data has already been loaded for current user, skipping...');
        // Just update the app state to indicate data is loaded
        appBloc.add(const AppDataLoaded(hasData: true));
        isDataLoadingTriggered = false; // Reset flag
        return;
      }

      // Notify the app that data is loading
      appBloc.add(const AppDataLoading());

      // Get the status stream for loading bar
      _statusStream = AuthService.instance.loadUserDataAfterLogin(context);

      // Show the loading bar overlay
      _showLoadingBar(context);
    } catch (e) {
      dev.log('Error preparing data loading: $e');
      isDataLoadingTriggered = false; // Reset flag on error

      if (context.mounted) {
        context.read<AppBloc>().add(AppDataLoadingError(e.toString()));
      }
    }
  }

  /// Show the loading bar overlay with beautiful animation
  void _showLoadingBar(BuildContext context) {
    if (_statusStream == null || !context.mounted) {
      isDataLoadingTriggered = false;
      return;
    }

    // IMPORTANT: Don't try to show overlay during navigation
    // Instead, schedule it for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        isDataLoadingTriggered = false;
        return;
      }

      try {
        // Ensure navigator is not in the middle of a transition
        if (Navigator.of(context, rootNavigator: true).userGestureInProgress) {
          dev.log('Navigator is locked, scheduling loading bar for later');
          // Try again after a delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              _showLoadingBar(context);
            } else {
              isDataLoadingTriggered = false;
            }
          });
          return;
        }

        // Use an overlay to show the loading bar
        final overlayState = Overlay.of(context);

        // First declare the overlayEntry variable
        late final OverlayEntry overlayEntry;

        // Then initialize it with the callbacks referring to the declared variable
        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: 130, // Position below app bar
            left: 0,
            right: 0,
            child: DataLoadingBar(
              statusStream: _statusStream!,
              onComplete: () {
                // Add safety check before removing overlay
                try {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                } catch (e) {
                  dev.log('Error removing overlay: $e');
                }

                if (context.mounted) {
                  // Schedule state update for the next frame to avoid navigator issues
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context
                          .read<AppBloc>()
                          .add(const AppDataLoaded(hasData: true));

                      // Add a simulated pull-to-refresh effect when data is loaded
                      _simulateRefreshIndicator(context);
                    }
                  });
                }
                isDataLoadingTriggered = false;
              },
              onError: (errorMessage) {
                // Add safety check before removing overlay
                try {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                } catch (e) {
                  dev.log('Error removing overlay: $e');
                }

                if (context.mounted) {
                  // Schedule state update for the next frame to avoid navigator issues
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context
                          .read<AppBloc>()
                          .add(AppDataLoadingError(errorMessage));

                      // Show error snackbar after a small delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    LocalizedText('Error loading data: $errorMessage'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            dev.log('Error showing snackbar: $e');
                          }
                        }
                      });
                    }
                  });
                }
                isDataLoadingTriggered = false;
              },
              onEmpty: () {
                // Add safety check before removing overlay
                try {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                } catch (e) {
                  dev.log('Error removing overlay: $e');
                }

                if (context.mounted) {
                  // Schedule state update for the next frame to avoid navigator issues
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context
                          .read<AppBloc>()
                          .add(const AppDataLoaded(hasData: false));

                      // Show info snackbar after a small delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: LocalizedText('No transactions found. Start by adding your first transaction!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          } catch (e) {
                            dev.log('Error showing snackbar: $e');
                          }
                        }
                      });
                    }
                  });
                }
                isDataLoadingTriggered = false;
              },
            ),
          ),
        );

        // Add overlay entry
        overlayState.insert(overlayEntry);
      } catch (e) {
        dev.log('Error showing loading bar: $e');
        isDataLoadingTriggered = false;
      }
    });
  }

  /// Create a simulated pull-to-refresh animation effect
  void _simulateRefreshIndicator(BuildContext context) {
    try {
      // Use a small delay to ensure the home screen is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!context.mounted) return;

        // Find the ExpenseListBloc and IncomeListBloc and refresh them
        context.read<ExpenseListBloc>().add(const LoadExpenses());
        context.read<IncomeListBloc>().add(const LoadIncomes());

        dev.log('Refreshed expenses and incomes after data load');
      });
    } catch (e) {
      dev.log('Error simulating refresh: $e');
    }
  }
}
