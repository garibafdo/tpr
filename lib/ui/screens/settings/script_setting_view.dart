import 'package:flutter/material.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/providers/font_provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';

import '../../../business_logic/view_models/script_settings_view_model.dart';
import 'select_script_language.dart';

class ScriptSettingView extends StatelessWidget {
  const ScriptSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScriptSettingController>(
        create: (_) => ScriptSettingController(),
        child: Consumer<ScriptSettingController>(
          builder: (context, controller, child) {
            String currentScriptLanguage = Prefs.currentScriptLanguage;

            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.font_download_outlined),
                title: Text(AppLocalizations.of(context)!.paliScript,
                    style: Theme.of(context).textTheme.titleLarge),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: ListTile(
                      title: Text(AppLocalizations.of(context)!.scriptLanguage),
                      trailing: const SelectScriptLanguageWidget(),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axis: Axis
                            .vertical, // Specify the axis of size change, here it's vertical
                        child: child,
                      );
                    },
                    child: currentScriptLanguage == 'ro'
                        ? Padding(
                            key: const ValueKey('RomanFontSelector'),
                            padding: const EdgeInsets.only(left: 32.0),
                            child: _buildRomanFontSelector(context),
                          )
                        : const SizedBox(
                            key: ValueKey('EmptySpace'),
                            height: 0,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.showAlternatePali),
                      trailing: Switch(
                        onChanged: (value) => context
                            .read<ScriptSettingController>()
                            .onToggleShowAlternatePali(value),
                        value: context
                            .read<ScriptSettingController>()
                            .isShowAlternatePali,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.showPTSPageNumber),
                      trailing: Switch(
                        onChanged: (value) => context
                            .read<ScriptSettingController>()
                            .onToggleShowPtsNumber(value),
                        value: context
                            .read<ScriptSettingController>()
                            .isShowPtsNumber,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: ListTile(
                      title: Text(
                          AppLocalizations.of(context)!.showThaiPageNumber),
                      trailing: Switch(
                        onChanged: (value) => context
                            .read<ScriptSettingController>()
                            .onToggleShowThaiNumber(value),
                        value: context
                            .read<ScriptSettingController>()
                            .isShowThaiNumber,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.showVRIPageNumber),
                      trailing: Switch(
                        onChanged: (value) => context
                            .read<ScriptSettingController>()
                            .onToggleShowVriNumber(value),
                        value: context
                            .read<ScriptSettingController>()
                            .isShowVriNumber,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildRomanFontSelector(BuildContext context) {
    final readerFontProvider = Provider.of<ReaderFontProvider>(context);

    return ListTile(
      title: Text(AppLocalizations.of(context)!.selectRomanFont),
      trailing: DropdownButton<String>(
        value: readerFontProvider.selectedFont,
        onChanged: (String? newValue) {
          readerFontProvider.setSelectedFont(newValue);
          _saveFontPreference(newValue);
        },
        items: <String>['Open Sans', 'Noto Serif', 'DejaVu Sans', 'System Font']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: ColoredText(value),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveFontPreference(String? fontName) async {
    Prefs.romanFontName = fontName ?? "";
  }
}
