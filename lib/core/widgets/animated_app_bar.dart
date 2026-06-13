import 'package:flutter/material.dart';

class AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const AnimatedAppBar({super.key, required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => child;
}
