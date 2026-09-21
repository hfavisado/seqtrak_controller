import 'package:flutter/material.dart';

import '../features/midi_explorer/midi_explorer_screen.dart';

class SeqtrakControllerApp extends StatelessWidget {
  const SeqtrakControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEQTRAK Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6750a4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MidiExplorerScreen(),
    );
  }
}
