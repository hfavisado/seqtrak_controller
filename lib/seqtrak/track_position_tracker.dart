import '../midi/midi_packet.dart';
import 'seqtrak_pattern_protocol.dart';
import 'seqtrak_track.dart';

class TrackPosition {
  const TrackPosition({
    required this.bar,
    required this.beat,
    required this.step,
  });

  final int bar;
  final int beat;
  final int step;
}

class TrackPositionTracker {
  TrackPositionTracker({this.protocol = const SeqtrakPatternProtocol()});

  final SeqtrakPatternProtocol protocol;
  final Map<SeqtrakTrack, int> _selectedPatterns = {};
  final Map<SeqtrakTrack, Map<int, int>> _stepCounts = {};
  int? _ticks;
  bool _running = false;

  bool get isRunning => _running;
  int? selectedPatternFor(SeqtrakTrack track) => _selectedPatterns[track];
  int? stepCountFor(SeqtrakTrack track) =>
      _stepCounts[track]?[_selectedPatterns[track]];

  TrackPosition? positionFor(SeqtrakTrack track) {
    final ticks = _ticks;
    final steps = stepCountFor(track);
    if (ticks == null || steps == null) return null;
    final stepIndex = (ticks ~/ 6) % steps;
    return TrackPosition(
      bar: stepIndex ~/ 16 + 1,
      beat: (stepIndex % 16) ~/ 4 + 1,
      step: stepIndex % 16 + 1,
    );
  }

  void reset() {
    _selectedPatterns.clear();
    _stepCounts.clear();
    _ticks = null;
    _running = false;
  }

  PatternParameterChange? accept(MidiPacket packet) {
    if (packet.direction != MidiDirection.rx) return null;
    final change = protocol.decode(packet.bytes);
    if (change != null) {
      if (change.kind == PatternParameterKind.selectedPattern) {
        _selectedPatterns[change.track] = change.pattern!;
      } else {
        _stepCounts.putIfAbsent(change.track, () => {})[change.pattern!] =
            change.value;
      }
      return change;
    }
    if (packet.bytes.length != 1) return null;
    switch (packet.bytes.single) {
      case 0xfa:
        _ticks = 0;
        _running = true;
      case 0xfb:
        _running = _ticks != null;
      case 0xfc:
        _running = false;
      case 0xf8:
        if (_running && _ticks != null) _ticks = _ticks! + 1;
    }
    return null;
  }
}
