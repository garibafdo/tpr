import 'package:flutter/material.dart';
import 'package:el_tooltip/el_tooltip.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/provider/script_language_provider.dart';
import '../../utils/pali_script_converter.dart';

Widget getVelthuisHelp(BuildContext context) {
  // if script = roman then return object.. else return null
  final selectedScript = context.watch<ScriptLanguageProvider>().currentScript;

  if (selectedScript == Script.roman) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: ElTooltip(
        position: ElTooltipPosition.bottomStart,
        content: Text(AppLocalizations.of(context)!.velthuisHelp),
        child: const Icon(Icons.question_mark),
      ),
    );
  } else {
    return const SizedBox.shrink();
  }
}
