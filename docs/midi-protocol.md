# SEQTRAK MIDI Protocol

This document distinguishes Yamaha-published behavior from behavior confirmed
on hardware. The source for the tables below is the official
[SEQTRAK User Guide, OS V2.00](https://manual.yamaha.com/mi/de/seqtrak/en/SEQTRAK_user_guide_En_D0_018.html),
sections 18.2 and 18.3.

Status values:

- `documented`: explicitly published by Yamaha but not yet tested here
- `verified`: confirmed with a focused hardware test and capture
- `suspected`: inferred from observations
- `unknown`: no reliable mapping yet

## Song position and bar / beat / step

The ring display also offers local step audition. Yamaha's Data List, MIDI Data
Format §3-1-1 and §3-1-2, documents incoming Note On (`9n note velocity`) and
Note Off (`8n note 0`) on channels 1–11. Tapping a step sends a short Note On /
Note Off pair on that track's channel, using its locally selected MIDI note,
velocity, and gate duration. The default note 60 is a generic audition choice,
not a verified sound or sample mapping. This does not read, toggle, or write
SEQTRAK pattern step contents; that protocol remains to be researched. In
particular, synth, DX, sampler, and DrumKit steps may need multiple notes and
additional per-step sound or effect parameters.

Yamaha's [SEQTRAK Data List](https://usa.yamaha.com/files/download/other_assets/5/2226075/SEQTRAK_data_list_En_D0.pdf),
MIDI Data Format and MIDI Implementation Chart (pages 111 and 162), specifies
outgoing Timing Clock (`F8`) when Clock Out is enabled and the internal clock
is in use. Outgoing sequencer control includes Start (`FA`) and Stop (`FC`) when
enabled. The chart marks Song Position Pointer (`F2`) unsupported for both
transmit and receive; the transmit flow does not list Continue (`FB`). No
documented message reports the currently playing bar or a loop boundary.

Clock alone cannot identify the current bar within a repeating pattern: it
provides timing but no pattern length or loop reset. Project Track General
parameters provide selected pattern and step lengths independently for each
track. The control surface uses these to calculate a provisional position for
each track after MIDI Start. Pattern-switch phase and song/scene behavior still
need hardware validation.

The Data List's Project Track General table documents `30 5p 16`/`17` as
Pattern 1 step count (two 7-bit data bytes, 1–128 steps), with further pairs
at `18`–`21` for Patterns 2–6. Part `p=7` is SYNTH 1. User-supplied captures
after setting bar length to 1 and 2 include `30 57 16 00 10` (16 steps) and
`30 57 16 00 20` (32 steps), respectively. These agree with Yamaha's SYNTH 1
Pattern 1 mapping. They report that pattern's length, not the current playhead
bar or a loop boundary. The undocumented `01 10 2E` messages also differ
(`01` versus `0D`), but their meaning remains unknown. See the
[research log](midi-research-log.md) for both captures.

For each part `p=0...10`, `30 5p 0F` selects Pattern 1–6 (data `00...05`).
Offsets `16`, `18`, `1A`, `1C`, `1E`, and `20` hold the corresponding pattern's
step count as two 7-bit bytes. On connection the app requests each selected
pattern, then requests that pattern's step count. Incoming parameter changes
update the stored state. An RX Start (`FA`) anchors the shared clock at step
zero; six Timing Clock (`F8`) ticks advance one step. Each track's step index
wraps at its own selected pattern length, and its bar/beat/step are calculated
from that index using 16 steps per bar and four steps per beat. Without a known
selected pattern, step count, or Start, that track displays `--`. This is an
estimate based on documented values and must be compared with hardware,
especially across pattern switches and song/scene playback.

| Function | Message/source | Direction | Status |
| --- | --- | --- | --- |
| Beat / step timing | Start and Clock, when outgoing settings enable them | From SEQTRAK | documented, not hardware verified |
| Selected pattern per track | `30 5p 0F`, values `00`–`05` | From SEQTRAK | documented, not hardware verified |
| Pattern length per track | `30 5p 16`–`20`, 1–128 steps | From SEQTRAK | documented; SYNTH 1 Pattern 1 observed at 16 and 32 steps |
| Current bar in active pattern | Calculated from Start, Clock, selection, and step count | Application estimate | provisional |

## MIDI channels

| Channel | Track | Status |
| ---: | --- | --- |
| 1 | KICK | documented |
| 2 | SNARE | documented |
| 3 | CLAP | documented |
| 4 | HAT 1 | documented |
| 5 | HAT 2 | documented |
| 6 | PERC 1 | documented |
| 7 | PERC 2 | documented |
| 8 | SYNTH 1 | documented |
| 9 | SYNTH 2 | documented |
| 10 | DX | documented |
| 11 | SAMPLER | documented |

## Sound-design control changes

| Function | CC | Channels | Values | Direction | Status |
| --- | ---: | --- | --- | --- | --- |
| Track Volume | 7 | 1–11 | 0–127 | TX/RX | documented |
| Track Pan | 10 | 1–11 | 1–127 | TX/RX | documented |
| Drum Pitch | 25 | 1–7 | 40–88 | TX/RX | documented |
| Mono/Poly/Chord | 26 | 8–10 | 0=Mono, 1=Poly, 2=Chord | TX/RX | documented |
| Attack Time | 73 | 1–11 | 0–127 | TX/RX | documented |
| Decay/Release Time | 75 | 1–11 | 0–127 | TX/RX | documented |
| Filter Cutoff | 74 | 1–11 | 0–127 | TX/RX | documented |
| Filter Resonance | 71 | 1–11 | 0–127 | TX/RX | documented |
| Reverb Send | 91 | 1–11 | 0–127 | TX/RX | documented |
| Delay Send | 94 | 1–11 | 0–127 | TX/RX | documented |
| EQ High Gain | 20 | 1–11 | 40–88 | TX/RX | documented |
| EQ Low Gain | 21 | 1–11 | 40–88 | TX/RX | documented |
| Portamento Time | 5 | 8–10 | 0–127; 0=Off | TX/RX | documented |
| Portamento Switch | 65 | 8–10 | 0=Off, 1=On | TX/RX | documented |
| ARP Type | 27 | 8–10 | 0–16; 0=Off | TX/RX | documented |
| ARP Gate | 28 | 8–10 | 0–127 | TX/RX | documented |
| ARP Speed | 29 | 8–10 | 0–9 | TX/RX | documented |
| FM Algorithm | 116 | 10 | 0–127 | TX/RX | documented |
| FM Modulation Amount | 117 | 10 | 0–127 | TX/RX | documented |
| FM Modulator Frequency | 118 | 10 | 0–127 | TX/RX | documented |
| FM Modulator Feedback | 119 | 10 | 0–127 | TX/RX | documented |

Yamaha notes that Portamento Time applies only when the synth or DX track is
mono.

## Effect control changes

| Function | CC | Channels | Values | Direction | Status |
| --- | ---: | --- | --- | --- | --- |
| Master Effect 1 Assigned Parameter 1 | 102 | 1 | 0–127 | TX/RX | documented |
| Master Effect 1 Assigned Parameter 2 | 103 | 1 | 0–127 | TX/RX | documented |
| Master Effect 1 Assigned Parameter 3 | 104 | 1 | 0–127 | TX/RX | documented |
| Master Effect 2 Assigned Parameter | 105 | 1 | 0–127 | TX/RX | documented |
| Master Effect 3 Assigned Parameter | 106 | 1 | 0–127 | TX/RX | documented |
| Single Effect Assigned Parameter 1 | 107 | 1–11 | 0–127 | TX/RX | documented |
| Single Effect Assigned Parameter 2 | 108 | 1–11 | 0–127 | TX/RX | documented |
| Single Effect Assigned Parameter 3 | 109 | 1–11 | 0–127 | TX/RX | documented |
| Send Reverb Assigned Parameter 1 | 110 | 1 | 0–127 | TX/RX | documented |
| Send Reverb Assigned Parameter 2 | 111 | 1 | 0–127 | TX/RX | documented |
| Send Reverb Assigned Parameter 3 | 112 | 1 | 0–127 | TX/RX | documented |
| Send Delay Assigned Parameter 1 | 113 | 1 | 0–127 | TX/RX | documented |
| Send Delay Assigned Parameter 2 | 114 | 1 | 0–127 | TX/RX | documented |
| Send Delay Assigned Parameter 3 | 115 | 1 | 0–127 | TX/RX | documented |

## Receive-only control changes

| Function | CC | Channels | Values | Direction | Status |
| --- | ---: | --- | --- | --- | --- |
| Mute | 23 | 1–11 | 0–63=Off, 64–127=On | To SEQTRAK only | documented |
| Solo | 24 | 1–11 | 0=Off, 1–11=Track 1–11 | To SEQTRAK only | documented |
| Damper Pedal | 64 | 8–11 | 0–127 | To SEQTRAK only | documented |
| Sostenuto | 66 | 8, 9, 11 | 0–63=Off, 64–127=On | To SEQTRAK only | documented |
| Expression Control | 11 | 1–11 | 0–127 | To SEQTRAK only | documented |

“Receive only” describes the SEQTRAK: the application may send these messages
to it, but should not expect the device to transmit them.

## Implementation

Centralized definitions live in `lib/seqtrak/seqtrak_parameter.dart` and channel
assignments in `lib/seqtrak/seqtrak_track.dart`. `SeqtrakProtocol` performs pure
Dart CC encoding and decoding without depending on Flutter or a physical device.

Hardware verification should add a capture and research-log entry, then change
only the tested definition from `documented` to `verified` in code and this file.
