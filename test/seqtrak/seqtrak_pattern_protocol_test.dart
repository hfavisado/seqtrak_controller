import 'package:flutter_test/flutter_test.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_pattern_protocol.dart';
import 'package:seqtrak_controller/seqtrak/seqtrak_track.dart';

void main() {
  const protocol = SeqtrakPatternProtocol();

  test('decodes captured SYNTH 1 pattern length changes', () {
    final oneBar = protocol.decode([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x57,
      0x16,
      0x00,
      0x10,
      0xf7,
    ]);
    final twoBars = protocol.decode([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x57,
      0x16,
      0x00,
      0x20,
      0xf7,
    ]);
    expect(oneBar?.track, SeqtrakTrack.synth1);
    expect(oneBar?.pattern, 1);
    expect(oneBar?.value, 16);
    expect(twoBars?.value, 32);
  });

  test('decodes selected pattern and each track independently', () {
    final change = protocol.decode([
      0xf0,
      0x43,
      0x10,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x5a,
      0x0f,
      0x02,
      0xf7,
    ]);
    expect(change?.track, SeqtrakTrack.sampler);
    expect(change?.kind, PatternParameterKind.selectedPattern);
    expect(change?.pattern, 3);
    expect(protocol.requestSelectedPattern(SeqtrakTrack.kick), [
      0xf0,
      0x43,
      0x30,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x50,
      0x0f,
      0xf7,
    ]);
    expect(protocol.requestStepCount(SeqtrakTrack.sampler, 3), [
      0xf0,
      0x43,
      0x30,
      0x7f,
      0x1c,
      0x0c,
      0x30,
      0x5a,
      0x1a,
      0xf7,
    ]);
  });

  test('rejects unrelated and invalid messages', () {
    expect(
      protocol.decode([
        0xf0,
        0x43,
        0x10,
        0x7f,
        0x1c,
        0x0c,
        0x01,
        0x10,
        0x39,
        0x01,
        0x01,
        0xf7,
      ]),
      isNull,
    );
    expect(
      protocol.decode([
        0xf0,
        0x43,
        0x10,
        0x7f,
        0x1c,
        0x0c,
        0x30,
        0x50,
        0x16,
        0x00,
        0x00,
        0xf7,
      ]),
      isNull,
    );
  });
}
