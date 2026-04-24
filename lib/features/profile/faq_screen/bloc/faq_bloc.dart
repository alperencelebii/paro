import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

part 'faq_event.dart';
part 'faq_state.dart';

/// BLoC for managing FAQ screen state
class FaqBloc extends Bloc<FaqEvent, FaqState> {
  // In a real production app, we might use a repository to fetch FAQ data
  // For now, we'll manage the state internally within the bloc

  FaqBloc() : super(FaqState.initial()) {
    on<InitializeFaqData>(_onInitializeFaqData);
    on<ToggleCategoryExpansion>(_onToggleCategoryExpansion);
    on<SearchFaqs>(_onSearchFaqs);
    on<ClearSearch>(_onClearSearch);
  }

  /// Initialize the FAQ data and setup state
  void _onInitializeFaqData(
    InitializeFaqData event,
    Emitter<FaqState> emit,
  ) {
    try {
      emit(state.copyWith(isLoading: true));

      // Populate initial state
      final Map<String, bool> expandedCategories = {};

      // By default, all categories are collapsed
      for (var category in state.faqCategories) {
        expandedCategories[category.title] = false;
      }

      emit(state.copyWith(
        expandedCategories: expandedCategories,
        isLoading: false,
        isInitialized: true,
      ));
    } catch (e) {
      dev.log('Error initializing FAQ data: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to initialize FAQ data: ${e.toString()}',
      ));
    }
  }

  /// Toggle the expansion state of a category
  void _onToggleCategoryExpansion(
    ToggleCategoryExpansion event,
    Emitter<FaqState> emit,
  ) {
    try {
      final Map<String, bool> updatedExpandedCategories =
          Map.from(state.expandedCategories);

      // Toggle the category expansion state
      updatedExpandedCategories[event.categoryTitle] =
          !updatedExpandedCategories[event.categoryTitle]!;

      emit(state.copyWith(expandedCategories: updatedExpandedCategories));
    } catch (e) {
      dev.log('Error toggling category expansion: $e');
      emit(state.copyWith(
        error: 'Failed to update category: ${e.toString()}',
      ));
    }
  }

  /// Search across all FAQ items
  void _onSearchFaqs(
    SearchFaqs event,
    Emitter<FaqState> emit,
  ) {
    try {
      final String query = event.query.trim();

      if (query.isEmpty) {
        emit(state.copyWith(
          searchQuery: '',
          searchResults: const [],
          isSearching: false,
        ));
        return;
      }

      final List<FaqSearchResult> results = [];
      final String lowerQuery = query.toLowerCase();

      for (var category in state.faqCategories) {
        for (var item in category.questions) {
          if (item.question.toLowerCase().contains(lowerQuery) ||
              item.answer.toLowerCase().contains(lowerQuery)) {
            results.add(FaqSearchResult(
              category: category.title,
              categoryIcon: category.icon,
              question: item.question,
              answer: item.answer,
            ));
          }
        }
      }

      emit(state.copyWith(
        searchQuery: query,
        searchResults: results,
        isSearching: true,
      ));
    } catch (e) {
      dev.log('Error searching FAQs: $e');
      emit(state.copyWith(
        error: 'Failed to search FAQs: ${e.toString()}',
      ));
    }
  }

  /// Clear the search and reset to category view
  void _onClearSearch(
    ClearSearch event,
    Emitter<FaqState> emit,
  ) {
    try {
      emit(state.copyWith(
        searchQuery: '',
        searchResults: const [],
        isSearching: false,
      ));
    } catch (e) {
      dev.log('Error clearing search: $e');
      emit(state.copyWith(
        error: 'Failed to clear search: ${e.toString()}',
      ));
    }
  }
}
