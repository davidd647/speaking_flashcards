import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/models/lang.dart';

class QuestionLangs extends StatefulWidget {
  const QuestionLangs({
    super.key,
  });

  @override
  State<QuestionLangs> createState() => _QuestionLangsState();
}

class _QuestionLangsState extends State<QuestionLangs> {
  void updateQuestionLanguages(newVal) async {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);

    // SPECIAL CODE FOR MANDARIN
    if (newVal.code == 'mnd-chn') {
      int synthMndIndex = providerSessionLogic.synthLangs.lastIndexWhere((lang) => lang.code == 'zh-CN');
      if (synthMndIndex != -1) {
        updateSynthQuestions(providerSessionLogic.synthLangs[synthMndIndex]);
      }

      int recogMndIndex = providerSessionLogic.recogLangs.lastIndexWhere((lang) => lang.code == 'cmn_CN');
      if (recogMndIndex != -1) {
        updateRecogQuestions(providerSessionLogic.recogLangs[recogMndIndex]);
      }

      // should attempt to update languages (and get appropriate questions here...)
      // get the appropriate quesitons for selected language
      providerSessionLogic.questionsList = [];
      providerSessionLogic.getUrgentQuestions();

      // set initial due!
      await providerSessionLogic.resetAmountsDue();

      return;
    }

    updateSynthQuestions(newVal);
    Lang match = Lang(
      code: '',
      name: '',
      flag: '',
      origin: [CodeOrigin.other],
    );

    // search for any similar recog values

    for (var lang in providerSessionLogic.recogLangs) {
      if (lang.code == newVal.code ||
          lang.code == newVal.code.replaceAll('-', '_') ||
          lang.code == newVal.code.replaceAll('_', '-')) {
        match = lang;
      }
    }

    // automatically assign recog value if match found
    if (match.code != '') {
      providerSessionLogic.changeRQLang(match.code);
    }

    // should attempt to update languages (and get appropriate questions here...)
    // get the appropriate quesitons for selected language
    providerSessionLogic.questionsList = [];
    providerSessionLogic.getUrgentQuestions();

    // set initial due!
    await providerSessionLogic.resetAmountsDue();
  }

  void updateSynthQuestions(newVal) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.changeSQLang(newVal.code);
  }

  void updateRecogQuestions(newVal) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.changeRQLang(newVal.code);
    // print('providerSessionLogic.screenMaxHeight: ${providerSessionLogic.screenMaxHeight}');
  }

  @override
  void initState() {
    super.initState();
  }

  // after state is initialized
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    afterStateInitializedUpdateSizeForDropdowns();
  }

  void afterStateInitializedUpdateSizeForDropdowns() {
    final fullWidth = MediaQuery.of(context).size.width;
    final padding = MediaQuery.of(context).padding;
    var keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double fullHeight = MediaQuery.of(context).size.height -
        padding.top - // height of status bar (your battery life and stuff)
        kToolbarHeight - // height of the toolbar (i.e. the AppBar)
        keyboardHeight;

    Provider.of<ProviderSessionLogic>(context, listen: false).setSize(fullWidth, fullHeight);
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);

    return DropdownButtonFormField(
      menuMaxHeight: (providerSessionLogic.screenMaxHeight / 4) * 3,
      decoration: const InputDecoration(labelText: 'Question Language'),
      value: providerSessionLogic.commonLangs.firstWhere(
          (lang) => lang.code == providerSessionLogic.selectedLangCombo.sqLang,
          orElse: () => providerSessionLogic.commonLangs[0]),
      isExpanded: true,
      items: providerSessionLogic.commonLangs.map((Lang lang) {
        return DropdownMenuItem(
          value: lang,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${lang.flag} ${lang.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                lang.code,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (newVal) {
        updateQuestionLanguages(newVal);
      },
    );
  }
}
