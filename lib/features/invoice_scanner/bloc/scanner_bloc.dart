import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../data/models/invoice_model.dart';
import '../services/ocr_service.dart';
import '../services/parser_service.dart';
import '../utils/permission_helper.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

/// BLoC for managing the invoice scanner flow
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final OcrService _ocrService;
  final ParserService _parserService;
  final ExpenseRepository _expenseRepository;
  final Uuid _uuid = const Uuid();

  ScannerBloc({
    required OcrService ocrService,
    required ParserService parserService,
    required ExpenseRepository expenseRepository,
  })  : _ocrService = ocrService,
        _parserService = parserService,
        _expenseRepository = expenseRepository,
        super(const ScannerInitial()) {
    on<ScannerStarted>(_onScannerStarted);
    on<ImagePicked>(_onImagePicked);
    on<ImageCropped>(_onImageCropped);
    on<RunOcr>(_onRunOcr);
    on<OcrCompleted>(_onOcrCompleted);
    on<FieldEdited>(_onFieldEdited);
    on<SaveInvoice>(_onSaveInvoice);
    on<RetryScan>(_onRetryScan);
    on<CancelScan>(_onCancelScan);
    on<RequestPermissions>(_onRequestPermissions);
  }

  Future<void> _onScannerStarted(
    ScannerStarted event,
    Emitter<ScannerState> emit,
  ) async {
    emit(const ScannerRequestingPermissions());
    
    // Check if permissions are already granted
    final cameraGranted = await PermissionHelper.isCameraPermissionGranted();
    final storageGranted = await PermissionHelper.isStoragePermissionGranted();
    
    if (cameraGranted || storageGranted) {
      // Permissions already granted, proceed to image selection
      emit(const ScannerInitial());
      return;
    }
    
    // Request permissions automatically
    final permissions = await PermissionHelper.requestAllPermissions();
    
    if (permissions['camera'] == true || permissions['storage'] == true) {
      // Permissions granted, proceed to image selection
      emit(const ScannerInitial());
    } else {
      // Permissions denied
      emit(const ScannerPermissionsDenied(
        message: 'Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.',
      ));
    }
  }

  void _onImagePicked(
    ImagePicked event,
    Emitter<ScannerState> emit,
  ) {
    emit(ScannerCaptured(image: event.image, source: event.source));
  }

  void _onImageCropped(
    ImageCropped event,
    Emitter<ScannerState> emit,
  ) {
    emit(ScannerCropping(image: event.croppedImage));
    // Automatically trigger OCR after cropping
    add(RunOcr(image: event.croppedImage));
  }

  Future<void> _onRunOcr(
    RunOcr event,
    Emitter<ScannerState> emit,
  ) async {
    emit(const ScannerProcessing(
      progress: 0.3,
      message: 'Processing image...',
    ));

    try {
      final recognizedText = await _ocrService.recognizeText(event.image);
      emit(const ScannerProcessing(
        progress: 0.7,
        message: 'Extracting data...',
      ));

      add(OcrCompleted(ocrResult: recognizedText, image: event.image));
    } catch (e) {
      emit(ScannerError(
        message: 'Failed to process image: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  void _onOcrCompleted(
    OcrCompleted event,
    Emitter<ScannerState> emit,
  ) {
    try {
      final invoiceId = _uuid.v4();
      // Parse plain text from Tesseract OCR
      final invoice = _parserService.parseInvoice(
        event.ocrResult as String, // Now expects plain String from Tesseract
        invoiceId,
        imagePath: event.image.path,
        source: 'camera', // Could be passed from ImagePicked event
      );

      emit(ScannerParsed(
        invoice: invoice,
        confidenceScores: invoice.confidence,
      ));
    } catch (e) {
      emit(ScannerError(
        message: 'Failed to parse invoice: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  void _onFieldEdited(
    FieldEdited event,
    Emitter<ScannerState> emit,
  ) {
    if (state is ScannerParsed) {
      final currentState = state as ScannerParsed;
      final invoice = currentState.invoice;

      InvoiceModel updatedInvoice;
      switch (event.fieldKey) {
        case 'merchant':
          updatedInvoice = invoice.copyWith(merchant: event.newValue as String);
          break;
        case 'date':
          updatedInvoice = invoice.copyWith(date: event.newValue as DateTime?);
          break;
        case 'total':
          updatedInvoice = invoice.copyWith(total: event.newValue as double?);
          break;
        case 'currency':
          updatedInvoice = invoice.copyWith(currency: event.newValue as String);
          break;
        default:
          updatedInvoice = invoice;
      }

      emit(ScannerParsed(
        invoice: updatedInvoice,
        confidenceScores: updatedInvoice.confidence,
      ));
    }
  }

  Future<void> _onSaveInvoice(
    SaveInvoice event,
    Emitter<ScannerState> emit,
  ) async {
    if (state is! ScannerParsed) {
      emit(const ScannerError(
        message: 'No invoice data to save',
        canRetry: false,
      ));
      return;
    }

    final currentState = state as ScannerParsed;
    final invoice = currentState.invoice;

    if (invoice.total == null || invoice.total! <= 0) {
      emit(const ScannerError(
        message: 'Invalid total amount',
        canRetry: false,
      ));
      return;
    }

    emit(const ScannerProcessing(
      progress: 0.9,
      message: 'Saving expense...',
    ));

    try {
      /// make invocie  hours and minutes to current time
      final invoiceDateWithoutTime = DateTime.now().copyWith(day: invoice.date?.day ?? DateTime.now().day, month: invoice.date?.month ?? DateTime.now().month, year: invoice.date?.year ?? DateTime.now().year, hour: DateTime.now().hour, minute: DateTime.now().minute);
      // Create expense from invoice
      final expense = Expense.create(
        uuid: _uuid.v4(),
        title: invoice.merchant.isNotEmpty
            ? invoice.merchant
            : 'Scanned Expense',
        amount: invoice.total!,
        date: invoiceDateWithoutTime, // Use current time, not bill date
        category: ExpenseCategory.other, // Default category
        notes: invoice.invoiceNumber != null
            ? 'Invoice #${invoice.invoiceNumber}'
            : null,
        paymentMethod: 'Card', // Default payment method
      );

      await _expenseRepository.addExpense(expense);

      emit(ScannerSaved(
        success: true,
        expenseId: expense.uuid,
      ));
    } catch (e) {
      emit(ScannerSaved(
        success: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onRetryScan(
    RetryScan event,
    Emitter<ScannerState> emit,
  ) {
    emit(const ScannerInitial());
  }

  void _onCancelScan(
    CancelScan event,
    Emitter<ScannerState> emit,
  ) {
    emit(const ScannerInitial());
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<ScannerState> emit,
  ) async {
    emit(const ScannerRequestingPermissions());
    
    // Request permissions
    final permissions = await PermissionHelper.requestAllPermissions();
    
    if (permissions['camera'] == true || permissions['storage'] == true) {
      // Permissions granted, proceed to image selection
      emit(const ScannerInitial());
    } else {
      // Permissions denied
      emit(const ScannerPermissionsDenied(
        message: 'Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.',
      ));
    }
  }

  @override
  Future<void> close() {
    _ocrService.dispose();
    return super.close();
  }
}

