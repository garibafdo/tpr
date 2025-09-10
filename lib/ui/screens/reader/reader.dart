import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
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
import 'package:tipitaka_pali/ui/screens/reader/widgets/interactive_html_text.dart';
import 'package:tipitaka_pali/ui/screens/reader/widgets/search_widget.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

import 'package:tipitaka_pali/l10n/app_localizations.dart';

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
    final openedBookProvider = context.read<OpenningBooksProvider>();
    final combo = openedBookProvider.books.map((e) => e['book'].id).join('-');
    return ChangeNotifierProvider<ReaderViewController>(
      key: Key('${book.id}@$combo'),
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

class ReaderView extends StatefulWidget {
  final BookViewMode bookViewMode;
  const ReaderView({super.key, required this.bookViewMode});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> implements Searchable {
  final _sc = SlidableBarController(initialStatus: Prefs.controlBarShow);
  final FocusNode _translationFocusNode = FocusNode();
  final FocusNode _readerFocusNode = FocusNode();
  final ScrollController _translationScrollController = ScrollController();
  final ScrollController _readerScrollController = ScrollController();
  String? _lastTranslation;
  final ValueNotifier<Offset> _offset = ValueNotifier(const Offset(12, 40));
  final ValueNotifier<Size> _size = ValueNotifier(Size(1500, 400));

  // Global key for the translation bubble
  final GlobalKey _translationBubbleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Request focus on the reader view initially
    _readerFocusNode.requestFocus();

    final readerViewController = context.read<ReaderViewController>();
    readerViewController.isTranslating.addListener(_translationStatusListener);
  }

  @override
  void dispose() {
    final readerViewController = context.read<ReaderViewController>();
    readerViewController.isTranslating.removeListener(_translationStatusListener);
    _translationFocusNode.dispose();
    _readerFocusNode.dispose();
    _translationScrollController.dispose();
    _readerScrollController.dispose();
    _offset.dispose();
    _size.dispose();
    super.dispose();
  }

  void _translationStatusListener() {
    final readerViewController = context.read<ReaderViewController>();
    if (!readerViewController.isTranslating.value) {
      // When translation is finished, give focus to the translation popup
      if (readerViewController.aiTranslationHtml.value != null) {
        _translationFocusNode.requestFocus();
      }
    }
  }


  @override
  void onSearchRequested(BuildContext context) {
    debugPrint('on search requested');
    final rc = Provider.of<ReaderViewController>(context, listen: false);
    rc.showSearchWidget(true, searchText: "");
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
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyA,
        ): const TranslateDharmamitraIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.keyA,
        ): const TranslateDharmamitraSimpleIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.keyR,
        ): const TranslateInPlaceIntent(),
        // Keyboard shortcuts for popup and scrolling
        LogicalKeySet(LogicalKeyboardKey.escape): const ClosePopupIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.escape):
            const ReopenPopupIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyK): const ScrollUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): const ScrollDownIntent(),
        // Vim-like navigation for popup
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH): const MovePopupLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyJ): const MovePopupDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): const MovePopupUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyL): const MovePopupRightIntent(),
        
        
        // ADD THESE NEW SHORTCUTS AFTER THE EXISTING ONES:
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoInPlaceTranslationIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoInPlaceTranslationIntent(),
        
// TO THIS:
LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.keyW,
): const TranslateDharmamitraHindiIntent()
      
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: SearchAction(this, context),
          TranslateDharmamitraIntent: CallbackAction<TranslateDharmamitraIntent>(
              onInvoke: (intent) async {
            final selectedText =
                context.read<ReaderViewController>().selection ?? '';
            await _onAiContextRightClick(selectedText, context,
                useDharmamitraSimple: false);
            return null;
          }),
          TranslateDharmamitraSimpleIntent:
              CallbackAction<TranslateDharmamitraSimpleIntent>(
                  onInvoke: (intent) async {
            final selectedText =
                context.read<ReaderViewController>().selection ?? '';
            await _onAiContextRightClick(selectedText, context,
                useDharmamitraSimple: true);
            return null;
          }),
          
           // ADD THIS NEW ACTION HANDLER RIGHT AFTER THE ABOVE:
    TranslateDharmamitraHindiIntent:
        CallbackAction<TranslateDharmamitraHindiIntent>(
            onInvoke: (intent) async {
      final selectedText =
          context.read<ReaderViewController>().selection ?? '';
      await _onAiContextRightClickHindi(selectedText, context);
      return null;
    }),
          TranslateInPlaceIntent: CallbackAction<TranslateInPlaceIntent>(
            onInvoke: (intent) async {
              final selectedText =
                  context.read<ReaderViewController>().selection ?? '';
              await _onInPlaceTranslation(selectedText, context);
              return null;
            },
          ),
          // In reader.dart, update the ClosePopupIntent and ReopenPopupIntent handlers:

          // Update the ClosePopupIntent handler:
