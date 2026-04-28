import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/scanner_bloc.dart';
import '../../bloc/scanner_event.dart';
import '../../bloc/scanner_state.dart';
import '../../utils/permission_helper.dart';
import '../../../../core/router/app_router.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Camera page for capturing receipt images
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isLoading = true;
  bool _isInitializing = false; // Prevent concurrent initialization

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Prevent concurrent initialization
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;

    try {
      // Check permissions first
      final cameraGranted = await PermissionHelper.isCameraPermissionGranted();
      if (!cameraGranted) {
        final granted = await PermissionHelper.requestCameraPermission();
        if (!granted) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isPermissionGranted = false;
              _isInitializing = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isPermissionGranted = true;
        });
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Initialize camera controller
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      final file = File(image.path);

      if (await file.exists()) {
        if (mounted) {
          context.read<ScannerBloc>().add(
                ImagePicked(
                  image: file,
                  source: 'camera',
                ),
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Failed to take picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPickingFromGallery = false; // Prevent concurrent gallery picks

  Future<void> _pickFromGallery() async {
    // Prevent concurrent gallery picks
    if (_isPickingFromGallery) {
      return;
    }

    _isPickingFromGallery = true;

    try {
      // On iOS, image_picker handles permissions internally via system picker
      // On Android, we should request permission first, but image_picker can also handle it
      // Try to pick first - if it fails due to permission, then request it
      
      final picker = ImagePicker();
      XFile? pickedFile;
      
      try {
        // Try to pick image - image_picker will handle permissions on iOS
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (e) {
        // If picking fails due to permission, request it explicitly (mainly for Android)
        if (e.toString().toLowerCase().contains('permission') || 
            e.toString().toLowerCase().contains('denied')) {
          
          // Check and request permission
          bool storageGranted = await PermissionHelper.isStoragePermissionGranted();
          
          if (!storageGranted) {
            storageGranted = await PermissionHelper.requestStoragePermission();
            
            if (!storageGranted) {
              // Check if permanently denied
              final isPermanentlyDenied = await PermissionHelper.isStoragePermissionPermanentlyDenied();
              
              if (mounted) {
                if (isPermanentlyDenied) {
                  // Show dialog to open settings
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const LocalizedText('Permission Required'),
                      content: const LocalizedText('Storage permission is required to select photos. Please grant permission in app settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const LocalizedText('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await PermissionHelper.openAppSettings();
                          },
                          child: const LocalizedText('Open Settings'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Show snackbar for temporary denial
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText('Storage permission is required to select photos'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
              return;
            }
            
            // Permission granted, try picking again
            try {
              pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
                maxWidth: 1920,
                maxHeight: 1920,
              );
            } catch (e2) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: LocalizedText('Failed to pick image: ${e2.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }
          }
        } else {
          // Other error, rethrow
          rethrow;
        }
      }

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          if (mounted) {
            // Dispatch event to bloc
            context.read<ScannerBloc>().add(
                  ImagePicked(
                    image: file,
                    source: 'gallery',
                  ),
                );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: LocalizedText('Selected image file not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle specific error cases
        String errorMessage = 'Failed to pick image';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant storage permission in app settings.';
        } else if (e.toString().contains('not found') || e.toString().contains('file')) {
          errorMessage = 'Image file not found. Please try selecting another image.';
        } else {
          errorMessage = 'Failed to pick image: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.tr('Retry'),
              textColor: Colors.white,
              onPressed: () => _pickFromGallery(),
            ),
          ),
        );
      }
    } finally {
      _isPickingFromGallery = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerCaptured) {
          // Navigate to crop page when image is captured or picked
          if (mounted) {
            Navigator.of(context).pushNamed(
              '/crop',
              arguments: state.image,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Camera preview
              if (_isInitialized && _controller != null)
                SizedBox.expand(
                  child: CameraPreview(_controller!),
                )
              else if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (!_isPermissionGranted)
                _buildPermissionDenied()
              else
                _buildErrorState(),

              // Top bar with close button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          // Navigate back to home using GoRouter
                          final rootContext = Navigator.of(context, rootNavigator: true).context;
                          if (rootContext.mounted) {
                            GoRouter.of(rootContext).go(AppPaths.home);
                          }
                        },
                      ),
                      // Select photo button
                      TextButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library,
                            color: Colors.white),
                        label: const LocalizedText('Select Photo',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              if (_isInitialized && _controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Capture button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const LocalizedText('Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const LocalizedText('Please grant camera permission to scan receipts',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final granted =
                    await PermissionHelper.requestCameraPermission();
                if (granted) {
                  _initializeCamera();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: LocalizedText('Please grant camera permission in app settings',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const LocalizedText('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const LocalizedText('Camera Not Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const LocalizedText('Unable to access camera. Please try again.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const LocalizedText('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
