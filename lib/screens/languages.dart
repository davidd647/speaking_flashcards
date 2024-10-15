import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/screens/languages/question_langs.dart';
import 'package:speaking_flashcards/screens/languages/answer_langs.dart';
import 'package:speaking_flashcards/models/lang_combo.dart';
import 'package:speaking_flashcards/helpers/reduce_flags.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});
  static const routeName = '/languages';

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  void langsQuickSwitch(langCombo) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);

    providerSessionLogic.langsQuickSwitch(langCombo);
  }

  @override
  void initState() {
    super.initState();

    Provider.of<ProviderSessionLogic>(context, listen: false).getAllLangCombosWithQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color bgColor = Colors.white;
    Color fgColor = Colors.black;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      bgColor = Colors.black;
      fgColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Languages', style: TextStyle(color: fgColor)),
        iconTheme: IconThemeData(color: fgColor),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // final maxHeight = constraints.maxHeight;

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              if (providerSessionLogic.commonLangs.isEmpty)
                const Text(
                  'LOADING LANGUAGES...',
                  style: TextStyle(color: Colors.red),
                ),
              if (providerSessionLogic.commonLangs.isNotEmpty)
                Row(
                  children: [
                    const SizedBox(width: 12.0),
                    SizedBox(
                      width: maxWidth - 24.0,
                      child: const QuestionLangs(),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Recog: ${providerSessionLogic.selectedLangCombo.rqLang}'),
                      Text('Synth: ${providerSessionLogic.selectedLangCombo.sqLang}'),
                    ],
                  ),
                  const SizedBox(width: 12.0),
                ],
              ),
              const SizedBox(height: 24),
              if (providerSessionLogic.commonLangs.isNotEmpty)
                Row(
                  children: [
                    const SizedBox(width: 12.0),
                    SizedBox(
                      width: maxWidth - 24.0,
                      child: const AnswerLangs(),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Recog: ${providerSessionLogic.selectedLangCombo.raLang}'),
                      Text('Synth: ${providerSessionLogic.selectedLangCombo.saLang}'),
                    ],
                  ),
                  const SizedBox(width: 12.0),
                ],
              ),
              const SizedBox(height: 42),
              Container(
                height: 1,
                width: maxWidth,
                color: Colors.grey.shade600,
                margin: const EdgeInsets.only(left: 12, right: 12),
              ),
              const SizedBox(height: 64),
              Text(
                'Languages Being Studied:',
                textAlign: TextAlign.center,
                style: TextStyle(color: fgColor),
              ),
              if (providerSessionLogic.allLangCombosWithQuestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'No saved questions yet...',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ...providerSessionLogic.allLangCombosWithQuestions.map((LangCombo langCombo) {
                var isSelectedlangCombo = true;
                if (langCombo.sqLang != providerSessionLogic.selectedLangCombo.sqLang) isSelectedlangCombo = false;
                if (langCombo.rqLang != providerSessionLogic.selectedLangCombo.rqLang) isSelectedlangCombo = false;
                if (langCombo.saLang != providerSessionLogic.selectedLangCombo.saLang) isSelectedlangCombo = false;
                if (langCombo.raLang != providerSessionLogic.selectedLangCombo.raLang) isSelectedlangCombo = false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0, left: 12, right: 12),
                  decoration: isSelectedlangCombo
                      ? BoxDecoration(
                          border: Border.all(
                          color: Colors.lightBlue.shade900,
                          width: 5,
                        ))
                      : BoxDecoration(border: Border.all(color: Colors.transparent)),
                  child: GestureDetector(
                    onTap: () async {
                      langsQuickSwitch(langCombo);

                      Navigator.pop(context);
                    },
                    child: Container(
                      color: Colors.lightBlue.shade300,
                      height: 50.0,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(reduceFlags(langCombo.sqLang, langCombo.rqLang)),
                                const Icon(Icons.swap_horiz, size: 18),
                                Text(reduceFlags(langCombo.saLang, langCombo.raLang)),
                              ],
                            ),
                            Text('Due: ${langCombo.amountOfQuestionsDue} Total: ${langCombo.amountOfQuestions}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 100),
            ],
            // ],
          ),
        );
      }),
    );
  }
}
