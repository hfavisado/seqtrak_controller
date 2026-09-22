import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../seqtrak/seqtrak_track.dart';
import '../../seqtrak/track_position_tracker.dart';
import '../midi_explorer/midi_explorer_screen.dart';
import 'position_controller.dart';
import 'step_audition_settings.dart';
import 'track_rings.dart';

class ControlSurfaceScreen extends ConsumerStatefulWidget {
  const ControlSurfaceScreen({super.key});

  @override
  ConsumerState<ControlSurfaceScreen> createState() =>
      _ControlSurfaceScreenState();
}

class _ControlSurfaceScreenState extends ConsumerState<ControlSurfaceScreen> {
  late final PositionController _positionController;
  final Map<SeqtrakTrack, String> _names = {};
  final Map<SeqtrakTrack, Color> _colors = {};
  final Map<SeqtrakTrack, Map<int, StepAuditionSettings>> _stepSettings = {};
  SeqtrakTrack? _selectedTrack;
  int? _selectedStep;

  String _nameFor(SeqtrakTrack track) => _names[track] ?? track.displayName;
  Color _colorFor(SeqtrakTrack track) => _colors[track] ?? trackColor(track);
  StepAuditionSettings _settingsFor(SeqtrakTrack track, int step) =>
      _stepSettings[track]?[step] ?? const StepAuditionSettings();

  void _updateStep(SeqtrakTrack track, int step, StepAuditionSettings value) {
    setState(() => _stepSettings.putIfAbsent(track, () => {})[step] = value);
  }

