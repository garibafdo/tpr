import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/app.dart';
import 'package:tipitaka_pali/business_logic/view_models/bookmark_page_view_model.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';


import '../../../../business_logic/models/book.dart';
import '../../../../business_logic/models/bookmark.dart';
import '../../../../business_logic/models/page_content.dart';
import '../../../../business_logic/models/paragraph_mapping.dart';
import '../../../../business_logic/models/recent.dart';
import '../../../../services/dao/recent_dao.dart';
import '../../../../services/database/database_helper.dart';
import '../../../../services/repositories/book_repo.dart';
import '../../../../services/repositories/page_content_repo.dart';
import '../../../../services/repositories/paragraph_mapping_repo.dart';
import '../../../../services/repositories/paragraph_repo.dart';
import '../../../../services/repositories/recent_repo.dart';
import '../../home/openning_books_provider.dart';

class ReaderViewController extends ChangeNotifier {
  final aiTranslationHtml = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isTranslating = ValueNotifier(false);
  // Add these new fields (make sure they're declared):
  final ValueNotifier<Map<int, String>> _translatedSections = ValueNotifier({});
  final ValueNotifier<String?> _lastTranslatedSection = ValueNotifier(null);
  final ValueNotifier<int?> _lastTranslatedPage = ValueNotifier(null);
  
  // Add these getters to the ReaderViewController class
int? get lastTranslatedPage => _lastTranslatedPage.value;
String? get lastTranslatedSection => _lastTranslatedSection.value;
  
  

// In ReaderViewController class:
void setInPlaceTranslation(String html, int pageNumber, String originalText) {
  final currentTranslations = Map<int, String>.from(_translatedSections.value);
  currentTranslations[pageNumber] = html;
  _translatedSections.value = currentTranslations;
  _lastTranslatedSection.value = originalText;
  _lastTranslatedPage.value = pageNumber;
  notifyListeners();
}

void clearInPlaceTranslation() {
  if (_lastTranslatedPage.value != null) {
    final currentTranslations = Map<int, String>.from(_translatedSections.value);
    currentTranslations.remove(_lastTranslatedPage.value);
    _translatedSections.value = currentTranslations;
  }
  notifyListeners();
}

String? getTranslatedContent(int pageNumber) {
  return _translatedSections.value[pageNumber];
}
void redoInPlaceTranslation() {
  if (_lastTranslatedPage.value != null && _lastTranslatedSection.value != null) {
    // This would need to re-trigger the translation, so we'll handle this differently
    // For now, let's just keep track that we want to redo
    _translatedSections.value = Map<int, String>.from(_translatedSections.value);
    notifyListeners();
  }
}

String replaceSelectedText(String originalContent, String selectedText, String translation) {
  // This is a simplified version - you'll need to implement proper text replacement
  // that only replaces the specific selected text, not all occurrences
  return originalContent.replaceFirst(selectedText, translation);
}



// Add this method to ReaderViewController class
String getCurrentPageContent() {
  final currentPageIndex = _currentPage.value - book.firstPage;
  if (currentPageIndex >= 0 && currentPageIndex < pages.length) {
    return pages[currentPageIndex].content;
  }
  return '';
}


  bool _mounted = true;
  bool get mounted => _mounted;

  @override
  void dispose() {
    super.dispose();
    _mounted = false;
  }

  final BuildContext context;
  final PageContentRepository pageContentRepository;
  final BookRepository bookRepository;
  final BookmarkRepository bookmarkRepository;
  final Book book;
  int? initialPage;
  String? textToHighlight;
  String? selection;

  final ValueNotifier<String> _searchText = ValueNotifier('');
  ValueListenable<String> get searchText => _searchText;

  final ValueNotifier<int> _searchResultCount = ValueNotifier(0);
  ValueListenable<int> get searchResultCount => _searchResultCount;

  final ValueNotifier<int> _currentSearchResult = ValueNotifier(1);
  ValueListenable<int> get currentSearchResult => _currentSearchResult;

  final ValueNotifier<bool> _highlightEveryMatch = ValueNotifier(true);
  ValueListenable<bool> get highlightEveryMatch => _highlightEveryMatch;

  bool isloadingFinished = false;

  late ValueNotifier<int> _currentPage;
  ValueListenable<int> get currentPage => _currentPage;

  late int? _pageToHighlight;
  int? get pageToHighlight => _pageToHighlight;

  // will be use this for scroll to this
  String? tocHeader;
  late List<PageContent> pages;
  late List<Bookmark> bookmarks;
  late int numberOfPage;

