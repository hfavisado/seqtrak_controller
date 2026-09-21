import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/midi/mock_midi_transport.dart';

void main() {
  test('discovers, connects, sends, and injects incoming MIDI', () async {
    final transport = MockMidiTransport();
    addTearDown(transport.dispose);
    final devicesFuture = transport.devices.first;

    await transport.start();
    final devices = await devicesFuture;
    await transport.connect(devices.single);
    await transport.send([0x90, 0x3c, 0x64]);
    final incomingFuture = transport.incomingMessages.first;
    transport.injectIncoming([0x80, 0x3c, 0x00]);

    expect(transport.sentMessages, [
      [0x90, 0x3c, 0x64],
    ]);
    expect((await incomingFuture).bytes, [0x80, 0x3c, 0x00]);
  });

  test('cannot send while disconnected', () async {
    final transport = MockMidiTransport();
    addTearDown(transport.dispose);
    await transport.start();

    expect(() => transport.send([0x90, 0x3c, 0x64]), throwsStateError);
  });
}
