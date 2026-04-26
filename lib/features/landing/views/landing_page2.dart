import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Second landing page - Features showcasing expense tracking, analytics, budgeting
class LandingPage2 extends StatelessWidget {
  const LandingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),

            // Header section
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 28.r,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akıllı Finans',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Finansal işlemlerinizi düzenlemek için yapay zeka destekli araçlar.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 600.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 600.ms,
                ),

            SizedBox(height: 32.h),

            // Feature showcase
            _buildFeatureItem(
              theme: theme,
              icon: Icons.show_chart,
              title: 'Gider Takibi',
              description:
                  'İşlemleri kolayca kaydedin ve otomatik olarak kategorize edin.',
              mockup: _buildExpenseTrackingMockup(theme),
            ),

            SizedBox(height: 24.h),

            _buildFeatureItem(
              theme: theme,
              icon: Icons.pie_chart,
              title: 'Akıllı Analitik',
              description:
                  'Harcama alışkanlıklarınız ve kalıplarınız hakkında bilgi edinin.',
              mockup: _buildAnalyticsMockup(theme),
            ),

            SizedBox(height: 24.h),

            _buildFeatureItem(
              theme: theme,
              icon: Icons.account_balance_wallet,
              title: 'Bütçe Belirleme',
              description:
                  'Farklı gider kategorileri için bütçeler belirleyin ve takip edin.',
              mockup: _buildBudgetPlanningMockup(theme),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required Widget mockup,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 20.r,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 150.h,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: mockup,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildExpenseTrackingMockup(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: theme.colorScheme.primary,
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 18.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'İşlem Ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 300.w,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(12.r),
                  itemCount: 3,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final List<Map<String, dynamic>> transactions = [
                      {
                        'name': 'Ali Yılmaz',
                        'amount': '-\₺32.50',
                        'icon': Icons.shopping_basket
                      },
                      {
                        'name': 'Maaş',
                        'amount': '+\₺1,250.00',
                        'icon': Icons.payments
                      },
                      {
                        'name': 'Hizmetler',
                        'amount': '-\₺75.30',
                        'icon': Icons.bolt
                      },
                    ];

                    final transaction = transactions[index];
                    final isExpense =
                        transaction['amount'].toString().contains('-');

                    return Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              transaction['icon'] as IconData,
                              size: 14.r,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              transaction['name'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            transaction['amount'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMockup(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.all(12.r),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 300.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aylık Özet',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gelir',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '\₺2,450',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gider',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '\₺1,286',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tasarruf',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '\₺1,164 (47%)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPlanningMockup(ThemeData theme) {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Yiyecek & İçecek',
        'spent': 320,
        'budget': 400,
        'icon': Icons.restaurant
      },
      {
        'name': 'Toplu taşıma',
        'spent': 180,
        'budget': 200,
        'icon': Icons.directions_car
      },
      {
        'name': 'Eğlence',
        'spent': 120,
        'budget': 150,
        'icon': Icons.movie
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.all(12.r),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 300.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bütçeye Genel Bakış',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),
              ...categories.map((category) {
                final progress =
                    (category['spent'] as int) / (category['budget'] as int);
                final isWarning = progress > 0.8;
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 14.r,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              category['name'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\₺${category['spent']} / \₺${category['budget']}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isWarning
                                  ? Colors.orange
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6.h,
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          color: isWarning
                              ? Colors.orange
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
