enum SeqtrakTrackType { drum, synth, dx, sampler }

enum SeqtrakTrack {
  kick(channel: 1, displayName: 'KICK', type: SeqtrakTrackType.drum),
  snare(channel: 2, displayName: 'SNARE', type: SeqtrakTrackType.drum),
  clap(channel: 3, displayName: 'CLAP', type: SeqtrakTrackType.drum),
  hat1(channel: 4, displayName: 'HAT 1', type: SeqtrakTrackType.drum),
  hat2(channel: 5, displayName: 'HAT 2', type: SeqtrakTrackType.drum),
  perc1(channel: 6, displayName: 'PERC 1', type: SeqtrakTrackType.drum),
  perc2(channel: 7, displayName: 'PERC 2', type: SeqtrakTrackType.drum),
  synth1(channel: 8, displayName: 'SYNTH 1', type: SeqtrakTrackType.synth),
  synth2(channel: 9, displayName: 'SYNTH 2', type: SeqtrakTrackType.synth),
  dx(channel: 10, displayName: 'DX', type: SeqtrakTrackType.dx),
  sampler(channel: 11, displayName: 'SAMPLER', type: SeqtrakTrackType.sampler);

  const SeqtrakTrack({
    required this.channel,
    required this.displayName,
    required this.type,
  });

  final int channel;
  final String displayName;
  final SeqtrakTrackType type;

  static SeqtrakTrack? fromMidiChannel(int channel) {
    for (final track in values) {
      if (track.channel == channel) return track;
    }
    return null;
  }
}
