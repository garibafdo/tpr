import 'dart:convert';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../business_logic/models/download_list_item.dart';
import 'download_notifier.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:dio/dio.dart';
import 'package:tipitaka_pali/business_logic/models/page_content.dart';

class DatabaseUpdate {
  final insertLines = [];
  final updateLines = [];
  final deleteLines = [];

  var insertCount = 0;
  var updateCount = 0;
  var deleteCount = 0;
}

class DownloadService {
  DownloadNotifier downloadNotifier;
  DownloadListItem downloadListItem;
  int batchAmount = 500;

  String _dir = "";

  late final String _zipPath;
  late final String _localZipFileName;
  final dbService = DatabaseHelper();

  DownloadService(
      {required this.downloadNotifier, required this.downloadListItem}) {
    _zipPath = downloadListItem.url;

    _localZipFileName = downloadListItem.filename;
  }

  Future<String> get _localPath async {
    return Prefs.databaseDirPath;
  }

  Future<File> get _localFile async {
    final path = Prefs.databaseDirPath;
    return File('$path/$_localZipFileName');
  }

  Future<String> getSQL() async {
    await downloadZip();
    final file = await _localFile;

    // Read the file
    String s = await file.readAsString();
    return s;
  }

  Future<List<File>> downloadZip() async {
    final zippedFile = await downloadFile(_zipPath, _localZipFileName);
    return await unarchiveAndSave(zippedFile);
  }

  Future<void> installSqlZip() async {
    initDir();
    downloadNotifier.connectionChecking = false;
    downloadNotifier.downloading = true;
    downloadNotifier.message =
        "\nNow downloading file.. ${downloadListItem.size}\nPlease wait.";

    final sqlFiles = await downloadZip();

    for (final sqlFile in sqlFiles) {
      await processLocalFile(sqlFile);
    }

    downloadNotifier.downloading = false;
  }

  Future<void> processLocalFile(File downloadedFile) async {
    final dbUpdate = DatabaseUpdate();

    final lineStream = downloadedFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final reBookId = RegExp("'.+'");
    final newBooks = <String>{};

    Database db = await dbService.database;
    await for (final rawLine in lineStream) {
      final line = rawLine.toLowerCase();

      // do these first
      if (line.startsWith("drop")) {
        await db.database.execute(line);
      } else if (line.startsWith("create")) {
        await db.database.execute(line);
      }

      if (line.startsWith("insert")) {
        dbUpdate.insertLines.add(rawLine);
        dbUpdate.insertCount++;
      } else if (line.startsWith("update")) {
        dbUpdate.updateLines.add(rawLine);
        dbUpdate.updateCount++;
      } else if (line.startsWith("delete")) {
        dbUpdate.deleteLines.add(rawLine);
        dbUpdate.deleteCount++;

        if (line.contains('delete from books')) {
          final match = reBookId.firstMatch(rawLine)!;
          newBooks.add(match[0]!);
        }
      }
      await processEntries(dbUpdate, db, batchAmount);
    }

    await processEntries(dbUpdate, db, 1);

    if (downloadListItem.type.contains("index")) {
      downloadNotifier.message = 'Building fts';

      await doFts(db, newBooks);

      Stopwatch stopwatch = Stopwatch()..start();
      await makeEnglishWordList2();
      debugPrint('Making English Word List took ${stopwatch.elapsed}.');

      // Original:
      // 15s
      // Improved:
      // 6s
    }

    if (downloadListItem.type.contains("dpd_grammar")) {
      downloadNotifier.message = 'adding dpd grammar flag';
      Prefs.isDpdGrammarOn = true;
    }

    // It costs 10 seconds to regen the indexes.. I'd like to do that.
    downloadNotifier.message = "Rebuilding Index";
    await dbService.buildBothIndexes();
    downloadNotifier.message = "Reloading Extension List";
  }

