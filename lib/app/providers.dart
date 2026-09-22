import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/midi_explorer/midi_explorer_controller.dart';
import '../features/control_surface/position_controller.dart';
import '../midi/flutter_midi_transport.dart';
import '../midi/midi_capture_exporter.dart';
import '../midi/midi_transport.dart';

final midiTransportProvider = Provider<MidiTransport>((ref) {
  return FlutterMidiTransport();
});

final midiCaptureExporterProvider = Provider<MidiCaptureExporter>((ref) {
  return const FileSelectorMidiCaptureExporter();
});

final midiExplorerControllerProvider = Provider<MidiExplorerController>((ref) {
  final controller = MidiExplorerController(
    transport: ref.watch(midiTransportProvider),
    exporter: ref.watch(midiCaptureExporterProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final positionControllerProvider = Provider<PositionController>((ref) {
  final controller = PositionController(
    transport: ref.watch(midiTransportProvider),
    explorer: ref.watch(midiExplorerControllerProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
