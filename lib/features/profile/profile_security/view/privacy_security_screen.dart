import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/export_service.dart';
import '../../../../data/objectbox.dart';
import '../../../../data/repositories/objectbox_expense_repository.dart';
import '../../../../data/repositories/objectbox_income_repository.dart';
import '../bloc/privacy_security_bloc.dart';
import '../../widgets/animated_settings_item.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PrivacySecurityBloc()..add(const LoadPrivacySecuritySettings()),
      child: const PrivacySecurityView(),
    );
  }
}

class PrivacySecurityView extends StatelessWidget {
  const PrivacySecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrivacySecurityBloc, PrivacySecurityState>(
      listenWhen: (previous, current) =>
          current.error != null ||
          current.successMessage != null ||
          current.isExporting,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (state.isExporting) {
          _exportTransactions(
            context: context,
            isJson: state.exportFormat == ExportFormat.json,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Privacy & Security'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<PrivacySecurityBloc, PrivacySecurityState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  SizedBox(height: 16.h),
                  _buildSecuritySection(context, state),
                  SizedBox(height: 16.h),
                  _buildPrivacySection(context, state),
                  SizedBox(height: 16.h),
                  _buildDataHandlingSection(context),
                  SizedBox(height: 16.h),
                  // _buildLegalSection(context),
                  // SizedBox(height: 32.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: const Color(0xFF6C63FF),
                size: 28.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Your Privacy Matters',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'This is your control center for privacy and security settings. '
            'We prioritize your data privacy with our offline-first approach.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(
      BuildContext context, PrivacySecurityState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'Security',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedSettingsItem(
          icon: Icons.fingerprint,
          title: 'Biometric Authentication',
          subtitle: 'Use fingerprint or face recognition to access the app',
          trailing: Switch(
            value: state.biometricEnabled,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (value) {
              // Show a snackbar notification instead of toggling the setting
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 10.w),
                      const Expanded(
                        child: Text('Biometric authentication coming soon!'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.amber.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
              );
            },
          ),
          iconColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildPrivacySection(
      BuildContext context, PrivacySecurityState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'Privacy',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedSettingsItem(
          icon: Icons.delete_outline,
          title: 'Request Data Deletion',
          subtitle: 'Delete all your data from our servers',
          iconColor: Colors.red,
          onTap: () => _showDataDeletionDialog(context),
        ),
      ],
    );
  }

  Widget _buildDataHandlingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'Data Handling',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedSettingsItem(
          icon: Icons.storage_outlined,
          title: 'Cloud Data Storage',
          subtitle: 'Your data is primarily stored locally with ObjectBox',
          iconColor: Colors.indigo,
          onTap: () => _showDataStorageInfoDialog(context),
        ),
        AnimatedSettingsItem(
          icon: Icons.cloud_outlined,
          title: 'Firebase Storage',
          subtitle: 'Secure cloud backup of your financial data',
          iconColor: Colors.orange,
          onTap: () => _showFirebaseInfoDialog(context),
        ),
        AnimatedSettingsItem(
          icon: Icons.download_outlined,
          title: 'Export Your Data',
          subtitle: 'Download a copy of all your financial data',
          iconColor: Colors.deepPurple,
          onTap: () => _showExportDataDialog(context),
        ),
      ],
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Data?'),
        content: const Text(
          'This will permanently delete all your data from our servers. Your local data will remain intact. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PrivacySecurityBloc>()
                  .add(const RequestDataDeletion());
            },
            child: const Text('Delete My Data'),
          ),
        ],
      ),
    );
  }

  void _showDataStorageInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Data Storage'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This app uses ObjectBox for secure local data storage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title:
                    Text('All financial data is stored on your device first'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title:
                    Text('Works offline with no internet connection required'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text('Fast and efficient with minimal battery usage'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Your data never leaves your device unless cloud sync is enabled'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Cloud Storage'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'When cloud sync is enabled:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text('Your data is securely encrypted in transit'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Only you can access your financial data with your account'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Google Firebase security standards protect your information'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                contentPadding: EdgeInsets.zero,
                title: Text('Data is synchronized across all your devices'),
              ),
              SizedBox(height: 8),
              Text(
                'You can disable cloud sync at any time to keep your data local only.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Your Data'),
        content: const Text(
          'You can export all your financial data as a CSV or JSON file. This includes all your income and expense transactions, categories, and budget settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PrivacySecurityBloc>()
                  .add(const ExportData(isJson: false));
            },
            child: const Text('Export as CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PrivacySecurityBloc>()
                  .add(const ExportData(isJson: true));
            },
            child: const Text('Export as JSON'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions({
    required BuildContext context,
    required bool isJson,
  }) async {
    final objectBox = ObjectBox.instance;
    final expenseRepository = ObjectBoxExpenseRepository(objectBox);
    final incomeRepository = ObjectBoxIncomeRepository(objectBox);

    final exportService = ExportService(
      expenseRepository: expenseRepository,
      incomeRepository: incomeRepository,
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting data, please wait...'),
          duration: Duration(seconds: 2),
        ),
      );

      final filePath = isJson
          ? await exportService.exportAsJSON()
          : await exportService.exportAsCSV();

      if (!context.mounted) return;

      // Show success message and give user option to share the file
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Export Successful'),
          content: Text(
            'Your transactions have been exported to: $filePath',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                exportService.shareFile(filePath);
              },
              child: const Text('Share File'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
