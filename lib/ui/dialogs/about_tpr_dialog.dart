import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import '../widgets/colored_text.dart';

showAboutTprDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  showAboutDialog(
    applicationIcon: Image.asset('assets/icon/icon.png', width: 50, height: 50),
    context: context,
    applicationName: AppLocalizations.of(context)!.tipitaka_pali_reader,
    applicationVersion: 'Version - ${info.version}+${info.buildNumber}',
    children: [ColoredText(AppLocalizations.of(context)!.about_info)],
  );
}
