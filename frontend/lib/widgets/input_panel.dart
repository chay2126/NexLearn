import 'chat_widget.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class InputPanel extends StatelessWidget {
  const InputPanel({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.simulation,
    required this.chemistryValues,
    required this.englishController,
    required this.englishAnalysis,
    required this.isBusy,
    required this.onTopicSelected,
    required this.onChemistryChanged,
    required this.onEnglishChanged,
    required this.apiService,
  });

  final List<TopicSummary> topics;
  final TopicSummary? selectedTopic;
  final TopicSimulation? simulation;
  final Map<String, double> chemistryValues;
  final TextEditingController englishController;
  final EnglishAnalysis? englishAnalysis;
  final bool isBusy;
  final ValueChanged<int> onTopicSelected;
  final void Function(String name, double value) onChemistryChanged;
  final ValueChanged<String> onEnglishChanged;
  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    final topic = selectedTopic;

    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topic != null) ...[
                _TopicReading(
                  topic: topic,
                  topics: topics,
                  isBusy: isBusy,
                  onTopicSelected: onTopicSelected,
                ),
                const SizedBox(height: 32),
              ],
              if (simulation == null && topic != null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (simulation != null && selectedTopic?.type == 'chemistry')
                _ChemistryControls(
                  simulation: simulation!,
                  values: chemistryValues,
                  onChanged: onChemistryChanged,
                ),
              if (simulation != null && selectedTopic?.type == 'english')
                _EnglishControls(
                  controller: englishController,
                  analysis: englishAnalysis,
                  onChanged: onEnglishChanged,
                ),
              // ── AI Chatbot ──────────────────────────
              if (selectedTopic != null) ...[
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 24),
                ChatWidget(
                  topicId: selectedTopic!.id,
                  apiService: apiService,
                ),
              ],  
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicReading extends StatelessWidget {
  const _TopicReading({
    required this.topic,
    required this.topics,
    required this.isBusy,
    required this.onTopicSelected,
  });

  final TopicSummary topic;
  final List<TopicSummary> topics;
  final bool isBusy;
  final ValueChanged<int> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final accent = topic.type == 'chemistry'
        ? const Color(0xFF0F766E)
        : const Color(0xFFE76F51);
    final explanation = _topicExplanation(topic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.28)],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          topic.type.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          topic.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF1F2D3D),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          topic.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF243647),
            fontWeight: FontWeight.w600,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 16),
        ...explanation.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              paragraph,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF526273),
                height: 1.75,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF526273),
              height: 1.6,
            ),
            children: [
              TextSpan(
                text: topic.type == 'chemistry'
                    ? 'Core formula: '
                    : 'Core structure: ',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
              TextSpan(text: topic.formula),
            ],
          ),
        ),
        if (topics.length > 1) ...[
          const SizedBox(height: 22),
          Text(
            'Topics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1F2D3D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topics
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.title),
                    selected: item.id == topic.id,
                    onSelected: isBusy ? null : (_) => onTopicSelected(item.id),
                    selectedColor: accent.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: item.id == topic.id
                          ? accent.withValues(alpha: 0.34)
                          : const Color(0xFFD8E1E8),
                    ),
                    labelStyle: TextStyle(
                      color: item.id == topic.id
                          ? accent
                          : const Color(0xFF526273),
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ChemistryControls extends StatelessWidget {
  const _ChemistryControls({
    required this.simulation,
    required this.values,
    required this.onChanged,
  });

  final TopicSimulation simulation;
  final Map<String, double> values;
  final void Function(String name, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Adjust the simulation', badge: 'LIVE'),
        const SizedBox(height: 12),
        Text(
          'The rate constant responds to both concentration and temperature. Move the sliders to change the decay curve instantly.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        ...simulation.config.inputs.map(
          (input) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _SliderCard(
              label: _formatInputName(input.name),
              value: values[input.name] ?? input.defaultValue,
              min: input.min,
              max: input.max,
              onChanged: (value) => onChanged(input.name, value),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnglishControls extends StatelessWidget {
  const _EnglishControls({
    required this.controller,
    required this.analysis,
    required this.onChanged,
  });

  final TextEditingController controller;
  final EnglishAnalysis? analysis;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Type a sentence', badge: 'TEXT'),
        const SizedBox(height: 12),
        Text(
          'NexLearn highlights the grammatical core of a sentence. Subject appears in blue, verb in red, and object in green.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          maxLines: 3,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'The scientist mixes the solution in the flask.',
            filled: true,
            fillColor: const Color(0xFFF8FBFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        if (analysis != null) ...[
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    _InfoTile(
                      label: 'Subject',
                      value: analysis!.subject,
                      accent: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      label: 'Verb',
                      value: analysis!.verb,
                      accent: const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      label: 'Object',
                      value: analysis!.object,
                      accent: const Color(0xFF16A34A),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Subject',
                      value: analysis!.subject,
                      accent: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Verb',
                      value: analysis!.verb,
                      accent: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Object',
                      value: analysis!.object,
                      accent: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
          Row(
            children: [
              Text(min.toStringAsFixed(0)),
              const Spacer(),
              Text(max.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});

  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.86),
    borderRadius: BorderRadius.circular(28),
    boxShadow: const [
      BoxShadow(
        color: Color(0x160F172A),
        blurRadius: 30,
        offset: Offset(0, 18),
      ),
    ],
  );
}

String _formatInputName(String value) {
  final words = value.split('_');
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

List<String> _topicExplanation(TopicSummary topic) {
  switch (topic.type) {
    case 'chemistry':
      return const [
        'This lesson focuses on first-order reaction kinetics, where the speed of the reaction depends on how much reactant is still present. Concentration tells you how much material is available to react, while temperature changes how energetically particles collide and therefore how quickly the reaction proceeds.',
        'As you adjust the inputs, NexLearn recalculates the rate constant and redraws the concentration-decay curve on the right. That makes it easy to compare slower and faster reactions visually instead of reading the formula alone.',
      ];
    case 'english':
      return const [
        'This lesson breaks a sentence into its main grammatical parts so you can see how meaning is organized. The subject tells who or what performs the action, the verb shows the action or state, and the object shows who or what receives that action.',
        'When you type in the input box, the app analyzes the sentence immediately and highlights each role on the right. That visual feedback helps you understand structure, word order, and phrasing at the same time.',
      ];
    default:
      return <String>[topic.description];
  }
}
