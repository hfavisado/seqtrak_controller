import '../seqtrak_parameter.dart';
import '../seqtrak_track.dart';

class ParameterChange {
  const ParameterChange({
    required this.definition,
    required this.channel,
    required this.value,
  });

  final SeqtrakParameterDefinition definition;
  final int channel;
  final int value;

  SeqtrakParameter get parameter => definition.parameter;
  SeqtrakTrack? get track => SeqtrakTrack.fromMidiChannel(channel);
}
