// import 'package:flutter/material.dart';
// import 'package:tipitaka_pali/l10n/app_localizations.dart';
// import 'package:provider/provider.dart';

// import '../../../business_logic/models/dictionary_history.dart';
// import '../../../services/database/database_helper.dart';
// import '../../../services/repositories/dictionary_history_page_view_model.dart';
// import '../../../services/repositories/dictionary_history_repo.dart';
// import '../../dialogs/confirm_dialog.dart';

// class DictionaryHistoryPage extends StatelessWidget {
//   const DictionaryHistoryPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<DictionaryHistoryPageViewModel>(
//       create: (_) => DictionaryHistoryPageViewModel(
//           DictionaryHistoryDatabaseRepository(dbh: DatabaseHelper()))
//         ..getDictionaryHistory(),
//       child: Scaffold(
//         // appBar: const RecentAppBar(),
//         body: Consumer<DictionaryHistoryPageViewModel>(
//             builder: (context, vm, child) {
//           final List<DictionaryHistory> recents = vm.recents;
//           return recents.isEmpty
//               ? Center(child: Text(AppLocalizations.of(context)!.recent))
//               : ListView.separated(
//                   itemCount: recents.length,
//                   itemBuilder: (context, index) {
//                     final DictionaryHistory recent = recents[index];
//                     return ListTile(
//                       leading: Text(recent.word),
//                       //onTap: (recent) => vm.openBook(recent, context),
//                       //onDelete: (recent) => vm.delete(recent),
//                     );
//                   },
//                   separatorBuilder: (_, __) {
//                     return const Divider(color: Colors.grey);
//                   });
//         }),
//       ),
//     );
//   }
// }

// class RecentAppBar extends StatelessWidget implements PreferredSizeWidget {
//   const RecentAppBar({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       title: Text(AppLocalizations.of(context)!.recent),
//       actions: [
//         IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: () async {
//               final action = await _getConfirmataion(context);
//               if (action == OkCancelAction.ok) {
//                 context.read<DictionaryHistoryPageViewModel>().deleteAll();
//               }
//             })
//       ],
//     );
//   }

//   @override
//   Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

//   Future<OkCancelAction?> _getConfirmataion(BuildContext context) async {
//     return await showDialog<OkCancelAction>(
//         context: context,
//         builder: (context) {
//           return ConfirmDialog(
//             title: AppLocalizations.of(context)!.confirmation,
//             message: AppLocalizations.of(context)!.areSureDelete,
//             okLabel: AppLocalizations.of(context)!.delete,
//             cancelLabel: AppLocalizations.of(context)!.cancel,
//           );
//         });
//   }
// }
