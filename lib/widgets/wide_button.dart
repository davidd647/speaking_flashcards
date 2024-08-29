import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.onTap,
    required this.child,
    this.primary = false,
    this.disabled = false,
  });

  final Function onTap;
  final Widget child;
  final bool primary;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled
          ? Colors.grey[200]
          : primary
              ? Colors.lightBlue[100]
              : Colors.grey[300],
      child: InkWell(
        onTap: () => onTap(),
        child: Container(
          alignment: Alignment.center,
          height: 64,
          child: child,
        ),
      ),
    );
  }
}
