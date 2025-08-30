import 'unicode_pali_letters.dart';
import 'package:characters/characters.dart';

String toUni(String input) {
  if (input.isEmpty) return input;

  return input
      .replaceAll(r'aa', 'ā')
      .replaceAll(r'ii', 'ī')
      .replaceAll(r'uu', 'ū')
      .replaceAll(r'.t', 'ṭ')
      .replaceAll(r'.d', 'ḍ')
      .replaceAll(r'"nk', 'ṅk')
      .replaceAll(r'"ng', 'ṅg')
      .replaceAll(r'.n', 'ṇ')
      .replaceAll(r'.m', UnicodePali.lowerNigahita)
      .replaceAll(r'\u1E41', UnicodePali.lowerNigahita)
      .replaceAll(r'~n', 'ñ')
      .replaceAll(r'.l', 'ḷ')
      .replaceAll(r'AA', 'Ā')
      .replaceAll(r'II', 'Ī')
      .replaceAll(r'UU', 'Ū')
      .replaceAll(r'.T', 'Ṭ')
      .replaceAll(r'.D', 'Ḍ')
      .replaceAll(r'"N', 'Ṅ')
      .replaceAll(r'.N', 'Ṇ')
      .replaceAll(r'.M', UnicodePali.upperNigahita)
      .replaceAll(r'~N', 'Ñ')
      .replaceAll(r'.L', 'Ḷ')
      .replaceAll(r'.ll', 'ḹ')
      .replaceAll(r'.r', 'ṛ')
      .replaceAll(r'.rr', 'ṝ')
      .replaceAll(r'.s', 'ṣ')
      .replaceAll(r'"s', 'ś')
      .replaceAll(r'.h', 'ḥ');
}

String toVel(String input) {
  if (input.isEmpty) return input;
  return input
      .replaceAll(r'"', '"')
      .replaceAll(r'\u0101', 'aa')
      .replaceAll(r'\u012B', 'ii')
      .replaceAll(r'\u016B', 'uu')
      .replaceAll(r'\u1E6D', '.t')
      .replaceAll(r'\u1E0D', '.d')
      .replaceAll(r'\u1E45', '"n')
      .replaceAll(r'\u1E47', '.n')
      .replaceAll(r'\u1E43', '.m')
      .replaceAll(r'\u1E41', '.m')
      .replaceAll(r'\u00F1', '~n')
      .replaceAll(r'\u1E37', '.l')
      .replaceAll(r'\u0100', 'AA')
      .replaceAll(r'\u012A', 'II')
      .replaceAll(r'\u016A', 'UU')
      .replaceAll(r'\u1E6C', '.T')
      .replaceAll(r'\u1E0C', '.D')
      .replaceAll(r'\u1E44', '"N')
      .replaceAll(r'\u1E46', '.N')
      .replaceAll(r'\u1E42', '.M')
      .replaceAll(r'\u00D1', '~N')
      .replaceAll(r'\u1E36', '.L')
      .replaceAll(r'ḹ', '.ll')
      .replaceAll(r'ṛ', '.r')
      .replaceAll(r'ṝ', '.rr')
      .replaceAll(r'ṣ', '.s')
      .replaceAll(r'ś', '"s')
      .replaceAll(r'ḥ', '.h');
}

String toVelRegEx(String input) {
  if (input.isEmpty) return input;
  return input
      .replaceAll(r'\u0101', 'aa')
      .replaceAll(r'\u012B', 'ii')
      .replaceAll(r'\u016B', 'uu')
      .replaceAll(r'\u1E6D', '\\.t')
      .replaceAll(r'\u1E0D', '\\.d')
      .replaceAll(r'\u1E45', '"n')
      .replaceAll(r'\u1E47', '\\.n')
      .replaceAll(r'\u1E43', '\\.m')
      .replaceAll(r'\u1E41', '\\.m')
      .replaceAll(r'\u00F1', '~n')
      .replaceAll(r'\u1E37', '\\.l')
      .replaceAll(r'\u0100', 'AA')
      .replaceAll(r'\u012A', 'II')
      .replaceAll(r'\u016A', 'UU')
      .replaceAll(r'\u1E6C', '\\.T')
      .replaceAll(r'\u1E0C', '\\.D')
      .replaceAll(r'\u1E44', '"N')
      .replaceAll(r'\u1E46', '\\.N')
      .replaceAll(r'\u1E42', '\\.M')
      .replaceAll(r'\u00D1', '~N')
      .replaceAll(r'\u1E36', '\\.L');
}

