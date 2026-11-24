import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import '../models/classification_result.dart';
import '../models/model_config.dart';
import 'text_tokenizer.dart';

class ScamClassifier {
  final ScamModelConfig config;

  static final RegExp _urlRegex = RegExp(
    r'(?:https?://|www\.)\S+|\b[\w-]+\.(?:xyz|top|apk|club|click|online|site)\b|bit\.ly/\S+',
    caseSensitive: false,
  );

  ScamClassifier({required this.config});

  /// Extracts URLs and suspicious domain patterns from SMS text.
  static List<String> extractUrls(String text) {
    return _urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Factory constructor to load and parse the model configuration from a JSON string.
  factory ScamClassifier.fromJsonString(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
    return ScamClassifier(config: ScamModelConfig.fromJson(data));
  }

  /// Factory constructor to load the bundled model asset.
  static Future<ScamClassifier> loadFromAsset([
    String assetPath = 'assets/models/scam_model.json',
  ]) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return ScamClassifier.fromJsonString(jsonString);
  }

  /// Evaluates an SMS text and returns a [ClassificationResult].
  ClassificationResult classify(String text) {
    if (text.trim().isEmpty) {
      return ClassificationResult(
        rawText: text,
        scamProbability: 0.0,
        threshold: config.threshold,
        category: ClassificationCategory.legitimate,
        topContributingTerms: const [],
        extractedUrls: const [],
      );
    }

    double z = config.intercept;
    final List<ContributingFeature> termContributions = [];

    // Process each TF-IDF block
    for (int b = 0; b < config.blocks.length; b++) {
      final block = config.blocks[b];
      final offset = config.blockOffsets[b];

      // Extract raw terms according to analyzer type
      final List<String> terms;
      if (block.analyzer == 'char_wb') {
        terms = TextTokenizer.charWbTerms(text, block.ngramMin, block.ngramMax);
      } else {
        final tokens = TextTokenizer.wordTokens(text, block.tokenPattern);
        terms = TextTokenizer.wordNgrams(tokens, block.ngramMin, block.ngramMax);
      }

      // Count term frequencies for known vocabulary terms
      final Map<String, int> termCounts = {};
      for (final t in terms) {
        if (block.vocabulary.containsKey(t)) {
          termCounts[t] = (termCounts[t] ?? 0) + 1;
        }
      }

      // Calculate sublinear TF * IDF and block L2 norm
      double sumSquares = 0.0;
      final Map<String, double> tfIdfValues = {};

      termCounts.forEach((term, count) {
        final j = block.vocabulary[term]!;
        final sublinearTf = 1.0 + math.log(count);
        final val = sublinearTf * block.idf[j];
        tfIdfValues[term] = val;
        sumSquares += val * val;
      });

      final norm = math.sqrt(sumSquares);

      // Add to linear score z using normalized TF-IDF features
      if (norm > 0) {
        final invNorm = 1.0 / norm;
        tfIdfValues.forEach((term, val) {
          final j = block.vocabulary[term]!;
          final normalizedVal = val * invNorm;
          final weight = config.coef[offset + j];
          final contribution = normalizedVal * weight;

          z += contribution;

          if (contribution.abs() > 1e-4) {
            termContributions.add(ContributingFeature(
              term: term,
              contribution: contribution,
              pushesScam: contribution > 0,
            ));
          }
        });
      }
    }

    // Logistic sigmoid: P(scam) = 1 / (1 + exp(-z))
    final probability = 1.0 / (1.0 + math.exp(-z));

    // Sort top contributing terms by absolute magnitude
    termContributions.sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    final topTerms = termContributions.take(8).toList();

    // Classification decision
    final ClassificationCategory category;
    if (probability >= config.threshold) {
      category = ClassificationCategory.scam;
    } else if (probability >= 0.50) {
      category = ClassificationCategory.uncertain;
    } else {
      category = ClassificationCategory.legitimate;
    }

    return ClassificationResult(
      rawText: text,
      scamProbability: probability,
      threshold: config.threshold,
      category: category,
      topContributingTerms: topTerms,
      extractedUrls: extractUrls(text),
    );
  }
}

