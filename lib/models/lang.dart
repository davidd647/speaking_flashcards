class Lang {
  String name;
  String code;
  String flag;
  List<CodeOrigin> origin;

  Lang({
    required this.name,
    required this.code,
    required this.flag,
    required this.origin,
  });
}

enum CodeOrigin {
  other,
  synth,
  recog,
}
