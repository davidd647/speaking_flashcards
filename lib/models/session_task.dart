class SessionTask {
  TaskName taskName;
  String value;
  String language;

  SessionTask({
    required this.taskName,
    required this.value,
    required this.language,
  });
}

enum TaskName {
  synth,
  recog,
  nonSubmitRecog,
  submitByText,
  sfx,
  congrats,
  giveHint,
  sayAnswer,
  debug,
}
