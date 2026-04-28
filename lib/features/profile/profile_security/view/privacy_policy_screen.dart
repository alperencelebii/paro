import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/localization/localization.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Privacy Policy'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24.h),
            _buildSection(
              'Introduction',
              'We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our Expense & Income Tracker app.',
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Information We Collect',
              'We collect the following types of information:',
              bulletPoints: [
                'Financial data: Your income and expense records that you enter into the app',
                'Account information: Email and authentication details when you sign up',
                'Device information: Device type, operating system, and app usage statistics',
                'Usage data: How you interact with our app to improve user experience',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'How We Use Your Information',
              'We use your information for:',
              bulletPoints: [
                'Providing and maintaining the app functionality',
                'Synchronizing your data across multiple devices using Firebase',
                'Improving and personalizing your experience',
                'Communicating with you about app updates and features',
                'Analyzing usage patterns to enhance our services',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Data Storage',
              'Our app uses an offline-first approach:',
              bulletPoints: [
                'ObjectBox: Your financial data is primarily stored locally on your device',
                'Firebase: When cloud sync is enabled, your data is securely backed up to the cloud',
                'Local encryption: You can enable encryption for your offline data for additional security',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Data Security',
              'We implement robust security measures:',
              bulletPoints: [
                'All data transmitted to Firebase is encrypted in transit using SSL/TLS',
                'Firebase authentication secures your account with industry-standard practices',
                'Optional biometric authentication for app access on your device',
                'Regular security audits and updates to protect your information',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Your Choices and Rights',
              'You have control over your data:',
              bulletPoints: [
                'Access, export, or delete your data at any time from the app settings',
                'Disable cloud sync to keep your data local only',
                'Opt out of analytics and data collection',
                'Request complete account deletion',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Third-Party Services',
              'We use the following third-party services:',
              bulletPoints: [
                'Firebase (Google): For authentication, cloud storage, and analytics',
                'ObjectBox: For local database storage on your device',
              ],
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Children\'s Privacy',
              'Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
            ),
            SizedBox(height: 16.h),
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:',
              bulletPoints: ['support@expensetracker.com'],
            ),
            SizedBox(height: 16.h),
            LocalizedText('Last updated: ${DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Privacy Policy',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6C63FF),
          ),
        ),
        SizedBox(height: 8.h),
        LocalizedText('Effective: ${DateTime.now().toString().substring(0, 10)}',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: const Color(0xFF6C63FF),
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: LocalizedText('Your financial data is important to us. This policy explains how we protect your privacy.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content,
      {List<String>? bulletPoints}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        LocalizedText(
          content,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
          ),
        ),
        if (bulletPoints != null) ...[
          SizedBox(height: 8.h),
          ...bulletPoints.map((point) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText('• ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: LocalizedText(
                        point,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
