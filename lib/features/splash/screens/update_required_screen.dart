import 'dart:io';
import 'package:finance_track/core/localization/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';

class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _isUpdating = false;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _isUpdating = true;
      _error = null;
    });
    try {
      if (Platform.isAndroid) {
        final manager = InAppUpdateManager();
        // Always check first to satisfy Play Core requirement
        final info = await manager.checkForUpdate();
        if (info == null ||
            info.updateAvailability != UpdateAvailability.updateAvailable) {
          // Nothing to update; continue app flow
          if (!mounted) return;
          Navigator.of(context).maybePop();
          return;
        }

        // Try immediate; if it returns an error message, fall back to flexible
        String? message =
            await manager.startAnUpdate(type: AppUpdateType.immediate);
        if (message != null) {
          // Play Core sometimes returns MSG_REQUIRE_CHECK_FOR_UPDATE if check wasn't run
          // or immediate flow not permitted. Fall back to flexible.
          message = await manager.startAnUpdate(type: AppUpdateType.flexible);
        }
        if (!mounted) return;
        if (message != null) {
          setState(() {
            _error = message;
            _isUpdating = false;
          });
        }
        return;
      }
      // else if (Platform.isIOS) {
      //   final packageInfo = await PackageManager.getPackageInfo();
      //   final versionInfo =
      //       await UpgradeVersion.getiOSStoreVersion(packageInfo: packageInfo);
      //   final link = versionInfo.appStoreLink;
      //   final uri = Uri.tryParse(link);
      //   if (uri != null) {
      //     await launchUrl(uri, mode: LaunchMode.externalApplication);
      //   }
      //   setState(() {
      //     _isUpdating = false;
      //   });
      // }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isUpdating = false;
      });
      // If anything goes wrong, allow user to proceed rather than blocking
      Navigator.of(context).maybePop();
    }
  }

  @override
  void initState() {
    super.initState();
    // For Android immediate flow, trigger right away
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startUpdate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.system_update,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              LocalizedText('Update Required',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LocalizedText('A newer version of the app is available and is required to continue.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                LocalizedText(_error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              if (Platform.isIOS)
                FilledButton(
                  onPressed: _isUpdating ? null : _startUpdate,
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const LocalizedText('Update Now'),
                ),
              if (Platform.isAndroid)
                LocalizedText('The update will start automatically. Please follow the on-screen instructions.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