String toFuzzy(String input) {
  if (input.isEmpty) return input;
  return toVel(input)
      .replaceAllMapped(r'\.([tdnlmTDNLM])', (match) => match.group(0) ?? '')
      .replaceAllMapped(r'~([nN])', (match) => match.group(0) ?? '')
      .replaceAllMapped(r'([nN])', (match) => match.group(0) ?? '')
      .replaceAll(r'aa', 'a')
      .replaceAll(r'ii', 'i')
      .replaceAll(r'uu', 'u')
      .replaceAll(r'nn', 'n')
      .replaceAll(r'mm', 'm')
      .replaceAll(r'yy', 'y')
      .replaceAll(r'll', 'l')
      .replaceAll(r'ss', 's')
      .replaceAllMapped(
          r'([kgcjtdpb])[kgcjtdpb]{0,1}h*', (match) => match.group(0) ?? '');
}

String toSkt(String input, bool rv) {
  if (input.isEmpty) return input;

  if (rv) {
    return input
        .replaceAll(r'A', 'aa')
        .replaceAll(r'I', 'ii')
        .replaceAll(r'U', 'uu')
        .replaceAll(r'f', '.r')
        .replaceAll(r'F', '.rr')
        .replaceAll(r'x', '.l')
        .replaceAll(r'X', '.ll')
        .replaceAll(r'E', 'ai')
        .replaceAll(r'O', 'au')
        .replaceAll(r'K', 'kh')
        .replaceAll(r'G', 'gh')
        .replaceAll(r'N', '"n')
        .replaceAll(r'C', 'ch')
        .replaceAll(r'J', 'jh')
        .replaceAll(r'Y', '~n')
        .replaceAll(r'w', '.t')
        .replaceAll(r'q', '.d')
        .replaceAll(r'W', '.th')
        .replaceAll(r'Q', '.dh')
        .replaceAll(r'R', '.n')
        .replaceAll(r'T', 'th')
        .replaceAll(r'D', 'dh')
        .replaceAll(r'P', 'ph')
        .replaceAll(r'B', 'bh')
        .replaceAll(r'S', '"s')
        .replaceAll(r'z', '.s')
        .replaceAll(r'M', '.m')
        .replaceAll(r'H', '.h');
  } else {
    return input
        .replaceAll(r'aa', 'A')
        .replaceAll(r'ii', 'I')
        .replaceAll(r'uu', 'U')
        .replaceAll(r'\.r', 'f')
        .replaceAll(r'\.rr', 'F')
        .replaceAll(r'\.l', 'x')
        .replaceAll(r'\.ll', 'X')
        .replaceAll(r'ai', 'E')
        .replaceAll(r'au', 'O')
        .replaceAll(r'kh', 'K')
        .replaceAll(r'gh', 'G')
        .replaceAll(r'"nk', 'Nk')
        .replaceAll(r'"ng', 'Ng')
        .replaceAll(r'ch', 'C')
        .replaceAll(r'jh', 'J')
        .replaceAll(r'~n', 'Y')
        .replaceAll(r'\.t', 'w')
        .replaceAll(r'\.d', 'q')
        .replaceAll(r'\.th', 'W')
        .replaceAll(r'\.dh', 'Q')
        .replaceAll(r'\.n', 'R')
        .replaceAll(r'th', 'T')
        .replaceAll(r'dh', 'D')
        .replaceAll(r'ph', 'P')
        .replaceAll(r'bh', 'B')
        .replaceAll(r'"s', 'S')
        .replaceAll(r'\.s', 'z')
        .replaceAll(r'\.m', 'M')
        .replaceAll(r'\.h', 'H');
  }
}

