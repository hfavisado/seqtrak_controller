# SEQTRAK Controller

A cross-platform Flutter control surface and MIDI research tool for the Yamaha
SEQTRAK. Development currently focuses on the MIDI Explorer needed to observe,
record, and test the device protocol before building the full control surface.

## Current status

The repository contains the first runnable MIDI Explorer foundation:

- a platform-independent `MidiTransport` interface
- a `MockMidiTransport` for development and automated tests
- MIDI device connection state
- raw RX/TX traffic display with timestamps
- generic MIDI message descriptions that retain the raw bytes
- validated hexadecimal message entry and sending
- a human-readable MIDI capture writer
- responsive narrow and desktop layouts

The app currently starts with the mock transport. It does **not** connect to
physical MIDI hardware yet, and no undocumented SEQTRAK mapping is treated as
known.

## Run the project

Install a current Flutter SDK with desktop support, then run:

```sh
flutter pub get
flutter run -d macos
```

Useful development checks:

```sh
dart format .
flutter analyze
flutter test
```

To exercise the mock explorer, connect to **Mock SEQTRAK**, enter complete MIDI
bytes such as `90 3C 64`, and press **Send**. Sent traffic appears in the monitor.

## Architecture

The project keeps Flutter UI, application state, SEQTRAK protocol logic, and
MIDI I/O separate. Widgets call the MIDI Explorer controller; they never import
a MIDI plugin or contain protocol constants.

```text
UI -> controller -> repository/protocol (next milestone) -> MidiTransport
```

See [Architecture](docs/architecture.md),
[MIDI protocol](docs/midi-protocol.md), and
[research log](docs/midi-research-log.md).

## Near-term roadmap

1. Add Riverpod and move controller ownership into providers.
2. Implement `FlutterMidiTransport` behind the existing interface.
3. Test device enumeration, connect/disconnect, RX, and TX on macOS.
4. Add start/stop recording and desktop/mobile capture export UI.
5. Record one-control-at-a-time experiments and only then add verified SEQTRAK
   mappings, tests, repository state, and the first bidirectional control.

Web remains optional; native MIDI reliability takes priority.
