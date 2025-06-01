import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class RateAppDialog {
  static void _setNeverRate() {
    Prefs.okToRate = false;
  }

  static void _resetUsageData() {
    Prefs.numberWordsLookedUp = 0;
    Prefs.numberBooksOpened = 0;
  }

  static Future<void> showUsageRateMeDialog(BuildContext context) async {
    String message =
        "${AppLocalizations.of(context)!.wouldLikeToRate}\n\n${AppLocalizations.of(context)!.booksOpened} = ${Prefs.numberBooksOpened}\n${AppLocalizations.of(context)!.wordsLookedUp} = ${Prefs.numberWordsLookedUp}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.tipitaka_pali_reader),
          content: Text(message),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      _setNeverRate();
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.never),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _resetUsageData();
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.later),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await rateApp();
                      _setNeverRate();
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.rateAppNow),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      /*   if (!(Platform.isLinux || Platform.isWindows)) {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        } else {
          debugPrint("failed to get inAppReview.isAvailable()");
          inAppReview.openStoreListing(
              appStoreId: '1541426949', microsoftStoreId: '9MTH9TD82TGR');
        }
      } else {
        if (Platform.isWindows) {
        }
      }*/
      // the package does not seem to be working but this works for sure.
      await inAppReview.openStoreListing(
          appStoreId: '1541426949', microsoftStoreId: '9MTH9TD82TGR');
    } catch (_) {
      debugPrint("fail to load in app review");
    }
  }
}