  bool _showSearch = false;

  bool get showSearch => _showSearch;

  final List<SearchIndex> searchIndexes = [];

  String bookUuid;

  // // script features
  // late final bool _isShowAlternatePali;

  ReaderViewController({
    required this.context,
    required this.pageContentRepository,
    required this.bookRepository,
    required this.bookmarkRepository,
    required this.book,
    this.initialPage,
    this.textToHighlight,
    required this.bookUuid,
  });

  void search(String text) {
    _searchText.value = text;
    searchIndexes.clear();

    if (text.isEmpty) {
      _searchResultCount.value = 0;
      _currentSearchResult.value = 0;
      return;
    }

    var totalResults = 0;
    _currentSearchResult.value = -1;

    // handles empty anchors like <a name="[ID]"></a>
    final String regexPattern = RegExp.escape(text)
        .replaceAll(' ', r'(?:\s*<a\s+name="[^"]*"></a>\s*|\s+)');
    final RegExp regex = RegExp(regexPattern, caseSensitive: false);

    pages.forEachIndexed((index, page) {
      final matches = regex.allMatches(page.content);
      final pageMatches = matches.length;

      if (index + 1 == _currentPage.value && _currentSearchResult.value == -1) {
        _currentSearchResult.value = searchIndexes.length;
      }
      for (int i = 0; i < pageMatches; i++) {
        searchIndexes.add(SearchIndex(book.firstPage + index, i));
      }
      totalResults += pageMatches;
    });
    _searchResultCount.value = totalResults;
    _currentSearchResult.value = 1;
  }

  void showSearchWidget(bool show, {String? searchText}) {
    _showSearch = show;
    if (searchText != null) {
      _searchText.value = searchText;
      search(searchText);
    } else {
      _searchText.value = '';
    }
    _searchText.value = searchText ?? '';

    notifyListeners();
  }

  void setHighlightEveryMatch(bool highlight) {
    _highlightEveryMatch.value = highlight;
  }

  void searchDownward() {
    var next = _currentSearchResult.value += 1;
    if (next > _searchResultCount.value) {
      next = 1;
    }

    final nextIndex = next - 1;
    final nextPage = searchIndexes[nextIndex].page;

    if (_currentPage.value != nextPage) {
      _currentPage.value = nextPage;
    }

    _currentSearchResult.value = next;
  }

  void searchUpward() {
    var next = _currentSearchResult.value -= 1;
    if (next == 0) {
      next = _searchResultCount.value;
    }

    final nextIndex = next - 1;
    final nextPage = searchIndexes[nextIndex].page;
    if (_currentPage.value != nextPage) {
      _currentPage.value = nextPage;
    }

    _currentSearchResult.value = next;
  }

  Future<void> loadDocument() async {
    pages = List.unmodifiable(await _loadPages(book.id));
    await _loadBookmarks(book.id);
    numberOfPage = pages.length;
    await _loadBookInfo(book.id);
    isloadingFinished = true;
    _pageToHighlight = initialPage;
    myLogger.i('loading finished for: ${book.name}');

    if (!_mounted) {
      return;
    }

    notifyListeners();

    // update opened book list
    final openedBookController = context.read<OpenningBooksProvider>();
    openedBookController.update(newPageNumber: _currentPage.value);
    // save to recent table on load of the book.
    // from general book opening and also tapping a search result tile..
    await _saveToRecent();
  }

  Future<List<PageContent>> _loadPages(String bookID) async {
    return await pageContentRepository.getPages(bookID);
  }

  Future<void> _loadBookInfo(String bookID) async {
    book.firstPage = await bookRepository.getFirstPage(bookID);
    book.lastPage = await bookRepository.getLastPage(bookID);
    _currentPage = ValueNotifier(initialPage ?? book.firstPage);
    _pageToHighlight = initialPage;
  }

  Future<void> _loadBookmarks(String bookID) async {
    bookmarks = await bookmarkRepository.getBookmarks(bookID: bookID);
    debugPrint('bookmark count: ${bookmarks.length}');
  }

  List<Bookmark> getBookmarks(int pageNumber) {
    return bookmarks
        .where((element) => element.pageNumber == pageNumber)
        .toList();
  }

  Future<int> getFirstParagraph() async {
    final DatabaseHelper databaseProvider = DatabaseHelper();
    final ParagraphRepository repository =
        ParagraphDatabaseRepository(databaseProvider);
    return await repository.getFirstParagraph(book.id);
  }

