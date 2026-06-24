import 'package:flutter/material.dart';

class CurtainDrop extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration itemDuration;

  const CurtainDrop({
    super.key,
    required this.child,
    this.index = 0,
    this.itemDuration = const Duration(milliseconds: 200),
  });

  @override
  State<CurtainDrop> createState() => _CurtainDropState();
}

class _CurtainDropState extends State<CurtainDrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.itemDuration,
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    final delay = widget.index * 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}
