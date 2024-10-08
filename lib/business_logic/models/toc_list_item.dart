import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/utils/font_utils.dart';
import 'package:tipitaka_pali/utils/pali_script_converter.dart';
import 'toc.dart';
import '../../services/provider/script_language_provider.dart';
import '../../utils/pali_script.dart';

abstract class TocListItem {
  late Toc toc;
  int getPageNumber();
  Widget build(BuildContext context, String filterText);
}

class TocHeadingOne implements TocListItem {
  TocHeadingOne(this.toc);

  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    Script script = context.read<ScriptLanguageProvider>().currentScript;
    final tocName = PaliScript.getScriptOf(script: script, romanText: toc.name);
    return SubstringHighlight(
      text: tocName,
      term: filterText,
      textStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: Prefs.uiFontSize + 2,
          fontWeight: FontWeight.bold,
          fontFamily: FontUtils.getfontName(script: script)),
      textStyleHighlight: TextStyle(color: colorScheme.primary),
    );
  }
}

class TocHeadingTwo implements TocListItem {
  TocHeadingTwo(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    Script script = context.read<ScriptLanguageProvider>().currentScript;
    final tocName = PaliScript.getScriptOf(script: script, romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: Prefs.uiFontSize + 2,
            fontFamily: FontUtils.getfontName(script: script)),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}

class TocHeadingThree implements TocListItem {
  TocHeadingThree(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    Script script = context.read<ScriptLanguageProvider>().currentScript;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tocName = PaliScript.getScriptOf(script: script, romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: Prefs.uiFontSize - 1,
            fontFamily: FontUtils.getfontName(script: script)),
        textStyleHighlight: TextStyle(
            color: colorScheme.primary,
            fontFamily: FontUtils.getfontName(script: script)),
      ),
    );
  }
}

class TocHeadingFour implements TocListItem {
  TocHeadingFour(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    Script script = context.read<ScriptLanguageProvider>().currentScript;

    final tocName = PaliScript.getScriptOf(script: script, romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: Prefs.uiFontSize + 3,
            fontFamily: FontUtils.getfontName(script: script)),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}

class TocHeadingFive implements TocListItem {
  TocHeadingFive(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    Script script = context.read<ScriptLanguageProvider>().currentScript;

    final tocName = PaliScript.getScriptOf(script: script, romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 64.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: Prefs.uiFontSize + 3,
            fontFamily: FontUtils.getfontName(script: script)),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}
