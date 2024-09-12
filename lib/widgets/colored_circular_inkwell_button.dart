import 'package:flutter/material.dart';

class ColoredCircularInkWell extends StatelessWidget {
  const ColoredCircularInkWell({
    super.key,
    required this.width,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final double width;
  final Color? color;
  final Function onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(width),
      child: InkWell(
        borderRadius: BorderRadius.circular(width),
        onTap: () => onTap(),
        child: SizedBox(
          width: width,
          height: width,
          child: child,
        ),
      ),
    );
  }
}
