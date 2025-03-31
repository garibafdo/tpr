import 'package:tipitaka_pali/business_logic/models/sutta.dart';
import '../database/database_helper.dart';
import '../prefs.dart';

abstract class SuttaRepository {
  Future<List<Sutta>> getAll();
  Future<List<Sutta>> getSuttas(String filterWord);
}

class SuttaRepositoryDatabase implements SuttaRepository {
  final DatabaseHelper databaseProvider;
  // final String tableSutta = 'sutta';
  // final String tableBook = 'book';
  // final String columnName = 'name';
  // final String columnBookID = 'book_id';
  // final String columnBookName = 'book_name';
  // final String columnPageNumber = 'page_number';
  bool _isValid = false;
  Map<String, String> qjbooks = {
    "kp": "mula_ku_01",
    "dhp": "mula_ku_02",
    "ud": "mula_ku_03",
    "iti": "mula_ku_04",
    "snp": "mula_ku_05",
    "vv": "mula_ku_06",
    "pv": "mula_ku_07",
    "thag": "mula_ku_08",
    "thig": "mula_ku_09",
  };
  final reNikaya = RegExp(r'^(DN|MN|SN|AN|Dhp|Vin)', caseSensitive: false);

  SuttaRepositoryDatabase(this.databaseProvider);

  @override
  Future<List<Sutta>> getAll() async {
    final db = await databaseProvider.database;
    var results = await db.rawQuery('''
SELECT suttas.name, book_id, books.name as book_name, page_number from suttas
INNER JOIN books on books.id = suttas.book_id
''');
    return results.map((e) => Sutta.fromMap(e)).toList();
  }

