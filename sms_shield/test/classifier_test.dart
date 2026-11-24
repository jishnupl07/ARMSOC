import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_shield/models/classification_result.dart';
import 'package:sms_shield/services/scam_classifier.dart';

void main() {
  late ScamClassifier classifier;

  setUpAll(() {
    final modelFile = File('assets/models/scam_model.json');
    expect(modelFile.existsSync(), isTrue, reason: 'scam_model.json must exist in assets/models/');
    final jsonContent = modelFile.readAsStringSync();
    classifier = ScamClassifier.fromJsonString(jsonContent);
  });

  group('ScamClassifier Python Parity Tests', () {
    test('Verifies SBI KYC scam message matches Python probability', () {
      const sms = 'Your SBI KYC expired. Update now at http://sbi-kyc-verify.xyz or account will be blocked';
      final result = classifier.classify(sms);

      expect(result.category, ClassificationCategory.scam);
      expect(result.scamProbability, closeTo(0.99960751, 1e-6));
      expect(result.isScam, isTrue);
      expect(result.isLegitimate, isFalse);
      expect(result.isUncertain, isFalse);
    });

    test('Verifies Lottery scam message matches Python probability', () {
      const sms = 'Dear customer, congratulations! You won 10,00,000 cash prize in lottery. Claim now by calling 9876543210';
      final result = classifier.classify(sms);

      expect(result.category, ClassificationCategory.scam);
      expect(result.scamProbability, closeTo(0.96691262, 1e-6));
      expect(result.isScam, isTrue);
    });

    test('Verifies bank OTP message is classified as legitimate', () {
      const sms = '123456 is your OTP for login to HDFC net banking. Do not share it with anyone.';
      final result = classifier.classify(sms);

      expect(result.category, ClassificationCategory.legitimate);
      expect(result.scamProbability, closeTo(0.00829330, 1e-6));
      expect(result.isLegitimate, isTrue);
    });

    test('Verifies casual personal chat is classified as legitimate', () {
      const sms = 'Reached home safely, will talk tomorrow';
      final result = classifier.classify(sms);

      expect(result.category, ClassificationCategory.legitimate);
      expect(result.scamProbability, closeTo(0.00186966, 1e-6));
      expect(result.isLegitimate, isTrue);
    });

    test('Verifies meeting lunch message is classified as legitimate', () {
      const sms = 'Hey, are we still meeting for lunch today at 1pm?';
      final result = classifier.classify(sms);

      expect(result.category, ClassificationCategory.legitimate);
      expect(result.scamProbability, closeTo(0.00480157, 1e-6));
      expect(result.isLegitimate, isTrue);
    });

    test('Verifies threshold preservation', () {
      expect(classifier.config.threshold, closeTo(0.8240050992072093, 1e-12));
    });

    test('Empty text handles safely as legitimate', () {
      final result = classifier.classify('   ');
      expect(result.category, ClassificationCategory.legitimate);
      expect(result.scamProbability, 0.0);
    });
  });
}

