import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';

class StudyChart extends StatefulWidget {
  const StudyChart({super.key});

  @override
  StudyChartState createState() => StudyChartState();
}

class StudyChartState extends State<StudyChart> {
  @override
  Widget build(BuildContext context) {
    // final theme = Provider.of<ThemeNotifier>(context);
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final fullWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          width: fullWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 0, right: 24, bottom: 8),
            child: Text(
              'Minutes studied from ${providerSessionLogic.earliestDate.substring(5)} to ${providerSessionLogic.mostRecentDate.substring(5)}:',
              style: const TextStyle(color: Colors.blue),
              textAlign: TextAlign.end,
            ),
          ),
        ),
        Container(
          height: 200,
          width: fullWidth - 25,
          padding: const EdgeInsets.fromLTRB(0, 0, 24, 24.0),
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(
                show: true,
                border: const Border.fromBorderSide(
                  BorderSide(
                    color: Color.fromARGB(255, 255, 255, 255),
                    width: 0.5,
                  ),
                ),
              ),
              alignment: BarChartAlignment.spaceAround,
              maxY: providerSessionLogic.maxMins,
              minY: 0, //minMins,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 30.0,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toInt()}min -',
                        style: const TextStyle(
                          color: Colors.lightBlue,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 42.0,
                  ),
                ),
              ),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 30.0,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: Color(0xFFececec),
                  dashArray: null,
                  strokeWidth: 1,
                ),
              ),
              barGroups: [
                ...providerSessionLogic.chartBars.reversed.map(
                  (chartBar) {
                    return BarChartGroupData(x: chartBar['i'], barRods: [
                      BarChartRodData(
                        // id: chartBar['i'],
                        toY: chartBar['y'],
                        width: 6,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
        Text(
          'Total time studied: ~${(providerSessionLogic.totalHoursStudied).round()}hrs',
          style: const TextStyle(color: Colors.blue),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
