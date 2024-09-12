import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';

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
    final providerSettings = Provider.of<ProviderSettings>(context);

    // Color bgColor = Colors.white;
    Color fgColor = Colors.black;
    Color containerColor = Colors.grey.shade200;

    if (providerSettings.darkMode) {
      // bgColor = Colors.black;
      fgColor = Colors.white;
      containerColor = Colors.grey.shade600;
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Card(
        color: containerColor,
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
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: containerColor,
                          width: 3,
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
                              style: TextStyle(
                                color: fgColor,
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
                    groupsSpace: 50,
                    alignment: BarChartAlignment.center,
                    barGroups: multiChartBars.reversed
                        .map(
                          (chartBar) => BarChartGroupData(
                            x: chartBar['i'],
                            barRods: (chartBar['y'] as List<BarChartRodData>),
                            groupVertically: true,

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