  Future processEntries(DatabaseUpdate dbUpdate, Database db, int limit) async {
    if (dbUpdate.insertLines.length >= limit) {
      await execSQL(db, dbUpdate.insertLines, 'insert');
      dbUpdate.insertLines.clear();
      notifyProcessed('Inserted', dbUpdate.insertCount);
    }

    if (dbUpdate.updateLines.length >= limit) {
      await execSQL(db, dbUpdate.updateLines, 'update');
      dbUpdate.updateLines.clear();
      notifyProcessed('Updated', dbUpdate.updateCount);
    }

    if (dbUpdate.deleteLines.isNotEmpty) {
      await execSQL(db, dbUpdate.deleteLines, 'delete');
      dbUpdate.deleteLines.clear();
      notifyProcessed('Deleted', dbUpdate.deleteCount);
    }
  }

  notifyProcessed(String operation, int counter) {
    downloadNotifier.message = "$operation $counter lines";
  }

  Future<Set<String>> doDeletes(Database db, String sql) async {
    Set<String> newBooks = <String>{};
    RegExp reBookId = RegExp("'.+'");
    sql = sql.toLowerCase();
    List<String> lines = sql.split("\n");
    //StringBuffer sb = StringBuffer("");

    //String deleteSql = sb.toString();
    downloadNotifier.message = "Deleting Records";

    if (lines.isNotEmpty) {
      var batch = db.batch();
      for (String line in lines) {
        if (line.contains("delete")) {
          if (line.contains('delete from books')) {
            final match = reBookId.firstMatch(line)!;
            newBooks.add(match[0]!);
          }
          batch.rawDelete(line);
        }
      }
      await batch.commit();
    }
    return newBooks;
  }

