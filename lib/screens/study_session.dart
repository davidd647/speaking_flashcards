// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/widgets/grey_ink_well.dart';
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
    // providerSessionLogic.skipped = true;
    providerSessionLogic.queueSubmitTyped();
  }

  FToast fToast = FToast();

  void showToast(Widget child, int duration) {
    fToast.showToast(
      child: child,
      gravity: ToastGravity.CENTER,
      toastDuration: Duration(seconds: duration),
    );

    // Fluttertoast.showToast(
    //   msg: message,
    //   toastLength: Toast.LENGTH_LONG,
    //   gravity: ToastGravity.CENTER,
    //   timeInSecForIosWeb: 5,
    //   backgroundColor: Colors.blueGrey.withOpacity(0.8),
    //   textColor: Colors.black,
    //   fontSize: 16.0,
    //   webPosition: "center",
    // );
    // Fluttertoast.showToast(child: Text('hi'));
  }

  @override
  void initState() {
    super.initState();

    providerSettings = Provider.of<ProviderSettings>(context, listen: false);
    providerSettings.init();
    providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    providerSessionLogic.init(showToast);
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    return Scaffold(
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
                      Colors.white.withOpacity(1),
                      Colors.white.withOpacity(0),
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
                      color: providerSessionLogic.userIsActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  // if (providerSessionLogic.dailyStreak != 0)
                  Text(
                    'Streak: ${providerSessionLogic.dailyStreak}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: providerSessionLogic.dailyStreak != 0 ? Colors.black : Colors.grey,
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
                  GreyInkWell(
                    primary: providerSessionLogic.questionsList.isEmpty ? true : false,
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      // open menu
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: const Icon(Icons.add),
                  ),
                  GreyInkWell(
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      providerSessionLogic.queueSynthQuestion();
                    },
                    child: const FittedBox(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(height: 15),
                        Icon(Icons.play_arrow),
                        Text('Question'),
                        SizedBox(height: 15),
                      ]),
                    ),
                  ),
                  GreyInkWell(
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      providerSessionLogic.queueSynthInput();
                    },
                    child: const FittedBox(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(height: 15),
                        Icon(Icons.play_arrow),
                        Text('Input'),
                        SizedBox(height: 15),
                      ]),
                    ),
                    // child: const Icon(Icons.bar_chart_sharp),
                  ),
                  GreyInkWell(
                    width: maxWidth / 4 - 12.5,
                    height: maxWidth / 4 - 20,
                    onTap: () {
                      providerSessionLogic.firstRecogGuessHintPlayed = false;
                      handleSkip();
                    },
                    child: const FittedBox(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(height: 15),
                        Icon(Icons.skip_next),
                        Text('Skip'),
                        SizedBox(height: 15),
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
              child: CircularInkWell(
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
                color: Colors.grey[300],
                child: Row(
                  children: [
                    FlagBox(flag: providerSessionLogic.qDisplayFlags, label: 'Q'),
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
                        style: const TextStyle(fontSize: 15),
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
                color: Colors.grey[300],
                child: Row(
                  children: [
                    FlagBox(flag: providerSessionLogic.qDisplayFlags, label: 'A'),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.only(left: 0, right: 2),
                        padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: providerSessionLogic.answerController,
                          style: const TextStyle(fontSize: 15),
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
                child: CircularInkWell(
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

class CircularInkWell extends StatelessWidget {
  const CircularInkWell({
    super.key,
    required this.width,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final double width;
  final Color? color;
  final Function onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(width),
      child: InkWell(
        borderRadius: BorderRadius.circular(width),
        onTap: () => onTap(),
        child: SizedBox(
          width: width,
          height: width,
          child: child,
        ),
      ),
    );
  }
}
