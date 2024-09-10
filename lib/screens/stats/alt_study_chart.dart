import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';

class AltStudyChart extends StatefulWidget {
  const AltStudyChart({super.key});

  @override
  State<AltStudyChart> createState() => _AltStudyChartState();
}

class _AltStudyChartState extends State<AltStudyChart> {
  late ProviderSessionLogic providerSessionLogic;

  List<Map<String, dynamic>> multiChartBars = [];

  getData() async {
    multiChartBars = await providerSessionLogic.getMultibarHistory();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);

    // given the start date:
    // providerSessionLogic.getMultibarHistory();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
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
                    maxY: providerSessionLogic.maxMins,
                    minY: 0,
                    barGroups: multiChartBars.reversed
                        .map(
                          (chartBar) => BarChartGroupData(
                            x: chartBar['i'],
                            barRods: (chartBar['y'] as List<BarChartRodData>),
                            groupVertically: true, // Add this line
                            // showingTooltipIndicators: [0], // Show tooltip for the first bar by default
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
