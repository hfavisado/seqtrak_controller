import 'messages/parameter_change.dart';
import 'seqtrak_parameter.dart';

class SeqtrakProtocol {
  const SeqtrakProtocol();

  ParameterChange? decode(List<int> bytes) {
    if (bytes.length != 3 || bytes.first & 0xf0 != 0xb0) return null;

    final channel = (bytes.first & 0x0f) + 1;
    final cc = bytes[1];
    final value = bytes[2];
    if (cc < 0 || cc > 127 || value < 0 || value > 127) return null;

    for (final definition in seqtrakParameterDefinitions) {
      if (definition.cc == cc &&
          definition.supportsChannel(channel) &&
          definition.supportsValue(value)) {
        return ParameterChange(
          definition: definition,
          channel: channel,
          value: value,
        );
      }
    }
    return null;
  }

  List<int> encodeControlChange({
    required SeqtrakParameter parameter,
    required int channel,
    required int value,
  }) {
    final definition = definitionFor(parameter);
    if (!definition.supportsChannel(channel)) {
      throw RangeError.value(
        channel,
        'channel',
        '${definition.name} is not documented for this channel',
      );
    }
    if (!definition.supportsValue(value)) {
      throw RangeError.range(
        value,
        definition.minimum,
        definition.maximum,
        'value',
        '${definition.name} expects ${definition.rangeDescription}',
      );
    }
    return [0xb0 | (channel - 1), definition.cc, value];
  }
}