String charAt(String input, position) {
  if (input.isEmpty) {
    return '';
  }
  if (position < 0 || position >= input.length) {
    return '';
  }
  return input[position];
}

String toSin(String input) {
  input = input.toLowerCase().replaceAll(r'ṁ', 'ṃ');
  final Map<String, String> vowel = {};

  vowel['a'] = 'අ';
  vowel['ā'] = 'ආ';
  vowel['i'] = 'ඉ';
  vowel['ī'] = 'ඊ';
  vowel['u'] = 'උ';
  vowel['ū'] = 'ඌ';
  vowel['e'] = 'එ';
  vowel['o'] = 'ඔ';

  final Map<String, String> sinhala = {};

  sinhala['ā'] = 'ා';
  sinhala['i'] = 'ි';
  sinhala['ī'] = 'ී';
  sinhala['u'] = 'ු';
  sinhala['ū'] = 'ූ';
  sinhala['e'] = 'ෙ';
  sinhala['o'] = 'ො';
  sinhala['ṃ'] = 'ං';
  sinhala['k'] = 'ක';
  sinhala['g'] = 'ග';
  sinhala['ṅ'] = 'ඞ';
  sinhala['c'] = 'ච';
  sinhala['j'] = 'ජ';
  sinhala['ñ'] = 'ඤ';
  sinhala['ṭ'] = 'ට';
  sinhala['ḍ'] = 'ඩ';
  sinhala['ṇ'] = 'ණ';
  sinhala['t'] = 'ත';
  sinhala['d'] = 'ද';
  sinhala['n'] = 'න';
  sinhala['p'] = 'ප';
  sinhala['b'] = 'බ';
  sinhala['m'] = 'ම';
  sinhala['y'] = 'ය';
  sinhala['r'] = 'ර';
  sinhala['l'] = 'ල';
  sinhala['ḷ'] = 'ළ';
  sinhala['v'] = 'ව';
  sinhala['s'] = 'ස';
  sinhala['h'] = 'හ';

  final Map<String, String> conj = {};

  conj['kh'] = 'ඛ';
  conj['gh'] = 'ඝ';
  conj['ch'] = 'ඡ';
  conj['jh'] = 'ඣ';
  conj['ṭh'] = 'ඨ';
  conj['ḍh'] = 'ඪ';
  conj['th'] = 'ථ';
  conj['dh'] = 'ධ';
  conj['ph'] = 'ඵ';
  conj['bh'] = 'භ';
  conj['jñ'] = 'ඥ';
  conj['ṇḍ'] = 'ඬ';
  conj['nd'] = 'ඳ';
  conj['mb'] = 'ඹ';
  conj['rg'] = 'ඟ';

  final Map<String, String> cons = {};

  cons['k'] = 'ක';
  cons['g'] = 'ග';
  cons['ṅ'] = 'ඞ';
  cons['c'] = 'ච';
  cons['j'] = 'ජ';
  cons['ñ'] = 'ඤ';
  cons['ṭ'] = 'ට';
  cons['ḍ'] = 'ඩ';
  cons['ṇ'] = 'ණ';
  cons['t'] = 'ත';
  cons['d'] = 'ද';
  cons['n'] = 'න';
  cons['p'] = 'ප';
  cons['b'] = 'බ';
  cons['m'] = 'ම';
  cons['y'] = 'ය';
  cons['r'] = 'ර';
  cons['l'] = 'ල';
  cons['ḷ'] = 'ළ';
  cons['v'] = 'ව';
  cons['s'] = 'ස';
  cons['h'] = 'හ';

  var im, i0, i1, i2, i3;
  var output = '';
  var i = 0;

  input = input.replaceAll(r'\&quot;', '`');

  while (i < input.length) {
    im = charAt(input, i - 2);
    i0 = charAt(input, i - 1);
    i1 = charAt(input, i);
    i2 = charAt(input, i + 1);
    i3 = charAt(input, i + 2);

    final vi1 = vowel[i1];
    if (vi1 != null) {
      if (i == 0 || i0 == 'a') {
        output += vi1;
      } else if (i1 != 'a') {
        final si1 = sinhala[i1];
        if (si1 != null) {
          output += si1;
        }
      }
      i++;
    } else if (conj[i1 + i2] != null) {
      // two character match
      output += conj[i1 + i2]!;
      i += 2;
      if (cons[i3] != null) {
        output += '්';
      }
    } else if (sinhala[i1] != null && i1 != 'a') {
      // one character match except a
      output += sinhala[i1]!;
      i++;
      if (cons[i2] != null && i1 != 'ṃ') {
        output += '්';
      }
    } else if (sinhala[i1] == null) {
      if (cons[i0] != null || (i0 == 'h' && cons[im] != null)) {
        output += '්'; // end word consonant
      }
      output += i1;
      i++;
      if (vowel[i2] != null) {
        // word-beginning vowel marker
        output += vowel[i2]!;
        i++;
      }
    } else {
      i++;
    }
  }

  if (cons[i1] != null) {
    output += '්';
  }

  // fudges

  // "‍" zero-width joiner inside of quotes

  return output
      .replaceAll(r'ඤ්ජ', 'ඦ')
      .replaceAll(r'ණ්ඩ', 'ඬ')
      .replaceAll(r'න්ද', 'ඳ')
      .replaceAll(r'ම්බ', 'ඹ')
      .replaceAll(r'්ර', '්‍ර')
      .replaceAll(r'\`+', '"');
}

