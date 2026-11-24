import 'package:flutter/material.dart';
import '../../models/classification_result.dart';

class ResultCard extends StatelessWidget {
  final ClassificationResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor;
    final Color backgroundColor;
    final IconData iconData;
    final String title;

    switch (result.category) {
      case ClassificationCategory.scam:
        primaryColor = Colors.red.shade700;
        backgroundColor = isDark ? Colors.red.shade900.withAlpha(120) : Colors.red.shade50;
        iconData = Icons.gpp_bad_rounded;
        title = 'SCAM DETECTED';
        break;
      case ClassificationCategory.uncertain:
        primaryColor = Colors.orange.shade800;
        backgroundColor = isDark ? Colors.orange.shade900.withAlpha(120) : Colors.orange.shade50;
        iconData = Icons.warning_amber_rounded;
        title = 'UNCERTAIN / SUSPICIOUS';
        break;
      case ClassificationCategory.legitimate:
        primaryColor = Colors.green.shade700;
        backgroundColor = isDark ? Colors.green.shade900.withAlpha(120) : Colors.green.shade50;
        iconData = Icons.verified_user_rounded;
        title = 'LEGITIMATE MESSAGE';
        break;
    }

    final probPercent = (result.scamProbability * 100).toStringAsFixed(1);
    final thresholdPercent = (result.threshold * 100).toStringAsFixed(1);
    final advice = result.advice;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withAlpha(140), width: 1.5),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: primaryColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scam Score: $probPercent%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.labelText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.scamProbability,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0% (Legitimate)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  'Threshold: $thresholdPercent%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '100% (Scam)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 28),

            // Actionable Description
            Text(
              result.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 14),

            // Detected URLs
            if (result.extractedUrls.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_off_rounded, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Suspicious Links Detected:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...result.extractedUrls.map(
                      (url) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          url,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Llama 3.2 Security Advisor Box
            if (advice != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Risk Advisor',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: advice.isFromLlama
                                ? Colors.purple.withAlpha(30)
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            advice.isFromLlama ? 'Llama 3.2 1B (INT4)' : 'Security Template',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: advice.isFromLlama
                                  ? Colors.purple.shade700
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      advice.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                    if (advice.recommendedActions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Recommended Actions:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...advice.recommendedActions.map((action) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],

            // Influencing Terms
            if (result.topContributingTerms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Key Influencing Terms:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.topContributingTerms.map((f) {
                  final pushesScam = f.pushesScam;
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: pushesScam
                        ? Colors.red.withAlpha(25)
                        : Colors.green.withAlpha(25),
                    side: BorderSide(
                      color: pushesScam
                          ? Colors.red.withAlpha(80)
                          : Colors.green.withAlpha(80),
                    ),
                    label: Text(
                      f.term.trim().isEmpty ? '␣' : f.term,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: pushesScam ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
