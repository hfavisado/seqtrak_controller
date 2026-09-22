import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seqtrak_controller/app/app.dart';
import 'package:seqtrak_controller/app/providers.dart';
import 'package:seqtrak_controller/midi/mock_midi_transport.dart';

void main() {
  testWidgets('shows track positions and opens MIDI Explorer', (tester) async {
    final transport = MockMidiTransport();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [midiTransportProvider.overrideWithValue(transport)],
        child: const SeqtrakControllerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('KICK'), findsOneWidget);
    expect(find.text('SNARE'), findsOneWidget);
    expect(find.text('Pattern unknown'), findsWidgets);
    final stepCenter = tester.getCenter(
      find.byKey(const ValueKey('position-kick-STEP')),
    );
    await tester.tap(find.byTooltip('Open MIDI Explorer'));
    await tester.pumpAndSettle();
    expect(find.text('SEQTRAK MIDI Explorer'), findsOneWidget);
    expect(find.text('Mock SEQTRAK'), findsOneWidget);
    expect(find.text('MIDI traffic will appear here'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    transport.injectIncoming([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x50,
      0x0f,
      0x00,
      0xf7,
    ]);
    transport.injectIncoming([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x50,
      0x16,
      0x00,
      0x10,
      0xf7,
    ]);
    transport.injectIncoming([0xfa]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('position-kick-BAR'))).data,
      '01',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('position-kick-STEP')))
          .data,
      '01',
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('position-kick-STEP'))).dx,
      stepCenter.dx,
    );
    for (var i = 0; i < 6; i++) {
      transport.injectIncoming([0xf8]);
    }
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('position-kick-STEP')))
          .data,
      '02',
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('position-kick-STEP'))).dx,
      stepCenter.dx,
    );
  });

  testWidgets('copies visible traffic to the clipboard', (tester) async {
    String? copiedText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final transport = MockMidiTransport();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [midiTransportProvider.overrideWithValue(transport)],
        child: const SeqtrakControllerApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Open MIDI Explorer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    transport.injectIncoming([
      0xfa,
    ], timestamp: DateTime(2026, 9, 22, 12, 34, 56, 78));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy traffic'));
    await tester.pump();
    expect(copiedText, contains('12:34:56.078 RX FA  Start'));
    expect(copiedText, contains('TX F0 43 30 7F 1C 0C 30 50 0F F7'));
  });
}