  Future<void> _tapStep(SeqtrakTrack track, int step) async {
    setState(() {
      _selectedTrack = track;
      _selectedStep = step;
    });
    final sound = _settingsFor(track, step);
    try {
      await _positionController.audition(
        track,
        note: sound.note,
        velocity: sound.velocity,
        gateMs: sound.gateMs,
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _renameTrack(SeqtrakTrack track) async {
    var draft = _nameFor(track);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename track ${track.channel}'),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Display name'),
          onChanged: (value) => draft = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draft),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (mounted && name != null && name.trim().isNotEmpty) {
      setState(() => _names[track] = name.trim());
    }
  }

  Future<void> _chooseColor(SeqtrakTrack track) async {
    final chosen = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Color for ${_nameFor(track)}'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < Colors.primaries.length; index++)
              IconButton(
                key: ValueKey('palette-$index'),
                tooltip: 'Choose color ${index + 1}',
                icon: Icon(
                  Icons.circle,
                  color: Colors.primaries[index].shade300,
                  size: 30,
                ),
                onPressed: () =>
                    Navigator.pop(context, Colors.primaries[index].shade300),
              ),
          ],
        ),
      ),
    );
    if (mounted && chosen != null) setState(() => _colors[track] = chosen);
  }

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
    final tracks = [
      for (final track in SeqtrakTrack.values)
        TrackRingData(
          track: track,
          stepCount: controller.stepCountFor(track),
          position: controller.positionFor(track),
          color: _colorFor(track),
        ),
    ];
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            final ringSize = wide
                ? (constraints.maxWidth * 0.55).clamp(
                    0.0,
                    constraints.maxHeight - 24,
                  )
                : constraints.maxWidth - 32;
            final diagram = SizedBox(
              width: ringSize,
              height: ringSize,
              child: TrackRings(
                tracks: tracks,
                selectedTrack: _selectedTrack,
                selectedStep: _selectedStep,
                selectedName: _selectedTrack == null
                    ? null
                    : _nameFor(_selectedTrack!),
                onStepTap: _tapStep,
              ),
            );
            final legend = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final track in SeqtrakTrack.values)
                  _TrackLegendRow(
                    track: track,
                    position: controller.positionFor(track),
                    pattern: controller.selectedPatternFor(track),
                    steps: controller.stepCountFor(track),
                    name: _nameFor(track),
                    color: _colorFor(track),
                    selected: _selectedTrack == track,
                    onSelect: () => setState(() {
                      _selectedTrack = track;
                      _selectedStep = null;
                    }),
                    onRename: () => _renameTrack(track),
                    onColor: () => _chooseColor(track),
                  ),
                if (_selectedTrack != null && _selectedStep != null)
                  _StepInspector(
                    trackName: _nameFor(_selectedTrack!),
                    step: _selectedStep!,
                    settings: _settingsFor(_selectedTrack!, _selectedStep!),
                    onChanged: (value) =>
                        _updateStep(_selectedTrack!, _selectedStep!, value),
                  ),
              ],
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    controller.isRunning
                        ? 'Track loops • following MIDI clock (estimated)'
                        : 'Track loops • connect and start playback',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        diagram,
                        const SizedBox(width: 16),
                        Expanded(child: legend),
                      ],
                    )
                  else ...[
                    diagram,
                    const SizedBox(height: 16),
                    legend,
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Outer ring: track 1 · inner ring: track 11. '
                    'Each ring spans its own pattern length; small dots show steps, '
                    'and the colored circle shows the estimated current step. '
                    'Tap a step to audition it. Step settings are local and do not edit the device pattern.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrackLegendRow extends StatelessWidget {
  const _TrackLegendRow({
    required this.track,
    required this.position,
    required this.pattern,
    required this.steps,
    required this.name,
    required this.color,
    required this.selected,
    required this.onSelect,
    required this.onRename,
    required this.onColor,
  });

  final SeqtrakTrack track;
  final TrackPosition? position;
  final int? pattern;
  final int? steps;
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onColor;

  @override
  Widget build(BuildContext context) {
    final bar = position?.bar.toString().padLeft(2, '0') ?? '--';
    final beat = position?.beat.toString() ?? '-';
    final step = position?.step.toString().padLeft(2, '0') ?? '--';
    final nameButton = TextButton(
      key: ValueKey('name-${track.name}'),
      onPressed: onRename,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
        ),
      ),
    );
    final colorButton = IconButton(
      key: ValueKey('color-${track.name}'),
      tooltip: 'Change color for $name',
      onPressed: onColor,
      icon: Icon(Icons.circle, color: color, size: 20),
      visualDensity: VisualDensity.compact,
    );
    final patternText = InkWell(
      onTap: onSelect,
      child: Text(
        pattern == null
            ? 'Pattern unknown'
            : steps == null
            ? 'P$pattern · length unknown'
            : 'P$pattern · ${position == null ? '--' : ((position!.bar - 1) * 16 + position!.step).toString().padLeft(2, '0')}/$steps',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
    final positions = [
      _PositionValue(track: track, label: 'BAR', value: bar),
      _PositionValue(track: track, label: 'BEAT', value: beat),
      _PositionValue(track: track, label: 'STEP', value: step),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(width: 4, height: compact ? 54 : 36, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: compact
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: nameButton),
                              colorButton,
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: patternText),
                              ...positions,
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 112, child: nameButton),
                          colorButton,
                          Expanded(child: patternText),
                          ...positions,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionValue extends StatelessWidget {
  const _PositionValue({
    required this.track,
    required this.label,
    required this.value,
  });

  final SeqtrakTrack track;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    child: Column(
      children: [
        Text(
          value,
          key: ValueKey('position-${track.name}-$label'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _StepInspector extends StatelessWidget {
  const _StepInspector({
    required this.trackName,
    required this.step,
    required this.settings,
    required this.onChanged,
  });

  final String trackName;
  final int step;
  final StepAuditionSettings settings;
  final ValueChanged<StepAuditionSettings> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$trackName · step $step',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Audition values (local)'),
          _valueSlider(
            label: 'MIDI note',
            value: settings.note,
            min: 0,
            max: 127,
            onChanged: (value) => onChanged(settings.copyWith(note: value)),
          ),
          _valueSlider(
            label: 'Velocity',
            value: settings.velocity,
            min: 1,
            max: 127,
            onChanged: (value) => onChanged(settings.copyWith(velocity: value)),
          ),
          _valueSlider(
            label: 'Gate (ms)',
            value: settings.gateMs,
            min: 50,
            max: 1000,
            onChanged: (value) => onChanged(settings.copyWith(gateMs: value)),
          ),
        ],
      ),
    ),
  );

  Widget _valueSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) => Row(
    children: [
      SizedBox(width: 88, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ),
      SizedBox(width: 38, child: Text('$value', textAlign: TextAlign.end)),
    ],
  );
}
