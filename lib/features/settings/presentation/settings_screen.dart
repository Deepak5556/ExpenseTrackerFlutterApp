import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageCompact),
        children: <Widget>[
          _SettingsGroup(
            title: 'Account',
            items: <_SettingsItem>[
              _SettingsItem('Profile', Icons.person_outline, '/profile'),
              _SettingsItem(
                'Notifications',
                Icons.notifications_outlined,
                '/notifications',
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Finances',
            items: <_SettingsItem>[
              _SettingsItem(
                'Monthly salary',
                Icons.payments_outlined,
                '/salary',
              ),
              _SettingsItem(
                'Categories',
                Icons.category_outlined,
                '/categories',
              ),
              _SettingsItem('Budgets', Icons.savings_outlined, '/budgets'),
            ],
          ),
          _SettingsGroup(
            title: 'Data and privacy',
            items: <_SettingsItem>[
              _SettingsItem(
                'Google Sheets',
                Icons.table_chart_outlined,
                '/connect-spreadsheet',
              ),
              _SettingsItem(
                'Privacy and terms',
                Icons.privacy_tip_outlined,
                '/privacy',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          const Text(
            'Your transactions will be stored only in the Google Sheet you authorize.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem(this.title, this.icon, this.location);

  final String title;
  final IconData icon;
  final String location;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x4,
                AppSpacing.x4,
                AppSpacing.x1,
              ),
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            for (final _SettingsItem item in items)
              ListTile(
                leading: Icon(item.icon, color: AppColors.brandStart),
                title: Text(item.title),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(item.location),
              ),
          ],
        ),
      ),
    );
  }
}