String fromSin(String input) {
  var vowel = {};

  vowel['අ'] = 'a';
  vowel['ආ'] = 'ā';
  vowel['ඉ'] = 'i';
  vowel['ඊ'] = 'ī';
  vowel['උ'] = 'u';
  vowel['ඌ'] = 'ū';
  vowel['එ'] = 'e';
  vowel['ඔ'] = 'o';

  vowel['ඒ'] = 'ē';
  vowel['ඇ'] = 'ai';
  vowel['ඈ'] = 'āi';
  vowel['ඕ'] = 'ō';
  vowel['ඖ'] = 'au';

  vowel['ා'] = 'ā';
  vowel['ි'] = 'i';
  vowel['ී'] = 'ī';
  vowel['ු'] = 'u';
  vowel['ූ'] = 'ū';
  vowel['ෙ'] = 'e';
  vowel['ො'] = 'o';

  vowel['ෘ'] = 'ṛ';
  vowel['ෟ'] = 'ḷ';
  vowel['ෲ'] = 'ṝ';
  vowel['ෳ'] = 'ḹ';

  vowel['ේ'] = 'ē';
  vowel['ැ'] = 'ae';
  vowel['ෑ'] = 'āe';
  vowel['ෛ'] = 'ai';
  vowel['ෝ'] = 'ō';
  vowel['ෞ'] = 'au';

  var sinhala = {};

  sinhala['ං'] = 'ṃ';
  sinhala['ක'] = 'k';
  sinhala['ඛ'] = 'kh';
  sinhala['ග'] = 'g';
  sinhala['ඝ'] = 'gh';
  sinhala['ඞ'] = 'ṅ';
  sinhala['ච'] = 'c';
  sinhala['ඡ'] = 'ch';
  sinhala['ජ'] = 'j';
  sinhala['ඣ'] = 'jh';
  sinhala['ඤ'] = 'ñ';
  sinhala['ට'] = 'ṭ';
  sinhala['ඨ'] = 'ṭh';
  sinhala['ඩ'] = 'ḍ';
  sinhala['ඪ'] = 'ḍh';
  sinhala['ණ'] = 'ṇ';
  sinhala['ත'] = 't';
  sinhala['ථ'] = 'th';
  sinhala['ද'] = 'd';
  sinhala['ධ'] = 'dh';
  sinhala['න'] = 'n';
  sinhala['ප'] = 'p';
  sinhala['ඵ'] = 'ph';
  sinhala['බ'] = 'b';
  sinhala['භ'] = 'bh';
  sinhala['ම'] = 'm';
  sinhala['ය'] = 'y';
  sinhala['ර'] = 'r';

  sinhala['ල'] = 'l';
  sinhala['ළ'] = 'ḷ';
  sinhala['ව'] = 'v';
  sinhala['ස'] = 's';
  sinhala['හ'] = 'h';

  sinhala['ෂ'] = 'ṣ';
  sinhala['ශ'] = 'ś';

  sinhala['ඥ'] = 'jñ';
  sinhala['ඬ'] = 'ṇḍ';
  sinhala['ඳ'] = 'nd';
  sinhala['ඹ'] = 'mb';
  sinhala['ඟ'] = 'rg';

  var im, i0, i1, i2, i3;
  var output = '';
  var i = 0;

  input = input.replaceAll(r'\&quot;', '`');

  while (i < input.length) {
    i1 = charAt(input, i);

    if (vowel[i1] != null) {
      if (output[output.length - 1] == 'a') {
        output = output.substring(0, output.length - 1);
      }

      output += vowel[i1];
    } else if (sinhala[i1] != null) {
      output += sinhala[i1] + 'a';
    } else {
      output += i1;
    }
    i++;
  }

  // fudges

  // "‍" zero-width joiner inside of quotes

  output = output.replaceAll(r'a්', '');
  return output;
}

