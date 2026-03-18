import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class VisualizationPanel extends StatelessWidget {
  const VisualizationPanel({
    super.key,
    required this.selectedTopic,
    required this.chemistryResult,
    required this.englishAnalysis,
    required this.isLoading,
    required this.errorMessage,
  });

  final TopicSummary? selectedTopic;
  final ChemistryResult? chemistryResult;
  final EnglishAnalysis? englishAnalysis;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33102A43),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (selectedTopic == null) {
      return const _EmptyState(
        title: 'Choose a topic',
        description:
            'Select Chemistry or English to load the lesson and visualization.',
      );
    }

    if (errorMessage != null) {
      return _EmptyState(
        title: 'Could not load visualization',
        description: errorMessage!,
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD166)),
      );
    }

    if (selectedTopic!.type == 'chemistry') {
      if (chemistryResult == null) {
        return const _EmptyState(
          title: 'Waiting for chemistry data',
          description:
              'Adjust the sliders to generate the concentration curve.',
        );
      }
      return _ChemistryVisualization(result: chemistryResult!);
    }

    if (englishAnalysis == null) {
      return const _EmptyState(
        title: 'Waiting for sentence analysis',
        description: 'Type a sentence to highlight subject, verb, and object.',
      );
    }
    return _EnglishVisualization(analysis: englishAnalysis!);
  }
}

class _ChemistryVisualization extends StatelessWidget {
  const _ChemistryVisualization({required this.result});

  final ChemistryResult result;

  @override
  Widget build(BuildContext context) {
    final spots = result.graphPoints
        .map((point) => FlSpot(point.time, point.concentration))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Reaction profile',
          subtitle: result.formula,
          cacheHit: result.cacheHit,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  _MetricCard(
                    label: 'Reaction rate',
                    value: result.rate.toStringAsFixed(4),
                    accent: const Color(0xFFFFD166),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Rate constant (k)',
                    value: result.rateConstant.toStringAsFixed(4),
                    accent: const Color(0xFF4FD1C5),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Reaction rate',
                    value: result.rate.toStringAsFixed(4),
                    accent: const Color(0xFFFFD166),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    label: 'Rate constant (k)',
                    value: result.rateConstant.toStringAsFixed(4),
                    accent: const Color(0xFF4FD1C5),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 22, 22, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F33),
              borderRadius: BorderRadius.circular(24),
            ),
            child: LineChart(
              LineChartData(
                minX: 0,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0x33FFFFFF), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF153A59),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFFFD166),
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0x33FFD166),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnglishVisualization extends StatelessWidget {
  const _EnglishVisualization({required this.analysis});

  final EnglishAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Sentence highlight',
          subtitle: analysis.visualization,
          cacheHit: analysis.cacheHit,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _LegendChip(label: 'Subject', color: Color(0xFF60A5FA)),
            _LegendChip(label: 'Verb', color: Color(0xFFF87171)),
            _LegendChip(label: 'Object', color: Color(0xFF4ADE80)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F33),
            borderRadius: BorderRadius.circular(24),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.55,
              ),
              children: analysis.segments
                  .map(
                    (segment) => TextSpan(
                      text: segment.text,
                      style: TextStyle(
                        color: _segmentColor(segment.role),
                        fontWeight: segment.role == 'plain'
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  _MetricCard(
                    label: 'Subject',
                    value: analysis.subject,
                    accent: const Color(0xFF60A5FA),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Verb',
                    value: analysis.verb,
                    accent: const Color(0xFFF87171),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Object',
                    value: analysis.object,
                    accent: const Color(0xFF4ADE80),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Subject',
                    value: analysis.subject,
                    accent: const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    label: 'Verb',
                    value: analysis.verb,
                    accent: const Color(0xFFF87171),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    label: 'Object',
                    value: analysis.object,
                    accent: const Color(0xFF4ADE80),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.cacheHit,
  });

  final String title;
  final String subtitle;
  final bool cacheHit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 15),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cacheHit ? const Color(0x334ADE80) : const Color(0x33FFD166),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            cacheHit ? 'Cache hit' : 'Fresh result',
            style: TextStyle(
              color: cacheHit
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFFFD166),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
        color: const Color(0xFF0B1F33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_graph_rounded,
              color: Color(0xFFFFD166),
              size: 52,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _segmentColor(String role) {
  switch (role) {
    case 'subject':
      return const Color(0xFF60A5FA);
    case 'verb':
      return const Color(0xFFF87171);
    case 'object':
      return const Color(0xFF4ADE80);
    default:
      return Colors.white;
  }
}
