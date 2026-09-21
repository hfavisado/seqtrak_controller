# SEQTRAK Controller

## Current repository state (2026-09-21)

The counter template has been replaced by a runnable MIDI Explorer foundation.
The app currently uses `MockMidiTransport`; physical MIDI support and Riverpod
have not yet been wired in. Existing implementation includes transport/domain
models, raw RX/TX monitoring, generic MIDI decoding, validated hex transmission,
a capture writer, responsive UI, and unit/widget tests.

Until `FlutterMidiTransport` is implemented, use the mock UI with:

```bash
flutter run -d macos
```

No SEQTRAK-specific mapping is verified yet. Do not interpret example MIDI bytes
in the UI or tests as Yamaha protocol documentation.

## Project purpose

This project is a cross-platform control surface and editor for the Yamaha SEQTRAK.

Primary goals:

1. Run on macOS, Windows, Linux, Android, and iOS from a mostly shared codebase.
2. Communicate with a Yamaha SEQTRAK using MIDI.
3. Reflect hardware changes in the UI with minimal latency.
4. Send UI changes to the SEQTRAK immediately.
5. Maintain a synchronized representation of SEQTRAK state.
6. Provide a responsive UI suitable for phones, tablets, laptops, and desktop displays.
7. Make the MIDI/protocol implementation independent of the UI.
8. Document discovered SEQTRAK MIDI behavior so protocol knowledge is not buried in source code.

Web support is optional and must not compromise the native architecture.

## Current development priority

Do NOT begin by implementing the complete control surface.

The initial milestone is a MIDI Explorer capable of:

* enumerating MIDI devices
* connecting/disconnecting
* displaying connection status
* receiving MIDI
* displaying raw MIDI bytes
* decoding known MIDI messages
* sending arbitrary MIDI messages for testing
* timestamping MIDI traffic
* distinguishing TX and RX
* recording MIDI sessions
* exporting recorded sessions to a human-readable file

The MIDI Explorer will be used to reverse engineer and verify SEQTRAK behavior before higher-level controls are implemented.

## Technology

Application framework:

* Flutter
* Dart

Initial MIDI implementation:

* flutter_midi_command

State management:

* Riverpod

Target platforms, in initial priority order:

1. macOS
2. Windows
3. Linux
4. Android
5. iOS
6. Web, optional

Do not introduce platform-specific code outside the transport/platform layer unless necessary.

## Architectural principles

The project must maintain strict separation between:

1. UI
2. application/domain state
3. SEQTRAK protocol
4. MIDI transport

The UI MUST NOT directly send or parse raw MIDI.

A widget must never contain:

* MIDI CC numbers
* SysEx byte sequences
* Yamaha protocol addresses
* MIDI device discovery logic
* SEQTRAK protocol parsing

The desired flow is:

UI
↓
ViewModel / Controller
↓
SeqtrakRepository
↓
SeqtrakProtocol
↓
MidiTransport
↓
SEQTRAK

Incoming communication follows the reverse direction:

SEQTRAK
↓
MidiTransport
↓
SeqtrakProtocol
↓
SeqtrakRepository
↓
application state
↓
UI

The repository is the application's source of truth for current SEQTRAK state.

## Suggested source structure

Use approximately:

lib/
app/
app.dart

midi/
midi_transport.dart
midi_device.dart
midi_packet.dart
flutter_midi_transport.dart

seqtrak/
seqtrak_protocol.dart
seqtrak_repository.dart
seqtrak_state.dart
seqtrak_parameter.dart
messages/

features/
midi_explorer/
midi_explorer_screen.dart
midi_explorer_controller.dart
widgets/

```
mixer/
synth/
sampler/
effects/
sequencer/
```

ui/
core/
controls/
layout/

test/
midi/
seqtrak/
features/

docs/
architecture.md
midi-protocol.md
midi-research-log.md
midi-captures/

Do not create abstraction layers merely for architectural purity. Add abstractions when they isolate a real responsibility or make testing/platform replacement easier.

