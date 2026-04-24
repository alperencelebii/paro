part of 'faq_bloc.dart';

/// State for the FAQ screen
class FaqState {
  /// Loading state flag
  final bool isLoading;

  /// Initialization status
  final bool isInitialized;

  /// Error message, if any
  final String? error;

  /// Current search query
  final String searchQuery;

  /// Whether search mode is active
  final bool isSearching;

  /// Search results
  final List<FaqSearchResult> searchResults;

  /// Map of category titles to their expansion state
  final Map<String, bool> expandedCategories;

  /// List of FAQ categories
  final List<FaqCategory> faqCategories;

  /// Create an instance of [FaqState]
  const FaqState({
    required this.isLoading,
    required this.isInitialized,
    required this.searchQuery,
    required this.isSearching,
    required this.searchResults,
    required this.expandedCategories,
    required this.faqCategories,
    this.error,
  });

  /// Create the initial state
  factory FaqState.initial() {
    return FaqState(
      isLoading: true,
      isInitialized: false,
      searchQuery: '',
      isSearching: false,
      searchResults: const [],
      expandedCategories: const {},
      faqCategories: _createDefaultCategories(),
      error: null,
    );
  }

  /// Create a copy of the current state with specified fields replaced
  FaqState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? searchQuery,
    bool? isSearching,
    List<FaqSearchResult>? searchResults,
    Map<String, bool>? expandedCategories,
    List<FaqCategory>? faqCategories,
    String? error,
  }) {
    return FaqState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      expandedCategories: expandedCategories ?? this.expandedCategories,
      faqCategories: faqCategories ?? this.faqCategories,
      error: error, // Intentionally overwrite with null if not provided
    );
  }
}

/// Model class for FAQ search result
class FaqSearchResult {
  final String category;
  final IconData categoryIcon;
  final String question;
  final String answer;

  const FaqSearchResult({
    required this.category,
    required this.categoryIcon,
    required this.question,
    required this.answer,
  });
}

/// Model class for FAQ category
class FaqCategory {
  final String title;
  final IconData icon;
  final List<FaqItem> questions;

  const FaqCategory({
    required this.title,
    required this.icon,
    required this.questions,
  });
}

/// Model class for FAQ item
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });
}

