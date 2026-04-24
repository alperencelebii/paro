// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/services/auth_service.dart';
import 'package:finance_track/core/services/data_fetching_service.dart';
import 'package:finance_track/core/widgets/data_loading_bar.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/home/screens/home_screen.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the public flag from auth_route_listener
import '../../../core/router/auth_route_listener.dart'
    show isDataLoadingTriggered;

/// A wrapper for the home screen that handles data loading
class HomeWrapper extends StatefulWidget {
  /// Constructor
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool _hasCheckedDataStatus = false;
  bool _isLoadingData = false;
  Stream<DataFetchStatus>? _statusStream;

  @override
  void initState() {
    super.initState();
    // Wait for the widget to be fully mounted and rendered
    // before checking data loading status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a longer delay to avoid conflicts with the router navigation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _checkDataLoadingStatus();
        }
      });
    });
  }

  /// Check if data needs to be loaded, and trigger loading if necessary
  Future<void> _checkDataLoadingStatus() async {
    if (!mounted || _hasCheckedDataStatus) {
      return;
    }

    // Set this first to prevent multiple simultaneous data loads
    setState(() {
      _hasCheckedDataStatus = true;
    });

    try {
      // Safety check - don't continue if navigator is locked
      if (Navigator.of(context, rootNavigator: true).userGestureInProgress) {
        debugPrint('Navigator is locked, scheduling data load check for later');
        // Try again after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkDataLoadingStatus();
          }
        });
        return;
      }

      final appBloc = context.read<AppBloc>();

      // Check if this is a new user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final isNewUser = user.metadata.creationTime?.isAtSameMomentAs(
                user.metadata.lastSignInTime ?? DateTime.now()) ??
            false;

        if (isNewUser) {
          debugPrint('New user detected in home wrapper, skipping data fetch');
          // For new users, just mark data as loaded and update app state
          await AuthService.instance.markDataLoadedForCurrentUser();
          if (!appBloc.state.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                appBloc.add(const AppDataLoaded(hasData: true));
              }
            });
          }
          return;
        }
      }

      // First check if data has already been loaded for this user session
      final hasLoadedData =
          await AuthService.instance.hasLoadedDataForCurrentUser();
      if (hasLoadedData) {
        // If data was already loaded, just update the app state
        if (!appBloc.state.hasData) {
          // Schedule the update for the next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              appBloc.add(const AppDataLoaded(hasData: true));
            }
          });
        }
        return;
      }

      // Only attempt to load data if:
      // 1. The user is authenticated
      // 2. Data isn't already loading
      // 3. Data hasn't been loaded already
      // 4. The AuthRouteListener hasn't already triggered data loading
      if (appBloc.state.status == AppStatus.authenticated &&
          !appBloc.state.isDataLoading &&
          !appBloc.state.hasData &&
          !isDataLoadingTriggered) {
        // Set the flag to prevent the AuthRouteListener from also loading data
        isDataLoadingTriggered = true;

        // Make sure we're still mounted before proceeding
        if (!mounted) {
          isDataLoadingTriggered = false;
          return;
        }

        // Schedule for next frame to avoid navigator issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            isDataLoadingTriggered = false;
            return;
          }

          // Trigger loading state in the bloc
          appBloc.add(const AppDataLoading());

          // Use setState in the next frame to avoid triggering builds during build
          Future.delayed(Duration.zero, () {
            if (mounted) {
              setState(() {
                _isLoadingData = true;
                // Get the status stream for the loading bar
                _statusStream =
                    AuthService.instance.loadUserDataAfterLogin(context);
              });
            } else {
              isDataLoadingTriggered = false;
            }
          });
        });
      }
    } catch (e) {
      // If something goes wrong, still mark as checked so we don't keep trying
      debugPrint('Error checking data status: $e');
      isDataLoadingTriggered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData && _statusStream != null) {
      return Scaffold(
        body: Stack(
          children: [
            const HomeScreen(),
            Positioned(
              top: 130, // Position below app bar
              left: 0,
              right: 0,
              child: DataLoadingBar(
                statusStream: _statusStream!,
                onComplete: () {
                  // Schedule state update for the next frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isLoadingData = false);

                      // Wait for setState to complete before updating bloc
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          context
                              .read<AppBloc>()
                              .add(const AppDataLoaded(hasData: true));

                          // Trigger refresh after data is loaded
                          _refreshData();
                        }
                      });
                    }
                  });
                },
                onError: (errorMessage) {
                  // Schedule state update for the next frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isLoadingData = false);

                      // Wait for setState to complete before updating bloc
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          context
                              .read<AppBloc>()
                              .add(AppDataLoadingError(errorMessage));

                          // Show error snackbar after a small delay
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              try {
                                // Show error snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error loading data: $errorMessage'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error showing snackbar: $e');
                              }
                            }
                          });
                        }
                      });
                    }
                  });
                },
                onEmpty: () {
                  // Schedule state update for the next frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isLoadingData = false);

                      // Wait for setState to complete before updating bloc
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          context
                              .read<AppBloc>()
                              .add(const AppDataLoaded(hasData: false));

                          // Show info snackbar after a small delay
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              try {
                                // Show info snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No transactions found. Start by adding your first transaction!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error showing snackbar: $e');
                              }
                            }
                          });
                        }
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    return const HomeScreen();
  }

  /// Refresh expenses and incomes after data loading completes
  void _refreshData() {
    // Use a small delay to ensure the UI is updated first
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      try {
        // Refresh expense and income data
        context.read<ExpenseListBloc>().add(const LoadExpenses());
        context.read<IncomeListBloc>().add(const LoadIncomes());

        debugPrint(
            'Refreshed expenses and incomes after data load in HomeWrapper');
      } catch (e) {
        debugPrint('Error refreshing data: $e');
      }
    });
  }
}
