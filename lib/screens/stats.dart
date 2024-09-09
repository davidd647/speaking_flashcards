import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/screens/stats/chart.dart';

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
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
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
              : Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    children: [
                      const StudyChart(),
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
                );
        },
      ),
    );
  }
}
