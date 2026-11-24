class TextTokenizer {
  /// Extracts character n-grams within word boundaries ('char_wb').
  /// Sklearn splits text on whitespace, pads each word with space (' ' + word + ' '),
  /// and extracts n-grams from ngramMin to ngramMax.
  static List<String> charWbTerms(String text, int ngramMin, int ngramMax) {
    final List<String> out = [];
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.isEmpty) continue;
      final w = ' $word ';
      final wLen = w.length;
      for (int n = ngramMin; n <= ngramMax; n++) {
        for (int i = 0; i <= wLen - n; i++) {
          out.add(w.substring(i, i + n));
        }
      }
    }
    return out;
  }

  /// Extracts tokens using the specified regex pattern (default: (?u)\b\w\w+\b)
  static List<String> wordTokens(String text, [String? pattern]) {
    final cleanPattern = (pattern != null && pattern.startsWith('(?u)'))
        ? pattern.substring(4)
        : (pattern ?? r'\b\w\w+\b');
    final regex = RegExp(cleanPattern, unicode: true);
    final matches = regex.allMatches(text.toLowerCase());
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Generates word n-grams from a list of tokens.
  static List<String> wordNgrams(List<String> tokens, int ngramMin, int ngramMax) {
    final List<String> out = [];
    final tLen = tokens.length;
    for (int n = ngramMin; n <= ngramMax; n++) {
      for (int i = 0; i <= tLen - n; i++) {
        out.add(tokens.sublist(i, i + n).join(' '));
      }
    }
    return out;
  }
}

