import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/midi/midi_packet.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_track.dart';
import 'package:seqtrak_controller/seqtrak/track_position_tracker.dart';

void main() {
  final tracker = TrackPositionTracker();

  void send(List<int> bytes) => tracker.accept(
    MidiPacket(
      timestamp: DateTime(2026),
      direction: MidiDirection.rx,
      bytes: bytes,
    ),
  );

  setUp(tracker.reset);

  test('tracks different pattern lengths from the same clock', () {
    send([0xf0, 0x43, 0x10, 0x7f, 0x1c, 0x0c, 0x30, 0x50, 0x0f, 0x00, 0xf7]);
    send([
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
    send([0xf0, 0x43, 0x10, 0x7f, 0x1c, 0x0c, 0x30, 0x57, 0x0f, 0x00, 0xf7]);
    send([
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
    send([0xfa]);
    for (var i = 0; i < 96; i++) {
      send([0xf8]);
    }
    expect(tracker.positionFor(SeqtrakTrack.kick)?.bar, 1);
    expect(tracker.positionFor(SeqtrakTrack.synth1)?.bar, 2);
    expect(tracker.positionFor(SeqtrakTrack.snare), isNull);
  });

  test('uses selected pattern and exact non-bar step length', () {
    send([0xf0, 0x43, 0x10, 0x7f, 0x1c, 0x0c, 0x30, 0x50, 0x0f, 0x01, 0xf7]);
    send([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x50,
      0x18,
      0x00,
      0x14,
      0xf7,
    ]);
    send([0xfa]);
    for (var i = 0; i < 120; i++) {
      send([0xf8]);
    }
    expect(tracker.positionFor(SeqtrakTrack.kick)?.bar, 1);
    expect(tracker.positionFor(SeqtrakTrack.kick)?.step, 1);
  });

  test('eight-bar pattern wraps after 128 steps', () {
    send([0xf0, 0x43, 0x10, 0x7f, 0x1c, 0x0c, 0x30, 0x5a, 0x0f, 0x00, 0xf7]);
    send([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x5a,
      0x16,
      0x01,
      0x00,
      0xf7,
    ]);
    send([0xfa]);
    for (var i = 0; i < 127 * 6; i++) {
      send([0xf8]);
    }
    expect(tracker.positionFor(SeqtrakTrack.sampler)?.bar, 8);
    expect(tracker.positionFor(SeqtrakTrack.sampler)?.step, 16);
    for (var i = 0; i < 6; i++) {
      send([0xf8]);
    }
    expect(tracker.positionFor(SeqtrakTrack.sampler)?.bar, 1);
    expect(tracker.positionFor(SeqtrakTrack.sampler)?.step, 1);
  });
}