  @override
  Future<List<Sutta>> getSuttas(String filterdWord) async {
    final db = await databaseProvider.database;

    if (reNikaya.hasMatch(filterdWord) &&
        filterdWord.contains(RegExp(r'\d+'))) {
      var results = await db.rawQuery('''
SELECT sutta_name as name, book_id, books.name as book_name,
start_page as page_number, sutta_shortcut as shortcut
from sutta_page_shortcut
INNER JOIN books on books.id = sutta_page_shortcut.book_id 
WHERE sutta_shortcut like '$filterdWord%'
''');
      return results.map((e) => Sutta.fromMap(e)).toList();
    } else {
      if (Prefs.isFuzzy) {
        String simpleFilteredWord = filterdWord.replaceAllMapped(
          RegExp('[ṭḍṃāūīḷñṅ]'),
          (match) => {
            'ṭ': 't',
            'ḍ': 'd',
            'ṃ': 'm',
            'ā': 'a',
            'ū': 'u',
            'ī': 'i',
            'ḷ': 'l',
            'ñ': 'n',
            'ṅ': 'n'
          }[match.group(0)]!,
        );
        var fuzzyResults = await db.rawQuery('''
SELECT suttas.name, book_id, books.name as book_name, page_number from suttas
INNER JOIN books on books.id = suttas.book_id 
WHERE suttas.simple LIKE '%$simpleFilteredWord%'
''');
        return fuzzyResults.map((e) => Sutta.fromMap(e)).toList();
      } else {
        var results = await db.rawQuery('''
SELECT suttas.name, book_id, books.name as book_name, page_number from suttas
INNER JOIN books on books.id = suttas.book_id 
WHERE suttas.name LIKE '%$filterdWord%'
''');
        return results.map((e) => Sutta.fromMap(e)).toList();
      }
    }
  }
/*
  Future<void> makeSNQuickjumpTable() async {
    List<int> numSuttas = [
      81,
      30,
      25,
      25,
      10,
      15,
      22,
      12,
      14,
      12,
      25,
      103,
      11,
      39,
      20,
      13,
      31,
      14,
      21,
      12,
      12,
      159,
      46,
      96,
      10,
      10,
      10,
      10,
      21,
      75,
      112,
      57,
      55,
      55,
      248,
      31,
      34,
      16,
      2,
      11,
      10,
      13,
      44,
      11,
      181,
      185,
      104,
      180,
      54,
      108,
      86,
      24,
      54,
      20,
      74,
      131
    ];

    List<QuickJump> qjList = [];
    //int counter = 1;

    Book book = Book(id: "mula_sn", name: "sn");
    for (int i = 0; i < numSuttas.length; i++) {
      int num = numSuttas[i];

      //suttaList.add("\n");
      for (int j = 1; j <= num; j++) {
        String suttanum = "sn${i + 1}.$j";
        book = await getSnBookDetails(suttanum, book);
        int paranum = getSNParagraph("$i.$j");

        QuickJump qj = QuickJump(
            qjID: suttanum,
            bookID: book.id,
            pageNumber: book.firstPage,
            paragraphNumber: paranum);
        qjList.add(qj);
      }
    }

    final dbHelper = DatabaseHelper();

    final db = await dbHelper.database;

    for (var qjItem in qjList) {
      String sqlString = '''
            INSERT INTO quick_jump VALUES ("${qjItem.qjID}","${qjItem.bookID}",${qjItem.pageNumber},${qjItem.paragraphNumber});''';
      await db.rawInsert(sqlString);
    }
    //debugPrint(suttaList.toString());
  }

  Book getDnBookDetails(String qj, Book book) {
    int suttaNumber = -1;
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9]'), ''); // '23'
    if (aStr.trim().contains(RegExp(r'[0-9]'))) {
      suttaNumber = int.parse(aStr);
    }
    int openPage = 1;
    switch (suttaNumber) {
      case 1:
        openPage = 1;
        break;
      case 2:
        openPage = 44;
        break;
      case 3:
        openPage = 82;
        break;
      case 4:
        openPage = 104;
        break;
      case 5:
        openPage = 120;
        break;
      case 6:
        openPage = 143;
        break;
      case 7:
        openPage = 151;
        break;
      case 8:
        openPage = 153;
        break;
      case 9:
        openPage = 167;
        break;
      case 10:
        openPage = 188;
        break;
      case 11:
        openPage = 205;
        break;
      case 12:
        openPage = 214;
        break;
      case 13:
        openPage = 222;
        break;
      case 14:
        openPage = 1;
        break;
      case 15:
        openPage = 47;
        break;
      case 16:
        openPage = 61;
        break;
      case 17:
        openPage = 139;
        break;
      case 18:
        openPage = 162;
        break;
      case 19:
        openPage = 178;
        break;
      case 20:
        openPage = 203;
        break;
      case 21:
        openPage = 211;
        break;
      case 22:
        openPage = 231;
        break;
      case 23:
        openPage = 253;
        break;
      case 24:
        openPage = 1;
        break;
      case 25:
        openPage = 30;
        break;
      case 26:
        openPage = 48;
        break;
      case 27:
        openPage = 66;
        break;
      case 28:
        openPage = 82;
        break;
      case 29:
        openPage = 97;
        break;
      case 30:
        openPage = 117;
        break;
      case 31:
        openPage = 146;
        break;
      case 32:
        openPage = 158;
        break;
      case 33:
        openPage = 175;
        break;
      case 34:
        openPage = 227;
        break;
      default:
        _isValid = false;
    }

    book.firstPage = openPage;
    book.id = getDnBookID(suttaNumber);

    return book;
  }

  String getDnBookID(int suttaNumber) {
    String bookId = "mula_di_01";
    // if 14 or higher change
    // if higher than 23 change again to 3rd vol
    if (suttaNumber > 13) {
      bookId = (suttaNumber <= 23) ? "mula_di_02" : "mula_di_03";
    }
    return bookId;
  }

  Book getMnBookDetails(String qj, Book book) {
    _isValid = true;
    int suttaNumber = -1;
    String aStr = qj.replaceAll(RegExp(r'[^0-9]'), ''); // '23'
    if (aStr.trim().contains(RegExp(r'[0-9]'))) {
      suttaNumber = int.parse(aStr);
    }
    int openPage = 1;
    switch (suttaNumber) {
      case 1:
        openPage = 1;
        break;
      case 2:
        openPage = 8;
        break;
      case 3:
        openPage = 15;
        break;
      case 4:
        openPage = 20;
        break;
      case 5:
        openPage = 29;
        break;
      case 6:
        openPage = 39;
        break;
      case 7:
        openPage = 43;
        break;
      case 8:
        openPage = 48;
        break;
      case 9:
        openPage = 57;
        break;
      case 10:
        openPage = 70;
        break;
      case 11:
        openPage = 92;
        break;
      case 12:
        openPage = 97;
        break;
      case 13:
        openPage = 118;
        break;
      case 14:
        openPage = 126;
        break;
      case 15:
        openPage = 132;
        break;
      case 16:
        openPage = 145;
        break;
      case 17:
        openPage = 149;
        break;
      case 18:
        openPage = 154;
        break;
      case 19:
        openPage = 161;
        break;
      case 20:
        openPage = 167;
        break;
      case 21:
        openPage = 173;
        break;
      case 22:
        openPage = 182;
        break;
      case 23:
        openPage = 195;
        break;
      case 24:
        openPage = 199;
        break;
      case 25:
        openPage = 205;
        break;
      case 26:
        openPage = 216;
        break;
      case 27:
        openPage = 232;
        break;
      case 28:
        openPage = 242;
        break;
      case 29:
        openPage = 250;
        break;
      case 30:
        openPage = 257;
        break;
      case 31:
        openPage = 266;
        break;
      case 32:
        openPage = 272;
        break;
      case 33:
        openPage = 281;
        break;
      case 34:
        openPage = 286;
        break;
      case 35:
        openPage = 289;
        break;
      case 36:
        openPage = 299;
        break;
      case 37:
        openPage = 318;
        break;
      case 38:
        openPage = 323;
        break;
      case 39:
        openPage = 338;
        break;
      case 40:
        openPage = 349;
        break;
      case 41:
        openPage = 354;
        break;
      case 42:
        openPage = 360;
        break;
      case 43:
        openPage = 365;
        break;
      case 44:
        openPage = 373;
        break;
      case 45:
        openPage = 379;
        break;
      case 46:
        openPage = 384;
        break;
      case 47:
        openPage = 392;
        break;
      case 48:
        openPage = 395;
        break;
      case 49:
        openPage = 401;
        break;
      case 50:
        openPage = 407;
        break;
      case 51:
        openPage = 1;
        break;
      case 52:
        openPage = 12;
        break;
      case 53:
        openPage = 16;
        break;
      case 54:
        openPage = 22;
        break;
      case 55:
        openPage = 31;
        break;
      case 56:
        openPage = 35;
        break;
      case 57:
        openPage = 50;
        break;
      case 58:
        openPage = 54;
        break;
      case 59:
        openPage = 59;
        break;
      case 60:
        openPage = 62;
        break;
      case 61:
        openPage = 77;
        break;
      case 62:
        openPage = 83;
        break;
      case 63:
        openPage = 89;
        break;
      case 64:
        openPage = 95;
        break;
      case 65:
        openPage = 100;
        break;
      case 66:
        openPage = 111;
        break;
      case 67:
        openPage = 119;
        break;
      case 68:
        openPage = 125;
        break;
      case 69:
        openPage = 133;
        break;
      case 70:
        openPage = 138;
        break;
      case 71:
        openPage = 148;
        break;
      case 72:
        openPage = 150;
        break;
      case 73:
        openPage = 156;
        break;
      case 74:
        openPage = 165;
        break;
      case 75:
        openPage = 169;
        break;
      case 76:
        openPage = 180;
        break;
      case 77:
        openPage = 194;
        break;
      case 78:
        openPage = 214;
        break;
      case 79:
        openPage = 221;
        break;
      case 80:
        openPage = 231;
        break;
      case 81:
        openPage = 236;
        break;
      case 82:
        openPage = 244;
        break;
      case 83:
        openPage = 262;
        break;
      case 84:
        openPage = 270;
        break;
      case 85:
        openPage = 277;
        break;
      case 86:
        openPage = 301;
        break;
      case 87:
        openPage = 309;
        break;
      case 88:
        openPage = 314;
        break;
      case 89:
        openPage = 320;
        break;
      case 90:
        openPage = 327;
        break;
      case 91:
        openPage = 334;
        break;
      case 92:
        openPage = 347;
        break;
      case 93:
        openPage = 354;
        break;
      case 94:
        openPage = 364;
        break;
      case 95:
        openPage = 375;
        break;
      case 96:
        openPage = 388;
        break;
      case 97:
        openPage = 395;
        break;
      case 98:
        openPage = 406;
        break;
      case 99:
        openPage = 413;
        break;
      case 100:
        openPage = 424;
        break;
      case 101:
        openPage = 1;
        break;
      case 102:
        openPage = 18;
        break;
      case 103:
        openPage = 26;
        break;
      case 104:
        openPage = 32;
        break;
      case 105:
        openPage = 39;
        break;
      case 106:
        openPage = 48;
        break;
      case 107:
        openPage = 52;
        break;
      case 108:
        openPage = 58;
        break;
      case 109:
        openPage = 66;
        break;
      case 110:
        openPage = 70;
        break;
      case 111:
        openPage = 75;
        break;
      case 112:
        openPage = 79;
        break;
      case 113:
        openPage = 86;
        break;
      case 114:
        openPage = 93;
        break;
      case 115:
        openPage = 106;
        break;
      case 116:
        openPage = 112;
        break;
      case 117:
        openPage = 116;
        break;
      case 118:
        openPage = 122;
        break;
      case 119:
        openPage = 130;
        break;
      case 120:
        openPage = 140;
        break;
      case 121:
        openPage = 147;
        break;
      case 122:
        openPage = 151;
        break;
      case 123:
        openPage = 159;
        break;
      case 124:
        openPage = 166;
        break;
      case 125:
        openPage = 169;
        break;
      case 126:
        openPage = 177;
        break;
      case 127:
        openPage = 184;
        break;
      case 128:
        openPage = 191;
        break;
      case 129:
        openPage = 201;
        break;
      case 130:
        openPage = 216;
        break;
      case 131:
        openPage = 226;
        break;
      case 132:
        openPage = 228;
        break;
      case 133:
        openPage = 231;
        break;
      case 134:
        openPage = 240;
        break;
      case 135:
        openPage = 243;
        break;
      case 136:
        openPage = 249;
        break;
      case 137:
        openPage = 258;
        break;
      case 138:
        openPage = 265;
        break;
      case 139:
        openPage = 273;
        break;
      case 140:
        openPage = 281;
        break;
      case 141:
        openPage = 291;
        break;
      case 142:
        openPage = 295;
        break;
      case 143:
        openPage = 301;
        break;
      case 144:
        openPage = 307;
        break;
      case 145:
        openPage = 311;
        break;
      case 146:
        openPage = 314;
        break;
      case 147:
        openPage = 324;
        break;
      case 148:
        openPage = 327;
        break;
      case 149:
        openPage = 335;
        break;
      case 150:
        openPage = 339;
        break;
      case 151:
        openPage = 342;
        break;
      case 152:
        openPage = 347;
        break;
      default:
        _isValid = false;
    }

    book.firstPage = openPage;
    book.id = getMnBookID(suttaNumber);
    book.name = book.id;

    return book;
  }

  String getMnBookID(suttaNumber) {
    String bookId = "mula_ma_01";
    // if 14 or higher change
    // if higher than 23 change again to 3rd vol
    if (suttaNumber > 50) {
      bookId = (suttaNumber <= 100) ? "mula_ma_02" : "mula_ma_03";
    }
    return bookId;
  }

  Future<Book> getSnBookDetails(String qj, Book book) async {
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9\.]'), '');
    String bookID = getSnBookID(aStr);
    int paranum = getSNParagraph(aStr);
    final dbHelper = DatabaseHelper();
    final paraRepo = ParagraphDatabaseRepository(dbHelper);
    book.firstPage = await paraRepo.getPageNumber(bookID, paranum);
    book.id = bookID;
    book.name = bookID;
    book.paraNum = paranum;
    return book;
  } // get the number

  String getSnBookID(String notation) {
    // there are 55 samyuttas.
    // get the first number from the string
    String bookID = "mula_sa_01";
    var samyuttaAndSutta = notation.split('.');
    var samyutta = int.parse(samyuttaAndSutta[0]);
    if (samyutta <= 11) {
      bookID = "mula_sa_01";
    }
    if (samyutta >= 12 && samyutta <= 21) {
      bookID = "mula_sa_02";
    }
    if (samyutta >= 22 && samyutta <= 34) {
      bookID = "mula_sa_03";
    }
    if (samyutta >= 35 && samyutta <= 44) {
      bookID = "mula_sa_04";
    }
    if (samyutta >= 45 && samyutta <= 56) {
      bookID = "mula_sa_05";
    }

    return bookID;
  }

  String getAnBookID(String notation) {
    // there are 55 samyuttas.
    // get the first number from the string
    String bookID = "mula_an_0";
    var anguttaraBookSutta = notation.split('.');
    int anguttaraBook = int.parse(anguttaraBookSutta[0]);

    anguttaraBook = (anguttaraBook > 11) ? 11 : anguttaraBook;

    if (anguttaraBook < 10) {
      bookID = bookID + anguttaraBook.toString();
    } else {
      bookID = "mula_an_$anguttaraBook";
    }
    return bookID;
  }

  int getAnParagraph(String notation) {
    var anguttaraBookAndSutta = notation.split('.');
    //var book = int.parse(anguttaraBookAndSutta[0]);
    var sutta = int.parse(anguttaraBookAndSutta[1]);
    return sutta;
  }

  int getSNParagraph(String notation) {
    var samyuttaAndSutta = notation.split('.');
    var samyutta = int.parse(samyuttaAndSutta[0]);
    var sutta = int.parse(samyuttaAndSutta[1]);
    sutta--;
    // adjust
    switch (samyutta) {
      case 1:
        return 1 + sutta;
      case 2:
        return 82 + sutta;
      case 3:
        return 112 + sutta;
      case 4:
        return 137 + sutta;
      case 5:
        return 162 + sutta;
      case 6:
        return 172 + sutta;
      case 7:
        return 187 + sutta;
      case 8:
        return 209 + sutta;
      case 9:
        return 221 + sutta;
      case 10:
        return 235 + sutta;
      case 11:
        return 247 + sutta;
      // book 2 below
      case 12:
        return 1 + sutta;
      case 13:
        return 74 + sutta;
      case 14:
        return 85 + sutta;
      case 15:
        return 124 + sutta;
      case 16:
        return 144 + sutta;
      case 17:
        return 157 + sutta;
      case 18:
        return 188 + sutta;
      case 19:
        return 202 + sutta;
      case 20:
        return 223 + sutta;
      case 21:
        return 235 + sutta;
// book 3 below
      case 22:
        return 1 + sutta;
      case 23:
        return 160 + sutta;
      case 24:
        return 206 + sutta;
      case 25:
        return 302 + sutta;
      case 26:
        return 312 + sutta;
      case 27:
        return 322 + sutta;
      case 28:
        return 332 + sutta;
      case 29:
        return 342 + sutta;
      case 30:
        return 392 + sutta;
      case 31:
        return 438 + sutta;
      case 32:
        return 550 + sutta;
      case 33:
        return 607 + sutta;
      case 34:
        return 662 + sutta;
//book 4 below
      case 35:
        return 1 + sutta;
      case 36:
        return 249 + sutta;
      case 37:
        return 280 + sutta;
      case 38:
        return 314 + sutta;
      case 39:
        return 330 + sutta;
      case 40:
        return 332 + sutta;
      case 41:
        return 343 + sutta;
      case 42:
        return 353 + sutta;
      case 43:
        return 366 + sutta;
      case 44:
        return 410 + sutta;
// book 5 below
      case 45:
        return 1 + sutta;
      case 46:
        return 182 + sutta;
      case 47:
        return 367 + sutta;
      case 48:
        return 471 + sutta;
      case 49:
        return 651 + sutta;
      case 50:
        return 705 + sutta;
      case 51:
        return 813 + sutta;
      case 52:
        return 899 + sutta;
      case 53:
        return 923 + sutta;
      case 54:
        return 977 + sutta;
      case 55:
        return 997 + sutta;
      case 56:
        return 1071 + sutta;
      default:
        return 0;
    }
  }

  Future<Book> getAnBookDetails(String qj, Book book) async {
    // we will get some type of number like an4.12
    // an = anguttara
    // 4 = book number
    // 12 = paragraph or sutta number (they are the same)
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9\.]'), '');
    String bookID = getAnBookID(aStr);
    int paranum = getAnParagraph(aStr);
    final dbHelper = DatabaseHelper();
    final paraRepo = ParagraphDatabaseRepository(dbHelper);
    book.firstPage = await paraRepo.getPageNumber(bookID, paranum);
    book.id = bookID;
    book.name = bookID;
    book.paraNum = paranum;
    return book;
  }

  String extractNumber(String input) {
    final RegExp regExp = RegExp(r'\d+');
    final String? match = regExp.stringMatch(input);
    return match ?? '';
  }

  Future<List<Sutta>> handleBook(String filterdWord) async {
    List<Sutta> suttas = [];

    for (var entry in qjbooks.entries) {
      if (filterdWord.toLowerCase().contains(entry.key)) {
        String num = extractNumber(filterdWord);
        if (num.isNotEmpty) {
          int paranum = int.parse(num);

          var book = Book(id: entry.value, name: entry.key);
          final paraRepo = ParagraphDatabaseRepository(DatabaseHelper());
          book.firstPage = await paraRepo.getPageNumber(entry.value, paranum);

          Sutta sutta = Sutta(
            bookID: entry.value,
            bookName: entry.key,
            name: num,
            pageNumber: book.firstPage,
          );
          if (book.firstPage != -1) {
            suttas.add(sutta);
          }
        }
      }
    }

    return suttas;
  }

String getBookKey(String filterdWord) {
    for (String book in qjbooks.keys) {
      if (filterdWord.toLowerCase().contains(book)) {
        return book;
      }
    }
    return "";
  }
  */
}
