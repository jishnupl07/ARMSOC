import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_shield/services/risk_advisor_service.dart';
import 'package:sms_shield/services/scam_classifier.dart';
import 'package:sms_shield/ui/home_screen.dart';
import 'package:sms_shield/ui/widgets/result_card.dart';

void main() {
  late ScamClassifier classifier;

  setUpAll(() {
    final modelFile = File('assets/models/scam_model.json');
    final jsonContent = modelFile.readAsStringSync();
    classifier = ScamClassifier.fromJsonString(jsonContent);
  });

  testWidgets('SMS Shield UI smoke test and scam classification', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        classifier: classifier,
        riskAdvisor: RiskAdvisorService(llamaBackend: TemplateLlamaBackend()),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Title and input field
    expect(find.text('SMS Shield'), findsOneWidget);
    expect(find.text('Offline Ready'), findsOneWidget);
    expect(find.text('Enter SMS Message'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Analyze Message'), findsOneWidget);

    // Verify quick sample chips exist
    expect(find.text('SBI KYC Scam'), findsOneWidget);
    expect(find.text('Bank OTP (Legit)'), findsOneWidget);

    // Tap quick sample chip for SBI KYC Scam
    await tester.tap(find.text('SBI KYC Scam'));
    await tester.pumpAndSettle();

    // Verify ResultCard appears with SCAM DETECTED
    expect(find.byType(ResultCard), findsOneWidget);
    expect(find.text('SCAM DETECTED'), findsOneWidget);
    expect(find.text('Scam'), findsOneWidget);

    // Now test a legitimate message
    await tester.tap(find.text('Bank OTP (Legit)'));
    await tester.pumpAndSettle();

    // Verify ResultCard changes to LEGITIMATE MESSAGE
    expect(find.text('LEGITIMATE MESSAGE'), findsOneWidget);
    expect(find.text('Legitimate'), findsOneWidget);
  });
}
