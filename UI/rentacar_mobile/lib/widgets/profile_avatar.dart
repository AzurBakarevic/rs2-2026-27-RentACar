import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../utils/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final placeholder = ColoredBox(
      color: AppColors.avatarBackground,
      child: Icon(Icons.person_outline, color: AppColors.primary, size: size * 0.6),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: provider.profile?.hasProfileImage ?? false
            ? Image.network(
                provider.imageUrl,
                headers: provider.imageHeaders(),
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
