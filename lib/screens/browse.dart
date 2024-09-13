import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaking_flashcards/helpers/placeholder_question.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/widgets/wide_button.dart';
import 'package:speaking_flashcards/models/question.dart';
import 'package:speaking_flashcards/helpers/extract_first_after_slash.dart';

class Browse extends StatefulWidget {
  const Browse({super.key});
  static const routeName = '/browse';

  @override
  State<Browse> createState() => _BrowseState();
}

class _BrowseState extends State<Browse> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  final soundalikesController = TextEditingController();

  int idOfActiveQuestion = -1;
  Question selectedQuestion = placeholderQuestion;

  void toggleEdit(Question q) {
    if (idOfActiveQuestion == q.id) {
      idOfActiveQuestion = -1;
    } else {
      idOfActiveQuestion = q.id;
    }

    questionController.text = q.q;

    String answer = q.a.split('/')[0];
    String soundalikes = extractAfterFirstSlash(q.a);

    setState(() {
      answerController.text = answer;
      soundalikesController.text = soundalikes;
    });
  }

  void delete(Question q) {
    // quickly delete question
    FocusScope.of(context).unfocus();

    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    // - delete from database
    providerSessionLogic.delete(q.id);
  }

  void save(Question q) {
    // quickly save changes done to question

    String fullAnswer = answerController.text;
    if (soundalikesController.text.trim() != '') {
      fullAnswer = '$fullAnswer/${soundalikesController.text}';
    }

    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    int qIndex = providerSessionLogic.questionsList.indexWhere((question) => question.id == q.id);
    Question updatedQuestion = Question(
      id: providerSessionLogic.questionsList[qIndex].id,
      q: questionController.text,
      a: fullAnswer,
      cat: providerSessionLogic.questionsList[qIndex].cat,
      sqLang: providerSessionLogic.questionsList[qIndex].sqLang,
      rqLang: providerSessionLogic.questionsList[qIndex].rqLang,
      saLang: providerSessionLogic.questionsList[qIndex].saLang,
      raLang: providerSessionLogic.questionsList[qIndex].raLang,
      dateCreated: providerSessionLogic.questionsList[qIndex].dateCreated,
      level: providerSessionLogic.questionsList[qIndex].level,
      spiritLevel: providerSessionLogic.questionsList[qIndex].spiritLevel,
      history: providerSessionLogic.questionsList[qIndex].history,
      note: providerSessionLogic.questionsList[qIndex].note,
      order: providerSessionLogic.questionsList[qIndex].order,
    );

    // - update the questionsList
    providerSessionLogic.questionsList[qIndex] = updatedQuestion;

    // - update the database
    providerSessionLogic.updateEditedQuestion(updatedQuestion);
  }

  @override
  void initState() {
    super.initState();

    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.questionsList.sort(((a, b) => a.order.compareTo(b.order)));
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color bgColor = Colors.white;
    Color fgColor = Colors.black;
    Color containerColor = const Color.fromARGB(255, 220, 220, 220);

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      bgColor = Colors.black;
      fgColor = Colors.white;
      containerColor = const Color.fromARGB(255, 100, 100, 100);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Browse', style: TextStyle(color: fgColor)),
        iconTheme: IconThemeData(color: fgColor),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          return SizedBox(
            height: maxHeight,
            width: maxWidth,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...providerSessionLogic.questionsList.map((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 12.5),
                              Flexible(
                                fit: FlexFit.tight,
                                child: WideButton(
                                  color: containerColor,
                                  onTap: () {
                                    toggleEdit(q);
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Icon(Icons.edit_note, size: 32, color: fgColor),
                                      ),
                                      Flexible(
                                          fit: FlexFit.tight,
                                          child: Text(
                                            q.q,
                                            style: TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              color: fgColor,
                                            ),
                                          )),
                                      Flexible(
                                          fit: FlexFit.tight,
                                          child: Text(
                                            q.a,
                                            style: TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              color: fgColor,
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.5),
                              SizedBox(
                                // height: 50,
                                width: 50,
                                child: WideButton(
                                  color: containerColor,
                                  onTap: () {
                                    delete(q);
                                  },
                                  child: Icon(Icons.delete, size: 24, color: fgColor),
                                ),
                              ),
                              const SizedBox(width: 12.5),
                            ],
                          ),
                          if (idOfActiveQuestion == q.id)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 10, right: 10),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        fit: FlexFit.tight,
                                        child: Container(
                                          height: 50,
                                          margin: const EdgeInsets.only(left: 2, right: 2),
                                          padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                                          alignment: Alignment.centerLeft,
                                          child: TextField(
                                            controller: questionController,
                                            style: TextStyle(color: fgColor),
                                            decoration: InputDecoration(
                                              labelText: 'Question',
                                              labelStyle: TextStyle(color: fgColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 10, right: 10),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        fit: FlexFit.tight,
                                        child: Container(
                                          height: 50,
                                          margin: const EdgeInsets.only(left: 2, right: 2),
                                          padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                                          alignment: Alignment.centerLeft,
                                          child: TextField(
                                            controller: answerController,
                                            style: TextStyle(color: fgColor),
                                            decoration: InputDecoration(
                                              labelText: 'Answer',
                                              labelStyle: TextStyle(color: fgColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 10, right: 10),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        fit: FlexFit.tight,
                                        child: Container(
                                          height: 75,
                                          margin: const EdgeInsets.only(left: 2, right: 2),
                                          padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                                          alignment: Alignment.centerLeft,
                                          child: TextField(
                                            controller: soundalikesController,
                                            style: TextStyle(color: fgColor),
                                            decoration: InputDecoration(
                                              labelText: 'Answer Soundalikes',
                                              labelStyle: TextStyle(color: fgColor),
                                              helperText: 'Separate soundalikes with a slash (/) character',
                                              helperStyle: TextStyle(color: fgColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 42),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 12.5),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: WideButton(
                                        color: containerColor,
                                        onTap: () {
                                          delete(q);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cancel, size: 24, color: fgColor),
                                            const SizedBox(width: 12.5),
                                            Text('Cancel', style: TextStyle(color: fgColor)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12.5),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: WideButton(
                                        color: containerColor,
                                        onTap: () {
                                          save(q);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 24, color: fgColor),
                                            const SizedBox(width: 12.5),
                                            Text('Save', style: TextStyle(color: fgColor)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12.5),
                                  ],
                                ),
                                const SizedBox(height: 75),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
