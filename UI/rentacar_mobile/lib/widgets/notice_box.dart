import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

enum NoticeType { error, info, warning, success }

class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.message, this.type = NoticeType.error, this.bottomSpacing = 20});

  final String? message;
  final NoticeType type;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) {
      return const SizedBox.shrink();
    }

    final (background, foreground) = switch (type) {
      NoticeType.error => (AppColors.errorBackground, AppColors.error),
      NoticeType.info => (AppColors.infoBackground, AppColors.textDark),
      NoticeType.warning => (AppColors.warningBackground, AppColors.warning),
      NoticeType.success => (AppColors.successBackground, AppColors.success),
    };

    return Container(
      margin: EdgeInsets.only(bottom: bottomSpacing),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: foreground, fontSize: 15)),
    );
  }
}
