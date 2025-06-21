import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/dao/bookmark_dao.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_fire_repo.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';

class BookmarkSyncRepo {
  BookmarkSyncRepo(DatabaseHelper databaseHelper, this.dao)
      : _sqlRepo = BookmarkDatabaseRepository(databaseHelper),
        _fireRepo = BookmarkFireRepository();
  final BookmarkDao dao;

  final BookmarkRepository _sqlRepo;
  final BookmarkFireRepository _fireRepo;

  Future<int> insert(Bookmark bookmark) async {
    // we do not write directly to the firestore
    // when we sync it will be written
    int result = await _sqlRepo.insert(bookmark);
    return result;
  }

  Future<int> delete(Bookmark bookmark) async {
    int result = 0;
    if (Prefs.isSignedIn) {
      result = await _fireRepo.delete(bookmark);
    }
    result = await _sqlRepo.deleteBookmark(bookmark.id);
    return result;
  }

  Future<int> deleteAll() async {
    int result = 0;
    if (Prefs.isSignedIn) {
      result = await _fireRepo.deleteAll();
    }
    result = await _sqlRepo.deleteAll();
    return result;
  }

  Future<List<Bookmark>> getBookmarks() {
    if (Prefs.isSignedIn) {
      return _fireRepo.getBookmarks();
    }
    return _sqlRepo.getAllBookmark();
  }

/*
  Future<void> syncBookmarks() async {
    if (Prefs.isSignedIn) {
      // Get last sync from Prefs
      final lastSyncDate = Prefs.lastSyncDate;

      // get all local bookmarks related to last sync
      final localBookmarks = await _sqlRepo.getBookmarksAfter(lastSyncDate);
      // get all the bookmarks from firebase after last sync
      final remoteBookmarks = await _fireRepo.getBookmarksAfter(lastSyncDate);

      // do the operation on firebase
      for (final localBookmark in localBookmarks) {
        if (localBookmark.action == BookmarkAction.insert) {
          await _fireRepo.insert(localBookmark);
        } else if (localBookmark.action == BookmarkAction.delete) {
          await _fireRepo.delete(localBookmark);
        }
      }

      // update local bookmarks
      for (final remoteBookmark in remoteBookmarks) {
        if (remoteBookmark.action == BookmarkAction.insert) {
          await _sqlRepo.insert(remoteBookmark);
        } else if (remoteBookmark.action == BookmarkAction.delete) {
          await _sqlRepo.delete(remoteBookmark);
        }
      }

      // Update lastSyncDate in Prefs
      // do we need a fixed time for all actions
      // to complete with the same time down to the second?
      final currentDateTime = DateTime.now().toUtc();
      Prefs.lastSyncDate = currentDateTime.toString();
    }
  }
  */
}
