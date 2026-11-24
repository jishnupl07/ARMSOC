import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/classification_result.dart';
import '../services/risk_advisor_service.dart';
import '../services/scam_classifier.dart';
import 'widgets/result_card.dart';
import 'widgets/sample_chips.dart';

class HomeScreen extends StatefulWidget {
  final ScamClassifier? classifier;
  final RiskAdvisorService? riskAdvisor;

  const HomeScreen({
    super.key,
    this.classifier,
    this.riskAdvisor,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ScamClassifier? _classifier;
  late final RiskAdvisorService _riskAdvisor;
  bool _isLoadingModel = true;
  String? _modelError;

  ClassificationResult? _result;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _riskAdvisor = widget.riskAdvisor ?? RiskAdvisorService(llamaBackend: ExecuTorchLlamaBackend());
    if (widget.classifier != null) {
      _classifier = widget.classifier;
      _isLoadingModel = false;
    } else {
      _loadModel();
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoadingModel = true;
      _modelError = null;
    });

    try {
      final classifier = await ScamClassifier.loadFromAsset();
      setState(() {
        _classifier = classifier;
        _isLoadingModel = false;
      });
    } catch (e) {
      setState(() {
        _modelError = 'Failed to load offline model: $e';
        _isLoadingModel = false;
      });
    }
  }

  Future<void> _analyzeMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste an SMS message to analyze.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_classifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model is still loading, please wait...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Run inference
    final initialResult = _classifier!.classify(text);
    final advice = await _riskAdvisor.advise(initialResult);

    if (mounted) {
      setState(() {
        _result = initialResult.copyWith(advice: advice);
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      _textController.text = data.text!;
      setState(() {});
    }
  }

  void _clearInput() {
    _textController.clear();
    setState(() {
      _result = null;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SMS Shield',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: Icon(
                _classifier != null ? Icons.check_circle : Icons.sync,
                size: 16,
                color: _classifier != null ? Colors.green : Colors.orange,
              ),
              label: Text(
                _classifier != null ? 'Offline Ready' : 'Loading',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: _isLoadingModel
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading offline classification model...'),
                ],
              ),
            )
          : _modelError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_modelError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadModel,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Input Card
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Enter SMS Message',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.content_paste_outlined, size: 20),
                                          tooltip: 'Paste from clipboard',
                                          onPressed: _pasteFromClipboard,
                                        ),
                                        if (_textController.text.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 20),
                                            tooltip: 'Clear',
                                            onPressed: _clearInput,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _textController,
                                  focusNode: _focusNode,
                                  maxLines: 5,
                                  minLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Type or paste the suspicious or legitimate SMS here...',
                                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerLowest,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _isAnalyzing ? null : _analyzeMessage,
                                  icon: _isAnalyzing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.search_rounded),
                                  label: Text(
                                    _isAnalyzing ? 'Analyzing...' : 'Analyze Message',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Test Samples
                        SampleChips(
                          onSelect: (sampleText) {
                            _textController.text = sampleText;
                            setState(() {});
                            _analyzeMessage();
                          },
                        ),
                        const SizedBox(height: 20),

                        // Classification Result
                        if (_result != null) ResultCard(result: _result!),
                      ],
                    ),
                  ),
                ),
    );
  }
}