ClosePopupIntent: CallbackAction<ClosePopupIntent>(
  onInvoke: (intent) {
    final rc = context.read<ReaderViewController>();
    if (rc.aiTranslationHtml.value != null) {
      _lastTranslation = rc.aiTranslationHtml.value;
      rc.aiTranslationHtml.value = null;
      _readerFocusNode.requestFocus();
    }
    // Also handle in-place translation revert - use the new method
    rc.clearInPlaceTranslation();
    return null;
  },
),
ReopenPopupIntent: CallbackAction<ReopenPopupIntent>(
  onInvoke: (intent) {
    final rc = context.read<ReaderViewController>();
    if (_lastTranslation != null) {
      rc.aiTranslationHtml.value = _lastTranslation;
      _translationFocusNode.requestFocus();
    }
    // Also handle in-place translation redo - use the new method
    if (rc.lastTranslatedPage != null && rc.lastTranslatedSection != null) {
      _onInPlaceTranslation(rc.lastTranslatedSection!, context);
    }
    return null;
  },
),
          ScrollDownIntent: CallbackAction<ScrollDownIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _translationScrollController.animateTo(
                  _translationScrollController.offset + 200,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (_readerFocusNode.hasFocus) {
                _readerScrollController.animateTo(
                  _readerScrollController.offset + 200,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              }
              return null;
            },
          ),
          ScrollUpIntent: CallbackAction<ScrollUpIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _translationScrollController.animateTo(
                  _translationScrollController.offset - 200,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (_readerFocusNode.hasFocus) {
                _readerScrollController.animateTo(
                  _readerScrollController.offset - 200,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              }
              return null;
            },
          ),
          MovePopupLeftIntent: CallbackAction<MovePopupLeftIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _offset.value = Offset(_offset.value.dx - 10, _offset.value.dy);
              }
              return null;
            },
          ),
          MovePopupRightIntent: CallbackAction<MovePopupRightIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _offset.value = Offset(_offset.value.dx + 10, _offset.value.dy);
              }
              return null;
            },
          ),
          MovePopupUpIntent: CallbackAction<MovePopupUpIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _offset.value = Offset(_offset.value.dx, _offset.value.dy - 10);
              }
              return null;
            },
          ),
          // In the Actions widget in reader.dart, update the handlers:
        UndoInPlaceTranslationIntent: CallbackAction<UndoInPlaceTranslationIntent>(
          onInvoke: (intent) {
            final rc = context.read<ReaderViewController>();
            rc.clearInPlaceTranslation();
            return null;
          },
        ),
        RedoInPlaceTranslationIntent: CallbackAction<RedoInPlaceTranslationIntent>(
  onInvoke: (intent) {
    final rc = context.read<ReaderViewController>();
    // For redo, we need to re-translate the last section
    if (rc.lastTranslatedPage != null && rc.lastTranslatedSection != null) {
      _onInPlaceTranslation(rc.lastTranslatedSection!, context);
    }
    return null;
  },
),
          MovePopupDownIntent: CallbackAction<MovePopupDownIntent>(
            onInvoke: (intent) {
              if (_translationFocusNode.hasFocus) {
                _offset.value = Offset(_offset.value.dx, _offset.value.dy + 10);
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _readerFocusNode,
          autofocus: true,
          child: _getReader(context),
        ),
      ),
    );
  }

  Widget _getReader(BuildContext context) {
    final themeNotifier = context.watch<ThemeChangeNotifier>();
    final isLoaded = context.select<ReaderViewController, bool>(
        (controller) => controller.isloadingFinished);

    if (!isLoaded) {
      return const Material(
        child: Center(
          child: Text('. . .'),
        ),
      );
    }

    return Scaffold(
      body: Consumer<ThemeChangeNotifier>(
        builder: (context, themeChangeNotifier, child) {
          return Container(
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
              child: Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      if (context.watch<ReaderViewController>().showSearch)
                        SearchWidget(
                          word: context
                              .watch<ReaderViewController>()
                              .searchText
                              .value,
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            controller: _readerScrollController, // Added this
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.8,
                                  child: widget.bookViewMode ==
                                          BookViewMode.horizontal
                                      ? VerticalBookView(
                                          onSearchedSelectedText: (text) =>
                                              _onSearchSelectedText(
                                                  text, context),
                                          onSharedSelectedText:
                                              _onShareSelectedText,
                                          onClickedWord: (word) =>
                                              _onClickedWord(word, context),
                                          onMiddleClickedWord: (word) =>
                                              _onMiddleClickedWord(word, context),
                                          onSearchedInCurrentBook: (text) =>
                                              _onClickedSearchInCurrent(
                                                  context, text),
                                          onAiContextRightClick: (text) =>
                                              _onAiContextRightClick(
                                                  text, context),
                                          onSelectionChanged: (text) {
                                            Provider.of<ReaderViewController>(
                                                    context,
                                                    listen: false)
                                                .selection = text;
                                          },
                                        )
                                      : HorizontalBookView(
                                          onSearchedSelectedText: (text) =>
                                              _onSearchSelectedText(
                                                  text, context),
                                          onSharedSelectedText:
                                              _onShareSelectedText,
                                          onClickedWord: (word) =>
                                              _onClickedWord(word, context),
                                          onMiddleClickedWord: (word) =>
                                              _onMiddleClickedWord(word, context),
                                          onSearchedInCurrentBook: (text) =>
                                              _onClickedSearchInCurrent(
                                                  context, text),
                                          onAiContextRightClick: (text) =>
                                              _onAiContextRightClick(
                                                  text, context),
                                          onSelectionChanged: (text) {
                                            Provider.of<ReaderViewController>(
                                                    context,
                                                    listen: false)
                                                .selection = text;
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Translation Overlay
                  _buildTranslationOverlay(context),

                  // Translation Loading Overlay
                  _buildTranslationLoadingOverlay(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildTranslationOverlay(BuildContext context) {
  final themeNotifier = context.watch<ThemeChangeNotifier>();
  final borderColor =
      themeNotifier.themeData.colorScheme.inverseSurface.getShadeColor();
  final mediumTheme = themeNotifier.themeData.colorScheme.surfaceVariant;
  final backgroundColor = switch (Prefs.selectedPageTheme) {
    PageTheme.light => Colors.white,
    PageTheme.medium => mediumTheme,
    PageTheme.dark => Colors.black,
  };

  return ValueListenableBuilder<String?>(
    valueListenable: context.read<ReaderViewController>().aiTranslationHtml,
    builder: (context, html, _) {
      final showTranslation = html != null && html.isNotEmpty;
      if (!showTranslation) {
        return const SizedBox.shrink();
      }

      return ValueListenableBuilder<Offset>(
        valueListenable: _offset,
        builder: (context, offset, _) {
          return Positioned(
            key: _translationBubbleKey,
            left: offset.dx,
            top: offset.dy,
            child: Focus(
              focusNode: _translationFocusNode,
              child: ValueListenableBuilder<Size>(
                valueListenable: _size,
                builder: (context, size, _) {
                  return Stack(
                    children: [
                      Material(
                        elevation: 12,
                        shadowColor: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: size.width,
                          height: size.height,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                backgroundColor,
                                backgroundColor.withOpacity(0.95),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header with drag handle
                              GestureDetector(
                                onPanUpdate: (details) {
                                  _offset.value = Offset(
                                    _offset.value.dx + details.delta.dx,
                                    _offset.value.dy + details.delta.dy,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Flexible(
                                child: SingleChildScrollView(
                                  controller: _translationScrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 20,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context)!.aiContext,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24, // Reduced from default
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              final rc =
                                                  context.read<ReaderViewController>();
                                              _lastTranslation =
                                                  rc.aiTranslationHtml.value;
                                              rc.aiTranslationHtml.value = null;
                                              _readerFocusNode.requestFocus();
                                            },
                                            tooltip:
                                                AppLocalizations.of(context)!.hide,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      InteractiveHtmlText(
  html: html ?? '',
  onWordTap: (word) => _onClickedWord(word, context),
  // Add reduced font size for translation content
  textStyle: TextStyle(
    fontSize: 24, // Reduced font size
    color: Theme.of(context).textTheme.bodyMedium?.color,
  ),
),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Resize handle
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            _size.value = Size(
                              _size.value.width + details.delta.dx,
                              _size.value.height + details.delta.dy,
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildTranslationLoadingOverlay(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.read<ReaderViewController>().isTranslating,
      builder: (context, isLoading, _) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: isLoading ? MediaQuery.of(context).size.height * 0.4 : -200,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isLoading ? 1.0 : 0.0,
            child: Center(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(
                    // Flexible constraints
                    minWidth: 150,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.aiContext,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    // Only show dictionary on middle click, not left click
    // Left click functionality removed for dictionary
    return;
  }

  Future<void> _onMiddleClickedWord(String word, BuildContext context) async {
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

Future<void> _onAiContextRightClick(String text, BuildContext context,
    {bool? useDharmamitraSimple}) async {
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No text selected for translation.'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  context.read<ReaderViewController>().isTranslating.value = true;
  try {
    // Trim and check for 1000-character limit
    String truncatedText = text.trim();
    String truncationNote = '';

    final Map<String, dynamic> result = useDharmamitraSimple != null
        ? (useDharmamitraSimple
            ? await _translateWithDharmamitraSimple(truncatedText)
            : await _translateWithDharmamitra(truncatedText))
        : (Prefs.useGeminiDirect
            ? await _translateWithDharmamitra(truncatedText)
            : await _translateWithDharmamitraSimple(truncatedText));

    final htmlOutput = result['text'] ?? '';
    final finishReason = result['finishReason'];

    // REMOVE THE WARNING BANNER
    final fullHtml = '$truncationNote$htmlOutput';

    if (context.mounted) {
      context.read<ReaderViewController>().aiTranslationHtml.value = fullHtml;
    }
  } finally {
    if (context.mounted) {
      context.read<ReaderViewController>().isTranslating.value = false;
    }
  }
}


// Add this method in the _ReaderViewState class, after the existing _onAiContextRightClick method:
Future<void> _onAiContextRightClickHindi(String text, BuildContext context) async {
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No text selected for translation.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  context.read<ReaderViewController>().isTranslating.value = true;
  try {
    final Map<String, dynamic> result = await _translateWithDharmamitraHindi(text.trim());
    final htmlOutput = result['text'] ?? '';
    final finishReason = result['finishReason'];

    final fullHtml = htmlOutput;

    if (context.mounted) {
      context.read<ReaderViewController>().aiTranslationHtml.value = fullHtml;
    }
  } finally {
    if (context.mounted) {
      context.read<ReaderViewController>().isTranslating.value = false;
    }
  }
}

Future<void> _onInPlaceTranslation(String text, BuildContext context) async {
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No text selected for translation.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  final rc = context.read<ReaderViewController>();
  final currentPage = rc.currentPage.value;

  context.read<ReaderViewController>().isTranslating.value = true;
  try {
    final Map<String, dynamic> result = await _translateWithDharmamitraSimple(text.trim());
    final htmlOutput = result['text'] ?? '';

    // Wrap the translation in a div with smaller font size for in-place translations
    final fullHtml = '<div style="font-size: 24px;">$htmlOutput</div>';

    if (context.mounted) {
      // Store the translation for this specific page and text
      rc.setInPlaceTranslation(fullHtml, currentPage, text);
    }
  } finally {
    if (context.mounted) {
      context.read<ReaderViewController>().isTranslating.value = false;
    }
  }
}

// REMOVE the _replaceSelectedTextWithTranslation function since we're not using it
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
          'HTTP-Referer': 'https://americanmonk.org',
          'X-Title': 'Tipitaka Pali Reader',
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
        SnackBar(
          content: Text('Exception: $e'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return {
        'text':
            '<div style="color: red; font-weight: bold;">Exception: $e</div>',
        'finishReason': 'exception',
      };
    }
  }

  Future<Map<String, dynamic>> _translateWithGemini(String inputText) async {
    final apiKey = Prefs.geminiDirectApiKey;

    // ✅ Hardcoded to Gemini 1.5 Flash (free tier)
    const endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": Prefs.openRouterPrompt.trim()},
            {"text": inputText}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data.containsKey('error')) {
        final errorMessage = data['error']['message'] ?? 'Gemini API Error';
        return {
          'text':
              '<div style="color: red; font-weight: bold;">$errorMessage</div>',
          'finishReason': 'error',
        };
      }

      final parts = data['candidates']?[0]['content']['parts'];
      final responseText = parts?.map((e) => e['text']).join('\n') ?? '';

      return {
        'text': responseText.isNotEmpty
            ? responseText
            : '<div style="color: red; font-weight: bold;">No Gemini response.</div>',
        'finishReason': 'success',
      };
    } catch (e) {
      return {
        'text':
            '<div style="color: red; font-weight: bold;">Gemini exception: $e</div>',
        'finishReason': 'exception',
      };
    }
  }

  Future<Map<String, dynamic>> _translateWithDharmamitra(
      String inputText) async {
    final Map<String, dynamic> jsonDataExplain = {
      'id':
          '{"input_sentence":"$inputText","input_encoding":"auto","target_lang":"english-explained","do_grammar_explanation":false,"model":"default"}',
      'messages': [
        {
          'role': 'user',
          'content': '',
          'parts': [
            {
              'type': 'text',
              'text': '',
            },
          ],
        },
      ],
      'input_sentence': inputText,
      'input_encoding': 'auto',
      'target_lang': 'english-explained',
      'do_grammar_explanation': false,
      'model': 'default',
    };

    // Define the headers.
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // The URL for the POST request.
    final Uri url =
        Uri.parse('https://dharmamitra.org/next/api/mitra-translation-stream');

    try {
      // Make the POST request.
      final http.Response responseExplain = await http.post(
        url,
        headers: headers,
        body: jsonEncode(jsonDataExplain),
      );

      // Check the status code and handle the response.
      if (responseExplain.statusCode == 200) {
        print('Success!');
        print('Response body: ${responseExplain.body}');
        final String htmlText = md.markdownToHtml(responseExplain.body);

        return {
          'text': htmlText,
          'finishReason': 'success',
        };
      } else {
        print('Request failed with status: ${responseExplain.statusCode}');
        print('Response body: ${responseExplain.body}');
        final errorMessage = responseExplain.body;
        return {
          'text':
              '<div style="color: red; font-weight: bold;">$errorMessage</div>',
          'finishReason': 'error',
        };
      }
    } catch (e) {
      print('An error occurred: $e');
      return {
        'text':
            '<div style="color: red; font-weight: bold;">Gemini exception: $e</div>',
        'finishReason': 'exception',
      };
    }
  }

  Future<Map<String, dynamic>> _translateWithDharmamitraSimple(
      String inputText) async {
    final Map<String, dynamic> jsonDataExplain = {
      'id':
          '{"input_sentence":"$inputText","input_encoding":"auto","target_lang":"english","do_grammar_explanation":false,"model":"default"}',
      'messages': [
        {
          'role': 'user',
          'content': inputText,
          'parts': [
            {'type': 'text', 'text': inputText}
          ]
        },
      ],
      'input_sentence': inputText,
      'input_encoding': 'auto',
      'target_lang': 'english',
      'do_grammar_explanation': false,
      'model': 'default',
    };

    // Define the headers.
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // The URL for the POST request.
    final Uri url =
        Uri.parse('https://dharmamitra.org/next/api/mitra-translation-stream');

    try {
      // Make the POST request.
      final http.Response responseExplain = await http.post(
        url,
        headers: headers,
        body: jsonEncode(jsonDataExplain),
      );

      // Check the status code and handle the response.
      if (responseExplain.statusCode == 200) {
        print('Success!');
        print('Response body: ${responseExplain.body}');
        final String htmlText = md.markdownToHtml(responseExplain.body);

        return {
          'text': htmlText,
          'finishReason': 'success',
        };
      } else {
        print('Request failed with status: ${responseExplain.statusCode}');
        print('Response body: ${responseExplain.body}');
        final errorMessage = responseExplain.body;
        return {
          'text':
              '<div style="color: red; font-weight: bold;">$errorMessage</div>',
          'finishReason': 'error',
        };
      }
    } catch (e) {
      print('An error occurred: $e');
      return {
        'text':
            '<div style="color: red; font-weight: bold;">Gemini exception: $e</div>',
        'finishReason': 'exception',
      };
    }
  }
  
  // Add this translation method (after the existing _translateWithDharmamitraSimple method):
Future<Map<String, dynamic>> _translateWithDharmamitraHindi(String inputText) async {
  final Map<String, dynamic> jsonDataExplain = {
    'id':
        '{"input_sentence":"$inputText","input_encoding":"auto","target_lang":"hindi","do_grammar_explanation":false,"model":"default"}',
    'messages': [
      {
        'role': 'user',
        'content': inputText,
        'parts': [
          {'type': 'text', 'text': inputText}
        ]
      },
    ],
    'input_sentence': inputText,
    'input_encoding': 'auto',
    'target_lang': 'hindi', // Changed from 'english' to 'hindi'
    'do_grammar_explanation': false,
    'model': 'default',
  };

  // Define the headers.
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // The URL for the POST request.
  final Uri url =
      Uri.parse('https://dharmamitra.org/next/api/mitra-translation-stream');

  try {
    // Make the POST request.
    final http.Response responseExplain = await http.post(
      url,
      headers: headers,
      body: jsonEncode(jsonDataExplain),
    );

    // Check the status code and handle the response.
    if (responseExplain.statusCode == 200) {
      print('Success!');
      print('Response body: ${responseExplain.body}');
      final String htmlText = md.markdownToHtml(responseExplain.body);

      return {
        'text': htmlText,
        'finishReason': 'success',
      };
    } else {
      print('Request failed with status: ${responseExplain.statusCode}');
      print('Response body: ${responseExplain.body}');
      final errorMessage = responseExplain.body;
      return {
        'text':
            '<div style="color: red; font-weight: bold;">$errorMessage</div>',
        'finishReason': 'error',
      };
    }
  } catch (e) {
    print('An error occurred: $e');
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

class TranslateDharmamitraIntent extends Intent {
  const TranslateDharmamitraIntent();
}

class TranslateDharmamitraSimpleIntent extends Intent {
  const TranslateDharmamitraSimpleIntent();
}

class TranslateInPlaceIntent extends Intent {
  const TranslateInPlaceIntent();
}

class ClosePopupIntent extends Intent {
  const ClosePopupIntent();
}

class ReopenPopupIntent extends Intent {
  const ReopenPopupIntent();
}

class ScrollUpIntent extends Intent {
  const ScrollUpIntent();
}

class ScrollDownIntent extends Intent {
  const ScrollDownIntent();
}

class MovePopupLeftIntent extends Intent {
  const MovePopupLeftIntent();
}

class MovePopupRightIntent extends Intent {
  const MovePopupRightIntent();
}


class MovePopupUpIntent extends Intent {
  const MovePopupUpIntent();
}

class MovePopupDownIntent extends Intent {
  const MovePopupDownIntent();
}

class TranslateDharmamitraHindiIntent extends Intent {
  const TranslateDharmamitraHindiIntent();
}

// ADD THESE NEW INTENT CLASSES AFTER THE EXISTING ONES:
class UndoInPlaceTranslationIntent extends Intent {
  const UndoInPlaceTranslationIntent();
}

class RedoInPlaceTranslationIntent extends Intent {
  const RedoInPlaceTranslationIntent();
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
