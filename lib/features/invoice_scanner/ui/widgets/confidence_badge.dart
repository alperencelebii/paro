import 'package:flutter/material.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Widget to display confidence score for a field
class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final double threshold;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.threshold = 0.70,
  });

  @override
  Widget build(BuildContext context) {
    final isLowConfidence = confidence < threshold;
    final percentage = (confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowConfidence
            ? Colors.orange.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowConfidence ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLowConfidence ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 14,
            color: isLowConfidence ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 4),
          LocalizedText('$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLowConfidence ? Colors.orange.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

