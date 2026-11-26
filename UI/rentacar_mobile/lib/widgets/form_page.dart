import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: title),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title});

  static const double _buttonSize = 48;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: _buttonSize,
          child: IconButton.outlined(
            tooltip: 'Nazad',
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: _buttonSize),
      ],
    );
  }
}

class TabTitle extends StatelessWidget {
  const TabTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark),
    );
  }
}
