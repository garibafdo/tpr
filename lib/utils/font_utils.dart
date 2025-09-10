import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/utils/pali_script_converter.dart';

class FontUtils {
  FontUtils._();

  static String? getfontName({required Script script}) {
    switch (script) {
      case Script.myanmar:
        return 'PyidaungSu';
      case Script.sinhala:
        return 'NotoSansSinhala';
      case Script.devanagari:
        //~ return 'NotoSansDevanagari';
        return 'TiroDevanagariHindi';
      case Script.laos:
        return 'Lao Pali Regular';
      case Script.taitham:
        return 'NotoSansTaiTham';
      case Script.brahmi:
        return "Noto Sans Brahmi";
      case Script.roman:
        return (Prefs.romanFontName == 'System Font')
            ? null
            : Prefs.romanFontName;
      //return 'Langar';
      default:
        return null;
    }
  }

  static String? getfontNameByLocale({required String locale}) {
    return switch (locale) {
      'en' => Prefs.romanFontName,
      //'en' => 'Langar',
      'my' => 'PyidaungSu',
      'si' => 'NotoSansSinhala',
      'hi' => 'NotoSansDevanagari',
      'lo' => 'Lao Pali Regular',
      'ccp' => 'NotoSans Chakma',
      _ => null,
    };
  }
}
