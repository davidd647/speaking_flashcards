import 'package:flutter/material.dart';

class GreyInkWell extends StatelessWidget {
  const GreyInkWell({
    super.key,
    required this.height,
    required this.width,
    required this.onTap,
    required this.child,
    this.primary = false,
  });

  final double width;
  final double height;
  final Function onTap;
  final Widget child;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? Colors.lightBlue[100] : Colors.grey[300],
      child: InkWell(
        onTap: () => onTap(),
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }
}
