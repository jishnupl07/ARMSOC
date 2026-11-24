import 'package:flutter_test/flutter_test.dart';
import 'package:sms_shield/models/classification_result.dart';
import 'package:sms_shield/services/risk_advisor_service.dart';
import 'package:sms_shield/services/scam_classifier.dart';

class MockLlamaBackend implements LlamaBackend {
  final String mockResponse;
  final bool shouldFail;

  MockLlamaBackend({
    this.mockResponse = 'This message is impersonating your bank to steal credentials.\n\nRecommended actions:\n1. Do not tap the link\n2. Block the sender\n3. Contact SBI support',
    this.shouldFail = false,
  });

  @override
  Future<bool> isModelAvailable() async => !shouldFail;

  @override
  Future<String> generate({required String systemPrompt, required String userPrompt}) async {
    if (shouldFail) throw Exception('Inference memory error');
    return mockResponse;
  }
}

void main() {
  group('RiskAdvisorService and URL Extraction Tests', () {
    test('extractUrls accurately parses diverse suspicious URLs', () {
      const text = 'Check out http://fake-bank.xyz and www.secure-login.top or download bit.ly/app123 update.apk';
      final urls = ScamClassifier.extractUrls(text);

      expect(urls, containsAll([
        'http://fake-bank.xyz',
        'www.secure-login.top',
        'bit.ly/app123',
        'update.apk',
      ]));
    });

    test('buildPrompt formats prompt matching Python reference specification', () {
      const result = ClassificationResult(
        rawText: 'Your SBI KYC expired. Update now at http://sbi-kyc-verify.xyz',
        scamProbability: 0.99960751,
        threshold: 0.8240050992072093,
        category: ClassificationCategory.scam,
        topContributingTerms: [
          ContributingFeature(term: 'kyc', contribution: 1.2, pushesScam: true),
          ContributingFeature(term: 'sbi', contribution: -0.1, pushesScam: false),
        ],
        extractedUrls: ['http://sbi-kyc-verify.xyz'],
      );

      final prompt = RiskAdvisorService.buildPrompt(result);

      expect(prompt, contains('Message: Your SBI KYC expired. Update now at http://sbi-kyc-verify.xyz'));
      expect(prompt, contains('Classifier decision: scam (scam score 0.9996, threshold 0.8240)'));
      expect(prompt, contains('Words that influenced the decision: "kyc" (scam), "sbi" (legitimate)'));
      expect(prompt, contains('Links found: http://sbi-kyc-verify.xyz'));
      expect(prompt, contains('Write the explanation and actions for the user.'));
    });

    test('RiskAdvisorService uses Llama when model is available', () async {
      final mock = MockLlamaBackend();
      final advisor = RiskAdvisorService(llamaBackend: mock);

      const result = ClassificationResult(
        rawText: 'Suspicious text here',
        scamProbability: 0.95,
        threshold: 0.824,
        category: ClassificationCategory.scam,
        topContributingTerms: [],
        extractedUrls: [],
      );

      final advice = await advisor.advise(result);

      expect(advice.source, AdviceSource.llama);
      expect(advice.isFromLlama, isTrue);
      expect(advice.explanation, contains('impersonating your bank'));
      expect(advice.recommendedActions.length, 3);
      expect(advice.recommendedActions[0], contains('Do not tap the link'));
    });

    test('RiskAdvisorService gracefully falls back to template on error', () async {
      final mock = MockLlamaBackend(shouldFail: true);
      final advisor = RiskAdvisorService(llamaBackend: mock);

      const result = ClassificationResult(
        rawText: 'Sample scam text',
        scamProbability: 0.95,
        threshold: 0.824,
        category: ClassificationCategory.scam,
      );

      final advice = await advisor.advise(result);

      expect(advice.source, AdviceSource.template);
      expect(advice.isFromLlama, isFalse);
      expect(advice.explanation, contains('looks like a scam'));
      expect(advice.recommendedActions, isNotEmpty);
    });
  });
}

