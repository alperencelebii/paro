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
import 'package:finance_track/core/localization/localization.dart';

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
      emit(ScannerPermissionsDenied(
        message: AppLocalizations.tr('Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.'),
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
    emit(ScannerProcessing(
      progress: 0.3,
      message: AppLocalizations.tr('Processing image...'),
    ));

    try {
      final recognizedText = await _ocrService.recognizeText(event.image);
      emit(ScannerProcessing(
        progress: 0.7,
        message: AppLocalizations.tr('Extracting data...'),
      ));

      add(OcrCompleted(ocrResult: recognizedText, image: event.image));
    } catch (e) {
      emit(ScannerError(
        message: AppLocalizations.tr('Failed to process image: ${e.toString()}'),
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
        message: AppLocalizations.tr('Failed to parse invoice: ${e.toString()}'),
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
      emit(ScannerError(
        message: AppLocalizations.tr('No invoice data to save'),
        canRetry: false,
      ));
      return;
    }

    final currentState = state as ScannerParsed;
    final invoice = currentState.invoice;

    if (invoice.total == null || invoice.total! <= 0) {
      emit(ScannerError(
        message: AppLocalizations.tr('Invalid total amount'),
        canRetry: false,
      ));
      return;
    }

    emit(ScannerProcessing(
      progress: 0.9,
      message: AppLocalizations.tr('Saving expense...'),
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
        category: _guessExpenseCategory(invoice),
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


  ExpenseCategory _guessExpenseCategory(InvoiceModel invoice) {
    final source = [
      invoice.merchant,
      invoice.rawOcrText ?? '',
      invoice.lineItems.map((item) => item.description).join(' '),
    ].join(' ').toLowerCase();

    if (RegExp(r'(market|mart|grocery|supermarket|migros|carrefour|bim|a101|sok|şok|food|restaurant|cafe|coffee|pizza|burger|yemek|lokanta)').hasMatch(source)) {
      return ExpenseCategory.food;
    }
    if (RegExp(r'(taxi|uber|fuel|gas|petrol|metro|bus|train|otobus|otobüs|ulaşım|transport)').hasMatch(source)) {
      return ExpenseCategory.transportation;
    }
    if (RegExp(r'(electric|water|internet|phone|bill|utility|fatura|doğalgaz|dogalgaz)').hasMatch(source)) {
      return ExpenseCategory.utilities;
    }
    if (RegExp(r'(pharmacy|eczane|hospital|clinic|health|medical|ilaç|ilac)').hasMatch(source)) {
      return ExpenseCategory.health;
    }
    if (RegExp(r'(clothes|fashion|store|shop|shopping|giyim|ayakkabı|ayakkabi)').hasMatch(source)) {
      return ExpenseCategory.shopping;
    }
    if (RegExp(r'(cinema|movie|game|entertainment|concert|eglence|eğlence)').hasMatch(source)) {
      return ExpenseCategory.entertainment;
    }
    if (RegExp(r'(hotel|flight|travel|booking|airlines|otel|uçak|ucak|seyahat)').hasMatch(source)) {
      return ExpenseCategory.travel;
    }
    if (RegExp(r'(school|course|book|education|kurs|kitap|okul)').hasMatch(source)) {
      return ExpenseCategory.education;
    }
    return ExpenseCategory.other;
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
      emit(ScannerPermissionsDenied(
        message: AppLocalizations.tr('Camera and storage permissions are required to scan receipts. Please grant permissions in app settings.'),
      ));
    }
  }

  @override
  Future<void> close() {
    _ocrService.dispose();
    return super.close();
  }
}

