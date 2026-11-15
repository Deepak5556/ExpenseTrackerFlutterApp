import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/window_size_class.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/spreadsheet_connection_provider.dart';
import '../../../repositories/spreadsheet_connection_repository.dart';

class SpreadsheetSetupScreen extends ConsumerStatefulWidget {
  const SpreadsheetSetupScreen({super.key});
  @override
  ConsumerState<SpreadsheetSetupScreen> createState() =>
      _SpreadsheetSetupScreenState();
}

class _SpreadsheetSetupScreenState
    extends ConsumerState<SpreadsheetSetupScreen> {
  bool _salaryShown = false;
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(spreadsheetConnectionProvider.notifier).connectOrCreate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spreadsheetConnectionProvider);
    if (state.status == SpreadsheetConnectionStatus.ready &&
        state.setupCompleted &&
        !_salaryShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
    if (state.status == SpreadsheetConnectionStatus.ready &&
        !state.setupCompleted &&
        !_salaryShown) {
      _salaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSalary();
      });
    }
    final bool working =
        state.status == SpreadsheetConnectionStatus.creating ||
        state.status == SpreadsheetConnectionStatus.validating;
    final bool hasProblem =
        state.status == SpreadsheetConnectionStatus.failed ||
        state.status == SpreadsheetConnectionStatus.missing ||
        state.status == SpreadsheetConnectionStatus.noPermission ||
        state.status == SpreadsheetConnectionStatus.needsRepair;
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your spreadsheet')),
      body: ResponsiveListView(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.table_chart_rounded,
                  size: context.responsiveValue(compact: 52, medium: 58),
                  color: AppColors.brandStart,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your journal will live in your Google Drive',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 28),
                for (final (int, String) step in <(int, String)>[
                  (0, 'Finding your sheet'),
                  (1, 'Creating your sheet'),
                  (2, 'Preparing worksheets'),
                  (3, 'Done'),
                ])
                  ListTile(
                    leading: CircleAvatar(
                      child: working
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('${step.$1 + 1}'),
                    ),
                    title: Text(step.$2),
                  ),
                if (state.warning != null)
                  Text(
                    state.warning!,
                    style: const TextStyle(color: AppColors.amber),
                  ),
                if (hasProblem) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    state.failure?.message ??
                        switch (state.status) {
                          SpreadsheetConnectionStatus.missing =>
                            'The saved sheet is missing or was trashed.',
                          SpreadsheetConnectionStatus.noPermission =>
                            'You no longer have permission to use this sheet.',
                          SpreadsheetConnectionStatus.needsRepair => 'The sheet exists but needs its tabs prepared. Retry setup.',
                          _ => 'Could not prepare your spreadsheet. Try again.',
                        },
                    style: const TextStyle(color: AppColors.brandStart),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref
                        .read(spreadsheetConnectionProvider.notifier)
                        .connectOrCreate(),
                    child: const Text('Retry'),
                  ),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(spreadsheetConnectionProvider.notifier)
                        .createNew(),
                    child: const Text('Create new sheet'),
                  ),
                ],
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Connect later'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSalary() async {
    final controller = TextEditingController();
    final int? value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What’s your monthly salary?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Monthly salary (INR)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final double amount =
                      double.tryParse(controller.text.trim()) ?? -1;
                  if (amount < 0) return;
                  Navigator.pop(context, amount.round());
                },
                child: const Text('Save and continue'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    await ref.read(spreadsheetConnectionProvider.notifier).completeSetup(value);
    if (mounted) context.go('/home');
  }
}
