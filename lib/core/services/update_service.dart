import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  Future<bool> checkAndNavigateIfRequired(BuildContext context) async {
    try {
      // Allow forcing off the update gate in debug and profile
      if (!kReleaseMode) return false;

      if (Platform.isAndroid) {
        final manager = InAppUpdateManager();
        final info = await manager.checkForUpdate();
        if (info == null) {
          return false;
        }
        final updateAvailable =
            info.updateAvailability == UpdateAvailability.updateAvailable ||
                info.updateAvailability ==
                    UpdateAvailability.developerTriggeredUpdateInProgress;
        if (updateAvailable) {
          if (context.mounted) {
            context.go(AppPaths.update);
          }
          return true;
        }
        return false;
      }

      if (Platform.isIOS) {
        final packageInfo = await PackageManager.getPackageInfo();
        final versionInfo = await UpgradeVersion.getiOSStoreVersion(
          packageInfo: packageInfo,
        );
        if (versionInfo.canUpdate == true) {
          if (context.mounted) {
            context.go(AppPaths.update);
          }
          return true;
        }
        return false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
