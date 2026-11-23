import 'package:material_ui/material_ui.dart';

import '../providers/base_provider.dart';
import '../utils/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.userId, required this.hasImage, this.size = 32});

  final int userId;
  final bool hasImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.avatarBackground,
      child: Icon(Icons.person_outline, color: AppColors.primary, size: size * 0.6),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.network(
                BaseProvider.buildUri('Users/$userId/Image').toString(),
                headers: BaseProvider.createHeaders()..remove('Content-Type'),
                fit: BoxFit.cover,
                cacheWidth: (size * 2 * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
