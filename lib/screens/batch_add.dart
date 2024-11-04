import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaking_flashcards/helpers/code_to_flag.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/widgets/wide_button.dart';
import 'package:speaking_flashcards/screens/languages.dart';

class BatchAdd extends StatefulWidget {
  const BatchAdd({super.key});
  static const routeName = '/batchadd';

  @override
  State<BatchAdd> createState() => _BatchAddState();
}

class _BatchAddState extends State<BatchAdd> {
  TextEditingController batchAddController = TextEditingController(); // for adding Q's by the batch!
  String invalidRow = '';

  void validateCSV() {
    invalidRow = '';

    List<String> lines = batchAddController.text.split('\n');
    for (int x = 0; x < lines.length; x++) {
      List<String> fields = lines[x].split(',');
      if (lines[x] != '' && fields.length != 2) {
        invalidRow = "Line $x invalid: ${lines[x]}";
      }
    }

    setState(() {});
  }

  String numOfQuestions = '0';
  void checkNumOfQuestions() {
    List<String> lines = batchAddController.text.split('\n');
    int numOfLines = 0;
    for (int x = 0; x < lines.length; x++) {
      List<String> fields = lines[x].split(',');
      if (fields.length == 2) {
        numOfLines++;
      }
    }

    // return numOfLines;
    numOfQuestions = numOfLines.toString();
  }

  void addFromCSV() async {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    List<String> lines = batchAddController.text.split('\n');
    for (int x = 0; x < lines.length; x++) {
      List<String> fields = lines[x].split(',');
      if (fields.length > 1) {
        await providerSessionLogic.addQuestion(fields[0], fields[1]);
      }
    }

    setState(() {
      batchAddController.text = '';
      invalidRow = '${lines.length} flashcards added! :)';
      numOfQuestions = '0';
    });
    providerSessionLogic.getCurrentQuestion();
    providerSessionLogic.questionForHint =
        providerSessionLogic.questionsList[providerSessionLogic.currentQuestionIndex];
  }

  @override
  void initState() {
    super.initState();
    batchAddController.addListener(() {
      // print('checking...');
      validateCSV();
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color bgColor = Colors.white;
    Color fgColor = Colors.black;
    Color containerColor = const Color.fromARGB(255, 220, 220, 220);
    bool showDarkKeyboard = false;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      bgColor = Colors.black;
      fgColor = Colors.white;
      containerColor = const Color.fromARGB(255, 100, 100, 100);
      showDarkKeyboard = true;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Batch Add', style: TextStyle(color: fgColor)),
        iconTheme: IconThemeData(color: fgColor),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // final maxWidth = constraints.maxWidth;
          // final maxHeight = constraints.maxHeight;

          return (providerSessionLogic.commonLangs.isEmpty)
              ? const Center(
                  child: Text(
                    'Err: providerSessionLogic.commonLangs is empty',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // show languages here...
                        WideButton(
                          color: containerColor,
                          onTap: () {
                            // Navigator.pop(context);
                            Navigator.of(context).pushNamed(Languages.routeName);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            // width: 47,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Change Languages',
                                  style: TextStyle(color: fgColor),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${providerSessionLogic.qDisplayFlags} ${providerSessionLogic.aDisplayFlags}',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Text(
                        //   '${providerSessionLogic.qDisplayFlags} ${providerSessionLogic.aDisplayFlags}',
                        //   style: const TextStyle(fontSize: 25),
                        // ),
                        const SizedBox(height: 12),

                        TextFormField(
                          keyboardAppearance: showDarkKeyboard ? Brightness.dark : Brightness.light,
                          controller: batchAddController,
                          onChanged: (content) {
                            checkNumOfQuestions();
                          },
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 15,
                            color: fgColor,
                          ),
                          // maxLines: null, // This makes it expandable to any number of lines
                          maxLines: 5,
                          minLines: 5, // Optional, but good to set a starting point
                          decoration: InputDecoration(
                            hintText: "Enter your batch here (in CSV format)\nE.g. \"question,answer\"",
                            hintStyle: TextStyle(color: fgColor),
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction:
                              TextInputAction.newline, // For iOS to show a return key that makes a new line
                        ),
                        if (numOfQuestions != '0') const SizedBox(height: 10),
                        if (numOfQuestions != '0')
                          Text('Number of Questions: $numOfQuestions', style: TextStyle(color: fgColor)),
                        const SizedBox(height: 10),
                        WideButton(
                          color: (invalidRow != '' || batchAddController.text.trim() == '')
                              ? Colors.grey.shade200
                              : containerColor,
                          // disabled: invalidRow != '' ? true : false,
                          onTap: () {
                            if (invalidRow != '') return;
                            if (batchAddController.text.trim() == '') return;

                            addFromCSV();
                          },
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Icon(Icons.add,
                                  color: (invalidRow != '' || batchAddController.text.trim() == '')
                                      ? Colors.grey[300]
                                      : fgColor),
                              const SizedBox(width: 10),
                              Text(
                                'Add Batch',
                                style: TextStyle(
                                    color: invalidRow != '' || batchAddController.text.trim() == ''
                                        ? Colors.grey[400]
                                        : fgColor),
                              ),
                            ],
                          ),
                        ),
                        if (invalidRow != '') const SizedBox(height: 10),
                        if (invalidRow != '') Text(invalidRow, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        // WideButton(
                        //   color: containerColor,
                        //   // disabled: true,
                        //   onTap: () async {
                        //     // if the target language is one of the selected languages, incorporate it in the URL...
                        //     String targetLangFlag = codeToFlag(providerSessionLogic.selectedLangCombo.saLang);
                        //     String urlAddendum = '';
                        //     if (targetLangFlag == '🇨🇳') {
                        //       urlAddendum = '/?lang=Mandarin';
                        //     } else if (targetLangFlag == '🇯🇵') {
                        //       urlAddendum = '/?lang=Japanese';
                        //     } else if (targetLangFlag == '🇰🇷') {
                        //       urlAddendum = '/?lang=Korean';
                        //     } else if (targetLangFlag == '🇺🇸' || targetLangFlag == '🇨🇦') {
                        //       urlAddendum = '/?lang=English';
                        //     }

                        //     final Uri url = Uri.parse('https://speaking-flashcards-web.web.app$urlAddendum');
                        //     if (!await launchUrl(url)) {
                        //       throw Exception('Could not launch $url');
                        //     }
                        //   },
                        //   child: Row(
                        //     children: [
                        //       const SizedBox(width: 10),
                        //       Icon(Icons.exit_to_app_sharp, color: fgColor),
                        //       const SizedBox(width: 10),
                        //       Text('Open website to copy batch from ${providerSessionLogic.aDisplayFlags}',
                        //           style: TextStyle(color: fgColor)),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
