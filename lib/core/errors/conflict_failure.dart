import '../../models/transaction_model.dart';

final class ConflictFailure implements Exception {
  const ConflictFailure(this.current);
  final TransactionModel current;
  @override
  String toString() =>
      'This transaction changed in Google Sheets. Reload it before saving.';
}