## MIDI transport

All MIDI I/O must go through an interface similar to:

```dart
abstract interface class MidiTransport {
  Stream<MidiPacket> get incomingMessages;
  Stream<List<MidiDevice>> get devices;

  Future<void> start();
  Future<void> connect(MidiDevice device);
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
  Future<void> dispose();
}
```

The rest of the application must not depend directly on `flutter_midi_command`.

`FlutterMidiTransport` implements this interface.

Also provide a `MockMidiTransport` for tests and UI development without physical hardware.

This allows the MIDI library to be replaced later without rewriting the application.

## MIDI packet representation

Raw MIDI traffic should be represented explicitly.

Example:

```dart
enum MidiDirection {
  rx,
  tx,
}

class MidiPacket {
  final DateTime timestamp;
  final MidiDirection direction;
  final List<int> bytes;
  final String? deviceId;
}
```

Do not discard raw MIDI bytes after parsing.

They are important for debugging and protocol research.

## SEQTRAK protocol layer

`SeqtrakProtocol` translates between raw MIDI and meaningful SEQTRAK operations.

Examples:

Raw:

```
B0 4A 64
```

Application representation:

```
ParameterChange(
  track: ...,
  parameter: SeqtrakParameter.cutoff,
  value: 100,
)
```

And in the other direction:

```
setParameter(
  track: 3,
  parameter: SeqtrakParameter.cutoff,
  value: 100,
)
```

becomes the appropriate MIDI message.

Protocol code must be testable without Flutter and without a physical SEQTRAK.

Prefer pure Dart for protocol logic.

## Parameter definitions

Do not scatter parameter information throughout source code.

Create centralized parameter definitions.

A parameter definition may eventually contain:

* stable internal identifier
* human-readable name
* minimum value
* maximum value
* default value if known
* MIDI representation
* CC number if applicable
* SysEx address if applicable
* track applicability
* scaling/conversion
* display formatting
* whether messages have been experimentally verified
* documentation source

Example conceptual model:

```dart
enum SeqtrakParameter {
  volume,
  pan,
  cutoff,
  resonance,
  attack,
  decay,
  sustain,
  release,
}
```

Do not assume an undocumented MIDI mapping is correct.

Mark protocol knowledge as either:

* documented
* experimentally verified
* suspected
* unknown

## Bidirectional synchronization

Every state change has an origin.

At minimum:

```dart
enum ChangeOrigin {
  userInterface,
  device,
  initialization,
}
```

A UI-originated change:

1. updates application state
2. generates the appropriate MIDI message
3. sends the message to SEQTRAK

A device-originated change:

1. parses incoming MIDI
2. updates application state
3. updates listening UI
4. MUST NOT blindly retransmit the same change

Prevent MIDI feedback loops.

Do not assume that the value sent to the device is necessarily the final authoritative value.

If SEQTRAK reports a resulting value, prefer the device-reported state.

## Responsiveness and performance

MIDI handling must be event-driven.

Do not poll the device merely to update the UI unless the SEQTRAK protocol specifically requires polling.

Do not rebuild an entire screen because one parameter changed.

State subscriptions should be granular enough that changing one parameter primarily rebuilds widgets dependent on that parameter.

Do not debounce ordinary incoming MIDI control changes unless measurements demonstrate that it is necessary.

Do not introduce artificial latency into parameter changes.

## Responsive UI

The application must support:

* phone portrait
* phone landscape
* tablet
* desktop

Avoid layouts based on a specific device resolution.

Use Flutter responsive layout mechanisms such as:

* LayoutBuilder
* MediaQuery
* flexible layouts
* reusable widgets

Prefer capability/layout breakpoints rather than checking for specific operating systems.

The same control should normally be reusable at different sizes.

## MIDI Explorer

The MIDI Explorer is the first major feature.

It should contain:

### Device section

* list available MIDI devices
* refresh/rescan
* connect
* disconnect
* clearly display current connection

### MIDI monitor

Display messages similar to:

