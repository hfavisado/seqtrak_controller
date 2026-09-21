import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/app/app.dart';

void main() {
  testWidgets('shows the MIDI Explorer and mock device', (tester) async {
    await tester.pumpWidget(const SeqtrakControllerApp());
    await tester.pump();

    expect(find.text('SEQTRAK MIDI Explorer'), findsOneWidget);
    expect(find.text('Mock SEQTRAK'), findsOneWidget);
    expect(find.text('MIDI traffic will appear here'), findsOneWidget);
  });
}
