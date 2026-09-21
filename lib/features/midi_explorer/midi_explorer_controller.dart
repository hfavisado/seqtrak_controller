import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../midi/midi_codec.dart';
import '../../midi/midi_device.dart';
import '../../midi/midi_packet.dart';
import '../../midi/midi_transport.dart';

class MidiExplorerController extends ChangeNotifier {
  MidiExplorerController({
    required this.transport,
    this.codec = const MidiCodec(),
  });

  final MidiTransport transport;
  final MidiCodec codec;
  final List<MidiDevice> _devices = [];
  final List<MidiPacket> _packets = [];

  StreamSubscription<List<MidiDevice>>? _deviceSubscription;
  StreamSubscription<MidiPacket>? _messageSubscription;
  MidiDevice? _connectedDevice;
  bool _isStarted = false;
  bool _isBusy = false;
  String? _error;

  List<MidiDevice> get devices => List.unmodifiable(_devices);
  List<MidiPacket> get packets => List.unmodifiable(_packets);
  MidiDevice? get connectedDevice => _connectedDevice;
  bool get isBusy => _isBusy;
  String? get error => _error;

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    _deviceSubscription = transport.devices.listen((devices) {
      _devices
        ..clear()
        ..addAll(devices);
      notifyListeners();
    });
    _messageSubscription = transport.incomingMessages.listen((packet) {
      _packets.add(packet);
      notifyListeners();
    });
    await _run(transport.start);
  }

  Future<void> connect(MidiDevice device) async {
    await _run(() async {
      await transport.connect(device);
      _connectedDevice = device;
    });
  }

  Future<void> disconnect() async {
    await _run(() async {
      await transport.disconnect();
      _connectedDevice = null;
    });
  }

  Future<void> sendHex(String input) async {
    final bytes = codec.parseHex(input);
    await _run(() async {
      await transport.send(bytes);
      _packets.add(
        MidiPacket(
          timestamp: DateTime.now(),
          direction: MidiDirection.tx,
          bytes: bytes,
          deviceId: _connectedDevice?.id,
        ),
      );
    });
  }

  void clearLog() {
    _packets.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_deviceSubscription?.cancel());
    unawaited(_messageSubscription?.cancel());
    unawaited(transport.dispose());
    super.dispose();
  }
}
