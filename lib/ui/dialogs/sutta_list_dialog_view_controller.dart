import 'package:flutter/foundation.dart';
import 'package:tipitaka_pali/utils/pali_script.dart';
import 'package:tipitaka_pali/utils/pali_script_converter.dart';
import 'package:tipitaka_pali/utils/script_detector.dart';

import '../../business_logic/models/sutta.dart';
import '../../services/repositories/sutta_repository.dart';

class SuttaListDialogViewController {
  SuttaListDialogViewController(this.suttaRepository);
  final SuttaRepository suttaRepository;

  // late Iterable<Sutta> _allSutta;
  late final ValueNotifier<Iterable<Sutta>?> _suttas = ValueNotifier(null);
  ValueListenable<Iterable<Sutta>?> get suttas => _suttas;

  String _filter = '';
  String get filter => _filter;

  void onLoad() async {
    // _allSutta = await suttaRepository.getAll();
    // _suttas.value = _allSutta;
  }

  void onFilterChanged(String filter) async {
    // _allSutta = await suttaRepository.getSuttas(filter);

    final Script inputScript = ScriptDetector.getLanguage(filter);
    if (inputScript != Script.roman) {
      filter = PaliScript.getRomanScriptFrom(script: inputScript, text: filter);
    }
    if (filter.trim().isEmpty) {
      _suttas.value = null;
      _filter = '';
    } else {
      _suttas.value = await suttaRepository.getSuttas(filter);
      _filter = filter;
    }
  }
}
