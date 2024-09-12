import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/screens/stats/alt_study_chart.dart';

class Stats extends StatefulWidget {
  const Stats({super.key});
  static const routeName = '/stats';

  @override
  State<Stats> createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  final answerInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    Color bgColor = Colors.white;
    // Color containerColor = Colors.grey.shade200;
    Color fgColor = Colors.black;

    if (providerSettings.darkMode) {
      bgColor = Colors.black;
      // containerColor = Colors.grey.shade600;
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
          final maxWidth = constraints.maxWidth;
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
                        // const StudyChart(),
                        SizedBox(
                          width: fullWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 0, right: 24, bottom: 8),
                            child: Text(
                              'Minutes studied from ${providerSessionLogic.earliestDate.substring(5)} to ${providerSessionLogic.mostRecentDate.substring(5)}:',
                              style: TextStyle(color: fgColor),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                        const AltStudyChart(),
                        Text(
                          'Total time studied: ~${(providerSessionLogic.totalHoursStudied).round()}hrs',
                          style: TextStyle(color: fgColor),
                        ),
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