```
12:43:21.042 RX  B0 4A 64
12:43:21.105 RX  B0 4A 63
12:43:23.781 TX  F0 43 ... F7
```

Where possible also display decoded information:

```
RX  B0 4A 64    CC ch1 74 = 100
```

and later:

```
RX  ...          Track 3 Cutoff = 100
```

Never replace the raw bytes with decoded information. Show or retain both.

### Filtering

Eventually support filtering by:

* RX / TX
* MIDI channel
* message type
* SysEx
* CC
* note
* parameter
* text

Filtering is not required for the very first implementation.

### Sending messages

Provide a development/debug interface for manually sending MIDI bytes.

Input may use hexadecimal notation:

```
F0 43 ... F7
```

Validate input before sending.

Do not allow malformed input to crash the application.

## MIDI recording

The MIDI Explorer must be able to record MIDI activity.

Recording means capturing ordered `MidiPacket` events with timestamps and direction.

Use a human-readable capture format during development.

Recommended format:

```text
# SEQTRAK MIDI Capture
# Date: 2026-09-21
# Notes: Turned track 1 SOUND DESIGN knob slowly clockwise

+0.000000 RX B0 4A 20
+0.041221 RX B0 4A 21
+0.082914 RX B0 4A 22
+0.125107 RX B0 4A 23
```

The timestamp should preferably represent elapsed monotonic time from capture start.

Do not rely solely on wall-clock timestamps for timing analysis.

A later structured format such as JSON may be added if useful.

Keep capture parsing/writing separate from UI code.

## Protocol research workflow

When investigating an unknown SEQTRAK control:

1. Start MIDI recording.
2. Record the initial hardware state if known.
3. Perform exactly ONE type of action.
4. Stop recording.
5. Save the capture.
6. Describe exactly what physical action was performed.
7. Compare the capture with previous captures.
8. Form a hypothesis about the MIDI mapping.
9. Test the hypothesis by transmitting the suspected command.
10. Record whether SEQTRAK responded as expected.
11. Update protocol documentation.

Example experiment:

```
Experiment:
Track 1 volume

Procedure:
Select track 1.
Move volume from minimum to maximum slowly.
Do not touch any other control.

Observation:
<recorded MIDI>

Hypothesis:
CC xx controls track volume.

Verification:
Send values 0, 64, and 127.

Result:
...
```

Never promote a hypothesis to "verified" merely because one capture appears to match it.

## Protocol documentation

Maintain:

```
docs/midi-protocol.md
```

This is the human-readable source of knowledge about SEQTRAK communication.

Suggested table:

| Function      | Message | Direction | Status  | Source/Experiment |
| ------------- | ------- | --------- | ------- | ----------------- |
| Track volume  | TBD     | TX/RX     | unknown |                   |
| Filter cutoff | TBD     | TX/RX     | unknown |                   |
| Resonance     | TBD     | TX/RX     | unknown |                   |

Status values:

* documented
* verified
* suspected
* unknown

When adding a discovered protocol mapping, update documentation and tests in the same change.

## Research log

Maintain:

```
docs/midi-research-log.md
```

Use this for chronological experimental notes.

Example:

```text
## 2026-09-21 - Track 1 volume

Setup:
- SEQTRAK connected through USB
- macOS
- firmware: unknown

Action:
Moved track 1 volume from minimum to maximum.

Capture:
docs/midi-captures/2026-09-21-track1-volume.txt

Observations:
...

Conclusion:
...

Confidence:
...
```

Raw experiments belong here rather than in source-code comments.

## Tests

Protocol behavior should have unit tests.

Example:

```dart
test('decodes track volume message', () {
  final message = protocol.decode([...]);

  expect(message, ...);
});
```

And:

```dart
test('encodes track volume message', () {
  final bytes = protocol.encode(...);

  expect(bytes, [...]);
});
```

Every experimentally verified MIDI mapping should eventually have a regression test.

Tests must not require physical SEQTRAK hardware unless explicitly categorized as integration/hardware tests.

