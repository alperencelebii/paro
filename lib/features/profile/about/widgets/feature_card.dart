import 'package:flutter/material.dart';
import '../bloc/about_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'package:finance_track/core/localization/localization.dart';

class FeatureCard extends StatelessWidget {
  final FeatureInfo feature;

  const FeatureCard({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToFeatureDetail(context, feature),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with icon and chevron
              Row(
                children: [
                  // Feature icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconData(feature.icon),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and preview badge if applicable
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LocalizedText(
                                feature.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Navigation chevron
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ],
              ),

              // Description
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: LocalizedText(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Tags
              if (feature.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: feature.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: LocalizedText('#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFeatureDetail(BuildContext context, FeatureInfo feature) {
    // Navigate to feature detail screen using GoRouter
    context.pushNamed(
      AppRoutes.featureDetail,
      extra: feature,
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return Icons.dashboard;
      case 'home':
        return Icons.home;
      case 'money_off':
        return Icons.money_off;
      case 'attach_money':
        return Icons.attach_money;
      case 'analytics':
        return Icons.analytics;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'category':
        return Icons.category;
      case 'person':
        return Icons.person;
      case 'security':
        return Icons.security;
      case 'help':
        return Icons.help;
      case 'cloud':
        return Icons.cloud;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.apps;
    }
  }
}
