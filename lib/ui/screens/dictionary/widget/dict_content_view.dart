import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/services/repositories/dictionary_history_repo.dart';
import 'package:tipitaka_pali/ui/dialogs/show_compound_family_dialog.dart';
import 'package:tipitaka_pali/ui/dialogs/show_declension_dialog.dart';
import 'package:tipitaka_pali/ui/dialogs/show_freq_dialog.dart';
import 'package:tipitaka_pali/ui/dialogs/show_root_family_dialog.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/controller/dictionary_controller.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/controller/dictionary_state.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/widget/dictionary_history_view.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';
import 'package:tipitaka_pali/utils/pali_script.dart';
import 'package:tipitaka_pali/utils/pali_script_converter.dart';
import 'package:tipitaka_pali/utils/script_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class DictionaryContentView extends StatelessWidget {
  final ScrollController? scrollController;
  const DictionaryContentView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final state = context.select<DictionaryController, DictionaryState>(
        (controller) => controller.dictionaryState);
    GlobalKey textKey = GlobalKey();

    return state.when(
        initial: () => ValueListenableBuilder(
            valueListenable: context.read<DictionaryController>().histories,
            builder: (_, histories, __) {
              return DictionaryHistoryView(
                histories: histories,
                onClick: (word) =>
                    context.read<DictionaryController>().onWordClicked(word),
                onDelete: (word) =>
                    context.read<DictionaryController>().onDelete(word),
                scrollController: scrollController,
              );
            }),
        loading: () => const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator())),
        data: (content) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(8.0),
              child: SelectionArea(
                child: GestureDetector(
                  onTapUp: (details) {
                    final box = textKey.currentContext?.findRenderObject()!
                        as RenderBox;
                    final result = BoxHitTestResult();
                    final offset = box.globalToLocal(details.globalPosition);
                    if (!box.hitTest(result, position: offset)) {
                      return;
                    }

                    for (final entry in result.path) {
                      final target = entry.target;
                      if (entry is! BoxHitTestEntry ||
                          target is! RenderParagraph) {
                        continue;
                      }

                      final p =
                          target.getPositionForOffset(entry.localPosition);
                      final text = target.text.toPlainText();
                      if (text.isNotEmpty && p.offset < text.length) {
                        final int offset = p.offset;
                        // print('pargraph: $text');
                        final charUnderTap = text[offset];
                        final leftChars = getLeftCharacters(text, offset);
                        final rightChars = getRightCharacters(text, offset);
                        final word = leftChars + charUnderTap + rightChars;
                        debugPrint(word);
                        writeHistory(
                            word,
                            AppLocalizations.of(context)!.dictionary,
                            1,
                            "dictionary");

                        // loading definitions
                        String romanWord = word;
                        Script inputScript = ScriptDetector.getLanguage(word);
                        if (inputScript != Script.roman) {
                          romanWord = PaliScript.getRomanScriptFrom(
                              script: inputScript, text: romanWord);
                        }

                        context
                            .read<DictionaryController>()
                            .onWordClicked(romanWord);
                      }
                    }
                  },
                  child: HtmlWidget(
                    key: textKey,
                    content,
                    customStylesBuilder: (element) {
                      if (element.classes.contains('dpdheader')) {
                        return {'font-weight:': 'bold'};
                      }
                      return null;
                    },
                    customWidgetBuilder: (element) {
                      final href = element.attributes['href'];
                      if (href != null) {
                        // Determine the link text
                        String linkText = href.contains("wikipedia")
                            ? "Wikipedia"
                            : "Submit a correction";
                        final allowedExtras = [
                          'inflect',
                          'root-family',
                          'compound-family',
                          'freq'
                        ];

                        if (href.startsWith("dpd://")) {
                          // Return a small button for DPD extra links

                          Uri parsedUri = Uri.parse(href);
                          String extra = parsedUri.host;
                          int id = parsedUri.port;

                          return InlineCustomWidget(
                            child: ElevatedButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                minimumSize: const Size(0,
                                    0), // Removes default minimum size constraints
                                tapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap, // Reduces button padding
                              ),
                              onPressed: () {
                                if (extra == 'get-extras') {
                                  debugPrint(
                                      'Get Extras button pressed for id: $id');
                                  // Implement logic to direct user to the download screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DownloadView()),
                                  );
                                } else if (allowedExtras.contains(extra)) {
                                  debugPrint(
                                      'DPD "$extra" extra operation for: $id');
                                  showDpdExtra(context, extra, id);
                                } else {
                                  debugPrint('Unhandled DPD link: $extra');
                                }
                              },
                              child: Text(
                                element.text,
                                style: const TextStyle(
                                    fontSize: 10), // Set font size to 10pt
                              ),
                            ),
                          );
                        } else {
                          // Use InkWell with 10pt font for other links
                          return InkWell(
                            onTap: () {
                              launchUrl(Uri.parse(href),
                                  mode: LaunchMode.externalApplication);
                              debugPrint('Will launch $href. --> $textKey');
                            },
                            child: Text(
                              linkText,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
                                fontSize: 10, // Set font size to 10pt
                              ),
                            ),
                          );
                        }
                      }
                      return null;
                    },
                    textStyle: TextStyle(
                        fontSize: Prefs.dictionaryFontSize.toDouble(),
                        color: context.watch<ThemeChangeNotifier>().isDarkMode
                            ? Colors.white
                            : Colors.black,
                        inherit: true),
                  ),
                ),
              ),
            ),
        noData: () => const SizedBox(
              height: 100,
              child: Center(child: Text('Not found')),
            ));
  }

  showDpdExtra(BuildContext context, String extra, int wordId) async {
    switch (extra) {
      case "inflect":
        showDeclensionDialog(context, wordId);
        break;
      case "root-family":
        showRootFamilyDialog(context, wordId);
        break;
      case "compound-family":
        showCompoundFamilyDialog(context, wordId);
        break;
      case "freq":
        showFreqDialog(context, wordId);
        break;
    }
  }

  // **Modified code ends here**

  String getLeftCharacters(String text, int offset) {
    RegExp wordBoundary = RegExp(r'[\s\.\-",\+]');
    StringBuffer chars = StringBuffer();
    for (int i = offset - 1; i >= 0; i--) {
      if (wordBoundary.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString().split('').reversed.join();
  }

  String getRightCharacters(String text, int offset) {
    RegExp wordBoundary = RegExp(r'[\s\.\-",\+]');
    StringBuffer chars = StringBuffer();
    for (int i = offset + 1; i < text.length; i++) {
      if (wordBoundary.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString();
  }
}

typedef WordChanged = void Function(String word);

// put in a common place?  also used in paliPageWidget
writeHistory(String word, String context, int page, String bookId) async {
  final DictionaryHistoryDatabaseRepository dictionaryHistoryRepository =
      DictionaryHistoryDatabaseRepository(dbh: DatabaseHelper());

  await dictionaryHistoryRepository.insert(word, context, page, bookId);
}
