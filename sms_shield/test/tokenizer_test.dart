import 'package:flutter_test/flutter_test.dart';
import 'package:sms_shield/services/text_tokenizer.dart';

void main() {
  group('TextTokenizer Unit Tests', () {
    test('charWbTerms extracts whitespace-padded n-grams', () {
      final terms = TextTokenizer.charWbTerms('hi go', 2, 3);
      // 'hi' padded is ' hi ' -> 2-grams: ' h', 'hi', 'i '; 3-grams: ' hi', 'hi '
      // 'go' padded is ' go ' -> 2-grams: ' g', 'go', 'o '; 3-grams: ' go', 'go '
      expect(terms, containsAll([' h', 'hi', 'i ', ' hi', 'hi ']));
      expect(terms, containsAll([' g', 'go', 'o ', ' go', 'go ']));
    });

    test('wordTokens extracts words matching \\b\\w\\w+\\b', () {
      final tokens = TextTokenizer.wordTokens('Hello world 123 a b test');
      expect(tokens, equals(['hello', 'world', '123', 'test']));
    });

    test('wordNgrams generates unigrams and bigrams', () {
      final tokens = ['hello', 'world', 'test'];
      final ngrams = TextTokenizer.wordNgrams(tokens, 1, 2);
      expect(ngrams, equals([
        'hello', 'world', 'test',
        'hello world', 'world test',
      ]));
    });
  });
}