## Mock device

Implement a mock MIDI transport early.

It should allow tests to:

* inject incoming MIDI
* inspect outgoing MIDI
* simulate connection/disconnection
* simulate device discovery

Example conceptual usage:

```dart
final midi = MockMidiTransport();

midi.injectIncoming([0xB0, 0x4A, 0x64]);

expect(...);

expect(midi.sentMessages, ...);
```

This is important because agents and CI systems normally do not have access to the physical SEQTRAK.

## Agent behavior

Before making significant architectural changes:

1. Read this file.
2. Inspect existing architecture.
3. Inspect relevant tests.
4. Explain why an architectural change is needed.
5. Prefer extending existing abstractions over creating parallel systems.

Do not silently replace architectural decisions.

Do not couple UI widgets directly to MIDI libraries.

Do not duplicate protocol constants.

Do not guess undocumented SEQTRAK protocol values.

If protocol information is unknown, represent it as unknown and request or create an experiment to determine it.

When implementing a feature involving MIDI:

1. identify protocol requirement
2. check protocol documentation
3. add/update protocol representation
4. add tests
5. update repository/state behavior
6. implement UI last

## Working with a human developer new to Flutter

The project owner is experienced with software/technical systems but is new to Flutter/Dart.

When proposing Flutter-specific code:

* explain unfamiliar Flutter/Dart concepts briefly
* prefer conventional Flutter patterns
* avoid clever language tricks
* explain where new files belong
* provide commands needed to generate/build/test code
* mention when code generation must be rerun
* do not assume familiarity with widget lifecycle or Flutter state management

Do not over-explain general programming concepts unless requested.

## Code quality

Before considering a change complete, run when applicable:

```bash
dart format .
flutter analyze
flutter test
```

All should pass.

Do not suppress analyzer warnings merely to make checks green unless the warning is genuinely inappropriate.

Prefer small, reviewable commits.

## Dependency policy

Before adding a dependency:

1. determine whether Flutter/Dart already provides the required functionality
2. check whether the package is actively maintained
3. check supported target platforms
4. avoid introducing overlapping libraries for the same responsibility
5. isolate important third-party packages behind project-owned interfaces when replacement could reasonably become necessary

In particular, the MIDI library must remain behind `MidiTransport`.

## Initial milestones

### Milestone 0 - Development environment

* Flutter project builds
* macOS application launches
* tests run
* analyzer passes

### Milestone 1 - MIDI transport

* enumerate MIDI devices
* connect to SEQTRAK
* receive raw MIDI
* send raw MIDI
* disconnect cleanly

### Milestone 2 - MIDI Explorer

* real-time RX/TX log
* hexadecimal representation
* basic MIDI decoding
* manual MIDI transmission
* start/stop recording
* export capture

### Milestone 3 - SEQTRAK protocol research

Determine and document enough protocol behavior for a small control surface.

Start with a few easily observable parameters.

### Milestone 4 - First bidirectional control

Implement ONE parameter end-to-end:

```
physical SEQTRAK control
    ↓
MIDI
    ↓
application state
    ↓
Flutter control
```

and:

```
Flutter control
    ↓
application state
    ↓
MIDI
    ↓
SEQTRAK
```

Verify that feedback loops do not occur.

### Milestone 5 - Control framework

Create reusable:

* knob
* fader
* toggle/button
* parameter display
* track selector

Do this only after at least one parameter works end-to-end.

### Milestone 6 - Functional screens

Add features incrementally:

* mixer
* sound/synth controls
* effects
* sampler
* sequencer

### Milestone 7 - Additional platforms

Validate and fix:

* Windows
* Linux
* Android
* iOS

Add BLE MIDI after USB MIDI is stable.

## Definition of done

A feature is not complete merely because its UI works.

For protocol-related features, completion normally requires:

* architecture respected
* protocol mapping documented
* MIDI behavior tested
* state synchronization tested
* no obvious MIDI feedback loop
* analyzer passes
* tests pass
* relevant documentation updated
