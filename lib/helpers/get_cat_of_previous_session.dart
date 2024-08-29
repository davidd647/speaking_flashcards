import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import 'package:speaking_flashcards/models/lang_combo.dart';
import 'package:speaking_flashcards/helpers/placeholder_lang_combo.dart';

// default selections for synth/recog questions and answers:
const sqLangDefault = 'en-US';
final rqLangDefault = Platform.isIOS ? 'en-US' : 'en_US';
const saLangDefault = 'en-US';
final raLangDefault = Platform.isIOS ? 'en-US' : 'en_US';

Future<LangCombo> getLangComboOfPreviousSession() async {
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  LangCombo previouslyUsedLangCombo = placeholderLangCombo;

  previouslyUsedLangCombo.sqLang = await prefs.then((SharedPreferences prefs) {
    return prefs.getString('sqLang') ?? sqLangDefault;
  });
  previouslyUsedLangCombo.rqLang = await prefs.then((SharedPreferences prefs) {
    return prefs.getString('rqLang') ?? rqLangDefault;
  });
  previouslyUsedLangCombo.saLang = await prefs.then((SharedPreferences prefs) {
    return prefs.getString('saLang') ?? saLangDefault;
  });
  previouslyUsedLangCombo.raLang = await prefs.then((SharedPreferences prefs) {
    return prefs.getString('raLang') ?? raLangDefault;
  });

  return previouslyUsedLangCombo;
}
