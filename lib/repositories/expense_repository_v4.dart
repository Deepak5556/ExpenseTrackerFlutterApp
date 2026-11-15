import '../models/transaction_model.dart';
import '../services/google_sheets_service.dart';

abstract interface class ExpenseRepositoryV4 {
  Future<SheetReadResult> readAll();
  Future<void> append(TransactionModel item);
  Future<void> update(TransactionModel item);
  Future<void> delete(TransactionModel item);
}
