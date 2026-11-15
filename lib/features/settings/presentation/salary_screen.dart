import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/design_system_widgets.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../features/data/expense_data_provider.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});
  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  final TextEditingController _salaryController = TextEditingController();
  bool _loadedFromSheet = false;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseDataState data = ref.watch(expenseDataProvider);
    if (!_loadedFromSheet && data.isConnected && !data.loading) {
      _loadedFromSheet = true;
      if (data.salaryMinor > 0) {
        _salaryController.text = (data.salaryMinor / 100).toStringAsFixed(
          data.salaryMinor % 100 == 0 ? 0 : 2,
        );
      }
    }
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Monthly salary')),
      body: ResponsiveListView(
        children: <Widget>[
          if (!data.isConnected)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.payments_outlined,
                title: 'Connect your spreadsheet',
                message:
                    'Your salary setting is stored in the Settings worksheet.',
              ),
            )
          else
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Monthly take-home salary',
                    subtitle: 'Used to calculate your remaining balance and savings rate.',
                    leading: Icon(
                      Icons.payments_outlined,
                      color: AppColors.brandStart,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Monthly salary',
                      prefixText: data.currency == 'INR'
                          ? '₹ '
                          : '${data.currency} ',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  if (data.salaryMinor > 0)
                    Text(
                      'Current setting · ${formatMoney(data.salaryMinor)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: AppSpacing.x4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: data.saving ? null : _save,
                      icon: data.saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(data.saving ? 'Saving…' : 'Save salary'),
                    ),
                  ),
                  if (data.error != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      data.error!,
                      style: const TextStyle(color: AppColors.brandStart),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final int? amount = _parseMinor(_salaryController.text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid salary amount.')),
      );
      return;
    }
    try {
      await ref.read(expenseDataProvider.notifier).setSalary(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly salary saved to Google Sheets.'),
          ),
        );
      }
    } catch (_) {
      // The form remains editable so the user can correct access and retry.
    }
  }

  int? _parseMinor(String value) {
    final String normalized = value.replaceAll(',', '').trim();
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
    final List<String> parts = normalized.split('.');
    return (int.tryParse(parts[0]) ?? -1) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }
}
