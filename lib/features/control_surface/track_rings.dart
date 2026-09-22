import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../seqtrak/seqtrak_track.dart';
import '../../seqtrak/track_position_tracker.dart';

class TrackRingData {
  const TrackRingData({
    required this.track,
    required this.stepCount,
    required this.position,
    required this.color,
  });

  final SeqtrakTrack track;
  final int? stepCount;
  final TrackPosition? position;
  final Color color;

  int? get currentStep =>
      position == null ? null : (position!.bar - 1) * 16 + position!.step;
}

Color trackColor(SeqtrakTrack track) =>
    Colors.primaries[track.index % Colors.primaries.length].shade300;

class TrackRings extends StatelessWidget {
  const TrackRings({
    super.key,
    required this.tracks,
    required this.onStepTap,
    required this.selectedTrack,
    required this.selectedStep,
    required this.selectedName,
  });

  final List<TrackRingData> tracks;
  final void Function(SeqtrakTrack track, int step) onStepTap;
  final SeqtrakTrack? selectedTrack;
  final int? selectedStep;
  final String? selectedName;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final size = context.size;
          if (size == null) return;
          final center = Offset(size.width / 2, size.height / 2);
          final radius = (details.localPosition - center).distance;
          final outerRadius = math.min(size.width, size.height) / 2 - 9;
          final spacing = outerRadius / 12;
          final index = ((outerRadius - radius) / spacing).round();
          if (index >= 0 && index < tracks.length) {
            final data = tracks[index];
            final count = data.stepCount;
            if (count == null || count < 1 || count > 128) return;
            final offset = details.localPosition - center;
            final angle =
                (math.atan2(offset.dy, offset.dx) + math.pi / 2 + 2 * math.pi) %
                (2 * math.pi);
            final step = ((angle * count / (2 * math.pi)).round() % count) + 1;
            onStepTap(data.track, step);
          }
        },
        child: CustomPaint(
          key: const ValueKey('track-rings'),
          painter: _TrackRingsPainter(
            tracks: tracks,
            inactiveColor: Theme.of(context).colorScheme.outlineVariant,
            selectedTrack: selectedTrack,
            selectedStep: selectedStep,
          ),
          child: Center(
            child: Text(
              selectedName ?? 'SEQTRAK\n11 TRACKS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackRingsPainter extends CustomPainter {
  _TrackRingsPainter({
    required this.tracks,
    required this.inactiveColor,
    required this.selectedTrack,
    required this.selectedStep,
  });

  final List<TrackRingData> tracks;
  final Color inactiveColor;
  final SeqtrakTrack? selectedTrack;
  final int? selectedStep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 9;
    final spacing = outerRadius / 12;
    for (var index = 0; index < tracks.length; index++) {
      final data = tracks[index];
      final radius = outerRadius - index * spacing;
      final color = data.color;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = inactiveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final count = data.stepCount;
      if (count == null || count < 1 || count > 128) continue;
      for (var step = 0; step < count; step++) {
        final angle = -math.pi / 2 + 2 * math.pi * step / count;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final major = step % 16 == 0;
        final dotRadius = math.max(
          1.1,
          math.min(
            spacing * (major ? 0.16 : 0.11),
            math.pi * radius / count * 0.4,
          ),
        );
        canvas.drawCircle(
          center + direction * radius,
          dotRadius,
          Paint()..color = color.withValues(alpha: major ? 1 : 0.7),
        );
        if (selectedTrack == data.track && selectedStep == step + 1) {
          canvas.drawCircle(
            center + direction * radius,
            math.max(4, dotRadius + 2),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
      final current = data.currentStep;
      if (current == null) continue;
      final angle =
          -math.pi / 2 + 2 * math.pi * ((current - 1) % count) / count;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawCircle(
        center + direction * radius,
        math.max(7, spacing * (selectedTrack == data.track ? 0.45 : 0.34)),
        Paint()..color = color,
      );
      canvas.drawCircle(
        center + direction * radius,
        math.max(7, spacing * (selectedTrack == data.track ? 0.45 : 0.34)),
        Paint()
          ..color = selectedTrack == data.track
              ? Colors.white
              : color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selectedTrack == data.track ? 2.5 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackRingsPainter oldDelegate) =>
      oldDelegate.tracks != tracks ||
      oldDelegate.inactiveColor != inactiveColor ||
      oldDelegate.selectedTrack != selectedTrack ||
      oldDelegate.selectedStep != selectedStep;
}
