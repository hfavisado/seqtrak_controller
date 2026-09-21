import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/features/midi_explorer/midi_explorer_controller.dart';
import 'package:seqtrak_controller/midi/midi_capture_exporter.dart';
import 'package:seqtrak_controller/midi/mock_midi_transport.dart';

void main() {
  test('records TX traffic and exports a human-readable capture', () async {
    final transport = MockMidiTransport();
    final exporter = _MemoryExporter();
    final controller = MidiExplorerController(
      transport: transport,
      exporter: exporter,
    );
    addTearDown(controller.dispose);

    await controller.start();
    await controller.connect(controller.devices.single);
    controller.startRecording();
    await controller.sendHex('90 3C 64');
    controller.stopRecording();
    await controller.exportCapture(notes: 'Pressed middle C');

    expect(controller.recordedPacketCount, 1);
    expect(exporter.contents, contains('# Notes: Pressed middle C'));
    expect(exporter.contents, contains('TX 90 3C 64'));
    expect(controller.lastExportPath, '/captures/${exporter.fileName}');
  });

  test(
    'hides clock and sensing from display but retains them in capture',
    () async {
      final transport = MockMidiTransport();
      final exporter = _MemoryExporter();
      final controller = MidiExplorerController(
        transport: transport,
        exporter: exporter,
      );
      addTearDown(controller.dispose);

      await controller.start();
      await controller.connect(controller.devices.single);
      controller.startRecording();
      transport.injectIncoming([0xf8]);
      transport.injectIncoming([0xfe]);
      transport.injectIncoming([0xfa]);
      transport.injectIncoming([0xb0, 0x4a, 0x64]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.packets, hasLength(4));
      expect(controller.visiblePackets, hasLength(2));
      expect(controller.visiblePackets.first.bytes, [0xfa]);
      expect(controller.visiblePackets.last.bytes, [0xb0, 0x4a, 0x64]);
      expect(controller.recordedPacketCount, 4);

      controller.setShowRealtimeNoise(true);
      expect(controller.visiblePackets, hasLength(4));
    },
  );
}

class _MemoryExporter implements MidiCaptureExporter {
  String? contents;
  String? fileName;

  @override
  Future<String?> export({
    required String contents,
    required String fileName,
  }) async {
    this.contents = contents;
    this.fileName = fileName;
    return '/captures/$fileName';
  }
}
