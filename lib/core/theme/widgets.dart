import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Primary emerald button with gradient and glow. Scales down slightly while pressed.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.light = false});
  final String label;
  final VoidCallback? onTap;
  final bool light;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final light = widget.light;
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : .45,
            duration: const Duration(milliseconds: 150),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.button),
                color: light ? Colors.white : null,
                border: light ? Border.all(color: C.emerald.withValues(alpha: .35)) : null,
                gradient: light
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.emeraldTop, C.emeraldBottom]),
                boxShadow: light
                    ? null
                    : [BoxShadow(color: C.emerald.withValues(alpha: .3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: ui(17, color: light ? C.emerald : Colors.white, weight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded group, iOS settings style.
class Group extends StatelessWidget {
  const Group({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(R.card)),
        child: child,
      );
}

/// Grey caption above a [Group].
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 6),
        child: Semantics(header: true, child: Text(text, style: ui(13, color: C.grey))),
      );
}

/// The Minha mark: two pointed arches forming an "m" (a mihrab), gold eight-point star inside.
class MinhaMark extends StatelessWidget {
  const MinhaMark({super.key, this.size = 40, this.color = Colors.white, this.star = C.gold});
  final double size;
  final Color color;
  final Color star;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Minha',
        image: true,
        child: CustomPaint(size: Size.square(size), painter: MarkPainter(color, star)),
      );
}

/// The "minha" wordmark: lowercase Newsreader.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28, this.color = C.ink});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text('minha', style: serif(size, color: color, weight: FontWeight.w500, height: 1).copyWith(letterSpacing: -0.5));
}

class MarkPainter extends CustomPainter {
  MarkPainter(this.color, this.star);
  final Color color;
  final Color star;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(18, 82)
      ..lineTo(18, 50)
      ..cubicTo(18, 36, 25, 27, 34, 19)
      ..cubicTo(43, 27, 50, 36, 50, 50)
      ..lineTo(50, 82)
      ..moveTo(50, 50)
      ..cubicTo(50, 36, 57, 27, 66, 19)
      ..cubicTo(75, 27, 82, 36, 82, 50)
      ..lineTo(82, 82);
    canvas.drawPath(path, p);
    final f = Paint()..color = star;
    canvas.save();
    canvas.translate(66, 58);
    canvas.drawRect(const Rect.fromLTWH(-6.5, -6.5, 13, 13), f);
    canvas.rotate(0.785398);
    canvas.drawRect(const Rect.fromLTWH(-6.5, -6.5, 13, 13), f);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MarkPainter old) => old.color != color || old.star != star;
}

/// Dark mesh background (emerald, blue, gold) used behind the feed and iftar screen.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, this.goldTop = false});
  final bool goldTop;
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        color: C.night,
        child: Stack(fit: StackFit.expand, children: [
          _blob(goldTop ? const Alignment(0, -1.1) : const Alignment(-0.8, -0.9), goldTop ? C.gold : C.meshGreen,
              goldTop ? .5 : .45),
          _blob(const Alignment(1.1, 0.2), C.meshBlue, .5),
          _blob(const Alignment(-0.6, 1.1), goldTop ? C.meshGreen : C.meshAmber, .3),
        ]),
      ),
    );
  }

  Widget _blob(Alignment a, Color c, double o) => Align(
        alignment: a,
        child: Container(
          width: 520,
          height: 520,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: o), c.withValues(alpha: 0)]),
          ),
        ),
      );
}
