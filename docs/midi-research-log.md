# MIDI Research Log

Use this file for chronological experiment results. Store raw captures under
`docs/midi-captures/`.

## 2026-09-22 - Bar length set to 1 (user-supplied capture)

Action: Set bar length to 1. Track selection, connection type, firmware, prior
length, and exact capture date were not supplied.

Capture: `docs/midi-captures/2026-09-22-bar-length-1-user-paste.txt`.

Observations: A parameter change at address `30 57 16` carries `00 10`, or
16 steps. Yamaha's Data List identifies this as Pattern 1 step count for part
7 (SYNTH 1). Messages at `01 10 39` through `01 1A 39` change from `05 05`
to `01 01`; their meaning is not established by the published parameter table.
The `01 10 2B` and `01 10 2E` messages are likewise unmapped here.

Conclusion: The documented pattern-length parameter appears in the capture
with a one-bar value. This capture does not identify the live playhead bar or
a loop boundary. The next capture below compares a two-bar setting.

## 2026-09-22 - Bar length set to 2 (user-supplied capture)

Action: Pressed BAR LENGTH once, resulting in 2 bars. Track selection,
connection type, firmware, starting length, and exact capture date were not
supplied.

Capture: `docs/midi-captures/2026-09-22-bar-length-2-user-paste.txt`.

Observations: The documented `30 57 16` Pattern 1 step-count message now
carries `00 20` (32 steps), versus `00 10` (16 steps) in the one-bar capture.
The `01 10 2E` message carries `0D` here, versus `01` after the one-bar change.
Messages at `01 10 39`–`01 1A 39` again change from `05 05` to `01 01` in
both captures, so they do not distinguish the two lengths.

Conclusion: The outgoing `30 57 16` parameter matches both observed length
settings and agrees with Yamaha's published mapping. This supports reading
SYNTH 1 Pattern 1 length when the device sends this message. The meaning of
`01 10 2E` remains unknown. Neither capture reports the current playhead bar
or shows when the pattern loops.

## Experiment template

```text
## YYYY-MM-DD - Control name

Setup:
- connection type and operating system
- SEQTRAK firmware version

Action:
- one physical action only

Capture:
- docs/midi-captures/YYYY-MM-DD-description.txt

Observations:
- raw-message patterns and changes

Hypothesis:
- suspected mapping, if any

Verification:
- transmitted test values and device response

Conclusion:
- result and confidence
```
