import 'package:speaking_flashcards/helpers/code_to_flag.dart';

String reduceFlags(langCode1, langCode2) {
  bool langSame = codeToFlag(langCode1) == codeToFlag(langCode2);

  return langSame ? codeToFlag(langCode1) : '${codeToFlag(langCode1)} ${codeToFlag(langCode2)}';
}
