import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/expense_data_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveListView(
        children: <Widget>[
          SurfaceCard(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.orangePillSurface,
                  child: Text(
                    (data.accountName?.isNotEmpty ?? false)
                        ? data.accountName![0].toUpperCase()
                        : 'G',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: AppColors.brandStart),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  data.accountName ?? 'Google account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  data.accountEmail ?? 'Not signed in',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.x3),
                PillBadge(
                  label: data.isConnected
                      ? 'Google Sheet connected'
                      : 'No spreadsheet connected',
                  icon: data.isConnected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                if (data.spreadsheetId != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x3),
                  SelectableText(
                    data.spreadsheetId!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/connect-spreadsheet'),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Manage connection'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Data ownership',
                  subtitle: 'Your spreadsheet is the system of record.',
                  leading: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                const Text(
                  'Transactions and settings are sent directly to the Google Sheet you connect. The app does not keep a local transaction database or upload your data to a separate server.',
                ),
              ],
            ),
          ),
          if (data.isConnected) ...<Widget>[
            const SizedBox(height: AppSpacing.x3),
            OutlinedButton.icon(
              onPressed: data.loading ? null : () => _disconnect(context, ref),
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Disconnect this device'),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.x2),
              child: Text(
                'Disconnecting removes the saved workbook reference from this device. The workbook and its rows stay in your Google Drive.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
          TextButton(
            onPressed: () => context.push('/privacy'),
            child: const Text('Privacy and terms'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Disconnect this device?'),
            content: const Text(
              'This signs out and forgets the workbook ID on this device. The spreadsheet will remain in your Google Drive.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref.read(expenseDataProvider.notifier).disconnect();
      if (context.mounted) context.go('/home');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
