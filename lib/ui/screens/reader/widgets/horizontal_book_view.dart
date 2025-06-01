import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../../business_logic/models/page_content.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../controller/reader_view_controller.dart';
import 'pali_page_widget.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class HorizontalBookView extends StatefulWidget {
  const HorizontalBookView(
      {super.key,
      this.onSearchedSelectedText,
      this.onSharedSelectedText,
      this.onClickedWord,
      this.onSearchedInCurrentBook,
      this.onAiContextRightClick,
      this.onSelectionChanged});
  final ValueChanged<String>? onSearchedSelectedText;
  final ValueChanged<String>? onSharedSelectedText;
  final ValueChanged<String>? onClickedWord;
  final ValueChanged<String>? onSearchedInCurrentBook;
  final ValueChanged<String>? onAiContextRightClick;
  final ValueChanged<String>? onSelectionChanged;

  @override
  State<HorizontalBookView> createState() => _HorizontalBookViewState();
}

class _HorizontalBookViewState extends State<HorizontalBookView> {
  late final ReaderViewController readerViewController;
  late final PageController pageController;

  String searchText = '';
  SelectedContent? _selectedContent;

  @override
  void initState() {
    super.initState();
    readerViewController =
        Provider.of<ReaderViewController>(context, listen: false);
    pageController = PageController(
        initialPage: readerViewController.currentPage.value -
            readerViewController.book.firstPage);

    readerViewController.currentPage.addListener(_listenPageChange);
    readerViewController.searchText.addListener(_onSearchTextChanged);
    readerViewController.currentSearchResult.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    readerViewController.highlightEveryMatch.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    readerViewController.currentPage.removeListener(_listenPageChange);
    pageController.dispose();
    readerViewController.currentSearchResult
        .removeListener(_onSearchTextChanged);
    readerViewController.highlightEveryMatch
        .removeListener(_onSearchTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerViewController =
        Provider.of<ReaderViewController>(context, listen: false);

    return PageView.builder(
      controller: pageController,
      pageSnapping: true,
      itemCount: readerViewController.pages.length,
      itemBuilder: (context, index) {
        final PageContent pageContent = readerViewController.pages[index];
        final script = context.read<ScriptLanguageProvider>().currentScript;
        // transciption
        String htmlContent = PaliScript.getScriptOf(
          script: script,
          romanText: pageContent.content,
          isHtmlText: true,
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: 100.0), // estimated toolbar height
            child: SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: [
                    ...selectableRegionState.contextMenuButtonItems,
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          widget.onSearchedSelectedText
                              ?.call(_selectedContent!.plainText);
                          // onSearch(_selectedContent!.plainText);
                        },
                        label: AppLocalizations.of(context)!.searchSelected),
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          widget.onSearchedInCurrentBook
                              ?.call(_selectedContent!.plainText);
                        },
                        label: AppLocalizations.of(context)!.searchInCurrent),
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          final fullText = _selectedContent?.plainText ?? '';
                          //final trimmed = fullText.length > 1800
                          //  ? fullText.substring(0, 1800)
                          // : fullText;
                          widget.onAiContextRightClick?.call(fullText);
                        },
                        label: AppLocalizations.of(context)!.aiContext),
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          widget.onSharedSelectedText
                              ?.call(_selectedContent!.plainText);
                          // Share.share(_selectedContent!.plainText,
                          //     subject: 'Pāḷi text from TPR');
                        },
                        label: AppLocalizations.of(context)!.share),
                  ],
                );
              },
              onSelectionChanged: (value) {
                _selectedContent = value;
                widget.onSelectionChanged?.call(value?.plainText ?? '');
              },
              child: PaliPageWidget(
                  pageNumber: pageContent.pageNumber!,
                  htmlContent: htmlContent,
                  script: script,
                  highlightedWord: readerViewController.textToHighlight,
                  searchText: searchText,
                  pageToHighlight: readerViewController.pageToHighlight,
                  onClick: widget.onClickedWord,
                  book: readerViewController.book),
            ),
          ),
        );
      },
      onPageChanged: (value) {
        int pageNumber = value + readerViewController.book.firstPage;
        readerViewController.onGoto(pageNumber: pageNumber);
      },
    );
  }

  // String? _needToHighlight(int index) {
  //   if (readerViewController.textToHighlight == null) return null;
  //   if (readerViewController.initialPage == null) return null;

  //   if (index ==
  //       readerViewController.initialPage! -
  //           readerViewController.book.firstPage) {
  //     return readerViewController.textToHighlight;
  //   }
  //   return null;
  // }

  void _listenPageChange() {
    int pageIndex = readerViewController.currentPage.value -
        readerViewController.book.firstPage;
    pageController.jumpToPage(pageIndex);
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {
        searchText = readerViewController.searchText.value;
      });
    }
  }
}
