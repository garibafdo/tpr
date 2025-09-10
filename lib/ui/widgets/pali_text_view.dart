import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/provider/script_language_provider.dart';
import '../../utils/font_utils.dart';
import '../../utils/pali_script.dart';
import '../../utils/pali_script_converter.dart';

class PaliTextView extends StatelessWidget {
  /// display pali text on current script locale and font family.
  /// text must be in roman script.
  const PaliTextView(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final script = context.read<ScriptLanguageProvider>().currentScript;
    final fontName = FontUtils.getfontName(script: script);
    return Text(
      script == Script.roman
          ? text
          : PaliScript.getScriptOf(
              romanText: text,
              script: script,
            ),
      style: style == null
          ? TextStyle(fontFamily: fontName, height: 1.2)
          : style?.copyWith(fontFamily: fontName, height: 1.2),
    );
  }
}
