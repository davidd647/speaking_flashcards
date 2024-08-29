import 'package:flutter/material.dart';

class CustomCircularProgressIndicator extends StatefulWidget {
  const CustomCircularProgressIndicator({super.key});

  @override
  CustomCircularProgressIndicatorState createState() => CustomCircularProgressIndicatorState();
}

class CustomCircularProgressIndicatorState extends State<CustomCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    const green = Color.fromARGB(255, 19, 213, 29);
    const black = Color.fromARGB(255, 59, 59, 59);

    _colorAnimation = TweenSequence<Color?>(
      [
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: black, end: green) as Animatable<Color?>,
        ),
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: green, end: black) as Animatable<Color?>,
        ),
      ],
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CircularProgressIndicator(
          value: _animation.value,
          valueColor: _colorAnimation,
          strokeWidth: 10,
        );
      },
    );
  }
}
