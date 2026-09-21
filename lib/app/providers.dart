import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/midi_explorer/midi_explorer_controller.dart';
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
