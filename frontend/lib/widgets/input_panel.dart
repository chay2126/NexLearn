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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore a topic',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'The left panel explains the concept and collects input. The right panel reacts with a chart or highlighted language structure.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: topics
                    .map(
                      (topic) => _TopicCard(
                        topic: topic,
                        isSelected: topic.id == selectedTopic?.id,
                        isBusy: isBusy,
                        onTap: () => onTopicSelected(topic.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              if (selectedTopic != null) ...[
                _SectionHeader(
                  title: selectedTopic!.title,
                  badge: selectedTopic!.type.toUpperCase(),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedTopic!.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  label: 'Formula / Structure',
                  value: selectedTopic!.formula,
                  accent: selectedTopic!.type == 'chemistry'
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFE76F51),
                ),
                const SizedBox(height: 24),
              ],
              if (simulation == null && selectedTopic != null)
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
            ],
          ),
        ),
      ),
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
  });

  final TopicSummary topic;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = topic.type == 'chemistry'
        ? const Color(0xFF0F766E)
        : const Color(0xFFE76F51);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 220,
      decoration: BoxDecoration(
        color: isSelected ? accent : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? accent : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: accent.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.type.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                topic.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF1F2D3D),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                topic.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
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
