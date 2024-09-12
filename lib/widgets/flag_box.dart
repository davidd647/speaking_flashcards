import 'package:flutter/material.dart';

class FlagBox extends StatelessWidget {
  const FlagBox({
    super.key,
    required this.flag,
    required this.label,
    required this.textColor,
  });

  final String flag;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47,
      width: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // COUNTRY FLAG
          Positioned(
            right: 0,
            top: -8,
            child: Opacity(
              opacity: 0.55,
              child: Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
