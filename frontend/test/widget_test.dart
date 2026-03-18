import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexlearn_frontend/main.dart';
import 'package:nexlearn_frontend/services/api_service.dart';

class FakeApiService extends ApiService {
  FakeApiService() : super(baseUrl: 'http://unused');

  @override
  Future<List<TopicSummary>> fetchTopics() async {
    return const [
      TopicSummary(
        id: 1,
        title: 'Reaction Rate Dynamics',
        description: 'Chemistry lesson',
        type: 'chemistry',
        formula: 'C(t) = C0 * e^(-kt)',
      ),
    ];
  }

  @override
  Future<TopicSimulation> fetchSimulation(int topicId) async {
    return TopicSimulation(
      topic: const TopicSummary(
        id: 1,
        title: 'Reaction Rate Dynamics',
        description: 'Chemistry lesson',
        type: 'chemistry',
        formula: 'C(t) = C0 * e^(-kt)',
      ),
      config: const SimulationConfig(
        visualization: 'line_chart',
        inputs: [
          InputDefinition(
            name: 'concentration',
            min: 0,
            max: 10,
            defaultValue: 1,
          ),
          InputDefinition(
            name: 'temperature',
            min: 250,
            max: 500,
            defaultValue: 300,
          ),
        ],
      ),
    );
  }

  @override
  Future<ChemistryResult> calculateReactionRate({
    required int topicId,
    required double concentration,
    required double temperature,
  }) async {
    return const ChemistryResult(
      topicId: 1,
      rate: 0.0812,
      rateConstant: 0.0812,
      graphPoints: [
        GraphPoint(time: 0, concentration: 1),
        GraphPoint(time: 1, concentration: 0.92),
      ],
      formula: 'C(t) = C0 * e^(-kt)',
      cacheHit: false,
    );
  }
}

void main() {
  testWidgets('nexlearn opens chemistry from the subject chooser', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(NexLearnApp(apiService: FakeApiService()));
    await tester.pumpAndSettle();

    expect(find.text('NexLearn'), findsOneWidget);
    expect(find.text('Chemistry'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Chemistry'));
    await tester.pumpAndSettle();

    expect(find.text('Reaction Rate Dynamics'), findsWidgets);
    expect(find.text('Reaction profile'), findsOneWidget);
  });
}