// ----------------  Roman Pāli ➜ Devanāgarī  ----------------
// Requires: import 'package:characters/characters.dart';

String toDeva(String input) {
  input = input.toLowerCase().replaceAll('ṁ', 'ṃ');

  // 1) Independent vowel letters (full glyphs)
  const iv = {
    'a': 'अ',
    'ā': 'आ',
    'i': 'इ',
    'ī': 'ई',
    'u': 'उ',
    'ū': 'ऊ',
    'e': 'ए',
    'o': 'ओ',
  };

  // 2) Dependent vowel signs (matras)
  const mv = {
    'ā': 'ा',
    'i': 'ि',
    'ī': 'ी',
    'u': 'ु',
    'ū': 'ू',
    'e': 'े',
    'o': 'ो',
  };

  // 3) Single consonants
  const sc = {
    'k': 'क',
    'g': 'ग',
    'ṅ': 'ङ',
    'c': 'च',
    'j': 'ज',
    'ñ': 'ञ',
    'ṭ': 'ट',
    'ḍ': 'ड',
    'ṇ': 'ण',
    't': 'त',
    'd': 'द',
    'n': 'न',
    'p': 'प',
    'b': 'ब',
    'm': 'म',
    'y': 'य',
    'r': 'र',
    'l': 'ल',
    'ḷ': 'ळ',
    'v': 'व',
    's': 'स',
    'h': 'ह',
  };

  // 4) Aspirated digraphs
  const asp = {
    'kh': 'ख',
    'gh': 'घ',
    'ch': 'छ',
    'jh': 'झ',
    'ṭh': 'ठ',
    'ḍh': 'ढ',
    'th': 'थ',
    'dh': 'ध',
    'ph': 'फ',
    'bh': 'भ',
  };

  // 5) Geminated-aspirated clusters (kkh, ggh …)
  final gemAsp = {
    for (final a in asp.entries)
      '${a.key[0]}${a.key}': '${sc[a.key[0]]}्${a.value}',
  };

  // helpers
  final indepVals = iv.values.toSet();
  String out = '';
  int i = 0;
  bool prevWasCon =
      false; // previously emitted a consonant (carrying inherent 'a')

  bool isDigit(String ch) {
    if (ch.isEmpty) return false;
    final u = ch.codeUnitAt(0);
    return u >= 0x30 && u <= 0x39; // '0'..'9'
  }

// Regex character class for pass-through characters
  const passThrough = r""".,;:!?()[]{}"''“”‘’—–-…%+/=|*@#_^$<>।॥॰ʼʼʼ""";
  bool isPassThrough(String ch) => passThrough.contains(ch);

  void killInherent() {
    if (prevWasCon) {
      out += '्'; // virama
      prevWasCon = false;
    }
  }

  String next(int o) => (i + o < input.length) ? input[i + o] : '';

  while (i < input.length) {
    final c1 = input[i];
    final c2 = next(1);
    final c3 = next(2);

    // --- digits: keep as ASCII digits ---
    if (isDigit(c1)) {
      out += c1;
      prevWasCon = false;
      i++;
      continue;
    }

    // --- punctuation & misc symbols: preserve as-is ---
    if (c1.trim().isEmpty || isPassThrough(c1)) {
      out += c1;
      prevWasCon = false;
      i++;
      continue;
    }

    // --- anusvāra / visarga ---
    if (c1 == 'ṃ') {
      out += 'ं';
      prevWasCon = false;
      i++;
      continue;
    }
    if (c1 == 'ḥ') {
      out += 'ः';
      prevWasCon = false;
      i++;
      continue;
    }

    // --- geminated-aspirated (kkh …) ---
    if (gemAsp.containsKey('$c1$c2$c3')) {
      killInherent();
      out += gemAsp['$c1$c2$c3']!;
      prevWasCon = true;
      i += 3;
      continue;
    }

    // --- aspirated digraph (kh …) ---
    if (asp.containsKey('$c1$c2')) {
      killInherent();
      out += asp['$c1$c2']!;
      prevWasCon = true;
      i += 2;
      continue;
    }

    // --- doubled consonant (kk …) ---
    if (c1 == c2 && sc.containsKey(c1)) {
      killInherent();
      out += sc[c1]! + '्' + sc[c1]!;
      prevWasCon = true;
      i += 2;
      continue;
    }

    // --- single consonant ---
    if (sc.containsKey(c1)) {
      killInherent();
      out += sc[c1]!;
      prevWasCon = true;
      i++;
      continue;
    }

    // --- vowels ---
    if (iv.containsKey(c1)) {
      // short “a”
      if (c1 == 'a') {
        if (!prevWasCon &&
            (out.isEmpty || !indepVals.contains(out.characters.last))) {
          out += iv['a']!;
        }
        prevWasCon = false;
        i++;
        continue;
      }

      // independent vowel after independent vowel (ā + i => आई)
      final prevIndV =
          out.isNotEmpty && indepVals.contains(out.characters.last);
      if (prevIndV) {
        out += iv[c1]!;
        prevWasCon = false;
        i++;
        continue;
      }

      // normal matra vs independent
      if (prevWasCon && mv.containsKey(c1)) {
        out += mv[c1]!;
      } else {
        out += iv[c1]!;
      }
      prevWasCon = false;
      i++;
      continue;
    }

    // --- default: preserve unknowns verbatim ---
    out += c1;
    prevWasCon = false;
    i++;
  }

// Choose the style you want:
  return styleDeva(
    out,
    devaDigits: true, // ← Tipitaka.org uses Devanāgarī digits
    useDanda: true, // ← and keeps a Western period after numbers
  );
// Make Devanāgarī look native (danda/double danda like Myanmar's ။/၊ behavior)
  // out = _applyDevaPunctuation(out);
  //return out;
}

