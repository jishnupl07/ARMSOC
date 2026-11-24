import 'dart:typed_data';

class TfidfBlock {
  final String analyzer;
  final int ngramMin;
  final int ngramMax;
  final Map<String, int> vocabulary;
  final Float64List idf;
  final String tokenPattern;

  TfidfBlock({
    required this.analyzer,
    required this.ngramMin,
    required this.ngramMax,
    required this.vocabulary,
    required this.idf,
    required this.tokenPattern,
  });

  factory TfidfBlock.fromJson(Map<String, dynamic> json) {
    final rawVocab = json['vocabulary'] as Map<String, dynamic>;
    final vocab = <String, int>{};
    rawVocab.forEach((key, value) {
      vocab[key] = (value as num).toInt();
    });

    final rawIdf = json['idf'] as List<dynamic>;
    final idfList = Float64List(rawIdf.length);
    for (int i = 0; i < rawIdf.length; i++) {
      idfList[i] = (rawIdf[i] as num).toDouble();
    }

    return TfidfBlock(
      analyzer: json['analyzer'] as String,
      ngramMin: (json['ngram_min'] as num).toInt(),
      ngramMax: (json['ngram_max'] as num).toInt(),
      vocabulary: vocab,
      idf: idfList,
      tokenPattern: (json['token_pattern'] as String?) ?? r'(?u)\b\w\w+\b',
    );
  }
}

class ScamModelConfig {
  final double threshold;
  final double intercept;
  final Float64List coef;
  final List<TfidfBlock> blocks;
  final List<int> blockOffsets;

  ScamModelConfig({
    required this.threshold,
    required this.intercept,
    required this.coef,
    required this.blocks,
    required this.blockOffsets,
  });

  factory ScamModelConfig.fromJson(Map<String, dynamic> json) {
    final rawCoef = json['coef'] as List<dynamic>;
    final coefList = Float64List(rawCoef.length);
    for (int i = 0; i < rawCoef.length; i++) {
      coefList[i] = (rawCoef[i] as num).toDouble();
    }

    final rawBlocks = json['blocks'] as List<dynamic>;
    final blocksList = rawBlocks
        .map((b) => TfidfBlock.fromJson(b as Map<String, dynamic>))
        .toList();

    final rawOffsets = json['block_offsets'] as List<dynamic>;
    final offsetsList = rawOffsets.map((o) => (o as num).toInt()).toList();

    return ScamModelConfig(
      threshold: (json['threshold'] as num).toDouble(),
      intercept: (json['intercept'] as num).toDouble(),
      coef: coefList,
      blocks: blocksList,
      blockOffsets: offsetsList,
    );
  }
}

