import 'dart:async';

import 'package:flutter/material.dart';

/// One-shot entrance animation: fades + gently slides a child in.
///
/// - Honors reduced-motion (jumps to the final state instantly).
/// - Finite by design (never loops), so `pumpAndSettle` in tests settles.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.1),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;

  /// Applied before the animation starts (used for stagger lists).
  final Duration delay;
  final Offset offset;
  final Curve curve;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  Timer? _delayTimer;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0,
    );
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion != null) return;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == true) {
      _controller.value = 1;
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Lays children out in a [Column] and staggers their entrance.
///
/// Each child starts [interval] after the previous one (default 70ms),
/// producing a soft "wave" — the standard motion pattern for lists/cards.
class StaggerList extends StatelessWidget {
  const StaggerList({
    super.key,
    required this.children,
    this.interval = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 380),
    this.offset = const Offset(0, 0.1),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration interval;
  final Duration duration;
  final Offset offset;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          Entrance(
            delay: interval * i,
            duration: duration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}

/// Adds subtle press feedback (scale down ~150ms) on pointer-down.
///
/// Uses a raw [Listener] so it never competes with inner tappables
/// (InkWell/GestureDetector) — no gesture-arena conflicts.
/// Honors reduced-motion: no scaling.
class AnimatedPress extends StatefulWidget {
  const AnimatedPress({
    super.key,
    required this.child,
    this.pressedScale = 0.985,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress> {
  bool _pressed = false;
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion ??= MediaQuery.disableAnimationsOf(context);
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale =
        _reduceMotion == true ? 1.0 : (_pressed ? widget.pressedScale : 1.0);
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}