// Devanāgarī punctuation normalizer: make '.' → '।', '..'/'।।' → '॥', keep '…', keep decimals.
String _applyDevaPunctuation(String s) {
  // normalize ASCII ellipsis to the single-character ellipsis
  s = s.replaceAll('...', '…');

  // turn double danda forms if someone typed ASCII first
  s = s.replaceAll('।।', '॥');

  // Replace sentence periods with danda but DO NOT touch decimals (e.g., 3.14).
  // (?<!\d)\.(?!\d)  = a dot not preceded or followed by a digit
  s = s.replaceAllMapped(RegExp(r'([^०-९>\s*])(\.)'), (m) => '${m.group(1)}।');

  // If someone typed '..' as section stop, turn into '॥'
  s = s.replaceAll('..', '॥');

  return s;
}

// Put these near your toDeva() function
const _asciiToDevaDigits = {
  '0': '०',
  '1': '१',
  '2': '२',
  '3': '३',
  '4': '४',
  '5': '५',
  '6': '६',
  '7': '७',
  '8': '८',
  '9': '९',
};

String _withDevaDigits(String s) =>
    s.split('').map((ch) => _asciiToDevaDigits[ch] ?? ch).join();

String _withDandaStops(String s) {
  // replace period that ends a sentence/section with danda
  // simple + robust: ". " -> "। ", ".\n" -> "।\n", "." at end -> "।"
  s = s.replaceAll(". ", "। ");
  s = s.replaceAll(".\n", "।\n");
  if (s.endsWith(".")) s = s.substring(0, s.length - 1) + "।";
  // optional: "||" → "॥"
  s = s.replaceAll("||", "॥");
  return s;
}