/// Create default FAQ categories with questions
List<FaqCategory> _createDefaultCategories() {
  return [
    const FaqCategory(
      title: 'Getting Started',
      icon: Icons.rocket_launch,
      questions: [
        FaqItem(
            question: 'How do I create an account?',
            answer:
                'To create an account, open the app and tap on "Sign Up" on the welcome screen. Enter your email address and create a password. You can also sign up using your Google account for faster access.'),
        FaqItem(
            question: 'Is my financial data secure?',
            answer:
                'Yes, your data is securely stored using Firebase authentication and database systems. We employ industry-standard encryption methods and never share your personal financial information with third parties.'),
        FaqItem(
            question: 'Can I use the app without creating an account?',
            answer:
                'No, an account is required to use the app. This ensures your data is securely stored and can be recovered if you change devices.'),
        FaqItem(
            question: 'How do I reset my password?',
            answer:
                'If you forgot your password, tap on "Forgot Password" on the login screen. Enter your email address and follow the instructions sent to your email to reset your password.'),
      ],
    ),
    const FaqCategory(
      title: 'Tracking Expenses',
      icon: Icons.receipt_long,
      questions: [
        FaqItem(
            question: 'How do I add a new expense?',
            answer:
                'To add a new expense, tap the "+" button in the bottom navigation bar, then select "Expense". Fill in details such as amount, category, date, and notes, then tap "Save".'),
        FaqItem(
            question: 'How do I add a recurring expense?',
            answer:
                'When adding an expense, toggle on the "Recurring" option. You can then set the frequency (daily, weekly, monthly) and the app will automatically track these recurring expenses.'),
        FaqItem(
            question: 'Can I attach receipts to my expenses?',
            answer:
                'Yes, when adding or editing an expense, tap the camera icon to take a photo of your receipt or select an existing image from your gallery.'),
        FaqItem(
            question: 'How do I edit or delete an expense?',
            answer:
                'Navigate to the transaction list, find the expense you want to modify, then swipe left to delete or tap to view details. In the details screen, you can edit the expense information or delete it permanently.'),
      ],
    ),
    const FaqCategory(
      title: 'Income Management',
      icon: Icons.account_balance_wallet,
      questions: [
        FaqItem(
            question: 'How do I add income?',
            answer:
                'To add income, tap the "+" button in the bottom navigation bar, then select "Income". Enter the amount, source, date, and any notes, then tap "Save".'),
        FaqItem(
            question: 'Can I set up recurring income entries?',
            answer:
                'Yes, similar to expenses, you can toggle on the "Recurring" option when adding income and set the frequency (daily, weekly, monthly).'),
        FaqItem(
            question: 'How do I view my income history?',
            answer:
                'Go to the "Transactions" tab and filter by "Income" to see your income history. You can also view income in the dashboard for different time periods.'),
      ],
    ),
    const FaqCategory(
      title: 'Categories',
      icon: Icons.category,
      questions: [
        FaqItem(
            question: 'How do I create a custom category?',
            answer:
                'Go to Settings > Categories > Add New Category. Enter a name for your category, select an icon, and choose a color. You can create categories for both expenses and income.'),
        FaqItem(
            question: 'Can I edit or delete categories?',
            answer:
                'Yes, go to Settings > Categories, find the category you want to modify, then tap the edit icon or swipe to delete. Note that deleting a category will not delete transactions - they will be moved to "Uncategorized".'),
        FaqItem(
            question: 'Is there a limit to how many categories I can create?',
            answer:
                'No, you can create as many custom categories as you need to organize your finances effectively.'),
      ],
    ),
    const FaqCategory(
      title: 'Budgeting',
      icon: Icons.savings,
      questions: [
        FaqItem(
            question: 'How do I set up a budget?',
            answer:
                'Go to the "Budget" tab and tap "Create Budget". Select a category, set your budget amount, and choose the time period (weekly, monthly). The app will track your spending against this budget.'),
        FaqItem(
            question: 'Can I set budgets for multiple categories?',
            answer:
                'Yes, you can create separate budgets for different expense categories to track spending across various aspects of your life.'),
        FaqItem(
            question: 'How will I know if I exceed my budget?',
            answer:
                'The app sends notifications when you reach 50%, 80%, and 100% of your budget. You can also see visual indicators in the Budget section showing your spending progress.'),
        FaqItem(
            question: 'Can I change or delete a budget?',
            answer:
                'Yes, go to the Budget tab, find the budget you want to modify, then tap to edit or use the menu options to delete it.'),
      ],
    ),
    const FaqCategory(
      title: 'Reports & Analytics',
      icon: Icons.insert_chart,
      questions: [
        FaqItem(
            question: 'What kinds of reports are available?',
            answer:
                'The app provides various reports including expense breakdown by category, income vs. expenses, spending trends over time, and monthly summaries.'),
        FaqItem(
            question: 'How do I view my spending trends?',
            answer:
                'Go to the "Analytics" tab to see charts and graphs showing your spending patterns over different time periods (weekly, monthly, yearly).'),
        FaqItem(
            question: 'Can I export my financial data?',
            answer:
                'Yes, go to Settings > Data > Export Data. You can export your transactions as a CSV file for use in spreadsheet applications.'),
        FaqItem(
            question: 'How do I view my monthly summary?',
            answer:
                'Navigate to the "Monthly Summary" section to see a comprehensive overview of your income, expenses, savings, and budget status for each month.'),
      ],
    ),
    const FaqCategory(
      title: 'Account & Settings',
      icon: Icons.settings,
      questions: [
        FaqItem(
            question: 'How do I change my account email or password?',
            answer:
                'Go to Profile > Account Settings. From there, you can update your email address or change your password by following the verification steps.'),
        FaqItem(
            question: 'Can I sync my data across multiple devices?',
            answer:
                'Yes, your data is automatically synced across all devices where you are signed in with the same account.'),
        FaqItem(
            question: 'How do I change the currency settings?',
            answer:
                'Go to Settings > General > Currency and select your preferred currency from the list of available options.'),
        FaqItem(
            question: 'Is there a dark mode available?',
            answer:
                'Yes, go to Settings > Display > Theme and toggle Dark Mode on or off, or select "System Default" to match your device settings.'),
      ],
    ),
    const FaqCategory(
      title: 'Troubleshooting',
      icon: Icons.build,
      questions: [
        FaqItem(
            question: 'The app is running slowly or crashing',
            answer:
                'Try clearing the app cache (Settings > Apps > Expense App > Clear Cache) or reinstalling the app. Make sure you have the latest version installed from the app store.'),
        FaqItem(
            question: 'My transactions aren\'t syncing across devices',
            answer:
                'Check your internet connection and ensure you\'re signed in with the same account on all devices. Go to Settings > Sync > Sync Now to force a manual sync.'),
        FaqItem(
            question: 'I\'m seeing incorrect totals in my reports',
            answer:
                'This might happen if you have transactions with future dates included in current reports. Check your date filters and ensure all transactions are correctly categorized.'),
        FaqItem(
            question: 'How do I report a bug or suggest a feature?',
            answer:
                'Go to Help & Support > Send Us a Message. Describe the issue or feature suggestion in detail, and our team will review it.'),
      ],
    ),
  ];
}
