// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
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

    if (providerSettings.darkMode && providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode) {
      fgColor = const Color.fromARGB(255, 225, 225, 225);
      bgColor = const Color.fromARGB(255, 0, 0, 0);
      containerColor = const Color.fromARGB(255, 100, 100, 100);
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

            const Positioned(
              right: 10,
              top: 50,
              child: Text('Today: 0/32'),
            ),
            Positioned(
              right: 10,
              top: 75,
              child: Container(
                width: 80,
                height: 10,
                color: Colors.grey[300],
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
            // middle
            Positioned(
              left: (maxWidth / 2) - ((maxWidth / 4) / 2),
              top: maxHeight / 2 - ((maxWidth / 4) / 2),
              child: ColoredCircularInkWell(
                width: maxWidth / 4,
                onTap: () {
                  providerSessionLogic.queueRecog();
                },
                // primary: providerSessionLogic.questionsList.isEmpty ? true : false,
                color: providerSessionLogic.questionsList.isEmpty ? Colors.grey[300] : Colors.lightBlue[100],
                child: const Icon(Icons.mic),
              ),
            ),
            if (providerSessionLogic.isRecoging)
              const Center(
                child: SizedBox(
                  width: 124,
                  height: 124,
                  child: CustomCircularProgressIndicator(),
                ),
              ),
            // middle (end)
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
