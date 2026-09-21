import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_parameter.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_protocol.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_track.dart';

void main() {
  const protocol = SeqtrakProtocol();

  test('contains every documented channel and CC definition', () {
    expect(SeqtrakTrack.values, hasLength(11));
    expect(seqtrakParameterDefinitions, hasLength(40));
    expect(
      seqtrakParameterDefinitions
          .map((definition) => definition.parameter)
          .toSet(),
      hasLength(40),
    );
    expect(
      seqtrakParameterDefinitions,
      everyElement(
        isA<SeqtrakParameterDefinition>().having(
          (definition) => definition.status,
          'status',
          ProtocolKnowledgeStatus.documented,
        ),
      ),
    );
  });

  test('decodes documented cutoff CC on the correct track', () {
    final change = protocol.decode([0xb2, 0x4a, 0x64]);

    expect(change, isNotNull);
    expect(change!.parameter, SeqtrakParameter.filterCutoff);
    expect(change.track, SeqtrakTrack.clap);
    expect(change.value, 100);
    expect(change.definition.status, ProtocolKnowledgeStatus.documented);
  });

  test('encodes documented track volume CC', () {
    expect(
      protocol.encodeControlChange(
        parameter: SeqtrakParameter.trackVolume,
        channel: SeqtrakTrack.synth1.channel,
        value: 100,
      ),
      [0xb7, 0x07, 0x64],
    );
  });

  test('enforces documented channel and value ranges', () {
    expect(
      () => protocol.encodeControlChange(
        parameter: SeqtrakParameter.drumPitch,
        channel: SeqtrakTrack.synth1.channel,
        value: 64,
      ),
      throwsRangeError,
    );
    expect(
      () => protocol.encodeControlChange(
        parameter: SeqtrakParameter.drumPitch,
        channel: SeqtrakTrack.kick.channel,
        value: 20,
      ),
      throwsRangeError,
    );
  });

  test('encodes parameters documented as receive-only by the device', () {
    expect(
      protocol.encodeControlChange(
        parameter: SeqtrakParameter.mute,
        channel: SeqtrakTrack.kick.channel,
        value: 127,
      ),
      [0xb0, 0x17, 0x7f],
    );
  });

  test('does not decode undocumented or invalid CC combinations', () {
    expect(protocol.decode([0xb0, 0x01, 0x40]), isNull);
    expect(protocol.decode([0xb0, 0x19, 0x20]), isNull);
    expect(protocol.decode([0x90, 0x3c, 0x64]), isNull);
  });
}
