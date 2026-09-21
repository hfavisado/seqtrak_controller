import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/midi/midi_codec.dart';

void main() {
  const codec = MidiCodec();

  test('parses and formats hexadecimal MIDI bytes', () {
    final bytes = codec.parseHex('b0 4A 64');

    expect(bytes, [0xb0, 0x4a, 0x64]);
    expect(codec.formatHex(bytes), 'B0 4A 64');
  });

  test('rejects malformed input', () {
    expect(() => codec.parseHex('B0 nope 64'), throwsFormatException);
    expect(() => codec.parseHex(''), throwsFormatException);
  });

  test('describes standard CC without assigning SEQTRAK meaning', () {
    expect(codec.describe([0xb0, 0x4a, 0x64]), 'CC ch1 74 = 100');
  });
}
