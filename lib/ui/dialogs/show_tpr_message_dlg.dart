import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/tpr_message.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';
import 'package:url_launcher/url_launcher.dart';

// stateful widget needed for switch.
// is here in the same file for ease..

Future<void> showWhatsNewDialog(
    BuildContext context, TprMessage tprMessage) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return WhatsNewDialog(tprMessage: tprMessage);
    },
  );
}

class WhatsNewDialog extends StatefulWidget {
  final TprMessage tprMessage;

  const WhatsNewDialog({super.key, required this.tprMessage});

  @override
  WhatsNewDialogState createState() => WhatsNewDialogState();
}

class WhatsNewDialogState extends State<WhatsNewDialog> {
  bool _showWhatsNew = Prefs.showWhatsNew; // use initial value from Prefs

  @override
  Widget build(BuildContext context) {
    String osInfo = "";
    if (Platform.isAndroid) {
      osInfo =
          "You can update to Android Version: ${widget.tprMessage.androidVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.androidPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.androidDpdDate}\n";
    }
    if (Platform.isWindows) {
      osInfo =
          "You can update to Windows Version: ${widget.tprMessage.windowsVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.windowsPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.windowsDpdDate}\n";
    }
    if (Platform.isLinux) {
      osInfo =
          "You can update to Linux Version: ${widget.tprMessage.linuxVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.linuxPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.linuxDpdDate}\n";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppBar(
            title: Text(AppLocalizations.of(context)!.whatsNew),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Column(
            children: [
              Text("Installed Version: ${Prefs.versionNumber}"),
              Text(osInfo),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(widget.tprMessage.generalMessage),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.showWhatsNew),
              Switch(
                onChanged: (value) {
                  setState(() {
                    _showWhatsNew = value;
                    Prefs.showWhatsNew = value; // Update the Prefs here
                  });
                },
                value: _showWhatsNew,
              ),
            ],
          ),
          ButtonBar(
            children: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.upgrade),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // check the os and open a url for each os
                  if (Platform.isAndroid) {
                    launchUrl(
                        Uri.parse(
                            "https://play.google.com/store/apps/details?id=com.paauk.tipitakapalireader"),
                        mode: LaunchMode.externalApplication);
                  } else if (Platform.isWindows) {
                    launchUrl(
                        Uri.parse(
                            "https://apps.microsoft.com/store/detail/tipitaka-pali-reader/9MTH9TD82TGR"),
                        mode: LaunchMode.externalApplication);
                  } else if (Platform.isLinux) {
                    launchUrl(
                        Uri.parse(
                            "https://github.com/bksubhuti/tipitaka-pali-reader/releases/latest"),
                        mode: LaunchMode.externalApplication);
                  } else if (Platform.isMacOS || Platform.isIOS) {
                    launchUrl(
                        Uri.parse(
                            "https://apps.apple.com/us/app/tipitaka-pali-reader/id1541426949"),
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.extensions),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadView(),
                    ),
                  );
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
