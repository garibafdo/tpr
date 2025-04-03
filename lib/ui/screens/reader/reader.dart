import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';
import 'package:tipitaka_pali/ui/screens/reader/mobile_reader_container.dart';
import 'package:tipitaka_pali/ui/screens/reader/widgets/search_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';

import '../../../app.dart';
import '../../../business_logic/models/book.dart';
import '../../../business_logic/view_models/search_page_view_model.dart';
import '../../../providers/navigation_provider.dart';
import '../../../services/database/database_helper.dart';
import '../../../services/provider/script_language_provider.dart';
import '../../../services/repositories/book_repo.dart';
import '../../../services/repositories/bookmark_repo.dart';
import '../../../services/repositories/page_content_repo.dart';
import '../../../utils/pali_script.dart';
import '../../../utils/platform_info.dart';
import '../../dialogs/dictionary_dialog.dart';
import '../dictionary/controller/dictionary_controller.dart';
import '../home/openning_books_provider.dart';
import '../home/search_page/search_page.dart';
import 'controller/reader_view_controller.dart';
import 'widgets/horizontal_book_view.dart';
import 'widgets/reader_tool_bar.dart';
import 'widgets/vertical_book_view.dart';

class Reader extends StatelessWidget {
  final Book book;
  final int? initialPage;
  final String? textToHighlight;
  final BookViewMode bookViewMode;
  final String bookUuid;

  const Reader({
    super.key,
    required this.book,
    this.initialPage,
    this.textToHighlight,
    required this.bookViewMode,
    required this.bookUuid,
  });

  @override
  Widget build(BuildContext context) {
    myLogger.i('calling Reader build method');
    // logger.i('pass parameter: book: ${book.id} --- ${book.name}');
    // logger.i('current Page in Reader Screen: $currentPage');
    // logger.i('textToHighlight in Reader Screen: $textToHighlight');
    final openedBookProvider = context.read<OpenningBooksProvider>();
    final combo = openedBookProvider.books.map((e) => e['book'].id).join('-');
    return ChangeNotifierProvider<ReaderViewController>(
      // this key prevents a refresh and the refresh is needed for this
      // no highlight bug to not show up.
      // open 2 book in two tabs, close one tab.. the remaining tab will
      // not allow highlighting if key(book.id) code is there.
      // it is good in many cases, but a bug somewhere causes
      // the highlight to fail
      // TODO try to fix this bug later
      //////////////////////////////////
      key: Key('${book.id}@$combo'),
      ////////////////////////
      create: (context) => ReaderViewController(
          context: context,
          bookRepository: BookDatabaseRepository(DatabaseHelper()),
          bookmarkRepository: BookmarkDatabaseRepository(DatabaseHelper()),
          pageContentRepository:
              PageContentDatabaseRepository(DatabaseHelper()),
          book: book,
          initialPage: initialPage,
          textToHighlight: textToHighlight,
          bookUuid: bookUuid)
        ..loadDocument(),
      child: ReaderView(
        bookViewMode: bookViewMode,
      ),
    );
  }
}

class ReaderView extends StatelessWidget implements Searchable {
  final BookViewMode bookViewMode;
  ReaderView({super.key, required this.bookViewMode});
  final _sc = SlidableBarController(initialStatus: Prefs.controlBarShow);

