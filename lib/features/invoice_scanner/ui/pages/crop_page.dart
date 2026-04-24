import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/scanner_bloc.dart';
import '../../bloc/scanner_event.dart';
import '../../bloc/scanner_state.dart';
import '../../data/models/invoice_model.dart';
import '../../../transactions/screens/add_transaction_bottom_sheet.dart';
import '../../../../core/router/app_router.dart';

/// Page for cropping the captured image
/// Managed by ScannerBloc for proper state management
class CropPage extends StatefulWidget {
  final File image;

  const CropPage({
    super.key,
    required this.image,
  });

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> with WidgetsBindingObserver {
  bool _hasStartedCropping = false;
  ImageCropper? _imageCropper;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _imageCropper = ImageCropper();

    // Start cropping after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCropping();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _imageCropper = null;
    super.dispose();
  }

  Future<void> _startCropping() async {
    // Prevent multiple calls
    if (_hasStartedCropping || !mounted) {
      return;
    }

    _hasStartedCropping = true;

    try {
      // Verify image file exists
      if (!await widget.image.exists()) {
        throw Exception('Image file not found');
      }

      final cropper = _imageCropper;
      if (cropper == null || !mounted) {
        return;
      }

      // Call cropImage with proper error handling
      final croppedFile = await cropper.cropImage(
        sourcePath: widget.image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1.4),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropFrameColor: Theme.of(context).colorScheme.primary,
            cropGridColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (!mounted) return;

      if (croppedFile != null) {
        // Verify cropped file exists
        final croppedImageFile = File(croppedFile.path);
        if (await croppedImageFile.exists()) {
          // Small delay to ensure UI is updated
          await Future.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          // Dispatch ImageCropped event - bloc will handle OCR automatically
          if (context.mounted) {
            context.read<ScannerBloc>().add(
                  ImageCropped(croppedImage: croppedImageFile),
                );
          }
        } else {
          throw Exception('Cropped image file not found');
        }
      } else {
        // User cancelled cropping, go back
        if (mounted) {
          context.read<ScannerBloc>().add(const CancelScan());
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            GoRouter.of(context).go(AppPaths.home);
          }
        }
      }
    } catch (e) {
      // Handle errors via bloc
      if (!mounted) return;

      if (context.mounted) {
        // Error will be handled by bloc listener
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _hasStartedCropping = false;
                _startCropping();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerError) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: state.canRetry
                    ? SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          _hasStartedCropping = false;
                          context.read<ScannerBloc>().add(const RetryScan());
                        },
                      )
                    : null,
              ),
            );
          }
        } else if (state is ScannerParsed) {
          // Navigate directly to expense bottom sheet, skip preview
          if (mounted && context.mounted) {
            _showExpenseBottomSheet(context, state.invoice);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
              statusBarBrightness:
                  Theme.of(context).brightness == Brightness.dark
                      ? Brightness.dark
                      : Brightness.light,
            ),
            title: const Text('Crop Receipt'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: state is ScannerProcessing
                  ? null
                  : () {
                      if (mounted && context.mounted) {
                        context.read<ScannerBloc>().add(const CancelScan());
                        // Navigate back to camera or home
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          // If can't pop, navigate to home
                          GoRouter.of(context).go(AppPaths.home);
                        }
                      }
                    },
            ),
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ScannerState state) {
    // Show error state
    if (state is ScannerError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error cropping image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (mounted && context.mounted) {
                        context.read<ScannerBloc>().add(const CancelScan());
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          GoRouter.of(context).go(AppPaths.home);
                        }
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      _hasStartedCropping = false;
                      _startCropping();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Show processing state
    if (state is ScannerProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Processing image...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                '${((state.progress ?? 0) * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              state.message == 'Processing image...'
                  ? 'Please crop your receipt'
                  : 'Extracting receipt information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    // Show cropping state or initial state
    if (state is ScannerCropping || !_hasStartedCropping) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _hasStartedCropping
                  ? 'Opening crop editor...'
                  : 'Preparing crop editor...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    // Default state
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  void _showExpenseBottomSheet(BuildContext context, InvoiceModel invoice) {
    // Close crop page first
    Navigator.of(context).pop();

    // Prepare initial data from invoice - include all content
    final notesBuilder = StringBuffer();

    // Add merchant name
    if (invoice.merchant.isNotEmpty) {
      notesBuilder.writeln(invoice.merchant);
    }

    // Add invoice number if available
    if (invoice.invoiceNumber != null && invoice.invoiceNumber!.isNotEmpty) {
      notesBuilder.writeln('Invoice #${invoice.invoiceNumber}');
    }

    // Add line items if available
    if (invoice.lineItems.isNotEmpty) {
      notesBuilder.writeln('\nItems:');
      for (final item in invoice.lineItems.take(5)) {
        // Limit to first 5 items
        if (item.description.isNotEmpty) {
          notesBuilder.writeln('• ${item.description}');
          if (item.quantity > 0 && item.total > 0) {
            notesBuilder.writeln(
                '  ${item.quantity}x ${invoice.currency}${item.unitPrice.toStringAsFixed(2)} = ${invoice.currency}${item.total.toStringAsFixed(2)}');
          }
        }
      }
      if (invoice.lineItems.length > 5) {
        notesBuilder
            .writeln('... and ${invoice.lineItems.length - 5} more items');
      }
    }

    // Add subtotal, tax, total if available
    if (invoice.subtotal != null) {
      notesBuilder.writeln(
          '\nSubtotal: ${invoice.currency}${invoice.subtotal!.toStringAsFixed(2)}');
    }
    if (invoice.tax != null && invoice.tax! > 0) {
      notesBuilder.writeln(
          'Tax: ${invoice.currency}${invoice.tax!.toStringAsFixed(2)}');
    }
    if (invoice.total != null) {
      notesBuilder.writeln(
          'Total: ${invoice.currency}${invoice.total!.toStringAsFixed(2)}');
    }

    // Use raw OCR text if available (contains all scanned content)
    final notes = invoice.rawOcrText != null && invoice.rawOcrText!.isNotEmpty
        ? invoice.rawOcrText!
        : notesBuilder.toString().trim();

    final initialData = <String, dynamic>{
      if (invoice.total != null) 'amount': invoice.total!,
      'date': DateTime.now(), // Use current time, not bill date
      'title':
          invoice.merchant.isNotEmpty ? invoice.merchant : 'Scanned Receipt',
      'notes': notes,
    };

    // Wait a frame to ensure navigation is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get root navigator context for proper navigation
      final rootContext = Navigator.of(context, rootNavigator: true).context;

      // Show the red Add Transaction bottom sheet with pre-filled data
      AddTransactionBottomSheet.show(
        context: rootContext,
        initialType: TransactionType.expense,
        initialData: initialData,
      ).then((result) {
        if (result == true) {
          // Expense was saved successfully - bottom sheet already refreshed the list
          // Navigate back to home - GoRouter will close the scanner wrapper
          if (rootContext.mounted) {
            // Navigate back to home (expense list is already refreshed by bottom sheet)
            GoRouter.of(rootContext).go(AppPaths.home);
          }
        }
      });
    });
  }
}
