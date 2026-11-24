import 'dart:async';
import 'package:flutter/services.dart';
import '../models/classification_result.dart';

abstract class LlamaBackend {
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
  });

  Future<bool> isModelAvailable();
}

/// Fallback backend using deterministic safety templates.
/// Mirrors template_advice(a) in arm/sms_scam_classifier_pipeline.ipynb.
class TemplateLlamaBackend implements LlamaBackend {
  @override
  Future<bool> isModelAvailable() async => true;

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    return '';
  }

  static AdviceResult generateTemplateAdvice(ClassificationResult result) {
    if (result.isScam) {
      return const AdviceResult(
        explanation:
            'This message looks like a scam. It may be trying to get your money, login details, or OTP.',
        recommendedActions: [
          'Do NOT click any link, call back numbers, or reply to the sender.',
          'Never share OTPs, PINs, or bank account credentials.',
          'Block and report the sender, and verify directly through your official banking app or website.'
        ],
        source: AdviceSource.template,
      );
    } else if (result.isUncertain) {
      return const AdviceResult(
        explanation:
            'This message exhibits borderline or suspicious characteristics that require verification.',
        recommendedActions: [
          'Do not click embedded links or download attachments.',
          'Cross-check the sender ID or phone number with official records.',
          'Contact the organization using their verified public customer support channel.'
        ],
        source: AdviceSource.template,
      );
    } else {
      return const AdviceResult(
        explanation:
            'This message looks legitimate and conforms to standard trusted message patterns.',
        recommendedActions: [
          'Still exercise regular caution if unexpected payments are requested.',
          'Never share one-time passwords (OTPs) with anyone claiming to be bank staff.',
          'Ensure any links open official, verified domains.'
        ],
        source: AdviceSource.template,
      );
    }
  }
}

/// ExecuTorch on-device quantized Llama 3.2 backend.
/// Calls the Android ExecuTorch C++ runtime via Platform Channel.
class ExecuTorchLlamaBackend implements LlamaBackend {
  static const MethodChannel _channel =
      MethodChannel('com.antigravity.sms_shield/llama_executorch');

  @override
  Future<bool> isModelAvailable() async {
    try {
      final bool available = await _channel.invokeMethod('isModelReady') ?? false;
      return available;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final String response = await _channel.invokeMethod('generate', {
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'maxNewTokens': 200,
      'temperature': 0.1,
    });
    return response.trim();
  }
}

/// RiskAdvisor service coordinating between classifier assessment and Llama 3.2.
class RiskAdvisorService {
  final LlamaBackend? llamaBackend;

  static const String systemInstruction =
      'You are a security assistant that explains SMS scam decisions to non-expert users. '
      'The classifier has already made the decision; do not change it. '
      'Explain in plain language, in at most 5 short sentences, why the message is or is not likely a scam. '
      'Then give 2 to 3 concrete actions the user should take. Never ask for OTPs, PINs or card details. '
      'Do not invent facts about the sender.';

  RiskAdvisorService({this.llamaBackend});

  /// Constructs the prompt matching build_prompt(a) from the Python reference.
  static String buildPrompt(ClassificationResult a) {
    final terms = a.topContributingTerms.isNotEmpty
        ? a.topContributingTerms
            .map((t) => '"${t.term}" (${t.pushesScam ? 'scam' : 'legitimate'})')
            .join(', ')
        : 'none';
    final urls = a.extractedUrls.isNotEmpty ? a.extractedUrls.join(', ') : 'none';

    return 'Message: ${a.rawText}\n'
        'Classifier decision: ${a.labelText.toLowerCase()} (scam score ${a.scamProbability.toStringAsFixed(4)}, threshold ${a.threshold.toStringAsFixed(4)})\n'
        'Words that influenced the decision: $terms\n'
        'Links found: $urls\n'
        'Write the explanation and actions for the user.';
  }

  /// Evaluates and generates security advice for a classified message.
  Future<AdviceResult> advise(ClassificationResult classification) async {
    final stopwatch = Stopwatch()..start();

    if (llamaBackend != null) {
      try {
        final isReady = await llamaBackend!.isModelAvailable();
        if (isReady) {
          final prompt = buildPrompt(classification);
          final rawOutput = await llamaBackend!.generate(
            systemPrompt: systemInstruction,
            userPrompt: prompt,
          );
          stopwatch.stop();

          // Parse explanation and actions from LLM output
          final parsed = _parseLlamaOutput(rawOutput);
          return AdviceResult(
            explanation: parsed.explanation,
            recommendedActions: parsed.actions,
            source: AdviceSource.llama,
            latencyMs: stopwatch.elapsedMilliseconds,
          );
        }
      } catch (e) {
        // Fall back gracefully to template on error
        final fallback = TemplateLlamaBackend.generateTemplateAdvice(classification);
        return AdviceResult(
          explanation: fallback.explanation,
          recommendedActions: fallback.recommendedActions,
          source: AdviceSource.template,
          error: e.toString(),
        );
      }
    }

    // Default template advice
    return TemplateLlamaBackend.generateTemplateAdvice(classification);
  }

  static ({String explanation, List<String> actions}) _parseLlamaOutput(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<String> explanationParts = [];
    final List<String> actions = [];

    bool inActionsSection = false;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('action') || lower.contains('steps') || lower.contains('what to do')) {
        inActionsSection = true;
        continue;
      }

      if (inActionsSection || RegExp(r'^(?:\d+[\.\)]|\-|\*)\s+').hasMatch(line)) {
        final cleanAction = line.replaceFirst(RegExp(r'^(?:\d+[\.\)]|\-|\*)\s+'), '').trim();
        if (cleanAction.isNotEmpty) {
          actions.add(cleanAction);
        }
      } else {
        explanationParts.add(line);
      }
    }

    final explanation = explanationParts.isNotEmpty
        ? explanationParts.join(' ')
        : (actions.isNotEmpty ? actions.removeAt(0) : text);

    if (actions.isEmpty) {
      actions.addAll([
        'Do not click any unverified links.',
        'Never disclose OTPs, passwords, or personal identity numbers.',
        'Verify with the sender organization through their official application.',
      ]);
    }

    return (explanation: explanation, actions: actions);
  }
}

