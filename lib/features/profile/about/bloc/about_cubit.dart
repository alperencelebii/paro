import 'package:flutter_bloc/flutter_bloc.dart';
import 'about_state.dart';

class AboutCubit extends Cubit<AboutState> {
  AboutCubit() : super(const AboutState()) {
    _loadFeatures();
  }

  /// Loads all app features and their details
  Future<void> _loadFeatures() async {
    emit(state.copyWith(isLoading: true));

    try {
      // In a real app, this data might come from a repository/API
      final features = [
        // Home feature
        const FeatureInfo(
          title: 'Home',
          description:
              'Your financial command center with current balance card, quick actions, and recent transactions for immediate financial oversight',
          icon: 'home',
          route: '/',
          tags: ['overview', 'insights', 'balance', 'transactions'],
        ),
        // Dashboard
        const FeatureInfo(
          title: 'Dashboard',
          description:
              'Comprehensive financial analytics with balance summary, income vs expense visualization, budget tracking, and category analysis charts',
          icon: 'dashboard',
          route: '/dashboard',
          tags: ['analytics', 'summary', 'charts', 'visualization'],
        ),

        // Transaction management
        const FeatureInfo(
          title: 'Expense Tracking',
          description:
              'Full expense management with categorization, receipt scanning, recurring expenses, location tagging, and detailed search filtering',
          icon: 'money_off',
          route: '/expense-list',
          tags: ['expenses', 'tracking', 'receipts', 'categories'],
        ),
        const FeatureInfo(
          title: 'Income Management',
          description:
              'Track multiple income sources with categorization, recurring income setup, tax category assignment, and goal progress tracking',
          icon: 'attach_money',
          route: '/income-list',
          tags: ['income', 'sources', 'tracking', 'recurring'],
        ),

        // Analytics features
        const FeatureInfo(
          title: 'Financial Analytics',
          description:
              'Advanced spending analytics with interactive charts, yearly comparisons, trend identification, and custom report generation',
          icon: 'analytics',
          route: '/analytics',
          tags: ['charts', 'insights', 'trends', 'forecasting'],
        ),
        const FeatureInfo(
          title: 'Monthly Summary',
          description:
              'Detailed month-by-month financial breakdown with month-over-month comparisons, spending patterns, and category highlights',
          icon: 'calendar_month',
          route: '/monthly-summary',
          tags: ['monthly', 'summary', 'reports', 'trends'],
        ),

        // Budget management
        const FeatureInfo(
          title: 'Budget Planning',
          description:
              'Personalized budget creation with category-specific limits, visual progress tracking, custom timeframes, and spending alerts',
          icon: 'account_balance_wallet',
          route: '/budget-settings',
          tags: ['budget', 'planning', 'goals', 'alerts'],
        ),

        // Category management
        const FeatureInfo(
          title: 'Category Management',
          description:
              'Create, customize, and organize expense and income categories with icons, colors, and detailed spending analytics',
          icon: 'category',
          route: '/all-categories',
          tags: ['categories', 'organization', 'customization'],
        ),

        // User profile and settings
        const FeatureInfo(
          title: 'User Profile',
          description:
              'Manage personal information, currency preferences, notification settings, and app appearance with customization options',
          icon: 'person',
          route: '/profile',
          tags: ['profile', 'settings', 'preferences', 'customization'],
        ),
        const FeatureInfo(
          title: 'Privacy & Security',
          description:
              'Enhanced security with biometric authentication, data encryption, PIN protection, and privacy controls for sensitive information',
          icon: 'security',
          route: '/privacy-security',
          tags: ['privacy', 'security', 'encryption', 'authentication'],
        ),

        // Support features
        const FeatureInfo(
          title: 'Help & Support',
          description:
              'Comprehensive support with in-app tutorials, searchable FAQ, video guides, email support, and community forum access',
          icon: 'help',
          route: '/help-support',
          tags: ['help', 'support', 'tutorials', 'guides'],
        ),

        // Advanced features
        const FeatureInfo(
          title: 'Firebase Integration',
          description:
              'Seamless cloud synchronization with real-time updates, offline mode functionality, secure data backup, and multi-device access',
          icon: 'cloud',
          route: '',
          tags: ['cloud', 'sync', 'backup', 'multi-device'],
        ),
        const FeatureInfo(
          title: 'Transaction Analytics',
          description:
              'AI-powered transaction analysis with anomaly detection, spending pattern insights, purchase trend visualization, and smart recommendations',
          icon: 'trending_up',
          route: '',
          tags: ['analytics', 'AI', 'insights', 'trends'],
        ),
      ];

      emit(state.copyWith(
        isLoading: false,
        appFeatures: features,
        filteredFeatures: features,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load features: ${e.toString()}',
      ));
    }
  }

  /// Search features based on query
  void searchFeatures(String query) {
    final searchText = query.toLowerCase();

    if (searchText.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        filteredFeatures: state.appFeatures,
      ));
      return;
    }

    final filteredList = state.appFeatures.where((feature) {
      return feature.title.toLowerCase().contains(searchText) ||
          feature.description.toLowerCase().contains(searchText) ||
          feature.tags.any((tag) => tag.toLowerCase().contains(searchText));
    }).toList();

    emit(state.copyWith(
      searchQuery: query,
      filteredFeatures: filteredList,
    ));
  }

  /// Reset search and show all features
  void resetSearch() {
    emit(state.copyWith(
      searchQuery: '',
      filteredFeatures: state.appFeatures,
    ));
  }
}
