import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/models/lang.dart';

class AnswerLangs extends StatefulWidget {
  const AnswerLangs({
    super.key,
  });

  @override
  State<AnswerLangs> createState() => _AnswerLangsState();
}

class _AnswerLangsState extends State<AnswerLangs> {
  void updateAnswerLanguages(newVal) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);

    // SPECIAL CODE FOR MANDARIN
    if (newVal.code == 'mnd-chn') {
      int synthMndIndex = providerSessionLogic.synthLangs.lastIndexWhere((lang) => lang.code == 'zh-CN');
      if (synthMndIndex != -1) {
        updateSynthAnswers(providerSessionLogic.synthLangs[synthMndIndex]);
      }

      int recogMndIndex = providerSessionLogic.recogLangs.lastIndexWhere((lang) => lang.code == 'cmn_CN');
      if (recogMndIndex != -1) {
        updateRecogAnswers(providerSessionLogic.recogLangs[recogMndIndex]);
      }
      // should attempt to update languages (and get appropriate questions here...)
      // get the appropriate quesitons for selected language
      providerSessionLogic.questionsList = [];
      providerSessionLogic.getUrgentQuestions();

      // set initial due!
      providerSessionLogic.resetAmountsDue();

      return;
    }

    updateSynthAnswers(newVal);
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
      providerSessionLogic.changeRALang(match.code);
    }

    // should attempt to update languages (and get appropriate questions here...)
    // get the appropriate quesitons for selected language
    providerSessionLogic.questionsList = [];
    providerSessionLogic.getUrgentQuestions();

    // set initial due!
    providerSessionLogic.resetAmountsDue();
  }

  void updateSynthAnswers(newVal) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.changeSALang(newVal.code);
  }

  void updateRecogAnswers(newVal) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.changeRALang(newVal.code);
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color containerColor = Colors.grey.shade200;
    Color fgColor = Colors.black;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      containerColor = Colors.grey.shade600;
      fgColor = Colors.white;
    }

    return DropdownButtonFormField(
      dropdownColor: containerColor,
      menuMaxHeight: (providerSessionLogic.screenMaxHeight / 4) * 3,
      decoration: InputDecoration(
        labelText: 'Answer Language',
        labelStyle: TextStyle(color: fgColor),
      ),
      value: providerSessionLogic.commonLangs.firstWhere(
          (lang) => lang.code == providerSessionLogic.selectedLangCombo.saLang,
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
                  style: TextStyle(color: fgColor),
                ),
              ),
              Text(
                lang.code,
                style: TextStyle(color: fgColor),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (newVal) {
        updateAnswerLanguages(newVal);
      },
    );
  }
}
