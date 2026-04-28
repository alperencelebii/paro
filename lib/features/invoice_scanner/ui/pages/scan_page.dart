import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../bloc/scanner_bloc.dart';
import '../../bloc/scanner_event.dart';
import '../../bloc/scanner_state.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Page for selecting image source (camera or gallery)
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: LocalizedText(state.message),
              backgroundColor: Colors.red,
              action: state.canRetry
                  ? SnackBarAction(
                      label: AppLocalizations.tr('Retry'),
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<ScannerBloc>().add(const RetryScan());
                      },
                    )
                  : null,
            ),
          );
        } else if (state is ScannerCaptured) {
          // Navigate to crop page using Navigator
          Navigator.of(context).pushNamed(
            '/crop',
            arguments: state.image,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const LocalizedText('Scan Receipt / Invoice'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<ScannerBloc>().add(const CancelScan());
              Navigator.of(context).pop();
              // Navigator.of(context).pushNamed(AppRoutes.home);
            },
          ),
        ),
        body: BlocBuilder<ScannerBloc, ScannerState>(
          builder: (context, state) {
            if (state is ScannerRequestingPermissions) {
              return _buildPermissionRequest(context);
            } else if (state is ScannerPermissionsDenied) {
              return _buildPermissionsDenied(context, state.message);
            } else if (state is ScannerLoadingCamera) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return _buildImageSourceSelection(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    // Permissions are being requested automatically by the bloc
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const LocalizedText('Requesting permissions...'),
        ],
      ),
    );
  }

  Widget _buildPermissionsDenied(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            LocalizedText('Permissions Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LocalizedText(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ScannerBloc>().add(const RequestPermissions());
              },
              child: const LocalizedText('Grant Permissions'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await Permission.camera.request();
                await Permission.photos.request();
                // If still denied, open app settings
                final cameraGranted = await Permission.camera.isGranted;
                final storageGranted = await Permission.photos.isGranted ||
                    await Permission.storage.isGranted;
                if (!cameraGranted && !storageGranted) {
                  await openAppSettings();
                } else {
                  context.read<ScannerBloc>().add(const RequestPermissions());
                }
              },
              child: const LocalizedText('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceSelection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          LocalizedText('Scan Receipt or Invoice',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          LocalizedText('Take a photo or choose from gallery',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSourceButton(
                context,
                icon: Icons.camera_alt,
                label: AppLocalizations.tr('Take Photo'),
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              const SizedBox(width: 24),
              _buildSourceButton(
                context,
                icon: Icons.photo_library,
                label: AppLocalizations.tr('Gallery'),
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            LocalizedText(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        // Verify file exists and is accessible
        final file = File(pickedFile.path);
        if (await file.exists()) {
          // Small delay to ensure file is fully written (especially for camera)
          if (source == ImageSource.camera) {
            await Future.delayed(const Duration(milliseconds: 300));
          }

          // Verify file still exists after delay
          if (await file.exists()) {
            if (context.mounted) {
              context.read<ScannerBloc>().add(
                    ImagePicked(
                      image: file,
                      source:
                          source == ImageSource.camera ? 'camera' : 'gallery',
                    ),
                  );
            }
          } else {
            throw Exception('Image file was not saved properly');
          }
        } else {
          throw Exception('Image file not found at path: ${pickedFile.path}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: AppLocalizations.tr('Retry'),
              textColor: Colors.white,
              onPressed: () => _pickImage(context, source),
            ),
          ),
        );
      }
    }
  }
}
