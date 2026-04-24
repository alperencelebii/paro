import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'landing_state.dart';

/// Cubit to manage landing page state
class LandingCubit extends Cubit<LandingState> {
  final PageController pageController = PageController();

  LandingCubit() : super(const LandingState());

  /// Navigate to the next page
  void nextPage() {
    final newPage = state.currentPage + 1;
    if (newPage <= 2) {
      emit(state.copyWith(currentPage: newPage));
    }
  }

  /// Navigate to the previous page
  void previousPage() {
    final newPage = state.currentPage - 1;
    if (newPage >= 0) {
      emit(state.copyWith(currentPage: newPage));
    }
  }

  /// Navigate to a specific page
  void goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= 2) {
      _animateToPage(pageIndex);
    }
  }

  /// Navigate to login page
  void goToLogin() {
    // Navigation will be handled by the router
  }

  /// Helper method to animate to a page and emit state
  void _animateToPage(int pageIndex) {
    // First mark as animating
    emit(state.copyWith(isAnimating: true));

    pageController
        .animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      // After animation completes, update the state with new page and mark animation as done
      emit(state.copyWith(
        currentPage: pageIndex,
        isAnimating: false,
      ));
    });
  }

  /// Update current page without animation (used by PageView's onPageChanged)
  void updateCurrentPage(int page) {
    emit(state.copyWith(currentPage: page));
  }

  void setPage(int page) {
    if (page >= 0 && page <= 2) {
      emit(state.copyWith(currentPage: page));
    }
  }

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
