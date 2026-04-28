import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/features/profile/help_support/cubit/help_support_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Help and Support screen with contact options and feature suggestions
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HelpSupportCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const LocalizedText('Help & Support'),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const _HelpSupportContent(),
      ),
    );
  }
}

class _HelpSupportContent extends StatelessWidget {
  const _HelpSupportContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportCard(),
            SizedBox(height: 24.h),
            _buildContactOptions(context),
            SizedBox(height: 24.h),
            _buildFeatureSuggestions(context),
            SizedBox(height: 24.h),
            _buildContactForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4839D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 32.r,
              ),
              SizedBox(width: 12.w),
              LocalizedText('We\'re Here to Help',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LocalizedText('Have questions or need assistance with the app? Our support team is ready to help you get the most out of your expense tracking experience.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOptions(BuildContext context) {
    final cubit = context.read<HelpSupportCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Contact Us',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        _buildContactItem(
          icon: Icons.email_outlined,
          title: 'Email Support',
          description: 'alperencelebiq@gmail.com',
          onTap: () => cubit.launchEmail(),
        ),
        SizedBox(height: 12.h),
        _buildContactItem(
          icon: Icons.question_answer_outlined,
          title: 'FAQ',
          description: 'Find answers to common questions',
          onTap: () {
            context.pushNamed(AppRoutes.faqScreen);
          },
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6C63FF),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      LocalizedText(
                        description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return BlocBuilder<HelpSupportCubit, HelpSupportState>(
      builder: (context, state) {
        final cubit = context.read<HelpSupportCubit>();

        return Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('Send Us a Message',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: state.subjectController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.tr('Subject'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: const Icon(Icons.subject),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.tr('Please enter a subject');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: state.messageController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.tr('Message'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: const Icon(Icons.message_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.tr('Please enter your message');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    if (state.errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: SelectableText.rich(
                          TextSpan(
                            text: state.errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    if (state.isSuccess)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8.w),
                            const LocalizedText('Message sent successfully!',
                              style: TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            state.isSending ? null : () => cubit.submitForm(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: state.isSending
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : LocalizedText('Send Message',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureSuggestions(BuildContext context) {
    final cubit = context.read<HelpSupportCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Feature Suggestions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 28.r,
                  ),
                  SizedBox(width: 12.w),
                  LocalizedText('Have an idea?',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              LocalizedText('We\'re constantly improving our app and would love to hear your suggestions for new features or improvements.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              _buildFeatureItem(
                title: 'Collaborate with us',
                description:
                    'Are you a developer or designer? Join our community to contribute directly to the app.',
                icon: Icons.people_outline,
                onTap: () => cubit.launchCollaborationEmail(),
              ),
              SizedBox(height: 16.h),
              _buildFeatureItem(
                title: 'Submit feature requests',
                description:
                    'Use the contact form above to suggest new features or improvements.',
                icon: Icons.add_circle_outline,
                onTap: () => cubit.launchFeatureRequestEmail(),
              ),
              SizedBox(height: 16.h),
              _buildFeatureItem(
                title: 'Join beta testing',
                description:
                    'Be the first to try new features and provide feedback.',
                icon: Icons.science_outlined,
                onTap: () => cubit.launchBetaTestingEmail(),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Set subject to Feature Suggestion
                    cubit.setSubject('Feature Suggestion');

                    // Scroll to the contact form
                    Scrollable.ensureVisible(
                      context
                          .read<HelpSupportCubit>()
                          .state
                          .formKey
                          .currentContext!,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: LocalizedText('Share Your Ideas',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6C63FF),
                size: 20.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16.r,
              ),
          ],
        ),
      ),
    );
  }
}
