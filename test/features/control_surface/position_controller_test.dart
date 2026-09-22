import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/features/control_surface/position_controller.dart';
import 'package:seqtrak_controller/features/midi_explorer/midi_explorer_controller.dart';
import 'package:seqtrak_controller/midi/midi_capture_exporter.dart';
import 'package:seqtrak_controller/midi/mock_midi_transport.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_track.dart';

class _NoopExporter implements MidiCaptureExporter {
  @override
  Future<String?> export({
    required String contents,
    required String fileName,
  }) async => null;
}

void main() {
  test('rapid auditions end the prior note before the next one', () async {
    final transport = MockMidiTransport();
    final explorer = MidiExplorerController(
      transport: transport,
      exporter: _NoopExporter(),
    );
    final controller = PositionController(
      transport: transport,
      explorer: explorer,
    );
    addTearDown(() {
      controller.dispose();
      explorer.dispose();
    });
    await explorer.start();
    await explorer.connect(explorer.devices.single);
    await Future<void>.delayed(Duration.zero);
    final first = controller.audition(
      SeqtrakTrack.synth1,
      note: 60,
      velocity: 90,
      gateMs: 30,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final second = controller.audition(
      SeqtrakTrack.synth1,
      note: 64,
      velocity: 80,
      gateMs: 30,
    );
    await Future.wait([first, second]);
    expect(transport.sentMessages.sublist(11), [
      [0x97, 60, 90],
      [0x87, 60, 0],
      [0x97, 64, 80],
      [0x87, 64, 0],
    ]);
  });

  test('requests each selection and follows per-track lengths', () async {
    final transport = MockMidiTransport();
    final explorer = MidiExplorerController(
      transport: transport,
      exporter: _NoopExporter(),
    );
    final controller = PositionController(
      transport: transport,
      explorer: explorer,
    );
    addTearDown(() {
      controller.dispose();
      explorer.dispose();
    });
    await explorer.start();
    await explorer.connect(explorer.devices.single);
    await Future<void>.delayed(Duration.zero);
    expect(transport.sentMessages.where((m) => m[8] == 0x0f), hasLength(11));
    expect(
      explorer.packets.where((p) => p.direction.name == 'tx'),
      hasLength(11),
    );

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
      0x57,
      0x0f,
      0x00,
      0xf7,
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(
      transport.sentMessages,
      contains(
        equals([0xf0, 0x43, 0x30, 0x7f, 0x1c, 0x0c, 0x30, 0x57, 0x16, 0xf7]),
      ),
    );
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
    transport.injectIncoming([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x57,
      0x16,
      0x00,
      0x20,
      0xf7,
    ]);
    transport.injectIncoming([0xfa]);
    for (var i = 0; i < 96; i++) {
      transport.injectIncoming([0xf8]);
    }
    await Future<void>.delayed(Duration.zero);
    expect(controller.positionFor(SeqtrakTrack.kick)?.bar, 1);
    expect(controller.positionFor(SeqtrakTrack.synth1)?.bar, 2);
    expect(controller.positionFor(SeqtrakTrack.snare), isNull);

    await explorer.disconnect();
    expect(controller.positionFor(SeqtrakTrack.kick), isNull);
  });
}
