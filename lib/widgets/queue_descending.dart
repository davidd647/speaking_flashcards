import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';

class QuestionQueueDescending extends StatelessWidget {
  const QuestionQueueDescending({
    super.key,
    required this.maxHeight,
    required this.maxWidth,
  });

  final double maxHeight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    const double questionHeight = 18.0;

    final providerSettings = Provider.of<ProviderSettings>(context);

    Color containerColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade400;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      containerColor = const Color.fromRGBO(69, 69, 69, 1);
      textColor = const Color.fromRGBO(142, 142, 142, 1);
    }

    return Stack(
      children: [
        ...providerSessionLogic.questionsList.map((question) {
          double bottom = 155 + (question.order - 1) * questionHeight;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            // width: maxWidth,
            left: 20,
            right: 20,
            // width: maxWidth * 0.42,
            // right: 0,
            height: questionHeight,
            bottom: bottom,

            child: Container(
              padding: const EdgeInsets.only(left: 6, right: 6),
              color: containerColor,
              // child: Opacity(
              //   opacity: question.level > 3 ? 0.15 : 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${question.order + 1} ', style: TextStyle(color: textColor)),
                  // if (question.level >= 3) Icon(Icons.check, color: textColor, size: 12),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        question.q,
                        // '${question.level}/${question.spiritLevel} ${question.q} (${question.a})',
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: textColor, // Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  if (!providerSettings.debugMode && question.level < 3)
                    Container(
                      width: 18,
                      height: 18,
                      padding: const EdgeInsets.all(2),
                      child: WedgeWidget(percentage: question.level * 0.33, color: textColor),
                    ),
                  if (question.level >= 3)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.lightBlue[200],
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                      // child: Text('👍'),
                    ),
                  if (providerSettings.debugMode)
                    Text(
                      '${question.level}/${question.spiritLevel}',
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: textColor,
                      ),
                    ),
                ],
              ),
            ),
            // ),
          );
        }),
      ],
    );
  }
}

class WedgePainter extends CustomPainter {
  final double percentage; // The percentage of the circle to draw
  final Color textColor;

  WedgePainter({required this.percentage, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textColor
      ..style = PaintingStyle.fill;

    // Define the rectangle for the circle
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the arc (wedge)
    canvas.drawArc(
      rect,
      -pi / 2, // Start angle (top center)
      2 * pi * percentage, // Sweep angle based on percentage
      true, // Use center for wedge shape
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class WedgeWidget extends StatelessWidget {
  final double percentage; // The percentage of the circle to draw
  final Color color;

  WedgeWidget({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(200, 200), // Specify the size of the circle
        painter: WedgePainter(percentage: percentage, textColor: color),
      ),
    );
  }
}
