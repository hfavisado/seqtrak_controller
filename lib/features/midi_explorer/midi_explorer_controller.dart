import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../midi/midi_capture.dart';
import '../../midi/midi_capture_exporter.dart';
import '../../midi/midi_codec.dart';
import '../../midi/midi_device.dart';
import '../../midi/midi_packet.dart';
import '../../midi/midi_transport.dart';

class MidiExplorerController extends ChangeNotifier {
  MidiExplorerController({
    required this.transport,
    required this.exporter,
    this.codec = const MidiCodec(),
    this.captureWriter = const MidiCaptureWriter(),
  });

  final MidiTransport transport;
  final MidiCaptureExporter exporter;
  final MidiCodec codec;
  final MidiCaptureWriter captureWriter;
  final List<MidiDevice> _devices = [];
  final List<MidiPacket> _packets = [];
  final List<MidiPacket> _capturePackets = [];

  StreamSubscription<List<MidiDevice>>? _deviceSubscription;
  StreamSubscription<MidiPacket>? _messageSubscription;
  MidiDevice? _connectedDevice;
  bool _isStarted = false;
  bool _isBusy = false;
  String? _error;
  DateTime? _captureStartedAt;
  bool _isRecording = false;
  bool _showRealtimeNoise = false;
  String? _lastExportPath;

  List<MidiDevice> get devices => List.unmodifiable(_devices);
  List<MidiPacket> get packets => List.unmodifiable(_packets);
  List<MidiPacket> get visiblePackets => List.unmodifiable(
    _showRealtimeNoise
        ? _packets
        : _packets.where((packet) => !_isRealtimeNoise(packet)),
  );
  MidiDevice? get connectedDevice => _connectedDevice;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get isRecording => _isRecording;
  bool get showRealtimeNoise => _showRealtimeNoise;
  int get recordedPacketCount => _capturePackets.length;
  String? get lastExportPath => _lastExportPath;

  String formatVisibleTraffic() => visiblePackets.map(formatPacket).join('\n');

  String formatPacket(MidiPacket packet) {
    final time = packet.timestamp;
    final timestamp =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    return '$timestamp ${packet.direction.name.toUpperCase()} '
        '${codec.formatHex(packet.bytes)}  ${codec.describe(packet.bytes)}';
  }

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
      _addPacket(packet);
      notifyListeners();
    });
    await _run(transport.start);
  }

  Future<void> refreshDevices() => _run(transport.refreshDevices);

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
    await _run(() async {
      final bytes = codec.parseHex(input);
      await sendProtocolBytes(bytes);
    });
  }

  Future<void> sendProtocolBytes(List<int> bytes) async {
    await transport.send(bytes);
    _addPacket(
      MidiPacket(
        timestamp: DateTime.now(),
        direction: MidiDirection.tx,
        bytes: bytes,
        deviceId: _connectedDevice?.id,
      ),
    );
    notifyListeners();
  }

  void startRecording() {
    _capturePackets.clear();
    _captureStartedAt = DateTime.now();
    _isRecording = true;
    _lastExportPath = null;
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  Future<void> exportCapture({String? notes}) async {
    if (_capturePackets.isEmpty) {
      _error = 'Record at least one MIDI message before exporting.';
      notifyListeners();
      return;
    }
    final startedAt = _captureStartedAt ?? _capturePackets.first.timestamp;
    final contents = captureWriter.write(
      _capturePackets,
      startedAt: startedAt,
      notes: notes,
    );
    final date = startedAt;
    final fileName =
        'seqtrak-${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}-capture.txt';
    await _run(() async {
      _lastExportPath = await exporter.export(
        contents: contents,
        fileName: fileName,
      );
    });
  }

  void clearLog() {
    _packets.clear();
    notifyListeners();
  }

  void setShowRealtimeNoise(bool value) {
    if (_showRealtimeNoise == value) return;
    _showRealtimeNoise = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _addPacket(MidiPacket packet) {
    _packets.add(packet);
    if (isRecording) _capturePackets.add(packet);
  }

  bool _isRealtimeNoise(MidiPacket packet) =>
      packet.bytes.length == 1 &&
      (packet.bytes.single == 0xf8 || packet.bytes.single == 0xfe);

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
