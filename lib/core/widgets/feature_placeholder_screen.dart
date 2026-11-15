import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import 'design_system_widgets.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.message,
    this.icon = Icons.construction_rounded,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageCompact),
        children: <Widget>[
          SurfaceCard(
            child: EmptyState(icon: icon, title: title, message: message),
          ),
        ],
      ),
    );
  }
}
