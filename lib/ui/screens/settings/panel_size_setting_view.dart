import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class PanelSizeControlView extends StatefulWidget {
  const PanelSizeControlView({super.key});

  @override
  State<PanelSizeControlView> createState() => _PanelSizeControlViewState();
}

class _PanelSizeControlViewState extends State<PanelSizeControlView> {
  late final StreamingSharedPreferences rxPrefs;
  final mininalSize = 200.0;
  late double size;
  @override
  void initState() {
    super.initState();
    rxPrefs = Provider.of<StreamingSharedPreferences>(context, listen: false);
    size = rxPrefs
        .getDouble(panelSizeKey, defaultValue: defaultPanelSize)
        .getValue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: _getPanelSlider()),
/*          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text('left panel width'),
            ),
          ),
          IconButton(
            onPressed: () async {
              setState(() {
                size = size - 10;
                if (size < 100) size = mininalSize;
                // todo show message to user
              });
              await rxPrefs.setDouble(panelSizeKey, size);
            },
            icon: const Icon(Icons.remove),
          ),
          Text(
            size.toInt().toString(),
          ),
          IconButton(
            onPressed: () async {
              setState(() {
                size = size + 10;
              });
              await rxPrefs.setDouble(panelSizeKey, size);
            },
            icon: const Icon(Icons.add),
          ),

          */
        ],
      );
    });
  }

  Widget _getPanelSlider() {
    return Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Column(
          children: [
            Slider(
              value: size,
              min: 250,
              max: 800,
              divisions: 30,
              label: size.round().toString(),
              onChanged: (double value) async {
                setState(() {
                  size = value;
                });
                await rxPrefs.setDouble(panelSizeKey, size);
              },
            ),
            Text(AppLocalizations.of(context)!.panelSize),
          ],
        ));
  }
}
