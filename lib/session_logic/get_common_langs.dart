import 'package:speaking_flashcards/models/lang.dart';

List<Lang> getCommonLangs(List<Lang> langs, List<Lang> recogLangs, List<Lang> synthLangs) {
  List<Lang> localLangs = [];

  for (var lang in langs) {
    int recogLangExistsIndex =
        recogLangs.indexWhere((recogLang) => recogLang.code.replaceAll('_', '-') == lang.code.replaceAll('_', '-'));
    int synthLangExistsIndex =
        synthLangs.indexWhere((synthLang) => synthLang.code.replaceAll('_', '-') == lang.code.replaceAll('_', '-'));
    int localLangExistsIndex =
        localLangs.indexWhere((localLang) => localLang.code.replaceAll('_', '-') == lang.code.replaceAll('_', '-'));

    bool recogLangExists = recogLangExistsIndex == -1 ? false : true;
    bool synthLangExists = synthLangExistsIndex == -1 ? false : true;
    bool localLangExists = localLangExistsIndex == -1 ? false : true;

    // add lang ONLY if it's in recogLangs AND synthLangs, but NEVER if it's already in localLangs!
    if (recogLangExists && synthLangExists && !localLangExists) {
      localLangs.add(lang);
    }
  }

  // this seems to be how Android is set up... more setup on popup_questions and popup_answers
  int synthMndIndex = synthLangs.lastIndexWhere((lang) => lang.code == 'zh-CN');
  int recogMndIndex = recogLangs.lastIndexWhere((lang) => lang.code == 'cmn_CN');
  bool synthMndExists = synthMndIndex == -1 ? false : true;
  bool recogMndExists = recogMndIndex == -1 ? false : true;

  if (synthMndExists && recogMndExists) {
    localLangs.add(Lang(
      name: 'Mandarin (China)',
      code: 'mnd-chn',
      flag: '🇨🇳',
      origin: [CodeOrigin.other],
    ));
  }

  return localLangs;
}
