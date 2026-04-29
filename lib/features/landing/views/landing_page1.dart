import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_track/core/localization/localization.dart';

/// First landing page - Overview with Hero Section & CTA
class LandingPage1 extends StatelessWidget {
  const LandingPage1({super.key});

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    'assets/images/paro_logo.png',
                    width: 56.r,
                    height: 56.r,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText('PARO Cüzdan',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      LocalizedText('Akıllı gelir-gider ve bütçe takibi',
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

            // App Preview Mock
            _buildAppPreview(theme),

            SizedBox(height: 32.h),

            // Features List
            LocalizedText('Başlıca Özellikler',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

            SizedBox(height: 16.h),

            _buildFeature(
              theme: theme,
              icon: Icons.track_changes_rounded,
              title: 'Akıllı Takip',
              description: 'Giderleri ve gelirleri otomatik olarak kategorize et.',
              color: theme.colorScheme.primary,
              index: 0,
            ),

            SizedBox(height: 16.h),

            _buildFeature(
              theme: theme,
              icon: Icons.insert_chart_outlined_rounded,
              title: 'Güçlü ve Analitik',
              description:
                  'İnteraktif grafikler ve analizlerle trendleri görselleştirin.',
              color: theme.colorScheme.secondary,
              index: 1,
            ),

            SizedBox(height: 16.h),

            _buildFeature(
              theme: theme,
              icon: Icons.attach_money_rounded,
              title: 'Bütçe Belirleme',
              description:
                  'Aylık bütçeler oluşturun ve harcama limitlerinizi takip edin.',
              color: theme.colorScheme.tertiary,
              index: 2,
            ),

            SizedBox(height: 16.h),

            _buildFeature(
              theme: theme,
              icon: Icons.sync_rounded,
              title: 'Bulut Senkronizasyonu',
              description: 'Verilerinize tüm cihazlarınızdan güvenli bir şekilde erişin.',
              color: theme.colorScheme.primary,
              index: 3,
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPreview(ThemeData theme) {
    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                ),
              ),
            ),

            // Decorative elements
            Positioned(
              right: -20.w,
              bottom: -20.h,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -30.w,
              top: -30.h,
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Dashboard UI
            Center(
              child: Container(
                width: 200.w,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LocalizedText('Kontrol Paneli',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        Icon(Icons.more_vert, size: 16.r),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            color: theme.colorScheme.primary,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText('Toplam Bakiye',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              LocalizedText('₺4,285.00',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: Colors.green,
                                  size: 14.r,
                                ),
                                SizedBox(height: 4.h),
                                LocalizedText('Gelir',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.green[700],
                                  ),
                                ),
                                LocalizedText('₺5,240',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Colors.red,
                                  size: 14.r,
                                ),
                                SizedBox(height: 4.h),
                                LocalizedText('Gider',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.red[700],
                                  ),
                                ),
                                LocalizedText('₺955',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
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
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 800.ms,
          delay: 200.ms,
        );
  }

  Widget _buildFeature({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int index,
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
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 24.r,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                LocalizedText(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 400 + (index * 200)),
          duration: 600.ms,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 600.ms,
          delay: Duration(milliseconds: 400 + (index * 200)),
        );
  }
}
