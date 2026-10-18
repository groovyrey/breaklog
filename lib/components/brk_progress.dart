import 'package:flutter/material.dart';

/// Spinner drawn from a plain arc so no Material progress indicator is used
/// anywhere in the app.
class BrkSpinner extends StatelessWidget {
  const BrkSpinner({super.key, this.size = 26, this.stroke = 2, this.color});

  final double size;
  final double stroke;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        strokeCap: StrokeCap.round,
        valueColor: color == null
            ? null
            : AlwaysStoppedAnimation<Color>(color!),
      ),
    );
  }
}
