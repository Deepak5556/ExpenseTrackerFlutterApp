import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../data/expense_data_provider.dart';

class GoogleSheetsConnectionScreen extends ConsumerStatefulWidget {
  const GoogleSheetsConnectionScreen({super.key});

  @override
  ConsumerState<GoogleSheetsConnectionScreen> createState() =>
      _GoogleSheetsConnectionScreenState();
}

class _GoogleSheetsConnectionScreenState
    extends ConsumerState<GoogleSheetsConnectionScreen> {
  final TextEditingController _spreadsheetController = TextEditingController();
  List<drive.File> _workbooks = const <drive.File>[];
  String? _localError;
  bool _loadingWorkbooks = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(expenseDataProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _spreadsheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    final ExpenseDataController controller = ref.read(
      expenseDataProvider.notifier,
    );
    final String? error = _localError ?? data.error;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Google Sheets connection')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageCompact),
        children: <Widget>[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Your spreadsheet is your data store',
                  subtitle: 'Transactions are read and written directly to Google Sheets. This app does not keep a transaction database or offline cache.',
                  leading: Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.brandStart,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                if (data.accountEmail != null)
                  PillBadge(
                    label: 'Signed in · ${data.accountEmail}',
                    icon: Icons.verified_user_outlined,
                  )
                else
                  const PillBadge(
                    label: 'Google sign-in is required',
                    icon: Icons.account_circle_outlined,
                  ),
                if (data.isConnected) ...<Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Connected workbook',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  SelectableText(
                    data.spreadsheetId!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: AppSpacing.x2,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => _openWorkbook(data.spreadsheetId!),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open in Google Sheets'),
                      ),
                      TextButton.icon(
                        onPressed: data.saving
                            ? null
                            : () => _run(controller.disconnect),
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Create a new workbook',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x2),
                const Text(
                  'Creates an Expense Journal & Budget workbook with Transactions, Categories, Settings and Budgets tabs.',
                ),
                const SizedBox(height: AppSpacing.x4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: data.saving
                        ? null
                        : () => _run(controller.connectNewWorkbook),
                    icon: data.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_to_drive_rounded),
                    label: Text(
                      data.saving
                          ? 'Connecting…'
                          : 'Sign in and create workbook',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Use an existing workbook',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x2),
                const Text(
                  'Paste a spreadsheet URL or ID. With the approved drive.file permission, Google only exposes files created by or explicitly opened with this app.',
                ),
                const SizedBox(height: AppSpacing.x3),
                TextField(
                  controller: _spreadsheetController,
                  decoration: const InputDecoration(
                    labelText: 'Google Sheets URL or ID',
                    hintText: 'https://docs.google.com/spreadsheets/d/…',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: data.saving
                        ? null
                        : () => _run(
                            () => controller.connectExistingWorkbook(
                              _spreadsheetController.text,
                            ),
                          ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Connect by link or ID'),
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                TextButton.icon(
                  onPressed: _loadingWorkbooks
                      ? null
                      : _loadAccessibleWorkbooks,
                  icon: _loadingWorkbooks
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Show workbooks available to this app'),
                ),
                if (_workbooks.isNotEmpty) ...<Widget>[
                  const Divider(),
                  for (final drive.File file in _workbooks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.table_chart_outlined),
                      title: Text(
                        file.name ?? 'Untitled spreadsheet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(file.id ?? ''),
                      onTap: file.id == null
                          ? null
                          : () => _run(
                              () =>
                                  controller.connectExistingWorkbook(file.id!),
                            ),
                    ),
                ],
              ],
            ),
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.x3),
            SurfaceCard(
              color: const Color(0xFFFFF0ED),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.brandStart,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          const Text(
            'Setup needed before sign-in: enable Google Sheets API and Drive API in your Cloud project. Configure an Android OAuth client for package com.app.tracker.expense_journal_budget and your signing SHA-1, plus a Web OAuth client ID passed as GOOGLE_SERVER_CLIENT_ID. Never put a client secret in the app.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _localError = null);
    try {
      await action();
      if (mounted && ref.read(expenseDataProvider).isConnected) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _localError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _loadAccessibleWorkbooks() async {
    setState(() {
      _loadingWorkbooks = true;
      _localError = null;
    });
    try {
      final List<drive.File> files = await ref
          .read(expenseRepositoryProvider)
          .listAccessibleWorkbooks();
      if (mounted) setState(() => _workbooks = files);
    } catch (error) {
      if (mounted) {
        setState(
          () => _localError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWorkbooks = false);
    }
  }

  Future<void> _openWorkbook(String id) async {
    final Uri uri = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$id/edit',
    );
    // url_launcher is intentionally invoked only from the user's explicit action.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