  Future<int> getLastParagraph() async {
    final DatabaseHelper databaseProvider = DatabaseHelper();
    final ParagraphRepository repository =
        ParagraphDatabaseRepository(databaseProvider);
    return await repository.getLastParagraph(book.id);
  }

  Future<List<ParagraphMapping>> getParagraphs(int currentPage) async {
    final DatabaseHelper databaseProvider = DatabaseHelper();
    final ParagraphMappingRepository repository =
        ParagraphMappingDatabaseRepository(databaseProvider);

    return await repository.getParagraphMappings(book.id, currentPage);
  }

  Future<List<ParagraphMapping>> getBackWardParagraphs(int currentPage) async {
    final DatabaseHelper databaseProvider = DatabaseHelper();
    final ParagraphMappingRepository repository =
        ParagraphMappingDatabaseRepository(databaseProvider);

    return await repository.getBackWardParagraphMappings(book.id, currentPage);
  }

  Future<int> getPageNumber(int paragraphNumber) async {
    final DatabaseHelper databaseProvider = DatabaseHelper();
    final ParagraphRepository repository =
        ParagraphDatabaseRepository(databaseProvider);
    return await repository.getPageNumber(book.id, paragraphNumber);
  }

  String getCaller(StackTrace currentStack) {
    // Use like so *in* the function you want to find the caller of
    // String caller = getCaller(StackTrace.current);
    // debugPrint("Caller: $caller");
    var stack = currentStack.toString();
    var newLineNum = stack.indexOf("\n", 0);
    var secondLine = stack.substring(newLineNum + 9, newLineNum + 100);
    var endIndex = secondLine.indexOf(" ", 0);
    return secondLine.substring(0, endIndex);
  }

  void gotoPage({required int pageNumber}) {
    _currentPage.value = pageNumber;
    final openedBookController = context.read<OpenningBooksProvider>();
    openedBookController.update(
        newPageNumber: _currentPage.value, bookUuid: bookUuid);
  }

  Future<void> onGoto(
      {required int pageNumber,
      String? word,
      bool saveToRecent = true,
      String? bookUuid}) async {
    myLogger.i('current page number: $pageNumber');
    String caller = getCaller(StackTrace.current);
    debugPrint("Caller: $caller, pageNumber: $pageNumber, word: $word");
    _pageToHighlight = pageNumber;
    // update current page
    gotoPage(pageNumber: pageNumber);
    textToHighlight = word;
    // persit
    if (saveToRecent) {
      await _saveToRecent();
    }
  }

  // Future onPageChanged(int index) async {
  //   _currentPage.value = book.firstPage! + index;
  //   // notifyListeners();

  //   final openedBookController = context.read<OpenedBooksProvider>();
  //   openedBookController.update(newPageNumber: _currentPage.value);
  //   await _saveToRecent();
  // }

  // Future gotoPage(double value) async {
  //   _currentPage.value = value.toInt();
  //   final index = _currentPage.value - book.firstPage!;
  //   // pageController?.jumpToPage(index);
  //   // itemScrollController?.jumpTo(index: index);

  //   final openedBookController = context.read<OpenedBooksProvider>();
  //   openedBookController.update(newPageNumber: _currentPage.value);

  //   //await _saveToRecent();
  // }

  // Future gotoPageAndScroll(double value, String tocText) async {
  //   _currentPage = value.toInt();
  //   tocHeader = tocText;
  //   final index = _currentPage! - book.firstPage!;
  //   // pageController?.jumpToPage(index);
  //   // itemScrollController?.jumpTo(index: _currentPage! - book.firstPage!);
  //   //await _saveToRecent();
  // }

  void saveToBookmark(String note, String selectedText) async {
    BookmarkDatabaseRepository repository =
        BookmarkDatabaseRepository(DatabaseHelper());
    BookDatabaseRepository bookRepository =
        BookDatabaseRepository(DatabaseHelper());
    String name = await bookRepository.getName(book.id);

    repository.insert(Bookmark(
      bookID: book.id,
      pageNumber: _currentPage.value,
      note: note,
      name: name,
      selectedText: selectedText,
    ));
    if (context.mounted) {
      context.read<BookmarkPageViewModel>().refreshBookmarks();
    }
  }

  Future _saveToRecent() async {
    final RecentRepository recentRepository =
        RecentDatabaseRepository(DatabaseHelper(), RecentDao());
    recentRepository.insertOrReplace(Recent(book.id, _currentPage.value));
  }
}

class SearchIndex {
  int page;
  int index;
  SearchIndex(this.page, this.index);
}
