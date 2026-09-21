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
- `lib/app/`: application root and theme

The current feature controller uses Flutter's `ChangeNotifier` as a temporary,
dependency-free state boundary. Riverpod remains the selected application state
tool and should own controller/repository lifetimes once it is added.

## Next boundary work

`FlutterMidiTransport` should be the only source file importing
`flutter_midi_command`. Plugin device objects and event shapes must be converted
to project-owned `MidiDevice` and `MidiPacket` values there.

SEQTRAK-specific decoding belongs in `lib/seqtrak/`, not in `MidiCodec`.
`MidiCodec` only describes standard MIDI message structure.
