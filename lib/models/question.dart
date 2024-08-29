class Question {
  int id;
  String q;
  String a;
  String cat;
  String sqLang;
  String rqLang;
  String saLang;
  String raLang;
  String dateCreated;
  int level;
  int spiritLevel;
  String history;
  String note;
  int order;

  Question({
    required this.id,
    required this.q,
    required this.a,
    required this.cat,
    required this.sqLang,
    required this.rqLang,
    required this.saLang,
    required this.raLang,
    required this.dateCreated,
    required this.level,
    required this.spiritLevel,
    required this.history,
    required this.note,
    required this.order,
  });
}
