import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/design_system_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.pageBackground,
    appBar: AppBar(title: const Text('Privacy and data')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Your data stays in your Google account',
                subtitle: 'This app uses Google Sheets as its source of truth.',
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.brandStart,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              const _PrivacyItem(
                title: 'Spreadsheet access',
                body: 'The app requests Google Drive’s drive.file access so it can create and use spreadsheets that you create or explicitly open with this app.',
              ),
              const _PrivacyItem(
                title: 'Storage',
                body: 'Transactions, categories, salary and budgets are stored in the connected Google workbook. This app has no backend or local transaction database; it keeps the current sheet data in memory while the app is open.',
              ),
              const _PrivacyItem(
                title: 'Device preferences',
                body: 'The connected workbook ID and notification preferences are saved in Android app preferences. Google access tokens are managed by Google Sign-In and are not written into this app’s data files.',
              ),
              const _PrivacyItem(
                title: 'Disconnect',
                body: 'Disconnecting removes the saved workbook ID and signs out on this device. It does not delete or modify the workbook.',
              ),
              const SizedBox(height: AppSpacing.x2),
              const Text(
                'This screen describes the app’s current data handling. A publisher-provided legal privacy policy and terms should be added before public release.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.x3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.x1),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
