import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart' as plugin;

import 'midi_device.dart';
import 'midi_packet.dart';
import 'midi_transport.dart';

/// The only application layer that depends on flutter_midi_command.
class FlutterMidiTransport implements MidiTransport {
  FlutterMidiTransport({plugin.MidiCommand? midi})
    : _midi = midi ?? plugin.MidiCommand();

  final plugin.MidiCommand _midi;
  final _incomingController = StreamController<MidiPacket>.broadcast();
  final _devicesController = StreamController<List<MidiDevice>>.broadcast();
  final Map<String, plugin.MidiDevice> _pluginDevices = {};

  StreamSubscription<plugin.MidiPacket>? _packetSubscription;
  StreamSubscription<plugin.MidiSetupChange>? _setupSubscription;
  MidiDevice? _connectedDevice;
  bool _started = false;
  bool _disposed = false;

  @override
  Stream<MidiPacket> get incomingMessages => _incomingController.stream;

  @override
  Stream<List<MidiDevice>> get devices => _devicesController.stream;

  @override
  Future<void> start() async {
    _ensureNotDisposed();
    if (_started) return;
    _started = true;

    // USB/native MIDI is the first milestone. Direct BLE is intentionally not
    // configured until the wired transport has been verified.
    _midi.configureBleTransport(null);
    _setupSubscription = _midi.onMidiSetupChanged?.listen((_) {
      unawaited(refreshDevices());
    });
    _packetSubscription = _midi.onMidiPacketReceived?.listen((packet) {
      _incomingController.add(
        MidiPacket(
          timestamp: DateTime.now(),
          direction: MidiDirection.rx,
          bytes: packet.data,
          deviceId: packet.device.id,
        ),
      );
    });
    await refreshDevices();
  }

  @override
  Future<void> refreshDevices() async {
    _ensureStarted();
    final pluginDevices = await _midi.devices ?? const <plugin.MidiDevice>[];
    _pluginDevices
      ..clear()
      ..addEntries(pluginDevices.map((device) => MapEntry(device.id, device)));
    _devicesController.add(
      List.unmodifiable(pluginDevices.map(_toDomainDevice)),
    );
  }

  @override
  Future<void> connect(MidiDevice device) async {
    _ensureStarted();
    final pluginDevice = _pluginDevices[device.id];
    if (pluginDevice == null) {
      throw StateError('MIDI device is no longer available: ${device.name}');
    }
    if (_connectedDevice != null && _connectedDevice != device) {
      await disconnect();
    }
    await _midi.connectToDevice(pluginDevice);
    _connectedDevice = device;
  }

  @override
  Future<void> disconnect() async {
    _ensureNotDisposed();
    final connected = _connectedDevice;
    if (connected == null) return;
    final pluginDevice = _pluginDevices[connected.id];
    if (pluginDevice != null) _midi.disconnectDevice(pluginDevice);
    _connectedDevice = null;
  }

  @override
  Future<void> send(List<int> bytes) async {
    _ensureStarted();
    final connected = _connectedDevice;
    if (connected == null) throw StateError('No MIDI device is connected');
    _validateBytes(bytes);
    await _midi.sendDataAwaitingDelivery(
      Uint8List.fromList(bytes),
      deviceId: connected.id,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _packetSubscription?.cancel();
    await _setupSubscription?.cancel();
    _midi.teardown();
    _midi.dispose();
    await _incomingController.close();
    await _devicesController.close();
  }

  MidiDevice _toDomainDevice(plugin.MidiDevice device) {
    final hasInput = device.inputPorts.isNotEmpty;
    final hasOutput = device.outputPorts.isNotEmpty;
    final type = hasInput && hasOutput
        ? MidiDeviceType.bidirectional
        : hasInput
        ? MidiDeviceType.input
        : MidiDeviceType.output;
    return MidiDevice(id: device.id, name: device.name, type: type);
  }

  void _validateBytes(List<int> bytes) {
    MidiPacket(
      timestamp: DateTime.now(),
      direction: MidiDirection.tx,
      bytes: bytes,
    );
  }

  void _ensureStarted() {
    _ensureNotDisposed();
    if (!_started) throw StateError('MIDI transport has not been started');
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('MIDI transport has been disposed');
  }
}
