import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';

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
              color: Colors.grey.shade200,
              // child: Opacity(
              //   opacity: question.level > 3 ? 0.15 : 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '${question.order + 1} ${question.level >= 3 ? '✔️' : ''} ${question.q}',
                        // '${question.level}/${question.spiritLevel} ${question.q} (${question.a})',
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.grey.shade400, // Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${question.level}/${question.spiritLevel}',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Colors.grey.shade400,
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
