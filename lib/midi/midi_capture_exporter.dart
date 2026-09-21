import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

abstract interface class MidiCaptureExporter {
  Future<String?> export({required String contents, required String fileName});
}

class FileSelectorMidiCaptureExporter implements MidiCaptureExporter {
  const FileSelectorMidiCaptureExporter();

  @override
  Future<String?> export({
    required String contents,
    required String fileName,
  }) async {
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return null;

    final file = XFile.fromData(
      Uint8List.fromList(contents.codeUnits),
      mimeType: 'text/plain',
      name: fileName,
    );
    await file.saveTo(location.path);
    return location.path;
  }
}