  @override
  void onSearchRequested(BuildContext context) {
    debugPrint('on search requested');
    Provider.of<ReaderViewController>(context, listen: false)
        .showSearchWidget(true);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
              Platform.isMacOS
                  ? LogicalKeyboardKey.meta
                  : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyF): const SearchIntent(),
        },
        child: Actions(actions: <Type, Action<Intent>>{
          SearchIntent: SearchAction(this, context),
        }, child: _getReader(context)));
  }

  Widget _getReader(BuildContext context) {
    final showSearch = context.select<ReaderViewController, bool>(
        (controller) => controller.showSearch);

    final isLoaded = context.select<ReaderViewController, bool>(
        (controller) => controller.isloadingFinished);

    if (!isLoaded) {
      // display fade loading
      // circular progessing is somehow annoying
      return const Material(
        child: Center(
          child: Text('. . .'),
        ),
      );
    }

    return Scaffold(
      // appBar: PlatformInfo.isDesktop || Mobile.isTablet(context)
      //     ? null
      //     : const ReaderAppBar(),
      body: Consumer<ThemeChangeNotifier>(
          builder: ((context, themeChangeNotifier, child) => Container(
                color: Prefs.getChosenColor(context),
                child: SlidableBar(
                    slidableController: _sc,
                    side: Side.bottom,
                    barContent: const ReaderToolbar(),
                    size: 100,
                    clicker: SlidableClicker(controller: _sc),
                    frontColor: Colors.white,
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    clickerSize: 32,
                    clickerPosition: 0.98,
                    child: Column(children: [
                      if (showSearch)
                        SearchWidget(
                          word: context
                              .read<ReaderViewController>()
                              .searchText
                              .value,
                        ),
                      Expanded(
                          // padding: EdgeInsets.only(top: showSearch ? 42 : 0),
                          child: bookViewMode == BookViewMode.horizontal
                              // don't const these two guys, otherwise theme changes
                              // won't be reflected, alternatively: get notified about
                              // changes in the views themselves
                              ? VerticalBookView(
                                  onSearchedSelectedText: (text) =>
                                      _onSearchSelectedText(text, context),
                                  onSharedSelectedText: _onShareSelectedText,
                                  onClickedWord: (word) =>
                                      _onClickedWord(word, context),
                                  onSearchedInCurrentBook: (text) =>
                                      _onClickedSearchInCurrent(context, text),
                                  onOpenRouterTranslateSelected: (text) =>
                                      _onOpenRouterTranslateSelected(
                                          text, context),
                                  onSelectionChanged: (text) {
                                    Provider.of<ReaderViewController>(context,
                                            listen: false)
                                        .selection = text;
                                  },
                                )
                              : HorizontalBookView(
                                  onSearchedSelectedText: (text) =>
                                      _onSearchSelectedText(text, context),
                                  onSharedSelectedText: _onShareSelectedText,
                                  onClickedWord: (word) =>
                                      _onClickedWord(word, context),
                                  onSearchedInCurrentBook: (text) =>
                                      _onClickedSearchInCurrent(context, text),
                                  onOpenRouterTranslateSelected: (text) =>
                                      _onOpenRouterTranslateSelected(
                                          text, context),
                                  onSelectionChanged: (text) {
                                    Provider.of<ReaderViewController>(context,
                                            listen: false)
                                        .selection = text;
                                  },
                                )),
                    ])),
              ))),
      // bottomNavigationBar: SafeArea(child: ControlBar()),
    );
  }

  void _onSearchSelectedText(String text, BuildContext context) {
    // removing punctuations etc.
    // convert to roman if display script is not roman
    var word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: text);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    if (PlatformInfo.isDesktop || Mobile.isTablet(context)) {
      // displaying dictionary in the side navigation view
      if (!context.read<NavigationProvider>().isNavigationPaneOpened) {
        context.read<NavigationProvider>().toggleNavigationPane();
      }
      context.read<NavigationProvider>().moveToSearchPage();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      );
    }
    // delay a little milliseconds to wait for SearchPage Initialization

    Future.delayed(
      const Duration(milliseconds: 50),
      () => globalSearchWord.value = word,
    );
  }

  void _onShareSelectedText(String text) {
    Share.share(text, subject: 'Pāḷi text from TPR');
  }

  Future<void> _onClickedWord(String word, BuildContext context) async {
    // removing punctuations etc.
    // convert to roman if display script is not roman
    word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: word);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    // displaying dictionary in the side navigation view
    if ((PlatformInfo.isDesktop || Mobile.isTablet(context))) {
      if (context.read<NavigationProvider>().isNavigationPaneOpened) {
        context.read<NavigationProvider>().moveToDictionaryPage();
        // delay a little milliseconds to wait for DictionaryPage initialization
        await Future.delayed(const Duration(milliseconds: 50),
            () => globalLookupWord.value = word);
        return;
      }

      // displaying dictionary in side sheet dialog
      final sideSheetWidth = context
          .read<StreamingSharedPreferences>()
          .getDouble(panelSizeKey, defaultValue: defaultPanelSize)
          .getValue();

      showGeneralDialog(
        context: context,
        barrierLabel: 'TOC',
        barrierDismissible: true,
        transitionDuration:
            Duration(milliseconds: Prefs.animationSpeed.round()),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(-1, 0), end: const Offset(0, 0))
                .animate(
              CurvedAnimation(parent: animation, curve: Curves.linear),
            ),
            child: child,
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                width: sideSheetWidth,
                height: MediaQuery.of(context).size.height - 80,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )),
                child: DictionaryDialog(word: word),
              ),
            ),
          );
        },
      );
    } else {
      // displaying dictionary using bottom sheet dialog
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.6, 0.8, 0.95],
          builder: (context, scrollController) => DictionaryDialog(
            scrollController: scrollController,
            word: word,
          ),
        ),
      );
    }
  }

  void _onClickedSearchInCurrent(BuildContext context, String text) {
    context.read<ReaderViewController>().showSearchWidget(
          true,
          searchText: text,
        );
  }

  Future<void> _onOpenRouterTranslateSelected(
      String text, BuildContext context) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text selected for translation.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String resultText = '';
        return AlertDialog(
          title: Text(
            'AI Translation ${openRouterModelLabels[Prefs.openRouterModel] ?? Prefs.openRouterModel}',
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _translateWithOpenRouter(context, text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final result = snapshot.data!;
              final htmlOutput = result['text'] ?? '';
              resultText = htmlOutput; // no setState needed
              final finishReason = result['finishReason'];

              final warning = '''
<div style="color: red; font-weight: bold; margin-bottom: 12px;">
⚠️ This translation was generated by an AI model. Accuracy is not guaranteed.
</div>
''';

              final truncationNote = (finishReason == 'length_exceeded')
                  ? '''
<div style="color: orange; font-style: italic; margin-bottom: 8px;">
Note: Only the first 4000 characters were sent for translation.
</div>
'''
                  : '';

              final fullHtml = '$warning$truncationNote$htmlOutput';

              return SizedBox(
                height: 400,
                width: 500,
                child: SingleChildScrollView(
                  child: HtmlWidget(fullHtml),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                if (resultText.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nothing to copy.')),
                  );
                  return;
                }
                // Use BeautifulSoup to strip HTML and get plain text
                // Replace <br> with double newlines
                String processedText = resultText.replaceAll(
                    RegExp(r'<br\s*/?>', caseSensitive: false), '\n\n');
                final soup = BeautifulSoup(processedText);
                final plainText = soup.text;
                await Clipboard.setData(ClipboardData(text: plainText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Translation copied.')),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _translateWithOpenRouter(
      BuildContext context, String inputText) async {
    final String apiKey = Prefs.openRouterApiKey;
    const String endpoint = 'https://openrouter.ai/api/v1/chat/completions';

    final prompt = '${Prefs.openRouterPrompt.trim()}\n\nText:\n\n$inputText';

    final requestBody = {
      "model": Prefs.openRouterModel,
      "messages": [
        {
          "role": "user",
          "content": prompt,
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://yourmonastery.org',
          'X-Title': 'Buddhist Sun',
        },
        body: utf8.encode(jsonEncode(requestBody)),
      );

      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);

      // Check if the response has an "error" object
      if (data.containsKey('error')) {
        final errorMessage = data['error']?['message'] ?? 'An error occurred.';
        return {
          'text':
              '<div style="color: red; font-weight: bold;">$errorMessage</div>',
          'finishReason': 'error',
        };
      }

      final content = data['choices']?[0]['message']['content']
              ?.replaceAll(RegExp(r'^```html|```$'), '')
              .trim() ??
          '';

      final finishReason = data['choices']?[0]['finish_reason'] ?? 'unknown';

      return {
        'text': content.isNotEmpty
            ? content
            : '<div style="color: red; font-weight: bold;">No translation returned.</div>',
        'finishReason': finishReason,
      };
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
      return {
        'text':
            '<div style="color: red; font-weight: bold;">Exception: $e</div>',
        'finishReason': 'exception',
      };
    }
  }
}

abstract class Searchable {
  void onSearchRequested(BuildContext context);
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SearchAction extends Action<SearchIntent> {
  SearchAction(this.searchable, this.context);

  final Searchable searchable;
  final BuildContext context;

  @override
  void invoke(covariant SearchIntent intent) =>
      searchable.onSearchRequested(context);
}

class SlidableClicker extends StatefulWidget {
  const SlidableClicker({super.key, required this.controller});

  final SlidableBarController controller;

  @override
  State<SlidableClicker> createState() => _SlidableClickerState();
}

class _SlidableClickerState extends State<SlidableClicker> {
  toggle() {
    setState(() {
      Prefs.controlBarShow = !Prefs.controlBarShow;
      (Prefs.controlBarShow)
          ? widget.controller.show()
          : widget.controller.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Material(
            child: InkWell(
          onTap: toggle,
          child: Ink(
            width: 42,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Icon(
              Prefs.controlBarShow
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
          ),
        )));
  }
}
