import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/input_panel.dart';
import '../widgets/visualization_panel.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({
    super.key,
    required this.subjectType,
    required this.subjectTitle,
    this.apiService,
  });

  final String subjectType;
  final String subjectTitle;
  final ApiService? apiService;

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late final ApiService _apiService;
  late final bool _ownsApiService;
  late final TextEditingController _englishController;

  final String _defaultEnglishSentence = 'The student writes a clear summary.';

  List<TopicSummary> _topics = <TopicSummary>[];
  TopicSummary? _selectedTopic;
  TopicSimulation? _selectedSimulation;
  Map<String, double> _chemistryValues = <String, double>{};
  ChemistryResult? _chemistryResult;
  EnglishAnalysis? _englishAnalysis;
  String? _errorMessage;
  bool _isBootstrapping = true;
  bool _isVisualizationLoading = false;
  Timer? _englishDebounce;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget.apiService == null;
    _apiService = widget.apiService ?? ApiService();
    _englishController = TextEditingController(text: _defaultEnglishSentence);
    _bootstrap();
  }

  @override
  void dispose() {
    _englishDebounce?.cancel();
    _englishController.dispose();
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _errorMessage = null;
    });

    try {
      final fetchedTopics = await _apiService.fetchTopics();
      final filteredTopics = fetchedTopics
          .where((topic) => topic.type == widget.subjectType)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _topics = filteredTopics;
      });

      if (filteredTopics.isEmpty) {
        setState(() {
          _selectedTopic = null;
          _selectedSimulation = null;
          _chemistryResult = null;
          _englishAnalysis = null;
          _isVisualizationLoading = false;
          _errorMessage =
              'No ${widget.subjectTitle.toLowerCase()} topics are available.';
        });
        return;
      }

      await _selectTopic(filteredTopics.first.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  Future<void> _selectTopic(int topicId) async {
    _englishDebounce?.cancel();
    final topic = _topics.firstWhere((item) => item.id == topicId);

    setState(() {
      _selectedTopic = topic;
      _selectedSimulation = null;
      _chemistryResult = null;
      _englishAnalysis = null;
      _errorMessage = null;
      _isVisualizationLoading = true;
    });

    try {
      final simulation = await _apiService.fetchSimulation(topicId);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSimulation = simulation;
        _chemistryValues = {
          for (final input in simulation.config.inputs)
            input.name: input.defaultValue,
        };
        if (_englishController.text.isEmpty) {
          _englishController.text = _defaultEnglishSentence;
        }
      });

      if (topic.type == 'chemistry') {
        await _refreshChemistry();
      } else {
        await _refreshEnglish();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isVisualizationLoading = false;
      });
    }
  }

  Future<void> _refreshChemistry() async {
    final topic = _selectedTopic;
    final simulation = _selectedSimulation;
    if (topic == null || simulation == null || topic.type != 'chemistry') {
      return;
    }

    setState(() {
      _isVisualizationLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.calculateReactionRate(
        topicId: topic.id,
        concentration: _chemistryValues['concentration'] ?? 1.0,
        temperature: _chemistryValues['temperature'] ?? 300.0,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _chemistryResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVisualizationLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEnglish() async {
    final topic = _selectedTopic;
    final simulation = _selectedSimulation;
    if (topic == null || simulation == null || topic.type != 'english') {
      return;
    }

    final trimmedSentence = _englishController.text.trim();
    if (trimmedSentence.isEmpty) {
      setState(() {
        _englishAnalysis = null;
        _isVisualizationLoading = false;
      });
      return;
    }

    setState(() {
      _isVisualizationLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.analyzeSentence(
        topicId: topic.id,
        sentence: trimmedSentence,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _englishAnalysis = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVisualizationLoading = false;
        });
      }
    }
  }

  void _handleChemistryValueChanged(String name, double value) {
    setState(() {
      _chemistryValues[name] = value;
    });
    unawaited(_refreshChemistry());
  }

  void _handleEnglishChanged(String value) {
    _englishDebounce?.cancel();
    _englishDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_refreshEnglish());
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width > 960 ? 28.0 : 18.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F2EA), Color(0xFFEAF5F6), Color(0xFFFDF7EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                _Header(
                  subjectTitle: widget.subjectTitle,
                  isLoading: _isBootstrapping,
                  onReload: _bootstrap,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      final inputPanel = InputPanel(
                        topics: _topics,
                        selectedTopic: _selectedTopic,
                        simulation: _selectedSimulation,
                        chemistryValues: _chemistryValues,
                        englishController: _englishController,
                        englishAnalysis: _englishAnalysis,
                        isBusy: _isBootstrapping,
                        onTopicSelected: _selectTopic,
                        onChemistryChanged: _handleChemistryValueChanged,
                        onEnglishChanged: _handleEnglishChanged,
                      );
                      final visualizationPanel = VisualizationPanel(
                        selectedTopic: _selectedTopic,
                        chemistryResult: _chemistryResult,
                        englishAnalysis: _englishAnalysis,
                        isLoading: _isVisualizationLoading,
                        errorMessage: _errorMessage,
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: inputPanel),
                            const SizedBox(width: 20),
                            Expanded(flex: 6, child: visualizationPanel),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Expanded(flex: 5, child: inputPanel),
                          const SizedBox(height: 16),
                          Expanded(flex: 6, child: visualizationPanel),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subjectTitle,
    required this.isLoading,
    required this.onReload,
  });

  final String subjectTitle;
  final bool isLoading;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x190F172A),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Interactive $subjectTitle learning with live visual feedback.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: isLoading ? null : () => unawaited(onReload()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
