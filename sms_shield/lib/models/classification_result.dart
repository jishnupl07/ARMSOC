enum ClassificationCategory {
  scam,
  uncertain,
  legitimate,
}

enum AdviceSource {
  llama,
  template,
}

class ContributingFeature {
  final String term;
  final double contribution;
  final bool pushesScam;

  const ContributingFeature({
    required this.term,
    required this.contribution,
    required this.pushesScam,
  });
}

class AdviceResult {
  final String explanation;
  final List<String> recommendedActions;
  final AdviceSource source;
  final String? error;
  final int? latencyMs;

  const AdviceResult({
    required this.explanation,
    required this.recommendedActions,
    required this.source,
    this.error,
    this.latencyMs,
  });

  bool get isFromLlama => source == AdviceSource.llama;
}

class ClassificationResult {
  final String rawText;
  final double scamProbability;
  final double threshold;
  final ClassificationCategory category;
  final List<ContributingFeature> topContributingTerms;
  final List<String> extractedUrls;
  final AdviceResult? advice;

  const ClassificationResult({
    required this.rawText,
    required this.scamProbability,
    required this.threshold,
    required this.category,
    this.topContributingTerms = const [],
    this.extractedUrls = const [],
    this.advice,
  });

  ClassificationResult copyWith({
    AdviceResult? advice,
  }) {
    return ClassificationResult(
      rawText: rawText,
      scamProbability: scamProbability,
      threshold: threshold,
      category: category,
      topContributingTerms: topContributingTerms,
      extractedUrls: extractedUrls,
      advice: advice ?? this.advice,
    );
  }

  bool get isScam => category == ClassificationCategory.scam;
  bool get isUncertain => category == ClassificationCategory.uncertain;
  bool get isLegitimate => category == ClassificationCategory.legitimate;

  String get labelText {
    switch (category) {
      case ClassificationCategory.scam:
        return 'Scam';
      case ClassificationCategory.uncertain:
        return 'Uncertain';
      case ClassificationCategory.legitimate:
        return 'Legitimate';
    }
  }

  String get description {
    switch (category) {
      case ClassificationCategory.scam:
        return 'This message displays strong indicators of an SMS scam or phishing attempt.';
      case ClassificationCategory.uncertain:
        return 'This message has suspicious elements but does not firmly cross the scam threshold. Exercise caution.';
      case ClassificationCategory.legitimate:
        return 'This message appears legitimate and matches standard trusted communication patterns.';
    }
  }
}
