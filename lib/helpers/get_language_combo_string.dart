import 'package:speaking_flashcards/models/lang_combo.dart';

String getLanguageComboString(LangCombo selectedLangCombo) {
  return '${selectedLangCombo.sqLang}/${selectedLangCombo.rqLang}/${selectedLangCombo.saLang}/${selectedLangCombo.raLang}';
}
