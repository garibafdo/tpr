import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tipitaka_pali/ui/dialogs/reset_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dialogs/about_tpr_dialog.dart';
import '../../widgets/colored_text.dart';

class HelpAboutView extends StatefulWidget {
  const HelpAboutView({super.key});

  @override
  State<HelpAboutView> createState() => _HelpAboutViewState();
}

class _HelpAboutViewState extends State<HelpAboutView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.info),
        title: Text(AppLocalizations.of(context)!.helpAboutEtc,
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          const SizedBox(
            height: 10,
          ),
          _getHelpTile(context),
          _getAboutTile(context),
          _getYouTubeChannel(context),
          _getReviewAppTile(context),
          _getReportIssueTile(context),
          _getResetDataTile(context),
        ],
      ),
    );
  }

  Widget _getQuotesOrRestore() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: const Text("Quote -> Restore:"),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        trailing: Switch(
          onChanged: (value) => {
            //prefs
          },
          value: true,
        ),
      ),
    );
  }

  Widget _getAboutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: const Icon(Icons.info), // Added Icon
        title: ColoredText(AppLocalizations.of(context)!.about),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => showAboutTprDialog(context),
      ),
    );
  }

  Widget _getHelpTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: const Icon(Icons.help), // Added Icon
        title: ColoredText(AppLocalizations.of(context)!.help),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => launchUrl(
            Uri.parse("https://americanmonk.org/tipitaka-pali-reader/"),
            mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _getYouTubeChannel(context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: const Icon(Icons.video_library), // Added Icon
        title: const ColoredText("YouTube Channel"),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => launchUrl(
            Uri.parse(
                "https://www.youtube.com/channel/UCMKjBJT7vMjyWt8RU4lpiDg"),
            mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _getReportIssueTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: const Icon(Icons.report), // Added Icon
        title: ColoredText(AppLocalizations.of(context)!.reportIssue),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => launchUrl(
            Uri.parse(
                "https://github.com/bksubhuti/tipitaka-pali-reader/issues"),
            mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _getReviewAppTile(BuildContext context) {
    return (Platform.isLinux)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: ListTile(
              leading: const Icon(Icons.star), // Added Icon
              title: ColoredText(AppLocalizations.of(context)!.rateThisApp),
              focusColor: Theme.of(context).focusColor,
              hoverColor: Theme.of(context).hoverColor,
              onTap: () {
                final InAppReview inAppReview = InAppReview.instance;
                inAppReview.openStoreListing();
              },
            ),
          );
  }

  Widget _getResetDataTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
          leading: const Icon(Icons.refresh), // Added Icon
          title: ColoredText(AppLocalizations.of(context)!.resetData),
          focusColor: Theme.of(context).focusColor,
          hoverColor: Theme.of(context).hoverColor,
          onTap: () {
            doResetDialog(context);
          }),
    );
  }
}
