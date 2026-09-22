import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../midi/midi_packet.dart';
import '../../midi/midi_transport.dart';
import '../../seqtrak/seqtrak_pattern_protocol.dart';
import '../../seqtrak/seqtrak_track.dart';
import '../../seqtrak/track_position_tracker.dart';
import '../midi_explorer/midi_explorer_controller.dart';

class PositionController extends ChangeNotifier {
  PositionController({required this.transport, required this.explorer}) {
    explorer.addListener(_connectionChanged);
    _subscription = transport.incomingMessages.listen(_onPacket);
  }

  final MidiTransport transport;
  final MidiExplorerController explorer;
  final TrackPositionTracker _tracker = TrackPositionTracker();
  late final StreamSubscription<MidiPacket> _subscription;
  String? _deviceId;

  TrackPosition? positionFor(SeqtrakTrack track) => _tracker.positionFor(track);
  int? selectedPatternFor(SeqtrakTrack track) =>
      _tracker.selectedPatternFor(track);
  int? stepCountFor(SeqtrakTrack track) => _tracker.stepCountFor(track);
  bool get isRunning => _tracker.isRunning;

  void _connectionChanged() {
    final id = explorer.connectedDevice?.id;
    if (id == _deviceId) return;
    _deviceId = id;
    _tracker.reset();
    notifyListeners();
    if (id != null) unawaited(_requestSelections(id));
  }

  Future<void> _requestSelections(String deviceId) async {
    for (final track in SeqtrakTrack.values) {
      if (_deviceId != deviceId) return;
      try {
        await explorer.sendProtocolBytes(
          _tracker.protocol.requestSelectedPattern(track),
        );
      } on Object {
        return;
      }
    }
  }

  Future<void> _requestStepCount(
    String deviceId,
    SeqtrakTrack track,
    int pattern,
  ) async {
    if (_deviceId != deviceId) return;
    try {
      await explorer.sendProtocolBytes(
        _tracker.protocol.requestStepCount(track, pattern),
      );
    } on Object {
      // A missing response leaves this track's position unknown.
    }
  }

  void _onPacket(MidiPacket packet) {
    if (_deviceId == null || packet.deviceId != _deviceId) return;
    final before = [
      for (final track in SeqtrakTrack.values) _tracker.positionFor(track),
    ];
    final wasRunning = _tracker.isRunning;
    final change = _tracker.accept(packet);
    if (change?.kind == PatternParameterKind.selectedPattern &&
        _tracker.stepCountFor(change!.track) == null) {
      unawaited(_requestStepCount(_deviceId!, change.track, change.pattern!));
    }
    final after = [
      for (final track in SeqtrakTrack.values) _tracker.positionFor(track),
    ];
    if (change != null ||
        wasRunning != _tracker.isRunning ||
        [
          for (var i = 0; i < before.length; i++)
            before[i]?.bar != after[i]?.bar ||
                before[i]?.beat != after[i]?.beat ||
                before[i]?.step != after[i]?.step,
        ].contains(true)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    explorer.removeListener(_connectionChanged);
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
