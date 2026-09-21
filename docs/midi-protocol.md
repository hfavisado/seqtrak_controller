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
