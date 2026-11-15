import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _budgetAlerts = true;
  bool _weeklySummary = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.pageBackground,
    appBar: AppBar(title: const Text('Notifications')),
    body: ResponsiveListView(
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Notification preferences',
                subtitle: 'Choose which in-app summaries you want to see.',
                leading: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.brandStart,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _budgetAlerts,
                onChanged: _loaded
                    ? (bool value) => _setPreference(budgetAlerts: value)
                    : null,
                title: const Text('Budget progress reminders'),
                subtitle: const Text(
                  'Show budget status when the app refreshes your sheet.',
                ),
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _weeklySummary,
                onChanged: _loaded
                    ? (bool value) => _setPreference(weeklySummary: value)
                    : null,
                title: const Text('Weekly summary'),
                subtitle: const Text(
                  'Keep the weekly summary preference for a future scheduled reminder.',
                ),
              ),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        const Text(
          'These preferences are saved on this device. The app does not request notification permission or schedule background alerts in this version.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );

  Future<void> _load() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _budgetAlerts =
            preferences.getBool('notifications_budget_progress') ?? true;
        _weeklySummary =
            preferences.getBool('notifications_weekly_summary') ?? false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _setPreference({bool? budgetAlerts, bool? weeklySummary}) async {
    final bool oldBudget = _budgetAlerts;
    final bool oldWeekly = _weeklySummary;
    setState(() {
      _budgetAlerts = budgetAlerts ?? _budgetAlerts;
      _weeklySummary = weeklySummary ?? _weeklySummary;
      _saving = true;
    });
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool('notifications_budget_progress', _budgetAlerts);
      await preferences.setBool('notifications_weekly_summary', _weeklySummary);
    } catch (_) {
      if (mounted) {
        setState(() {
          _budgetAlerts = oldBudget;
          _weeklySummary = oldWeekly;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notification preferences.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
