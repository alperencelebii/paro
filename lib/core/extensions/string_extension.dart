// ignore_for_file: public_member_api_docs

extension StringExtension on String {
  /// Capitializes the first letter of the string
  String capitalized() => '${this[0].toUpperCase()}${substring(1)}';
  /// Checks if the string contains another string after trimming
  bool trimmedContains(String other) => trim().toLowerCase().contains(
        other.trim().toLowerCase(),
      );
}
