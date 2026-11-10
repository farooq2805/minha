import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const emerald = Color(0xFF00875A);
  static const emeraldTop = Color(0xFF00A86B);
  static const emeraldBottom = Color(0xFF00804F);
  static const deep = Color(0xFF00573A);
  static const glow = Color(0xFF2BE08F);
  static const gold = Color(0xFFE7C48A);
  static const night = Color(0xFF04201A);
  static const ink = Color(0xFF1C1C1E);
  static const grey = Color(0xFF6C6C70);
  static const grouped = Color(0xFFF2F2F7);
  static const hair = Color(0xFFD1D1D6);
}

TextStyle arabic(double size, {Color color = C.ink, double height = 1.9}) =>
    GoogleFonts.getFont('Amiri Quran', fontSize: size, color: color, height: height);

TextStyle serif(double size, {Color color = C.ink, double height = 1.4, FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.getFont('Newsreader', fontSize: size, color: color, height: height, fontWeight: weight);

TextStyle ui(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double? height, double spacing = 0}) =>
    GoogleFonts.getFont('Inter Tight', fontSize: size, color: color, fontWeight: weight, height: height, letterSpacing: spacing);

TextStyle largeTitle({Color color = C.ink}) => ui(34, color: color, weight: FontWeight.w700, spacing: -0.75, height: 1.1);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.emerald, primary: C.emerald),
    scaffoldBackgroundColor: C.grouped,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(textTheme: GoogleFonts.getTextTheme('Inter Tight', base.textTheme));
}

/// Primary emerald button with gradient and glow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.light = false});
  final String label;
  final VoidCallback? onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: light ? Colors.white : null,
            border: light ? Border.all(color: C.emerald.withOpacity(.35)) : null,
            gradient: light
                ? null
                : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.emeraldTop, C.emeraldBottom]),
            boxShadow: light ? null : [BoxShadow(color: C.emerald.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Text(label, style: ui(17, color: light ? C.emerald : Colors.white, weight: FontWeight.w600)),
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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

/// The Minha mark: two pointed arches forming an "m", gold star inside.
class MinhaMark extends StatelessWidget {
  const MinhaMark({super.key, this.size = 40, this.color = Colors.white, this.star = C.gold});
  final double size;
  final Color color;
  final Color star;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter(color, star));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.star);
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
  bool shouldRepaint(covariant _MarkPainter old) => old.color != color || old.star != star;
}

/// Dark mesh background used on the feed and iftar screens.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, this.goldTop = false});
  final bool goldTop;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.night,
      child: Stack(fit: StackFit.expand, children: [
        _blob(goldTop ? const Alignment(0, -1.1) : const Alignment(-0.8, -0.9), goldTop ? C.gold : const Color(0xFF00C878), goldTop ? .5 : .45),
        _blob(const Alignment(1.1, 0.2), const Color(0xFF274C78), .5),
        _blob(const Alignment(-0.6, 1.1), goldTop ? const Color(0xFF00C878) : const Color(0xFFC49660), .3),
      ]),
    );
  }

  Widget _blob(Alignment a, Color c, double o) => Align(
        alignment: a,
        child: Container(
          width: 520,
          height: 520,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withOpacity(o), c.withOpacity(0)]),
          ),
        ),
      );
}
