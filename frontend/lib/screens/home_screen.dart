import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'subject_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width >= 1100
        ? 40.0
        : size.width >= 760
        ? 28.0
        : 18.0;
    final verticalPadding = size.width >= 760 ? 28.0 : 18.0;

    const subjects = <_SubjectSpec>[
      _SubjectSpec(
        subjectType: 'chemistry',
        title: 'Chemistry',
        eyebrow: 'Experiment Track',
        subtitle:
            'Explore reaction-rate lessons with live sliders, kinetic feedback, and dynamic graphs that respond instantly.',
        accent: Color(0xFF0F766E),
        gradientColors: [
          Color(0xFF0B3B40),
          Color(0xFF126A6B),
          Color(0xFF3F9B90),
        ],
        icon: Icons.science_rounded,
        highlights: ['Live graph', 'Kinetics', 'Interactive controls'],
        detailLabel: 'Focus',
        detailValue: 'Reaction profiles',
        outcomeLabel: 'Best for',
        outcomeValue: 'Visual experimentation',
        buttonLabel: 'Launch lesson',
      ),
      _SubjectSpec(
        subjectType: 'english',
        title: 'English',
        eyebrow: 'Language Studio',
        subtitle:
            'Break sentences into subject, verb, and object with instant highlighting designed to make grammar easier to read.',
        accent: Color(0xFFE76F51),
        gradientColors: [
          Color(0xFF5B2432),
          Color(0xFF9A3A4D),
          Color(0xFFE76F51),
        ],
        icon: Icons.auto_stories_rounded,
        highlights: ['Grammar map', 'Realtime analysis', 'Color highlights'],
        detailLabel: 'Focus',
        detailValue: 'Sentence structure',
        outcomeLabel: 'Best for',
        outcomeValue: 'Fast comprehension',
        buttonLabel: 'Open studio',
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F1E5), Color(0xFFE8F4F2), Color(0xFFFDF8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _HomeBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  final spacing = isWide ? 24.0 : 0.0;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - spacing) / 2
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - (verticalPadding * 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HomeHeader(),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: spacing,
                            runSpacing: 18,
                            children: subjects
                                .map(
                                  (subject) => SizedBox(
                                    width: cardWidth,
                                    child: _SubjectCard(
                                      spec: subject,
                                      onTap: () => _openSubject(
                                        context,
                                        subject.subjectType,
                                        subject.title,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          const _FooterNote(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubject(BuildContext context, String subjectType, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SubjectScreen(
          apiService: apiService,
          subjectType: subjectType,
          subjectTitle: title,
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F172A),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6F78).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Choose your learning track',
              style: TextStyle(
                color: Color(0xFF145965),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'NexLearn',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: isWide ? 44 : 34,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'Pick the subject that matches how you want to learn today. Each card opens a focused workspace with interactive feedback instead of a static lesson.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF32485C),
                fontSize: isWide ? 18 : 16,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeaderStat(
                label: 'Subjects',
                value: '2 interactive paths',
                accent: Color(0xFF0F766E),
              ),
              _HeaderStat(
                label: 'Learning style',
                value: 'Visual + hands-on',
                accent: Color(0xFFE76F51),
              ),
              _HeaderStat(
                label: 'Response',
                value: 'Live updates',
                accent: Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  const _SubjectCard({required this.spec, required this.onTap});

  final _SubjectSpec spec;
  final VoidCallback onTap;

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 16,
      height: 1.55,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: _isHovered ? 1.015 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 380),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: spec.accent.withValues(alpha: _isHovered ? 0.28 : 0.18),
                blurRadius: _isHovered ? 40 : 28,
                offset: Offset(0, _isHovered ? 24 : 18),
              ),
              const BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 24,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: spec.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _isHovered ? 0.44 : 0.24,
                    ),
                    width: 1.1,
                  ),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(34),
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.05),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -32,
                        right: -30,
                        child: _CardGlow(
                          size: 180,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      Positioned(
                        bottom: -46,
                        left: -24,
                        child: _CardGlow(
                          size: 150,
                          color: spec.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      Positioned(
                        top: 88,
                        right: 24,
                        child: Transform.rotate(
                          angle: -0.18,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CardEyebrow(label: spec.eyebrow),
                                const Spacer(),
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    spec.icon,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            Text(spec.title, style: titleStyle),
                            const SizedBox(height: 12),
                            Text(spec.subtitle, style: subtitleStyle),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: spec.highlights
                                  .map(
                                    (highlight) =>
                                        _HighlightChip(label: highlight),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _CardMetric(
                                      label: spec.detailLabel,
                                      value: spec.detailValue,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 42,
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                  Expanded(
                                    child: _CardMetric(
                                      label: spec.outcomeLabel,
                                      value: spec.outcomeValue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: widget.onTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: spec.accent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(spec.buttonLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1F6F78).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Color(0xFF145965),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Tap anywhere on a card or use its button to open the lesson workspace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF3A4C5E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A7786),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1F2D3D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardEyebrow extends StatelessWidget {
  const _CardEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardGlow extends StatelessWidget {
  const _CardGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _CardGlow(
              size: 260,
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 120,
            right: -50,
            child: _CardGlow(
              size: 220,
              color: const Color(0xFFE76F51).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -90,
            left: MediaQuery.of(context).size.width * 0.18,
            child: _CardGlow(
              size: 280,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectSpec {
  const _SubjectSpec({
    required this.subjectType,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.accent,
    required this.gradientColors,
    required this.icon,
    required this.highlights,
    required this.detailLabel,
    required this.detailValue,
    required this.outcomeLabel,
    required this.outcomeValue,
    required this.buttonLabel,
  });

  final String subjectType;
  final String title;
  final String eyebrow;
  final String subtitle;
  final Color accent;
  final List<Color> gradientColors;
  final IconData icon;
  final List<String> highlights;
  final String detailLabel;
  final String detailValue;
  final String outcomeLabel;
  final String outcomeValue;
  final String buttonLabel;
}
