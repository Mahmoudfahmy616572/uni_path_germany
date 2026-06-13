import 'package:flutter/material.dart';

class AnimatedScreenContent extends StatelessWidget {
  final Widget child;
  final int tabIndex;

  const AnimatedScreenContent({
    super.key,
    required this.child,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) => child;
}
