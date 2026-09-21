import 'dart:async';

import 'midi_device.dart';
import 'midi_packet.dart';
import 'midi_transport.dart';

class MockMidiTransport implements MidiTransport {
  MockMidiTransport({List<MidiDevice>? initialDevices})
    : _availableDevices =
          initialDevices ??
          const [
            MidiDevice(
              id: 'mock-seqtrak',
              name: 'Mock SEQTRAK',
              type: MidiDeviceType.bidirectional,
            ),
          ];

  final StreamController<MidiPacket> _incomingController =
      StreamController<MidiPacket>.broadcast();
  final StreamController<List<MidiDevice>> _devicesController =
      StreamController<List<MidiDevice>>.broadcast();
  final List<MidiDevice> _availableDevices;
  final List<List<int>> sentMessages = [];

  MidiDevice? connectedDevice;
  bool _started = false;
  bool _disposed = false;

  @override
  Stream<MidiPacket> get incomingMessages => _incomingController.stream;

  @override
  Stream<List<MidiDevice>> get devices => _devicesController.stream;

  @override
  Future<void> start() async {
    _ensureNotDisposed();
    _started = true;
    _publishDevices();
  }

  @override
  Future<void> refreshDevices() async {
    _ensureStarted();
    _publishDevices();
  }

  @override
  Future<void> connect(MidiDevice device) async {
    _ensureStarted();
    if (!_availableDevices.contains(device)) {
      throw ArgumentError.value(device, 'device', 'Device is unavailable');
    }
    connectedDevice = device;
  }

  @override
  Future<void> disconnect() async {
    _ensureNotDisposed();
    connectedDevice = null;
  }

  @override
  Future<void> send(List<int> bytes) async {
    _ensureStarted();
    if (connectedDevice == null) {
      throw StateError('No MIDI device is connected');
    }
    _validateBytes(bytes);
    sentMessages.add(List<int>.unmodifiable(bytes));
  }

  void injectIncoming(List<int> bytes, {DateTime? timestamp}) {
    _ensureStarted();
    _validateBytes(bytes);
    _incomingController.add(
      MidiPacket(
        timestamp: timestamp ?? DateTime.now(),
        direction: MidiDirection.rx,
        bytes: bytes,
        deviceId: connectedDevice?.id,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _incomingController.close();
    await _devicesController.close();
  }

  void _publishDevices() {
    _devicesController.add(List<MidiDevice>.unmodifiable(_availableDevices));
  }

  void _ensureStarted() {
    _ensureNotDisposed();
    if (!_started) throw StateError('MIDI transport has not been started');
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('MIDI transport has been disposed');
  }

  void _validateBytes(List<int> bytes) {
    MidiPacket(
      timestamp: DateTime.now(),
      direction: MidiDirection.tx,
      bytes: bytes,
    );
  }
}
