# SEQTRAK Controller

A cross-platform, touch-capable display and focused control surface for the
Yamaha SEQTRAK. It prioritizes frequently used features that are cumbersome
on the device. The central bar / beat / step display is a core part of the
interface. MIDI Explorer remains available for protocol research.

## Current status

The repository contains the first runnable MIDI Explorer foundation:

- a platform-independent `MidiTransport` interface
- a `MockMidiTransport` for development and automated tests
- MIDI device connection state
- raw RX/TX traffic display with timestamps
- timing-clock (`F8`) and active-sensing (`FE`) messages hidden from the monitor
  by default, but retained in recordings
- generic MIDI message descriptions that retain the raw bytes
- centralized Yamaha-documented channel and CC definitions with pure-Dart
  encoding and decoding
- validated hexadecimal message entry and sending
- a human-readable MIDI capture writer
- responsive narrow and desktop layouts

The app now starts on an 11-track position view. Connect to SEQTRAK in MIDI
Explorer using the cable icon. The app requests each track's selected pattern
and step count, then combines that state with MIDI Start and Clock to estimate
its own looping bar / beat / step. Unknown pattern state stays blank. The step
always uses two digits and the readouts use a monospace font. Pattern-switch
alignment and song/scene behavior still need hardware verification.
`FlutterMidiTransport` supports native USB MIDI.
Direct BLE is deliberately disabled until USB MIDI is verified. No undocumented
SEQTRAK mapping is treated as known.

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

Connect a MIDI device, enter complete MIDI bytes such as `90 3C 64`, and press
**Send**. Sent traffic appears in the monitor. Recordings can be annotated and
exported through the desktop save dialog. In MIDI Explorer, select traffic text
directly or press **Copy traffic** to copy the entire visible log for sharing.
Enable **Show clock/sensing** first if the timing messages are relevant to the
capture you want to paste.

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

1. Test device enumeration, connect/disconnect, RX, and TX on macOS hardware.
2. Determine whether MIDI supplies reliable bar / beat / step position, and
   document the origin, reset behavior, and time-signature assumptions.
3. Identify the few frequent tasks that are difficult on the hardware.
4. Verify their MIDI behavior and add one useful bidirectional control.

Web remains optional; native MIDI reliability takes priority.
