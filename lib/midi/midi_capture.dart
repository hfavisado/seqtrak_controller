import 'midi_codec.dart';
import 'midi_packet.dart';

class MidiCaptureWriter {
  const MidiCaptureWriter({this.codec = const MidiCodec()});

  final MidiCodec codec;

  String write(
    List<MidiPacket> packets, {
    required DateTime startedAt,
    String? notes,
  }) {
    final buffer = StringBuffer()
      ..writeln('# SEQTRAK MIDI Capture')
      ..writeln('# Date: ${_date(startedAt)}');
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln('# Notes: ${notes.trim()}');
    }
    buffer.writeln();

    for (final packet in packets) {
      final elapsed = packet.timestamp.difference(startedAt);
      final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      buffer.writeln(
        '+${seconds.toStringAsFixed(6)} '
        '${packet.direction.name.toUpperCase()} '
        '${codec.formatHex(packet.bytes)}',
      );
    }
    return buffer.toString();
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
