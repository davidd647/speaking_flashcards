import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
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
                      width: 64,
                      height: 64,
                      onTap: () {
                        // open menu
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus(); // close soft keyboard
                      },
                      child: const Icon(Icons.close),
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
                color: Colors.grey[200],
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
                          const Text(
                            'Question:',
                            style: TextStyle(fontSize: 17),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WideButton(
                                onTap: () {
                                  handleRecordQuestion();
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  height: 47,
                                  child: Stack(
                                    children: [
                                      const Center(child: Icon(Icons.mic)),
                                      if (providerSessionLogic.isRecogingQuestion)
                                        Container(
                                          alignment: Alignment.center,
                                          width: 47,
                                          height: 47,
                                          child: const CustomCircularProgressIndicator(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: const Icon(Icons.play_arrow),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
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
                              child: TextField(controller: providerSessionLogic.questionController),
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
                          const Text(
                            'Answer:',
                            style: TextStyle(fontSize: 17),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WideButton(
                                onTap: () {
                                  // queue a recording...
                                  handleRecordAnswer();
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: Stack(
                                    children: [
                                      const Center(child: Icon(Icons.mic)),
                                      if (providerSessionLogic.isRecogingAnswer)
                                        Container(
                                          alignment: Alignment.center,
                                          width: 47,
                                          height: 47,
                                          child: const CustomCircularProgressIndicator(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 47,
                                  child: const Icon(Icons.play_arrow),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WideButton(
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
                              child: TextField(controller: providerSessionLogic.answerController),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                      child: WideButton(
                        primary: true,
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(BatchAdd.routeName);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.playlist_add, size: 24),
                      ),
                      Text('Batch Add'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Languages.routeName);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.language, size: 24),
                      ),
                      Text('Languages'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Browse.routeName);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.edit, size: 24),
                      ),
                      Text('Browse / Edit'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: WideButton(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Stats.routeName);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.bar_chart_sharp, size: 24),
                      ),
                      Text('Stats'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: WideButton(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(Settings.routeName);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.settings, size: 24),
                      ),
                      Text('Settings'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: WideButton(
                  onTap: () {
                    providerSessionLogic.addInputAsAnswer();
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.check, size: 24),
                      ),
                      Text('Add Input as Acceptable Soundalike'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: WideButton(
                  onTap: () {
                    Navigator.pop(context);
                    providerSessionLogic.showPreviousGuessInfo();
                  },
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Icon(Icons.repeat, size: 24),
                      ),
                      Text('Show Previous Guess'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
