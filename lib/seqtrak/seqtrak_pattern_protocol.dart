import 'seqtrak_track.dart';

enum PatternParameterKind { selectedPattern, stepCount }

class PatternParameterChange {
  const PatternParameterChange({
    required this.track,
    required this.kind,
    required this.value,
    this.pattern,
  });

  final SeqtrakTrack track;
  final PatternParameterKind kind;
  final int value;
  final int? pattern;
}

/// Project Track General parameters from Yamaha's SEQTRAK Data List.
class SeqtrakPatternProtocol {
  const SeqtrakPatternProtocol();

  PatternParameterChange? decode(List<int> bytes) {
    if (bytes.length != 11 && bytes.length != 12) return null;
    if (bytes[0] != 0xf0 ||
        bytes[1] != 0x43 ||
        (bytes[2] & 0xf0) != 0x10 ||
        bytes[3] != 0x7f ||
        bytes[4] != 0x1c ||
        bytes[5] != 0x0c ||
        bytes[6] != 0x30 ||
        bytes[7] < 0x50 ||
        bytes[7] > 0x5a ||
        bytes.last != 0xf7 ||
        bytes.sublist(8, bytes.length - 1).any((b) => b > 0x7f)) {
      return null;
    }
    final track = SeqtrakTrack.values[bytes[7] - 0x50];
    final offset = bytes[8];
    if (offset == 0x0f && bytes.length == 11 && bytes[9] <= 5) {
      return PatternParameterChange(
        track: track,
        kind: PatternParameterKind.selectedPattern,
        pattern: bytes[9] + 1,
        value: bytes[9],
      );
    }
    if (offset >= 0x16 &&
        offset <= 0x20 &&
        offset.isEven &&
        bytes.length == 12) {
      final steps = (bytes[9] << 7) | bytes[10];
      if (steps < 1 || steps > 128) return null;
      return PatternParameterChange(
        track: track,
        kind: PatternParameterKind.stepCount,
        pattern: (offset - 0x16) ~/ 2 + 1,
        value: steps,
      );
    }
    return null;
  }

  List<int> requestSelectedPattern(SeqtrakTrack track) => _request(track, 0x0f);

  List<int> requestStepCount(SeqtrakTrack track, int pattern) {
    if (pattern < 1 || pattern > 6) {
      throw RangeError.range(pattern, 1, 6, 'pattern');
    }
    return _request(track, 0x16 + (pattern - 1) * 2);
  }

  List<int> _request(SeqtrakTrack track, int offset) => [
    0xf0,
    0x43,
    0x30,
    0x7f,
    0x1c,
    0x0c,
    0x30,
    0x50 + track.index,
    offset,
    0xf7,
  ];
}
