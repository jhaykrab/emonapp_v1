import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ... (other imports)

// Create a simple CounterWidget
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$_counter'),
        ElevatedButton(
          onPressed: _incrementCounter,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the CounterWidget and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: CounterWidget()));

    // Verify that the counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the 'Increment' button and trigger a frame.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify that the counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
