// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/models/chron.dart';
import 'package:speaking_flashcards/helpers/code_to_flag.dart';
import 'package:speaking_flashcards/widgets/colored_inkwell_button.dart';
import 'package:speaking_flashcards/widgets/colored_circular_inkwell_button.dart';
import 'package:speaking_flashcards/widgets/flag_box.dart';
import 'package:speaking_flashcards/widgets/custom_circular_progress_indicator.dart';
import 'package:speaking_flashcards/widgets/queue_descending.dart';
import 'package:speaking_flashcards/menu.dart';

class StudySession extends StatefulWidget {
  const StudySession({super.key});
  static const routeName = '/studysession';

  @override
  State<StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends State<StudySession> {
  late ProviderSessionLogic providerSessionLogic;
  late ProviderSettings providerSettings;

  void handleRecordAnswer() {
    if (providerSessionLogic.isRecoging) return;
    // stop focusing on the keyboard if the keyboard is focused:
    FocusScope.of(context).unfocus();

    providerSessionLogic.queueRecog();
  }

  void handleSkip() {
    if (providerSessionLogic.isRecoging) return;
    // submitting the typed answer has same effect as skipping the question,
    // so instead of making a new function for that, we're just submitting the typed answer:
    providerSessionLogic.firstRecogGuessHintPlayed = false;

    // make sure to trigger ONE auto-recog after skipped:
    providerSessionLogic.skipped = true;
    providerSessionLogic.queueSubmitTyped();
  }

  FToast fToast = FToast();

  void showToast(Widget child, int duration) {
    fToast.showToast(
      child: child,
      gravity: ToastGravity.CENTER,
      toastDuration: Duration(seconds: duration),
    );
  }

  var brightness = Brightness.dark;
  @override
  void initState() {
    super.initState();

    providerSettings = Provider.of<ProviderSettings>(context, listen: false);
    providerSettings.init();
    providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.init(showToast);
    fToast.init(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      brightness = MediaQuery.of(context).platformBrightness;
      providerSettings.updateSystemDarkModeState(brightness == Brightness.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color fgColor = const Color.fromARGB(255, 44, 44, 44);
    Color containerColor = const Color.fromARGB(255, 220, 220, 220);
    Color bgColor = const Color.fromARGB(255, 249, 247, 247);

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      fgColor = const Color.fromARGB(255, 225, 225, 225);
      bgColor = const Color.fromARGB(255, 0, 0, 0);
      containerColor = const Color.fromARGB(255, 100, 100, 100);
    }

    String debuggingText = '';
    String taskHistoryText = '';
    if (providerSettings.debugMode) {
      debuggingText = '${providerSettings.debugMode ? '🟩' : '🟥'} providerSettings.debugMode\n';
      debuggingText += '${providerSessionLogic.sfxPlaying ? '🟩' : '🟥'} providerSessionLogic.sfxPlaying\n';
      debuggingText += '${providerSessionLogic.isSynthing ? '🟩' : '🟥'} providerSessionLogic.isSynthing\n';
      debuggingText += '${providerSessionLogic.isRecoging ? '🟩' : '🟥'} providerSessionLogic.isRecoging\n';
      debuggingText += '${providerSessionLogic.recog.recogEnabled ? '🟩' : '🟥'} providerSessionLogic.recog.enabled\n';

      // display all times recorded for today:
      providerSessionLogic.getTodaysChrons();

      for (var x = 0; x < providerSessionLogic.todaysChrons.length; x++) {
        Chron tmpChron = providerSessionLogic.todaysChrons[x];
        debuggingText += '${tmpChron.date}        ';
        debuggingText += '${tmpChron.languageCombo.split('/').map((lang) => codeToFlag(lang)).join()}        ';
        debuggingText += tmpChron.timeStudied < 120
            ? '${tmpChron.timeStudied}s'
            : '${tmpChron.timeStudied > 60 * 5 ? '⭐️' : ''} ${tmpChron.timeStudied ~/ 60}m${tmpChron.timeStudied % 60 < 10 ? '0' : ''}${tmpChron.timeStudied % 60}s';
        debuggingText += '\n';
      }

      debuggingText += '\n\n';
      debuggingText += '${providerSessionLogic.recogStatus} <- Recog status\n';
      debuggingText += '${providerSessionLogic.synthStatus} <- Synth status\n';
      debuggingText += '${providerSessionLogic.sfxStatus} <- Sfx status\n';
      debuggingText += '\n\n';

      debuggingText += 'Queue: (length: ${providerSessionLogic.delegationStack.length})\n';
      for (var x = 0; x < providerSessionLogic.delegationStack.length; x++) {
        debuggingText += '${providerSessionLogic.delegationStack[x].taskName}';
      }

      taskHistoryText = '';
      for (var x = providerSessionLogic.delegationHistory.length - 1; x >= 0; x--) {
        taskHistoryText += '#$x ';
        if (providerSessionLogic.delegationHistory[x].taskName.toString() == 'TaskName.recog') {
          taskHistoryText += 'name: 🦻recog ';
        } else if (providerSessionLogic.delegationHistory[x].taskName.toString() == 'TaskName.synth') {
          taskHistoryText += 'name: 🗣️synth ';
        } else if (providerSessionLogic.delegationHistory[x].taskName.toString() == 'TaskName.sfx') {
          taskHistoryText += 'name: 🔈sfx                            ';
        } else {
          taskHistoryText += 'name: ${providerSessionLogic.delegationHistory[x].taskName.toString().substring(9)} ';
        }
        if (providerSessionLogic.delegationHistory[x].language != '') {
          taskHistoryText += 'lang: ${providerSessionLogic.delegationHistory[x].language} ';
        }
        taskHistoryText += 'val: ${providerSessionLogic.delegationHistory[x].value} ';
        taskHistoryText += '\n';
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      endDrawer: const MenuContainer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          return Stack(children: [
            // top
            if (providerSettings.showQueue) QuestionQueueDescending(maxHeight: maxHeight, maxWidth: maxWidth),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: maxHeight * 0.6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [
                      0.42,
                      1,
                    ],
                    colors: [
                      bgColor.withOpacity(1),
                      bgColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // display time in the format ~m~~s (for brevity):
                    providerSessionLogic.secondsPassed < 120
                        ? 'Studied: ${providerSessionLogic.secondsPassed}s'
                        : 'Studied: ${providerSessionLogic.secondsPassed ~/ 60}m${providerSessionLogic.secondsPassed % 60 < 10 ? '0' : ''}${providerSessionLogic.secondsPassed % 60}s ${providerSessionLogic.secondsPassed > 60 * 5 ? '⭐️' : ''}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: providerSessionLogic.userIsActive ? fgColor : Colors.grey,
                    ),
                  ),
                  // if (providerSessionLogic.dailyStreak != 0)
                  Text(
                    'Streak: ${providerSessionLogic.dailyStreak}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: providerSessionLogic.dailyStreak != 0 ? fgColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 10,
              top: 50,
              child: Text(
                'Today: ${providerSessionLogic.dueInitially - providerSessionLogic.due}/${providerSessionLogic.dueInitially}',
                style: TextStyle(color: fgColor),
              ),
            ),
            Positioned(
              top: 75,
              right: 10,
              child: SizedBox(
                width: 75,
                height: 10,
                child: LinearProgressIndicator(
                  // if there's no questions due, DON'T divide by zero!
                  // otherwise, measure progress by remaining over initially due:
                  value: providerSessionLogic.dueInitially != 0
                      ? ((providerSessionLogic.dueInitially - providerSessionLogic.due) /
                          providerSessionLogic.dueInitially)
                      : 1,
                  backgroundColor: containerColor,
                  color: fgColor,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ColoredInkWellButton(
                    color: providerSessionLogic.questionsList.isEmpty ? Colors.lightBlue[100] : containerColor,
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      // open menu
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: Icon(Icons.add, color: fgColor),
                  ),
                  ColoredInkWellButton(
                    color: containerColor,
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      providerSessionLogic.queueSynthQuestion();
                    },
                    child: FittedBox(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(height: 15),
                        Icon(Icons.play_arrow, color: fgColor),
                        Text('Question', style: TextStyle(color: fgColor)),
                        const SizedBox(height: 15),
                      ]),
                    ),
                  ),
                  ColoredInkWellButton(
                    color: containerColor,
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      providerSessionLogic.queueSynthInput();
                    },
                    child: FittedBox(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(height: 15),
                        Icon(Icons.play_arrow, color: fgColor),
                        Text('Input', style: TextStyle(color: fgColor)),
                        const SizedBox(height: 15),
                      ]),
                    ),
                    // child: const Icon(Icons.bar_chart_sharp),
                  ),
                  if (providerSessionLogic.questionsList.isNotEmpty &&
                      providerSessionLogic.questionsList[providerSessionLogic.currentQuestionIndex].spiritLevel == 0)
                    ColoredInkWellButton(
                      color: containerColor,
                      width: maxWidth / 4 - 12.5,
                      height: maxWidth / 4 - 20,
                      onTap: () {
                        providerSessionLogic.queueGetHint();
                      },
                      child: FittedBox(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(height: 15),
                          Icon(Icons.question_mark, color: fgColor),
                          Text('Hint', style: TextStyle(color: fgColor)),
                          const SizedBox(height: 15),
                        ]),
                      ),
                      // child: const Icon(Icons.bar_chart_sharp),
                    ),
                  if (providerSessionLogic.questionsList.isNotEmpty &&
                      providerSessionLogic.questionsList[providerSessionLogic.currentQuestionIndex].spiritLevel != 0)
                    ColoredInkWellButton(
                      color: containerColor,
                      width: maxWidth / 4 - 12.5,
                      height: maxWidth / 4 - 20,
                      onTap: () {
                        providerSessionLogic.firstRecogGuessHintPlayed = false;
                        handleSkip();
                      },
                      child: FittedBox(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(height: 15),
                          Icon(Icons.skip_next, color: fgColor),
                          Text('Skip', style: TextStyle(color: fgColor)),
                          const SizedBox(height: 15),
                        ]),
                      ),
                      // child: const Icon(Icons.bar_chart_sharp),
                    ),
                ],
              ),
            ),
            if (providerSettings.debugMode)
              Positioned(
                top: 200,
                left: 10,
                right: 10,
                child: Text(debuggingText, style: TextStyle(color: fgColor)),
              ),
            // middle
            Positioned(
              left: (maxWidth / 2) - ((maxWidth / 4) / 2),
              top: maxHeight / 2 - ((maxWidth / 4) / 2),
              child: ColoredCircularInkWell(
                width: maxWidth / 4,
                onTap: () {
                  // stop focusing on the keyboard if the keyboard is focused:
                  FocusScope.of(context).unfocus();

                  providerSessionLogic.queueRecog();
                },
                // primary: providerSessionLogic.questionsList.isEmpty ? true : false,
                color: providerSessionLogic.questionsList.isEmpty ? Colors.grey[300] : Colors.lightBlue[100],
                child: const Icon(Icons.mic),
              ),
            ),
            if (providerSessionLogic.isRecoging)
              Center(
                child: SizedBox(
                  width: 124,
                  height: 124,
                  child: CustomCircularProgressIndicator(
                    color1: bgColor,
                    color2: Colors.greenAccent,
                  ),
                ),
              ),
            // middle (end)
            if (providerSettings.debugMode)
              Positioned(
                bottom: 150,
                left: 10,
                height: 100,
                child: SingleChildScrollView(
                  child: Text(taskHistoryText, style: TextStyle(color: fgColor)),
                ),
              ),
            // bottom
            Positioned(
              bottom: 42 + 35,
              left: 10,
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                width: maxWidth - 20,
                color: containerColor,
                child: Row(
                  children: [
                    FlagBox(
                      flag: providerSessionLogic.qDisplayFlags,
                      label: 'Q',
                      textColor: fgColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        providerSessionLogic.questionsList.isEmpty ||
                                // also need to check that there's a question with an order of zero:
                                (providerSessionLogic.questionsList.firstWhereOrNull((q) {
                                      return q.order == 0;
                                    }) ==
                                    null)
                            ? '(No flashcards yet)'
                            : providerSessionLogic.questionsList.firstWhere((q) {
                                return q.order == 0;
                              }).q,
                        style: TextStyle(fontSize: 15, color: fgColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 21,
              left: 10,
              right: 10,
              child: Container(
                color: containerColor,
                child: Row(
                  children: [
                    FlagBox(
                      flag: providerSessionLogic.qDisplayFlags,
                      label: 'A',
                      textColor: fgColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.only(left: 0, right: 2),
                        padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                        alignment: Alignment.centerLeft,
                        child: TextFormField(
                          controller: providerSessionLogic.answerController,
                          // "onEditingComplete: () {}" keeps the user from automatically escaping keyboard on submit
                          onEditingComplete: () {},
                          onFieldSubmitted: (res) {
                            // print('res: $res');
                            // don't do anything if user pressed 'submit' when the text field was empty:
                            if (res == '') {
                              FocusScope.of(context).unfocus();
                              return;
                            }

                            // submit the typed answer:
                            providerSessionLogic.queueSubmitTyped();
                          },
                          style: TextStyle(fontSize: 15, color: fgColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (providerSessionLogic.recogRes.length > 1)
              Positioned(
                right: 12,
                bottom: 28,
                child: ColoredCircularInkWell(
                  width: 38,
                  color: Colors.grey.shade300,
                  onTap: () {
                    String allSpokenWords = '';
                    for (var x = 0; x < providerSessionLogic.recogRes.length; x++) {
                      allSpokenWords += '${providerSessionLogic.recogRes[x].words}\n';
                    }

                    showToast(
                        Container(
                          constraints: const BoxConstraints(minHeight: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            color: Colors.greenAccent,
                          ),
                          child: Text('Heard:\n$allSpokenWords'),
                        ),
                        5);
                  },
                  child: const Icon(Icons.more_vert),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
