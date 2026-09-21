import 'midi_device.dart';
import 'midi_packet.dart';

abstract interface class MidiTransport {
  Stream<MidiPacket> get incomingMessages;
  Stream<List<MidiDevice>> get devices;

  Future<void> start();
  Future<void> connect(MidiDevice device);
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
  Future<void> dispose();
}
