import 'package:finance_track/features/invoice_scanner/bloc/scanner_bloc.dart';
import 'package:finance_track/features/invoice_scanner/bloc/scanner_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'pages/camera_page.dart';
import 'pages/crop_page.dart';
import 'pages/preview_page.dart';
import 'dart:io';

/// Wrapper widget that uses the app-level ScannerBloc
/// The bloc is provided at the app level in app.dart
class ScannerWrapper extends StatefulWidget {
  const ScannerWrapper({super.key});

  @override
  State<ScannerWrapper> createState() => _ScannerWrapperState();
}

class _ScannerWrapperState extends State<ScannerWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize scanner when wrapper is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ScannerBloc>().add(const ScannerStarted());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ScannerBloc is provided at app level, just use it
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Reset scanner state when leaving
        if (mounted) {
          context.read<ScannerBloc>().add(const CancelScan());
          // Navigate back to home when back button is pressed
          GoRouter.of(context).go(AppPaths.home);
        }
      },
      child: Navigator(
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const CameraPage());
            case '/crop':
              final image = settings.arguments as File?;
              return MaterialPageRoute(
                builder: (_) => image != null
                    ? CropPage(image: image)
                    : const Scaffold(
                        body: Center(child: Text('No image provided')),
                      ),
              );
            case '/preview':
              return MaterialPageRoute(builder: (_) => const PreviewPage());
            default:
              return MaterialPageRoute(builder: (_) => const CameraPage());
          }
        },
        initialRoute: '/',
      ),
    );
  }
}
