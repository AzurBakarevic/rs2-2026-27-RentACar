import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';
import 'user_details_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  static const String title = 'Korisnici';

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: title,
      child: CrudListView<User>(
        provider: context.read<UserProvider>(),
        idOf: (item) => item.id,
        searchKey: 'text',
        labels: CrudListLabels(
          searchHint: 'po imenu ili e-mailu',
          newItem: 'Novi korisnik',
          deleteQuestion: (item) => 'Da li želite obrisati korisnika „${item.fullName}”?',
          saved: 'Korisnik je sačuvan.',
          deleted: 'Korisnik je obrisan.',
        ),
        columns: const [
          TableColumnDef('Slika', flex: 70),
          TableColumnDef('Ime', flex: 100),
          TableColumnDef('Prezime', flex: 110),
          TableColumnDef('E-mail', flex: 200),
          TableColumnDef('Telefon', flex: 120),
          TableColumnDef('Uloga', flex: 130),
          TableColumnDef('Status', flex: 130),
        ],
        actionsFlex: 110,
        cells: (item) => [
          UserAvatar(userId: item.id, hasImage: item.hasProfileImage, size: 48),
          _TextCell(item.firstName),
          _TextCell(item.lastName),
          _TextCell(item.email),
          _TextCell(item.phoneNumber),
          _TextCell(item.roleName),
          StatusBadge(active: item.isActive, activeLabel: 'Aktivan', inactiveLabel: 'Neaktivan'),
        ],
        openForm: (context, item) async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => UserDetailsScreen(user: item)),
          );
          return saved ?? false;
        },
        deleteBlockedReason: (item) => item.deleteBlockedReason,
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  const _TextCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    );
  }
}
