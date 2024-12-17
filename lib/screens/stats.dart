import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
// import 'package:speaking_flashcards/screens/stats/alt_study_chart.dart';
import 'package:speaking_flashcards/models/chron.dart';
import 'package:speaking_flashcards/helpers/code_to_flag.dart';

class Stats extends StatefulWidget {
  const Stats({super.key});
  static const routeName = '/stats';

  @override
  State<Stats> createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  final answerInput = TextEditingController();
  late ProviderSessionLogic providerSessionLogic;

  // Map<String, List<Chron>>
  Map<String, List<Chron>> groupedChrons = {};

  Map<String, List<Chron>> groupChronsByDate(List<Chron> chrons) {
    Map<String, List<Chron>> groupedChrons = {};

    for (var chron in chrons) {
      if (!groupedChrons.containsKey(chron.date)) {
        groupedChrons[chron.date] = [];
      }
      groupedChrons[chron.date]!.add(chron);
    }

    return groupedChrons;
  }

  void getDataSplitIntoDates() {
    groupedChrons = groupChronsByDate(providerSessionLogic.studyChronList);
  }

  @override
  void initState() {
    super.initState();

    providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    getDataSplitIntoDates();
    // get data split into dates...
  }

  @override
  Widget build(BuildContext context) {
    // final fullWidth = MediaQuery.of(context).size.width;
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color bgColor = Colors.white;
    Color containerColor = Colors.grey.shade200;
    Color fgColor = Colors.black;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      bgColor = Colors.black;
      containerColor = Colors.grey.shade600;
      fgColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Stats',
          style: TextStyle(color: fgColor),
        ),
        iconTheme: IconThemeData(color: fgColor),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // final maxWidth = constraints.maxWidth;
          // final maxHeight = constraints.maxHeight;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                children: [
                  // const StudyChart(),
                  // SizedBox(
                  //   width: fullWidth,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 8, top: 0, right: 24, bottom: 8),
                  //     child: Text(
                  //       'Minutes studied from ${providerSessionLogic.earliestDate.substring(5)} to ${providerSessionLogic.mostRecentDate.substring(5)}:',
                  //       style: TextStyle(color: fgColor),
                  //       textAlign: TextAlign.end,
                  //     ),
                  //   ),
                  // ),
                  // const AltStudyChart(),
                  Text(
                    'Total time studied: ~${(providerSessionLogic.totalHoursStudied).round()}hrs',
                    style: TextStyle(color: fgColor),
                  ),
                  const SizedBox(height: 16.0),
                  ...groupedChrons.entries.map((g) {
                    return Container(
                      color: containerColor,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          ...g.value.map((Chron chron) {
                            String langCombo = chron.languageCombo.split('/').map((lang) => codeToFlag(lang)).join();

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('d: ${chron.date.substring(5)}        l: $langCombo'),
                                Text(
                                  chron.timeStudied < 120
                                      ? '${chron.timeStudied}s'
                                      : '${chron.timeStudied > 60 * 5 ? '⭐️' : ''} ${chron.timeStudied ~/ 60}m${chron.timeStudied % 60 < 10 ? '0' : ''}${chron.timeStudied % 60}s',
                                ),
                              ],
                            );
                          })
                        ],
                      ),
                    );
                  }),
                  if (providerSessionLogic.batchHistoryList.isNotEmpty) const SizedBox(height: 12),
                  if (providerSessionLogic.batchHistoryList.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('Added from Community:'),
                    ),
                  if (providerSessionLogic.batchHistoryList.isNotEmpty)
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...providerSessionLogic.batchHistoryList.map(
                              (collection) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${collection.category},'),
                                      Flexible(
                                        child: Text(
                                          '${collection.name},',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(collection.date.toString()),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
