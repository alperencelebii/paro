import 'package:flutter/material.dart';
import '../widgets/confidence_badge.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Widget to display an editable field with confidence badge
class FieldChip extends StatelessWidget {
  final String label;
  final String value;
  final double? confidence;
  final VoidCallback? onTap;
  final bool isLowConfidence;

  const FieldChip({
    super.key,
    required this.label,
    required this.value,
    this.confidence,
    this.onTap,
    this.isLowConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLowConfidence
              ? Colors.orange.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLowConfidence
                ? Colors.orange.withOpacity(0.5)
                : Colors.grey.shade300,
            width: isLowConfidence ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalizedText(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                LocalizedText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLowConfidence ? Colors.orange.shade900 : Colors.black87,
                  ),
                ),
              ],
            ),
            if (confidence != null) ...[
              const SizedBox(width: 8),
              ConfidenceBadge(confidence: confidence!),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

