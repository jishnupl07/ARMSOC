import 'package:flutter/material.dart';

class SampleMessage {
  final String label;
  final String text;
  final IconData icon;

  const SampleMessage({
    required this.label,
    required this.text,
    required this.icon,
  });
}

class SampleChips extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const SampleChips({super.key, required this.onSelect});

  static const List<SampleMessage> samples = [
    SampleMessage(
      label: 'SBI KYC Scam',
      text: 'Your SBI KYC expired. Update now at http://sbi-kyc-verify.xyz or account will be blocked',
      icon: Icons.dangerous_outlined,
    ),
    SampleMessage(
      label: 'Lottery Scam',
      text: 'Dear customer, congratulations! You won 10,00,000 cash prize in lottery. Claim now by calling 9876543210',
      icon: Icons.money_off_csred_outlined,
    ),
    SampleMessage(
      label: 'Bank OTP (Legit)',
      text: '123456 is your OTP for login to HDFC net banking. Do not share it with anyone.',
      icon: Icons.lock_outline,
    ),
    SampleMessage(
      label: 'Casual Chat (Legit)',
      text: 'Reached home safely, will talk tomorrow',
      icon: Icons.chat_bubble_outline,
    ),
    SampleMessage(
      label: 'Lunch Meet (Legit)',
      text: 'Hey, are we still meeting for lunch today at 1pm?',
      icon: Icons.restaurant_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Quick Test Samples:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: samples.map((sample) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: Icon(sample.icon, size: 16),
                  label: Text(sample.label),
                  onPressed: () => onSelect(sample.text),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

