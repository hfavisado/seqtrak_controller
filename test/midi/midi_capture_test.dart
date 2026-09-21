import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/midi/midi_capture.dart';
import 'package:seqtrak_controller/midi/midi_packet.dart';

void main() {
  test('writes elapsed timestamps, direction, and raw bytes', () {
    final start = DateTime.utc(2026, 9, 21, 12);
    final capture = const MidiCaptureWriter().write(
      [
        MidiPacket(
          timestamp: start.add(const Duration(microseconds: 41221)),
          direction: MidiDirection.rx,
          bytes: [0xb0, 0x4a, 0x21],
        ),
      ],
      startedAt: start,
      notes: 'Turned one control',
    );

    expect(capture, contains('# Date: 2026-09-21'));
    expect(capture, contains('# Notes: Turned one control'));
    expect(capture, contains('+0.041221 RX B0 4A 21'));
  });
}
