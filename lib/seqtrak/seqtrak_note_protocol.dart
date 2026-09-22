import 'seqtrak_track.dart';

/// MIDI note messages accepted by SEQTRAK on its documented track channels.
class SeqtrakNoteProtocol {
  const SeqtrakNoteProtocol();

  List<int> noteOn(
    SeqtrakTrack track, {
    required int note,
    required int velocity,
  }) {
    _checkNote(note);
    if (velocity < 1 || velocity > 127) {
      throw RangeError.range(velocity, 1, 127, 'velocity');
    }
    return [0x90 | (track.channel - 1), note, velocity];
  }

  List<int> noteOff(SeqtrakTrack track, {required int note}) {
    _checkNote(note);
    return [0x80 | (track.channel - 1), note, 0];
  }

  void _checkNote(int note) {
    if (note < 0 || note > 127) {
      throw RangeError.range(note, 0, 127, 'note');
    }
  }
}
