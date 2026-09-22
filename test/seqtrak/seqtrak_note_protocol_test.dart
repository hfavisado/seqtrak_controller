import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_note_protocol.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_track.dart';

void main() {
  const protocol = SeqtrakNoteProtocol();

  test('encodes note audition on each fixed MIDI channel', () {
    expect(protocol.noteOn(SeqtrakTrack.kick, note: 60, velocity: 100), [
      0x90,
      60,
      100,
    ]);
    expect(protocol.noteOff(SeqtrakTrack.kick, note: 60), [0x80, 60, 0]);
    expect(protocol.noteOn(SeqtrakTrack.sampler, note: 64, velocity: 90), [
      0x9a,
      64,
      90,
    ]);
    expect(protocol.noteOff(SeqtrakTrack.sampler, note: 64), [0x8a, 64, 0]);
  });

  test('rejects invalid note and velocity', () {
    expect(
      () => protocol.noteOn(SeqtrakTrack.dx, note: 128, velocity: 100),
      throwsRangeError,
    );
    expect(
      () => protocol.noteOn(SeqtrakTrack.dx, note: 60, velocity: 0),
      throwsRangeError,
    );
  });
}
