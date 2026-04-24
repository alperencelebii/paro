part of 'faq_bloc.dart';

/// Base class for all FAQ events
abstract class FaqEvent {
  const FaqEvent();
}

/// Event to initialize the FAQ data
class InitializeFaqData extends FaqEvent {
  const InitializeFaqData();
}

/// Event to toggle a category's expansion state
class ToggleCategoryExpansion extends FaqEvent {
  final String categoryTitle;

  const ToggleCategoryExpansion({required this.categoryTitle});
}

/// Event to search in FAQs
class SearchFaqs extends FaqEvent {
  final String query;

  const SearchFaqs({required this.query});
}

/// Event to clear the search
class ClearSearch extends FaqEvent {
  const ClearSearch();
}
