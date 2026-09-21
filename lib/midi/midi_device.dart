enum MidiDeviceType { input, output, bidirectional }

class MidiDevice {
  const MidiDevice({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final MidiDeviceType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiDevice &&
          id == other.id &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, name, type);
}
