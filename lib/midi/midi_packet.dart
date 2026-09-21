enum MidiDirection { rx, tx }

class MidiPacket {
  MidiPacket({
    required this.timestamp,
    required this.direction,
    required List<int> bytes,
    this.deviceId,
  }) : bytes = List<int>.unmodifiable(bytes) {
    if (bytes.any((byte) => byte < 0 || byte > 0xff)) {
      throw ArgumentError.value(bytes, 'bytes', 'Each byte must be 0...255');
    }
  }

  final DateTime timestamp;
  final MidiDirection direction;
  final List<int> bytes;
  final String? deviceId;
}
