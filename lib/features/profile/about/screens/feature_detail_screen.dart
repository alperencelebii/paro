import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/about_state.dart';
import 'package:finance_track/core/localization/localization.dart';

class FeatureDetailScreen extends StatelessWidget {
  final FeatureInfo feature;

  const FeatureDetailScreen({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with feature title and tags
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(12),
            ),
            actions: const [],
            title: LocalizedText(
              feature.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0, // Prevent title scaling
              titlePadding: EdgeInsets.zero,
              // title: Column(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     Padding(
              //       padding: const EdgeInsets.only(bottom: 24),
              //       child: LocalizedText(
              //         feature.title,
              //         style: const TextStyle(
              //           fontSize: 28,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.white,
              //         ),
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ],
              // ),
              background: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    // Tags displayed above the title
                    if (feature.tags.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: feature.tags.map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: LocalizedText('#$tag',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // Overview card
                _buildInfoCard(
                  context,
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  title: 'Overview',
                  content: LocalizedText(
                    feature.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),

                // Key capabilities card
                _buildInfoCard(
                  context,
                  icon: Icons.check_circle_outline,
                  iconColor: theme.colorScheme.primary,
                  title: 'Key Capabilities',
                  content: Column(
                    children: _getFeatureCapabilities(feature.title)
                        .map((capability) => _buildCapabilityItem(
                            capability, Theme.of(context).colorScheme.primary))
                        .toList(),
                  ),
                ),

                // Usage examples card
                _buildInfoCard(
                  context,
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber[700]!,
                  title: 'Usage Examples',
                  content: Column(
                    children: _getFeatureUsageExamples(feature.title)
                        .map((example) => _buildUsageExampleItem(example))
                        .toList(),
                  ),
                ),

                // Integration with other features card
                _buildInfoCard(
                  context,
                  icon: Icons.link,
                  iconColor: Colors.green[700]!,
                  title: 'Integration with Other Features',
                  content: Column(
                    children: _getFeatureIntegrations(feature.title)
                        .map((integration) => _buildCapabilityItem(
                            integration, Colors.green[700]!))
                        .toList(),
                  ),
                ),

                // Preview badge for preview features
                // if (feature.isPreview)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(
                //       vertical: 12,
                //     ),
                //     child: Container(
                //       width: double.infinity,
                //       padding: const EdgeInsets.symmetric(
                //         vertical: 12,
                //         horizontal: 14,
                //       ),
                //       decoration: BoxDecoration(
                //         color: Colors.amber[50],
                //         borderRadius: BorderRadius.circular(12),
                //         border: Border.all(
                //           color: Colors.amber[300]!,
                //           width: 1,
                //         ),
                //       ),
                //       child: Row(
                //         children: [
                //           Icon(
                //             Icons.lightbulb_outline,
                //             color: Colors.amber[800],
                //             size: 22,
                //           ),
                //           const SizedBox(width: 10),
                //           Expanded(
                //             child: LocalizedText(
                //               'This feature is coming soon to the app!',
                //               style: TextStyle(
                //                 fontSize: 14,
                //                 color: Colors.amber[900],
                //                 fontWeight: FontWeight.w500,
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with icon and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LocalizedText(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Card content
          content,
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String capability, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LocalizedText(
              capability,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExampleItem(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LocalizedText(
              example,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFeatureCapabilities(String featureTitle) {
    // Map of feature capabilities
    final featureCapabilities = {
      'Home': [
        'Real-time current balance display with currency conversion',
        'Quick access buttons for adding expenses and income',
        'Recent transactions list with category icons and amounts',
        'Pull-to-refresh for updated financial data',
        'Current month summary with expense vs income visualization',
      ],
      'Dashboard': [
        'Balance summary card with income vs expense visualization',
        'Budget tracking progress with visual indicators by category',
        'Interactive expense category analysis charts',
        'Month-over-month financial change indicators',
        'Top spending and income category breakdowns',
      ],
      'Expense Tracking': [
        'Create expenses with customizable categories and subcategories',
        'Attach and store receipt images with OCR data extraction',
        'Set up recurring expenses with custom frequencies',
        'Location tagging for geospatial expense analysis',
        'Advanced filtering by date, amount, category, and tags',
      ],
      'Income Management': [
        'Track multiple income sources with detailed categorization',
        'Set up recurring income entries with flexible scheduling',
        'Tag income with tax categories for tax season preparation',
        'Income goal setting with progress visualization',
        'Income history with monthly and yearly comparisons',
      ],
      'Financial Analytics': [
        'Interactive spending trend charts with drill-down capabilities',
        'Year-over-year comparison with monthly breakdowns',
        'Custom report generation with export functionality',
        'Predictive expense forecasting based on historical data',
        'Category-specific trend analysis with anomaly detection',
      ],
      'Monthly Summary': [
        'Comprehensive month-by-month financial breakdown',
        'Visual comparison with previous months and same month last year',
        'Spending pattern identification by day and week',
        'Category highlight cards showing biggest changes',
        'Month-end projection based on current spending rate',
      ],
      'Budget Planning': [
        'Create custom budgets per category with monthly or custom timeframes',
        'Visual progress indicators showing budget usage percentage',
        'Adjustable budget periods (weekly, monthly, quarterly, yearly)',
        'Real-time budget vs. actual spending comparisons',
        'Configurable alerts for approaching or exceeding budget limits',
      ],
      'Category Management': [
        'Create and customize expense and income categories with icons',
        'Organize categories with color-coding and hierarchy support',
        'Set budget limits directly within category settings',
        'View category-specific spending analytics and trends',
        'Archive rarely used categories without losing historical data',
      ],
      'User Profile': [
        'Personal information management with secure storage',
        'Currency preference selection with automatic conversion',
        'Customizable notification settings for various alerts',
        'Data backup and restore options with cloud integration',
        'UI theme customization with light/dark mode support',
      ],
      'Privacy & Security': [
        'Biometric authentication (fingerprint/face recognition)',
        'End-to-end encryption for sensitive financial data',
        'Customizable PIN code for app access protection',
        'Granular privacy controls for data sharing and visibility',
        'Session management with auto-logout after inactivity',
      ],
      'Help & Support': [
        'Interactive in-app tutorials with step-by-step guidance',
        'Searchable FAQ database with common solutions',
        'In-app email support with attachment capabilities',
        'Video tutorials demonstrating key feature usage',
        'Community forum access with user discussions and tips',
      ],
      'Firebase Integration': [
        'Real-time data synchronization across multiple devices',
        'Secure cloud backup with versioning and restore points',
        'Offline mode support with automatic data syncing when online',
        'Cross-platform data consistency with conflict resolution',
        'Multi-user account support with privacy controls',
      ],
      'Transaction Analytics': [
        'AI-powered analysis identifying unusual spending patterns',
        'Automated detection of potential duplicate transactions',
        'Personalized spending habit insights and recommendations',
        'Visual purchase pattern analysis with merchant grouping',
        'Smart category suggestions based on transaction description',
      ],
    };

    // Return a list of capabilities for the feature
    return featureCapabilities[featureTitle] ??
        [
          'Detailed tracking and management',
          'Customizable settings and preferences',
          'Data visualization and reporting',
          'Search and filtering capabilities',
          'Integration with other app features',
        ];
  }

  List<String> _getFeatureUsageExamples(String featureTitle) {
    // Map of feature usage examples
    final featureExamples = {
      'Home': [
        'Check your current balance at a glance as soon as you open the app',
        'Quickly add a new expense after making a purchase using the + button',
        'Review your most recent transactions without navigating to a different screen',
        'See your monthly financial summary with expense-to-income ratio',
        'Pull down to refresh all financial data when you complete a transaction',
      ],
      'Dashboard': [
        'Monitor your monthly budget status across all spending categories',
        'Identify your highest spending categories with the pie chart visualization',
        'Compare your income and expenses with the visual balance summary',
        'Track month-over-month changes in your spending and saving habits',
        'View your top expense categories to identify areas for potential savings',
      ],
      'Expense Tracking': [
        'Take a photo of your receipt and automatically extract amount and date',
        'Set up a monthly subscription as a recurring expense to track automatically',
        'Filter expenses by category to see all your dining expenses for the month',
        'Tag expenses with location to analyze spending patterns by area',
        'Search for a specific expense using keywords from the description',
      ],
      'Income Management': [
        'Set up your salary as a recurring income with automatic monthly entries',
        'Categorize a freelance payment under "Side Projects" for accurate reporting',
        'Tag income with appropriate tax classifications for year-end tax preparation',
        'Compare this month\'s income with previous months using the history view',
        'Set income goals and track your progress toward achieving them',
      ],
      'Financial Analytics': [
        'Analyze your year-over-year spending trends to identify patterns',
        'Generate a custom report of all expenses in a specific category',
        'Use the spending forecast to anticipate expenses for upcoming months',
        'Identify unusual spending spikes with the trend analysis tool',
        'Compare different expense categories side by side with the chart view',
      ],
      'Monthly Summary': [
        'Review your complete financial status at the end of each month',
        'Compare your current month\'s spending with the same month last year',
        'Identify which days of the month have the highest spending activity',
        'See which spending categories changed the most from last month',
        'Plan your end-of-month budget based on projected spending',
      ],
      'Budget Planning': [
        'Create a monthly grocery budget with alerts when you reach 80% of the limit',
        'Set up a quarterly entertainment budget with weekly breakdown',
        'Adjust your budget mid-month if unexpected expenses arise',
        'Compare your actual spending against your budgeted amounts visually',
        'Receive notifications when you\'re approaching or have exceeded a budget',
      ],
      'Category Management': [
        'Create a custom category for a specific project with its own unique icon',
        'Organize subcategories under main categories for better expense tracking',
        'Assign color codes to categories for easier visual identification',
        'Review spending analysis for a specific category over time',
        'Archive seasonal categories that are only used during certain times',
      ],
      'User Profile': [
        'Update your currency preference when traveling to a different country',
        'Customize notification settings to receive alerts on large expenses',
        'Back up your financial data to the cloud before changing devices',
        'Switch between light and dark mode based on your preference',
        'Update your personal information when your details change',
      ],
      'Privacy & Security': [
        'Enable fingerprint authentication for quick and secure app access',
        'Set up a PIN code as a secondary security measure',
        'Configure privacy settings to control what data is synchronized',
        'Enable auto-logout to secure your data when the app is not in use',
        'Review and manage active sessions on different devices',
      ],
      'Help & Support': [
        'Take the interactive tutorial to learn how to set up a budget',
        'Search the FAQ to find a solution for a specific issue',
        'Contact support with screenshots if you encounter a problem',
        'Watch video tutorials to learn advanced features',
        'Join the community forum to share tips with other users',
      ],
      'Firebase Integration': [
        'Access your financial data seamlessly across your phone and tablet',
        'Continue using the app offline during travel with automatic sync later',
        'Restore your data after getting a new device using cloud backup',
        'Share limited financial information with a family member securely',
        'Maintain consistent data when switching between devices',
      ],
      'Transaction Analytics': [
        'Receive an alert about an unusual purchase that doesn\'t match your patterns',
        'Get smart suggestions for categorizing new transactions automatically',
        'Review personalized insights about your spending habits each month',
        'Identify repeated purchases from the same merchant with pattern analysis',
        'Get recommendations for potential savings based on your spending habits',
      ],
    };

    // Return a list of examples for the feature
    return featureExamples[featureTitle] ??
        [
          'Access this feature from the main navigation menu',
          'Customize settings according to your preferences',
          'Use the search functionality to find specific items',
          'Export data for external analysis when needed',
          'Set up notifications to stay informed about important updates',
        ];
  }

  List<String> _getFeatureIntegrations(String featureTitle) {
    // Map of feature integrations
    final featureIntegrations = {
      'Home': [
        'Balance updates automatically when new transactions are added',
        'Quick access buttons link directly to expense and income creation screens',
        'Recent transactions list pulls from both expense and income tracking',
        'Monthly summary integrates with analytics for deeper insights',
        'Syncs with Firebase to ensure data is current across devices',
      ],
      'Dashboard': [
        'Budget tracking connects with the Budget Planning module',
        'Category analysis links with Category Management for detailed views',
        'Balance summary integrates with Expense and Income tracking',
        'Financial trends connect with Analytics for historical data comparison',
        'Data visualizations update in real-time with new transactions',
      ],
      'Expense Tracking': [
        'Categories sync with Category Management for consistent organization',
        'Receipt photos store in Firebase cloud storage for access anywhere',
        'Expense data feeds directly into Dashboard and Analytics views',
        'Location data can be viewed on maps within the Analytics section',
        'Budget alerts trigger based on expense entries in specific categories',
      ],
      'Income Management': [
        'Income categories sync with Category Management system',
        'Income data feeds into Dashboard and Analytics visualizations',
        'Tax categorization supports export for tax preparation software',
        'Income goals integrate with the budget planning system',
        'Recurring income automatically updates balance calculations',
      ],
      'Financial Analytics': [
        'Pulls transaction data from both Expense and Income tracking',
        'Integrates with Category Management for categorical analysis',
        'Budget Planning data used for budget vs. actual comparisons',
        'Exportable reports can be shared via email or cloud storage',
        'Historical data access enabled through Firebase synchronization',
      ],
      'Monthly Summary': [
        'Aggregates data from Expense and Income tracking modules',
        'Connects with Budget Planning to show budget adherence',
        'Integrates with Category Management for category-based analysis',
        'Links with Analytics for trend identification and projections',
        'Data accessible offline through Firebase\'s offline capabilities',
      ],
      'Budget Planning': [
        'Categories align with Category Management for consistency',
        'Real-time updates based on Expense Tracking entries',
        'Budget status visible on Dashboard for quick access',
        'Alert system connects with app notifications framework',
        'Historical budget data available through Financial Analytics',
      ],
      'Category Management': [
        'Categories used consistently across Expense and Income tracking',
        'Budget limits set per category sync with Budget Planning',
        'Category analytics feed into Dashboard visualizations',
        'Custom icons and colors appear throughout the app interface',
        'Category hierarchy respected in all filtering and reporting features',
      ],
      'User Profile': [
        'Currency settings apply globally across all financial calculations',
        'Notification preferences control alerts from all app features',
        'Backup/restore functionality works with Firebase Integration',
        'Theme settings applied consistently across all app screens',
        'Personal data securely managed with Privacy & Security features',
      ],
      'Privacy & Security': [
        'Authentication controls access to all financial data',
        'Encryption protects data in Firebase cloud storage',
        'Privacy controls determine what syncs across devices',
        'Security settings integrate with device biometric systems',
        'Session management works across all app instances',
      ],
      'Help & Support': [
        'Contextual help available within each feature screen',
        'Tutorial system covers all major app functionalities',
        'Support requests can include diagnostic data from the app',
        'Video guides demonstrate real app features and workflows',
        'Community forum connects with user accounts for personalized help',
      ],
      'Firebase Integration': [
        'Enables real-time synchronization of all financial data',
        'Supports authentication across multiple devices securely',
        'Provides offline capabilities throughout the entire app',
        'Enables backup and restore functionality for all user data',
        'Facilitates multi-device and potentially multi-user access',
      ],
      'Transaction Analytics': [
        'Works with data from both Expense and Income tracking',
        'AI insights feed into Dashboard recommendations',
        'Anomaly detection alerts users through the notification system',
        'Pattern analysis improves category suggestions in transaction entry',
        'Spending recommendations link to Budget Planning for adjustments',
      ],
    };

    // Return a list of integrations for the feature
    return featureIntegrations[featureTitle] ??
        [
          'Integrates with the main data management system',
          'Works seamlessly with user profile settings',
          'Connects with notification system for important alerts',
          'Data feeds into analytics for comprehensive reporting',
          'Syncs across devices through Firebase integration',
        ];
  }
}