/// Post-process Devanāgarī output to a chosen house style.
/// - devaDigits: use ०१२३… (Tipitaka.org style)
/// - useDanda:   use danda `।` / `॥` for stops (CST-like)
String styleDeva(String s, {bool devaDigits = true, bool useDanda = false}) {
  if (devaDigits) s = _withDevaDigits(s);
  if (useDanda) s = _applyDevaPunctuation(s); // ← uses the regex version
  return s;
}

String fromThai(String input) {
  return input
      .replaceAllMapped(r'([อกขคฆงจฉชฌญฏฐฑฒณตถทธนปผพภมยรลฬวสห])(?!ฺ)',
          (match) => match.group(0) ?? '')
      .replaceAllMapped(r'([เโ])([อกขคฆงจฉชฌญฏฐฑฒณตถทธนปผพภมยรลฬวสหฺฺ]+a)',
          (match) => '${match.group(1) ?? ''}${match.group(0) ?? ''}')
      .replaceAllMapped(r'[a]([าิีึุูเโ])', (match) => match.group(0) ?? '')
      .replaceAll(r'ฺ', "")
      .replaceAll(r'อ', '')
      .replaceAll(r'า', 'ā')
      .replaceAll(r'ิ', 'i')
      .replaceAll(r'ี', 'ī')
      .replaceAll(r'ึ', 'iṃ')
      .replaceAll(r'ุ', 'u')
      .replaceAll(r'ู', 'ū')
      .replaceAll(r'เ', 'e')
      .replaceAll(r'โ', 'o')
      .replaceAll(r'ํ', 'ṃ')
      .replaceAll(r'ก', 'k')
      .replaceAll(r'ข', 'kh')
      .replaceAll(r'ค', 'g')
      .replaceAll(r'ฆ', 'gh')
      .replaceAll(r'ง', 'ṅ')
      .replaceAll(r'จ', 'c')
      .replaceAll(r'ฉ', 'ch')
      .replaceAll(r'ช', 'j')
      .replaceAll(r'ฌ', 'jh')
      .replaceAll(r'', 'ñ')
      .replaceAll(r'ญ', 'ñ')
      .replaceAll(r'ฏ', 'ṭ')
      .replaceAll(r'', 'ṭh')
      .replaceAll(r'ฐ', 'ṭh')
      .replaceAll(r'ฑ', 'ḍ')
      .replaceAll(r'ฒ', 'ḍh')
      .replaceAll(r'ณ', 'ṇ')
      .replaceAll(r'ต', 't')
      .replaceAll(r'ถ', 'th')
      .replaceAll(r'ท', 'd')
      .replaceAll(r'ธ', 'dh')
      .replaceAll(r'น', 'n')
      .replaceAll(r'ป', 'p')
      .replaceAll(r'ผ', 'ph')
      .replaceAll(r'พ', 'b')
      .replaceAll(r'ภ', 'bh')
      .replaceAll(r'ม', 'm')
      .replaceAll(r'ย', 'y')
      .replaceAll(r'ร', 'r')
      .replaceAll(r'ล', 'l')
      .replaceAll(r'ฬ', 'ḷ')
      .replaceAll(r'ว', 'v')
      .replaceAll(r'ส', 's')
      .replaceAll(r'ห', 'h')
      .replaceAll(r'๐', '0')
      .replaceAll(r'๑', '1')
      .replaceAll(r'๒', '2')
      .replaceAll(r'๓', '3')
      .replaceAll(r'๔', '4')
      .replaceAll(r'๕', '5')
      .replaceAll(r'๖', '6')
      .replaceAll(r'๗', '7')
      .replaceAll(r'๘', '8')
      .replaceAll(r'๙', '9')
      .replaceAll(r'ฯ', '...')
      .replaceAll(r'', '');
}
