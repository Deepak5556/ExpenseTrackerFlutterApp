import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;

import '../features/data/expense_data_provider.dart';
import '../models/transaction_model.dart';
import '../services/google_sheets_service.dart';

/// Temporary Phase 4 service screen. Remove in Phase 11.
class SheetDebugScreen extends ConsumerStatefulWidget {
  const SheetDebugScreen({super.key});
  @override
  ConsumerState<SheetDebugScreen> createState() => _SheetDebugScreenState();
}

class _SheetDebugScreenState extends ConsumerState<SheetDebugScreen> {
  String _output = 'Ready';
  TransactionModel? _sample;
  bool _busy = false;
  Future<void> _run(
    String label,
    Future<String> Function(
      String id,
      GoogleSheetsService service,
      google_auth.AuthClient client,
    )
    action,
  ) async {
    setState(() {
      _busy = true;
      _output = '$label…';
    });
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final id = repo.spreadsheetId ?? await repo.loadConnectionId();
      if (id == null) throw StateError('Connect a spreadsheet first.');
      final auth = ref.read(googleAuthServiceProvider);
      final client = await auth.authorizedClient();
      try {
        _output = await action(id, const GoogleSheetsService(), client);
      } finally {
        client.close();
      }
    } catch (e) {
      _output = 'Error: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sheets data debug')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _button(
              'Validate',
              () => _run(
                'Validating',
                (id, s, c) async =>
                    '${(await s.validateSpreadsheetV4(id, client: c)).problems}',
              ),
            ),
            _button(
              'Read all',
              () => _run('Reading', (id, s, c) async {
                final r = await s.readAll(id, client: c);
                return 'Transactions: ${r.transactions.length}; invalid rows: ${r.invalidRows}; categories: ${r.categoryRows.length}; settings: ${r.settingsRows.length}';
              }),
            ),
            _button(
              'Append sample',
              () => _run('Appending', (id, s, c) async {
                final now = DateTime.now().toUtc().toIso8601String();
                _sample = TransactionModel(
                  transactionId: const Uuid().v4(),
                  type: TransactionType.expense,
                  title: 'Debug sample',
                  amountMinor: 12345,
                  categoryId: 'food',
                  categoryName: 'Food',
                  date: '2026-11-15',
                  time: '12:00',
                  updatedAt: now,
                );
                await s.appendTransaction(id, _sample!, client: c);
                return 'Appended ${_sample!.transactionId}';
              }),
            ),
            _button(
              'Update sample',
              () => _run('Updating', (id, s, c) async {
                final item = _sample;
                if (item == null) throw StateError('Append a sample first.');
                final updated = item.copyWith(title: 'Updated debug sample');
                await s.updateTransaction(id, updated, client: c);
                _sample = updated.copyWith(
                  updatedAt: DateTime.now().toUtc().toIso8601String(),
                );
                return 'Updated ${item.transactionId}';
              }),
            ),
            _button(
              'Delete sample',
              () => _run('Deleting', (id, s, c) async {
                final item = _sample;
                if (item == null) throw StateError('Append a sample first.');
                await s.deleteTransaction(id, item, client: c);
                _sample = null;
                return 'Deleted ${item.transactionId}';
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_busy) const LinearProgressIndicator(),
        SelectableText(_output),
      ],
    ),
  );
  Widget _button(String title, VoidCallback onPressed) => FilledButton.tonal(
    onPressed: _busy ? null : onPressed,
    child: Text(title),
  );
}
