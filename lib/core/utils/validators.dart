abstract final class FormValidators {
  static const int maxTitleLength = 60;
  static const int maxNotesLength = 200;
  static const int maxAmountMinor = 10000000000; // 10 crore rupees (₹100,000,000.00)

  /// Title is required and must not exceed [maxTitleLength] characters.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or less';
    }
    return null;
  }

  /// Amount must be greater than 0, with at most 2 decimal places and below a sane upper bound.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final String normalized = value.replaceAll(',', '').trim();
    final RegExp regex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!regex.hasMatch(normalized)) {
      return 'Enter a valid amount with up to 2 decimal places';
    }
    final double? parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    final int? minor = parseAmountMinor(value);
    if (minor == null || minor <= 0) {
      return 'Amount must be greater than 0';
    }
    if (minor > maxAmountMinor) {
      return 'Amount exceeds maximum allowable limit';
    }
    return null;
  }

  /// Parses monetary input into integer minor units (paise).
  static int? parseAmountMinor(String? value) {
    if (value == null) return null;
    final String normalized = value.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
    final List<String> parts = normalized.split('.');
    final int? rupees = int.tryParse(parts[0]);
    if (rupees == null) return null;
    final int paise = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
    return rupees * 100 + paise;
  }

  /// Category selection is mandatory.
  static String? validateCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return 'Please choose a category';
    }
    return null;
  }

  /// Date must be within a realistic timeframe.
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    final DateTime minDate = DateTime(2000, 1, 1);
    final DateTime maxDate = DateTime.now().add(const Duration(days: 365 * 5));
    if (date.isBefore(minDate)) {
      return 'Date is too far in the past';
    }
    if (date.isAfter(maxDate)) {
      return 'Date is too far in the future';
    }
    return null;
  }
}
