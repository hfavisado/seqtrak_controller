# Architecture

## Boundaries

The application uses four boundaries:

```text
Flutter UI
  -> feature controller / Riverpod provider
  -> SeqtrakRepository and SeqtrakProtocol
  -> MidiTransport
  -> platform MIDI implementation
```

Incoming events travel in the reverse direction. Raw `MidiPacket` values are
retained even when a message can be decoded.

## Implemented

- `lib/midi/`: device and packet models, transport interface, mock transport,
  generic codec, and capture serialization
- `lib/features/midi_explorer/`: feature controller and responsive screen
- `lib/features/control_surface/`: touch-first landing screen with one
  provisional position readout per track, driven by selected pattern, step
  count, and transport clock state
- `lib/app/`: application root and theme
- `lib/seqtrak/`: Yamaha-documented parameter definitions and pure-Dart protocol
  encoding/decoding

The feature controller uses Flutter's `ChangeNotifier` for granular UI updates,
while Riverpod creates and owns the controller, transport, and export service.

## Next boundary work

`FlutterMidiTransport` is the only source file importing
`flutter_midi_command`. It converts plugin device objects and raw packet events
to project-owned `MidiDevice` and `MidiPacket` values. Native USB MIDI is enabled;
the optional direct BLE transport is not yet configured.

SEQTRAK-specific decoding belongs in `lib/seqtrak/`, not in `MidiCodec`.
`MidiCodec` only describes standard MIDI message structure.
