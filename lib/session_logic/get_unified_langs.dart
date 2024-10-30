import 'package:speaking_flashcards/models/lang.dart';
import 'package:speaking_flashcards/helpers/code_to_flag.dart';

Future<List<Lang>> getUnifiedLangs(recogLangs, synthLangs) async {
  List<Lang> localLangs = [];
  // recog typically has languages names WITH the codes, so we can start with them...
  for (var recogLang in recogLangs) {
    localLangs.add(recogLang);
  }

  // for each synth lang,
  for (var synthLang in synthLangs) {
    var matches = false;
    for (var x = 0; x < localLangs.length; x++) {
      if (localLangs[x].code == synthLang.code) {
        // Prepare to add the origin separately if there are no matches
        matches = true;

        // Add the synth CodeOrigin if it was found as a synth code as well
        localLangs[x] = Lang(
          name: localLangs[x].name,
          code: localLangs[x].code,
          origin: [localLangs[x].origin[0], CodeOrigin.synth],
          flag: localLangs[x].flag,
        );
      }
      // give names to Android synthesizers
      if (localLangs[x].code.replaceAll('_', '-') == synthLang.code) {
        synthLang = Lang(
          name: localLangs[x].name,
          code: synthLang.code,
          origin: synthLang.origin,
          flag: synthLang.flag,
        );
      }
    }
    if (!matches) {
      // add as a new lang...
      localLangs.add(synthLang);
    }
  }

  // add flags
  localLangs = localLangs.map((lang) {
    return Lang(
      name: lang.name,
      code: lang.code,
      origin: lang.origin,
      flag: codeToFlag(lang.code),
    );
  }).toList();

  return localLangs;
}
