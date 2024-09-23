import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/widgets/colored_inkwell_button.dart';
import 'package:speaking_flashcards/widgets/custom_circular_progress_indicator.dart';
import 'package:speaking_flashcards/widgets/wide_button.dart';
import 'package:speaking_flashcards/screens/batch_add.dart';
import 'package:speaking_flashcards/screens/browse.dart';
import 'package:speaking_flashcards/screens/languages.dart';
import 'package:speaking_flashcards/screens/settings.dart';
import 'package:speaking_flashcards/screens/stats.dart';

class MenuContainer extends StatefulWidget {
  const MenuContainer({
    super.key,
  });

  @override
  State<MenuContainer> createState() => _MenuContainerState();
}

class _MenuContainerState extends State<MenuContainer> {
  late ProviderSessionLogic providerSessionLogic;

  void handleRecordQuestion() {
    if (providerSessionLogic.isRecoging) return;
    // stop focusing on the keyboard if the keyboard is focused:
    FocusScope.of(context).unfocus();

    providerSessionLogic.queueNonSubmitRecog('question');
  }

  void handleRecordAnswer() {
    if (providerSessionLogic.isRecoging) return;
    // stop focusing on the keyboard if the keyboard is focused:
    FocusScope.of(context).unfocus();

    providerSessionLogic.queueNonSubmitRecog('answer');
  }

  @override
  void initState() {
    super.initState();

    providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    // final maxWidth = MediaQuery.of(context).size.width;

    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color fgColor = const Color.fromARGB(255, 44, 44, 44);
    Color containerColor = const Color.fromARGB(255, 220, 220, 220);
    Color bgColor = const Color.fromARGB(255, 249, 247, 247);
    Color disabledTextColor = const ui.Color.fromARGB(255, 150, 150, 150); // doesn't change for dark mode...

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      fgColor = const Color.fromARGB(255, 225, 225, 225);
      containerColor = const Color.fromARGB(255, 100, 100, 100);
      bgColor = const Color.fromARGB(255, 0, 0, 0);
    }

    return Drawer(
      backgroundColor: Colors.black12,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(
                height: 100,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ColoredInkWellButton(
                      color: containerColor,
                      width: 64,
                      height: 64,
                      onTap: () {
                        // open menu
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus(); // close soft keyboard
                      },
                      child: Icon(Icons.close, color: fgColor),
                    ),
                    const Flexible(
                      fit: FlexFit.tight,
                      child: FittedBox(
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          child: Text(
                            'Speaking Flashcards',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Container(
                color: containerColor,
                margin: const EdgeInsets.only(left: 10, right: 10),
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      height: 47, // same as FlagBox (as of 20-Aug-2024)
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question:',
                            style: TextStyle(
                              fontSize: 17,
                              color: fgColor,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WideButton(
                                color: bgColor,
                                onTap: () {
                                  // stop focusing on the keyboard if the keyboard is focused:
                                  FocusScope.of(context).unfocus();

                                  handleRecordQuestion();
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  height: 47,
                                  child: Stack(
                                    children: [
                                      Center(child: Icon(Icons.mic, color: fgColor)),
                                      if (providerSessionLogic.isRecogingQuestion)
                                        Container(
                                          alignment: Alignment.center,
                                          width: 47,
                                          height: 47,
                                          child: CustomCircularProgressIndicator(
                                            color1: bgColor,
                                            color2: Colors.greenAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                color: bgColor,
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Icon(Icons.play_arrow, color: fgColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                color: bgColor,
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Text(providerSessionLogic.qDisplayFlags),
                                ),
                              ),
                            ],
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
                                controller: providerSessionLogic.questionController,
                                style: TextStyle(color: fgColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      height: 47, // same as FlagBox (as of 20-Aug-2024)
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Answer:',
                            style: TextStyle(
                              fontSize: 17,
                              color: fgColor,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WideButton(
                                color: bgColor,
                                onTap: () {
                                  // stop focusing on the keyboard if the keyboard is focused:
                                  FocusScope.of(context).unfocus();

                                  // queue a recording...
                                  handleRecordAnswer();
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Stack(
                                    children: [
                                      Center(child: Icon(Icons.mic, color: fgColor)),
                                      if (providerSessionLogic.isRecogingAnswer)
                                        Container(
                                          alignment: Alignment.center,
                                          width: 47,
                                          height: 47,
                                          child: CustomCircularProgressIndicator(
                                            color1: bgColor,
                                            color2: Colors.greenAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                color: bgColor,
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Icon(Icons.play_arrow, color: fgColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                color: bgColor,
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Text(providerSessionLogic.aDisplayFlags),
                                ),
                              ),
                            ],
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
                              margin: const EdgeInsets.only(left: 0, right: 2),
                              padding: const EdgeInsets.only(left: 0, right: 2, bottom: 3.0),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: providerSessionLogic.answerController,
                                style: TextStyle(color: fgColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                      child: WideButton(
                        color: Colors.lightBlue.shade100,
                        onTap: () async {
                          final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);

                          bool successfullyAddedFlashcard = await providerSessionLogic.addQuestion(
                            providerSessionLogic.questionController.text,
                            providerSessionLogic.answerController.text,
                          );

                          if (successfullyAddedFlashcard) {
                            providerSessionLogic.questionController.text = '';
                            providerSessionLogic.answerController.text = '';
                          }
                        },
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Icon(Icons.add, size: 24),
                            ),
                            Text('Add Flashcard'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(BatchAdd.routeName);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.playlist_add, size: 24, color: fgColor),
                      ),
                      Text('Batch Add', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Languages.routeName);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.language, size: 24, color: fgColor),
                      ),
                      Text('Languages', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Browse.routeName);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.edit, size: 24, color: fgColor),
                      ),
                      Text('Browse / Edit', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Stats.routeName);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.bar_chart_sharp, size: 24, color: fgColor),
                      ),
                      Text('Stats', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Settings.routeName);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.settings, size: 24, color: fgColor),
                      ),
                      Text('Settings', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    if (providerSessionLogic.answerController.text == '') return;
                    providerSessionLogic.addInputAsAnswer();
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(
                          Icons.check,
                          size: 24,
                          color: (providerSessionLogic.answerController.text != '') ? fgColor : disabledTextColor,
                        ),
                      ),
                      Text(
                        'Add Input as Soundalike ',
                        style: TextStyle(
                          color: (providerSessionLogic.answerController.text != '') ? fgColor : disabledTextColor,
                        ),
                      ),
                      if (providerSessionLogic.answerController.text == '')
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '(Empty)',
                              style: TextStyle(color: fgColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      if (providerSessionLogic.answerController.text != '')
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              '(${providerSessionLogic.answerController.text})',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: fgColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: WideButton(
                  color: containerColor,
                  onTap: () {
                    Navigator.pop(context);
                    providerSessionLogic.showPreviousGuessInfo();
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.repeat, size: 24, color: fgColor),
                      ),
                      Text('Show Previous Guess', style: TextStyle(color: fgColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Center(child: Text('version: 1.0.15+16', style: TextStyle(color: fgColor))),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}
