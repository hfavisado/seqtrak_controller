/// Local audition values for one step. Pattern step editing is not yet mapped.
class StepAuditionSettings {
  const StepAuditionSettings({
    this.note = 60,
    this.velocity = 100,
    this.gateMs = 150,
  });

  final int note;
  final int velocity;
  final int gateMs;

  StepAuditionSettings copyWith({int? note, int? velocity, int? gateMs}) =>
      StepAuditionSettings(
        note: note ?? this.note,
        velocity: velocity ?? this.velocity,
        gateMs: gateMs ?? this.gateMs,
      );
}
