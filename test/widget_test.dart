import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seqtrak_controller/app/app.dart';
import 'package:seqtrak_controller/app/providers.dart';
import 'package:seqtrak_controller/midi/mock_midi_transport.dart';

void main() {
  testWidgets('ring overview fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          midiTransportProvider.overrideWithValue(MockMidiTransport()),
        ],
        child: const SeqtrakControllerApp(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('track-rings')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renames a track and changes its ring color', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          midiTransportProvider.overrideWithValue(MockMidiTransport()),
        ],
        child: const SeqtrakControllerApp(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('name-kick')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bass drum');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Bass drum'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('color-kick')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-1')));
    await tester.pumpAndSettle();
    final colorButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('color-kick')),
    );
    expect((colorButton.icon as Icon).color, Colors.pink.shade300);
  });

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
    expect(find.byKey(const ValueKey('track-rings')), findsOneWidget);
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
    final rings = find.byKey(const ValueKey('track-rings'));
    final topLeft = tester.getTopLeft(rings);
    final width = tester.getSize(rings).width;
    await tester.tapAt(topLeft + Offset(width / 2, 9));
    await tester.pump(const Duration(milliseconds: 200));
    expect(transport.sentMessages, contains(equals([0x90, 60, 100])));
    expect(transport.sentMessages, contains(equals([0x80, 60, 0])));
    expect(find.text('KICK · step 1'), findsOneWidget);
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
