import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/business_logic/view_models/bookmark_page_view_model.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_fire_repo.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class BookmarkCloudTransferDialog extends StatefulWidget {
  const BookmarkCloudTransferDialog({super.key});

  @override
  TransferDialogState createState() => TransferDialogState();
}

class TransferDialogState extends State<BookmarkCloudTransferDialog> {
  List<Bookmark> localBookmarks = [];
  List<Bookmark> cloudBookmarks = [];
  ScrollController localListController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBookmarks();
  }

  void fetchBookmarks() async {
    localBookmarks =
        await BookmarkDatabaseRepository(DatabaseHelper()).getAllBookmark();
    cloudBookmarks = await BookmarkFireRepository().getBookmarks();
    setState(() {});
  }

  void downloadBookmark(Bookmark bookmark) async {
    final bookmarkViewModel =
        Provider.of<BookmarkPageViewModel>(context, listen: false);
    bookmarkViewModel.insertBookmark(bookmark);
    fetchBookmarks();
    scrollToBottom();
  }

  void scrollToBottom() {
    if (localListController.hasClients) {
      localListController.animateTo(
        localListController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void deleteFromCloud(Bookmark bookmark) async {
    await BookmarkFireRepository().delete(bookmark);
    fetchBookmarks();
  }

  void transferToCloud(Bookmark bookmark) async {
    await BookmarkFireRepository().insert(bookmark);
    fetchBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.transferBookmarks),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            ColoredText(
              AppLocalizations.of(context)!.localBookmarks,
              style: const TextStyle(fontWeight: FontWeight.bold),
              fontSize: Prefs.uiFontSize + 3,
            ),
            Expanded(
              child: buildLocalBookmarksList(),
            ),
            const SizedBox(
              height: 20,
            ),
            ColoredText(
              AppLocalizations.of(context)!.cloudBookmarks,
              style: const TextStyle(fontWeight: FontWeight.bold),
              fontSize: Prefs.uiFontSize + 3,
            ),
            Expanded(
              child: buildCloudBookmarksList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget buildLocalBookmarksList() {
    return Card(
      child: ListView.builder(
        itemCount: localBookmarks.length,
        controller: localListController,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(localBookmarks[index].note),
            trailing: IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: () => transferToCloud(localBookmarks[index]),
            ),
          );
        },
      ),
    );
  }

  Widget buildCloudBookmarksList() {
    return Card(
      child: ListView.builder(
        itemCount: cloudBookmarks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(cloudBookmarks[index].note),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cloud_download),
                  onPressed: () => downloadBookmark(cloudBookmarks[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteFromCloud(cloudBookmarks[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
