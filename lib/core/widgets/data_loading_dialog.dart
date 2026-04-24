// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../services/data_fetching_service.dart';

// /// A dialog that shows loading progress while fetching data from Firebase.
// class DataLoadingDialog extends StatefulWidget {
//   /// The stream of data fetch status to listen to
//   final Stream<DataFetchStatus> statusStream;

//   /// Optional callback when loading completes
//   final VoidCallback? onComplete;

//   /// Optional callback when there's an error
//   final Function(String)? onError;

//   /// Optional callback when no data is found
//   final VoidCallback? onEmpty;

//   /// Constructor
//   const DataLoadingDialog({
//     super.key,
//     required this.statusStream,
//     this.onComplete,
//     this.onError,
//     this.onEmpty,
//   });

//   @override
//   State<DataLoadingDialog> createState() => _DataLoadingDialogState();
// }

// class _DataLoadingDialogState extends State<DataLoadingDialog> {
//   DataFetchStatus _status = DataFetchStatus.loading;
//   String _errorMessage = '';
//   double _progress = 0.0;

//   // This flag prevents multiple callbacks from being triggered
//   bool _hasCompletedCallback = false;

//   @override
//   void initState() {
//     super.initState();

//     // Use late subscription to allow for cleanup in dispose
//     late final StreamSubscription<DataFetchStatus> subscription;

//     subscription = widget.statusStream.listen(
//       (status) {
//         // Check if widget is still mounted before updating state
//         if (!mounted) return;

//         // Prevent updating if we've already completed
//         if (_hasCompletedCallback) return;

//         setState(() {
//           _status = status;

//           // Update progress
//           if (status == DataFetchStatus.loading) {
//             _progress = DataFetchingService.instance.fetchProgress;
//           }
//         });

//         // Handle completion
//         if (status == DataFetchStatus.success &&
//             widget.onComplete != null &&
//             !_hasCompletedCallback) {
//           _hasCompletedCallback = true;
//           // Don't pop the navigator here - leave that to the parent
//           widget.onComplete!();
//         }

//         // Handle error
//         if (status == DataFetchStatus.error &&
//             widget.onError != null &&
//             !_hasCompletedCallback) {
//           _hasCompletedCallback = true;
//           // Don't pop the navigator here - leave that to the parent
//           widget.onError!(
//               _errorMessage.isEmpty ? 'Failed to fetch data' : _errorMessage);
//         }

//         // Handle empty
//         if (status == DataFetchStatus.empty &&
//             widget.onEmpty != null &&
//             !_hasCompletedCallback) {
//           _hasCompletedCallback = true;
//           // Don't pop the navigator here - leave that to the parent
//           widget.onEmpty!();
//         }
//       },
//       onError: (error) {
//         // Check if widget is still mounted before updating state
//         if (!mounted || _hasCompletedCallback) return;

//         _hasCompletedCallback = true;

//         setState(() {
//           _status = DataFetchStatus.error;
//           _errorMessage = error.toString();
//         });

//         if (widget.onError != null) {
//           // Don't pop the navigator here - leave that to the parent
//           widget.onError!(error.toString());
//         }
//       },
//     );

//     // Store subscription for cleanup in dispose
//     _statusSubscription = subscription;
//   }

//   // Store the subscription to cancel it on dispose
//   StreamSubscription<DataFetchStatus>? _statusSubscription;

//   @override
//   void dispose() {
//     // Cancel the subscription to prevent memory leaks
//     _statusSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16.r),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(24.r),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Loading Your Data',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             SizedBox(height: 16.h),
//             _buildStatusContent(),
//             SizedBox(height: 8.h),
//             if (_status == DataFetchStatus.loading) ...[
//               LinearProgressIndicator(
//                 value: _progress > 0 ? _progress : null,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).primaryColor,
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               Text(
//                 'Please wait while we fetch your transactions...',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14.sp,
//                 ),
//               ),
//             ],
//             if (_status == DataFetchStatus.error ||
//                 _status == DataFetchStatus.empty)
//               ElevatedButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Close'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusContent() {
//     switch (_status) {
//       case DataFetchStatus.loading:
//         return SizedBox(
//           height: 100.h,
//           width: 100.w,
//           child: CircularProgressIndicator(
//             strokeWidth: 5.w,
//             valueColor: AlwaysStoppedAnimation<Color>(
//               Theme.of(context).primaryColor,
//             ),
//           ),
//         );

//       case DataFetchStatus.success:
//         return Column(
//           children: [
//             Icon(
//               Icons.check_circle,
//               color: Colors.green,
//               size: 64.r,
//             ),
//             SizedBox(height: 16.h),
//             const Text(
//               'Data loaded successfully!',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         );

//       case DataFetchStatus.error:
//         return Column(
//           children: [
//             Icon(
//               Icons.error,
//               color: Colors.red,
//               size: 64.r,
//             ),
//             SizedBox(height: 16.h),
//             Text(
//               _errorMessage.isEmpty
//                   ? 'Failed to load data. Please try again.'
//                   : _errorMessage,
//               textAlign: TextAlign.center,
//             ),
//           ],
//         );

//       case DataFetchStatus.empty:
//         return Column(
//           children: [
//             Icon(
//               Icons.info,
//               color: Colors.blue,
//               size: 64.r,
//             ),
//             SizedBox(height: 16.h),
//             const Text(
//               'No transactions found. Start adding your income and expenses!',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         );

//       default:
//         return const SizedBox.shrink();
//     }
//   }
// }
