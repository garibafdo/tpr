String superscripterUni(String text) {
  // Superscript using unicode characters.
  text = text.replaceAllMapped(
    RegExp(r'( )(\d)'),
    (Match match) => '\u200A${match.group(2)}',
  );
  text = text.replaceAll('0', '⁰');
  text = text.replaceAll('1', '¹');
  text = text.replaceAll('2', '²');
  text = text.replaceAll('3', '³');
  text = text.replaceAll('4', '⁴');
  text = text.replaceAll('5', '⁵');
  text = text.replaceAll('6', '⁶');
  text = text.replaceAll('7', '⁷');
  text = text.replaceAll('8', '⁸');
  text = text.replaceAll('9', '⁹');
  text = text.replaceAll('.', '·');
  return text;
}
