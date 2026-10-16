import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/features/timer/presentation/widgets/circular_timer_dial.dart';

void main() {
  group('CircularTimerDial', () {
    testWidgets(
        'renders CustomPaint dial and formatted time text with tabular figures',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerDial(
              progress: 0.75,
              formattedTime: '18:45',
              primaryColor: Colors.teal,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('18:45'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('18:45'));
      expect(textWidget.style?.fontSize, 52);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(
        textWidget.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(CircularTimerDial),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.size, const Size(260, 260));
    });

    testWidgets('updates displayed time and repaints when progress changes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerDial(
              progress: 0.5,
              formattedTime: '12:30',
              primaryColor: Colors.teal,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('12:30'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerDial(
              progress: 0.25,
              formattedTime: '06:15',
              primaryColor: Colors.amber,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('06:15'), findsOneWidget);
      expect(find.text('12:30'), findsNothing);
    });

    testWidgets('renders cleanly when progress is 0.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerDial(
              progress: 0.0,
              formattedTime: '00:00',
              primaryColor: Colors.teal,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
    });
  });
}
