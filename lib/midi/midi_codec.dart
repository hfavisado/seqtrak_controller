class MidiCodec {
  const MidiCodec();

  List<int> parseHex(String input) {
    final tokens = input.trim().split(RegExp(r'\s+'));
    if (tokens.length == 1 && tokens.single.isEmpty) {
      throw const FormatException('Enter one or more hexadecimal bytes.');
    }
    return tokens
        .map((token) {
          if (!RegExp(r'^[0-9a-fA-F]{2}$').hasMatch(token)) {
            throw FormatException('Invalid MIDI byte: "$token"');
          }
          return int.parse(token, radix: 16);
        })
        .toList(growable: false);
  }

  String formatHex(Iterable<int> bytes) => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  String describe(List<int> bytes) {
    if (bytes.isEmpty) return 'Empty message';
    final status = bytes.first;
    if (status == 0xf0) return 'System Exclusive (${bytes.length} bytes)';
    if (status == 0xf8 && bytes.length == 1) return 'Timing Clock';
    if (status == 0xfe && bytes.length == 1) return 'Active Sensing';
    if (status < 0x80) return 'Data bytes';

    final channel = (status & 0x0f) + 1;
    final type = status & 0xf0;
    return switch (type) {
      0x80 when bytes.length >= 3 =>
        'Note off ch$channel ${bytes[1]} velocity ${bytes[2]}',
      0x90 when bytes.length >= 3 =>
        'Note on ch$channel ${bytes[1]} velocity ${bytes[2]}',
      0xa0 when bytes.length >= 3 =>
        'Poly pressure ch$channel note ${bytes[1]} = ${bytes[2]}',
      0xb0 when bytes.length >= 3 => 'CC ch$channel ${bytes[1]} = ${bytes[2]}',
      0xc0 when bytes.length >= 2 => 'Program change ch$channel = ${bytes[1]}',
      0xd0 when bytes.length >= 2 =>
        'Channel pressure ch$channel = ${bytes[1]}',
      0xe0 when bytes.length >= 3 =>
        'Pitch bend ch$channel = ${(bytes[2] << 7) | bytes[1]}',
      _ => 'MIDI message (${bytes.length} bytes)',
    };
  }
}