  Future<void> execSQL(Database db, List lines, String operation) async {
    var batch = db.batch();
    for (final line in lines) {
      if (operation == 'insert') {
        batch.rawInsert(line);
      } else if (operation == 'update') {
        batch.rawUpdate(line);
      } else if (operation == 'delete') {
        batch.rawDelete(line);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> doInserts(Database db, String sql) async {
    sql = sql.toLowerCase();
    List<String> lines = sql.split("\n");
    var batch = db.batch();

    int counter = 0;
    for (String line in lines) {
      if (line.contains("insert")) {
        batch.rawInsert(line);
        counter++;
        if (batchAmount % counter == 1) {
          await batch.commit(noResult: true);
          downloadNotifier.message =
              "inserted $counter of ${lines.length}: ${(counter / lines.length * 100).toStringAsFixed(0)}%";
          batch = db.batch();
        }
      }
    }
    await batch.commit(noResult: true);

    downloadNotifier.message = "Insert Complete";
  }

  Future<void> doUpdates(Database db, String sql) async {
    sql = sql.toLowerCase();
    List<String> lines = sql.split("\n");
    var batch = db.batch();

    int counter = 0;
    for (String line in lines) {
      if (line.contains("update")) {
        batch.rawUpdate(line);
        counter++;
        if (counter % batchAmount == 1) {
          await batch.commit(noResult: true);
          downloadNotifier.message =
              "updated $counter of ${lines.length}: ${(counter / lines.length * 100).toStringAsFixed(0)}%";
          batch = db.batch();
        }
      }
    }
    await batch.commit(noResult: true);

    downloadNotifier.message = "Update Complete";
  }

  Future<void> doFts(Database db, Set<String> newBooks) async {
    int maxWrites = 50;
    var batch = db.batch();
    int counter = 0;
    for (final bookId in newBooks) {
      final qureySql =
          'SELECT id, bookid, page, content, paranum FROM pages WHERE bookid = $bookId';
      final maps = await db.rawQuery(qureySql);
      for (var element in maps) {
        // before populating to fts, need to remove html tag
        final value = <String, Object?>{
          'id': element['id'] as int,
          'bookid': element['bookid'] as String,
          'page': element['page'] as int,
          'content': _cleanText(element['content'] as String),
          'paranum': element['paranum'] as String,
        };
        batch.insert('fts_pages', value);
        counter++;
        if (counter % maxWrites == 1) {
          await batch.commit(noResult: true);
//          String pcent = (counter / maps.length * 100).toStringAsFixed(0);
          downloadNotifier.message = "inserted $counter";
          batch = db.batch();
        }
      }
      // commit remainder inserts after the loop stops.
      await batch.commit(noResult: true);
    }
    downloadNotifier.message = "FTS is complete";
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      String percent = (received / total * 100).toStringAsFixed(0);
      downloadNotifier.message = "Downloading: $percent %\n";
    }
  }

  Future<File> downloadFile(String url, String fileName) async {
    var req = await Dio().get(
      url,
      onReceiveProgress: showDownloadProgress,
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    if (req.statusCode == 200) {
      var file = File('$_dir/$fileName');
      debugPrint("file.path ${file.path}");
      return file.writeAsBytes(req.data);
    } else {
      throw Exception('Failed to load zip file');
    }
  }

  initDir() async {
    _dir = Prefs.databaseDirPath;
  }

  Future<List<File>> unarchiveAndSave(File zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    List<File> extractedSqlFiles = [];

    for (var file in archive) {
      final outPath = '$_dir/${file.name}';
      if (!file.isFile || outPath.contains('__MACOSX')) continue;

      final outFile = File(outPath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content);

      if (outFile.path.endsWith('.sql')) {
        extractedSqlFiles.add(outFile);
      }
    }

    downloadNotifier.message =
        "\nDownloaded ${extractedSqlFiles.length} .sql files.\nPlease wait for further processing";

    return extractedSqlFiles;
  }

  String _cleanText(String text) {
    final regexHtmlTags = RegExp(r'<[^>]*>');
    return text.replaceAll(regexHtmlTags, '');
  }

  Future<void> makeEnglishWordList() async {
    // select * from pages where bookid like "annya_pe%"
    // build Stringbuffer from  bs t1 which is english
    // add unique words to list
    //
    // delete words table which have -1 count
    // insert the words to the word table with count -1
    //  final pageContentRepository =
    //    PageContentDatabaseRepository(DatabaseHelper());
    downloadNotifier.message = "Creating unique wordlist\n";
    Database db = await dbService.database;
    List<String> uniqueWords = [];

    List<String> categories = [
      "annya_pe_vinaya",
      "annya_pe_dn",
      "annya_pe_mn",
      "annya_pe_sn",
      "annya_pe_an",
      "annya_pe_kn"
    ];

    for (String x in categories) {
      downloadNotifier.message += "\nprocesseing wordlist for $x";
      debugPrint(downloadNotifier.message);
      List<Map> list = await db.rawQuery(
          '''SELECT pages.id, pages.bookid, pages.page, pages.content, pages.paranum from pages,books,category 
          WHERE category.id ='$x'
              AND books.category = category.id
              AND books.id = pages.bookid;''');

      var pages = list.map((x) => PageContent.fromJson(x)).toList();
      int lines = 0;

      var englishPagesBuffer = StringBuffer();
      // build massive 17k pages of text into string buffer.
      for (PageContent page in pages) {
        BeautifulSoup bs = BeautifulSoup(page.content);
        List<Bs4Element> englishLines = bs.findAll("p");
        for (Bs4Element bsEnglishLine in englishLines) {
          if (bsEnglishLine.toString().contains("t1")) {
            englishPagesBuffer.write("${bsEnglishLine.text.toLowerCase()} ");
            lines++;
          }
          if (x == "annya_pe_kn") {
            // hack fix for dhpA
            //TODO fix the import file so that it is t1 for english
            englishPagesBuffer.write("${bsEnglishLine.text.toLowerCase()} ");
            lines++;
          }
        }
      }

      String englishPagesString = englishPagesBuffer.toString();

      List<String> words = englishPagesString.split(RegExp(r"[\s—]+"));
      // Iterate through the words and add them to the wordlist with frequency

      for (var word in words) {
        String w = word.trim().toLowerCase().toString();
        w = w.replaceAll(RegExp('[^A-Za-zāīūṃṅñṭṭḍṇḷ-]'), '');
        if (!uniqueWords.contains(w)) {
          uniqueWords.add(w);
        }
      }
    }
    downloadNotifier.message = "Adding word list";

    // now delete all words from the table with -1 count
    await db.rawDelete("Delete from words where frequency = -1");
    var batch = db.batch();
    int counter = 0;
    for (String s in uniqueWords) {
      // keep plain duplicate so works with fuzzy if turned on
      batch.rawInsert(
          '''INSERT INTO words (word, plain, frequency) SELECT '$s','$s', -1  
                          WHERE NOT EXISTS 
                          (SELECT word from words where word ='$s');''');
      counter++;
      if (counter % 100 == 1) {
        await batch.commit();
        batch = db.batch();
        downloadNotifier.message = "$counter of ${uniqueWords.length}";
      }
    }
    await batch.commit();
    downloadNotifier.message = "English word list is complete";
  }

  Future<void> makeEnglishWordList2() async {
    downloadNotifier.message = "Creating unique wordlist";
    final Database db = await dbService.database;
    final uniqueWords = <String>{};

    final List<String> categories = [
      "annya_pe_vinaya",
      "annya_pe_dn",
      "annya_pe_mn",
      "annya_pe_sn",
      "annya_pe_an",
      "annya_pe_kn"
    ];

    final commas = List.filled(categories.length, '?').join(', ');

    var startId = 0;
    var batchesCount = 0;
    while (true) {
      final QueryCursor cursor = await db.rawQueryCursor('''
        SELECT 
          pages.id, pages.content, category.id as category
        FROM 
          pages
        JOIN 
          books on books.id = pages.bookid
        JOIN 
          category on category.id = books.category
        WHERE 
          pages.id > ? AND
          category.id IN ($commas)
        LIMIT 
          5000
        ''', [startId, ...categories]);

      final hasFirst = await cursor.moveNext();
      if (!hasFirst) {
        break;
      }
      batchesCount++;

      final allowedLetters = RegExp('[^a-z —āīūṃṅñṭṭḍṇḷ]+');
      final wordSplitter = RegExp(r"[\s—]+");

      while (true) {
        final content = cursor.current['content'] as String;
        final category = cursor.current['category'] as String;

        final startTag =
            category == 'annya_pe_kn' ? '<p>' : '<span class="t1">';
        final startTagLen = startTag.length;
        final endTag = category == 'annya_pe_kn' ? '</p>' : '</span>';
        final endTagLen = endTag.length;

        startId = cursor.current['id'] as int;
        var startFrom = 0;
        while (true) {
          final start = content.indexOf(startTag, startFrom);
          if (start == -1) {
            break;
          }
          final end = content.indexOf(endTag, start + startTagLen);
          if (end == -1) {
            break;
          }
          final text = content.substring(start + startTagLen, end);
          startFrom = end + endTagLen;

          if (text == ' ' || text == ' ' || text == '') {
            continue;
          }

          uniqueWords.addAll(text
              .toLowerCase()
              .replaceAll(allowedLetters, '')
              .split(wordSplitter));
        }

        final hasNext = await cursor.moveNext();
        if (!hasNext) {
          break;
        }
      }
    }

    debugPrint(
        'Total unique: ${uniqueWords.length}, fetched in $batchesCount batches.');

    downloadNotifier.message = "Adding word list";

    // now delete all words from the table with -1 count
    await db.rawDelete("Delete from words where frequency = -1");
    var batch = db.batch();
    int counter = 0;
    for (final String word in uniqueWords) {
      batch.rawInsert('''
          INSERT OR IGNORE INTO 
          words (word, plain, frequency) 
          VALUES('$word', '$word', -1)
          ''');
      counter++;
      if (counter % 100 == 0) {
        await batch.commit();
        batch = db.batch();
        downloadNotifier.message = "$counter of ${uniqueWords.length}";
      }
    }
    if (counter % 100 != 0) {
      await batch.commit();
    }
    downloadNotifier.message = "English word list is complete";
  }

  Future<List<File>> getExtensionFiles() async {
    final directory = Directory(Prefs.databaseDirPath);
    final files = directory.listSync().whereType<File>().toList();
    List<File> extensions = [];

    for (final file in files) {
      if (file.path.endsWith('.sql')) {
        //await processLocalFile(file);
        extensions.add(file);
      }
    }
    return extensions;
  }
}
