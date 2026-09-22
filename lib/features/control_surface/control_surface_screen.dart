import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../seqtrak/seqtrak_track.dart';
import '../../seqtrak/track_position_tracker.dart';
import '../midi_explorer/midi_explorer_screen.dart';
import 'position_controller.dart';

class ControlSurfaceScreen extends ConsumerStatefulWidget {
  const ControlSurfaceScreen({super.key});

  @override
  ConsumerState<ControlSurfaceScreen> createState() =>
      _ControlSurfaceScreenState();
}

class _ControlSurfaceScreenState extends ConsumerState<ControlSurfaceScreen> {
  late final PositionController _positionController;

  @override
  void initState() {
    super.initState();
    ref.read(midiExplorerControllerProvider).start();
    _positionController = ref.read(positionControllerProvider)
      ..addListener(_onPositionChanged);
  }

  void _onPositionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _positionController.removeListener(_onPositionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _positionController;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEQTRAK'),
        actions: [
          IconButton(
            tooltip: 'Open MIDI Explorer',
            icon: const Icon(Icons.cable),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const MidiExplorerScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                controller.isRunning
                    ? 'Track positions • following MIDI clock (provisional)'
                    : 'Track positions • connect and start playback',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 166,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: SeqtrakTrack.values.length,
                itemBuilder: (context, index) {
                  final track = SeqtrakTrack.values[index];
                  return _TrackPositionCard(
                    track: track,
                    position: controller.positionFor(track),
                    pattern: controller.selectedPatternFor(track),
                    steps: controller.stepCountFor(track),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPositionCard extends StatelessWidget {
  const _TrackPositionCard({
    required this.track,
    required this.position,
    required this.pattern,
    required this.steps,
  });

  final SeqtrakTrack track;
  final TrackPosition? position;
  final int? pattern;
  final int? steps;

  @override
  Widget build(BuildContext context) {
    final bar = position?.bar.toString().padLeft(2, '0') ?? '--';
    final beat = position?.beat.toString() ?? '-';
    final step = position?.step.toString().padLeft(2, '0') ?? '--';
    return Card(
      key: ValueKey('track-${track.name}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              track.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PositionBlock(track: track, label: 'BAR', value: bar),
                      _PositionBlock(track: track, label: 'BEAT', value: beat),
                      _PositionBlock(track: track, label: 'STEP', value: step),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              pattern == null
                  ? 'Pattern unknown'
                  : steps == null
                  ? 'Pattern $pattern • length unknown'
                  : 'Pattern $pattern • $steps steps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionBlock extends StatelessWidget {
  const _PositionBlock({
    required this.track,
    required this.label,
    required this.value,
  });

  final SeqtrakTrack track;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  key: ValueKey('position-${track.name}-$label'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
