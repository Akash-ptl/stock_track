import 'package:flutter/material.dart';

class BackgroundWave extends StatelessWidget {
  const BackgroundWave({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: 180, // Height of the bottom waves
          child: CustomPaint(
            painter: WavePainter(),
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Back Wave (Lighter opacity)
    final Paint paint1 = Paint()
      ..color = const Color(0xFFDCFCE7).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final Path path1 = Path()
      ..moveTo(0, h * 0.7)
      ..cubicTo(
        w * 0.25, h * 0.45,
        w * 0.55, h * 0.85,
        w, h * 0.5,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path1, paint1);

    // Front Wave (Stronger opacity)
    final Paint paint2 = Paint()
      ..color = const Color(0xFFDCFCE7).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final Path path2 = Path()
      ..moveTo(0, h * 0.85)
      ..cubicTo(
        w * 0.35, h * 0.6,
        w * 0.7, h * 0.95,
        w, h * 0.75,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
