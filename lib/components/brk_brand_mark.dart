import 'package:flutter/material.dart';

/// The BreakLog mark. Sits to the left of a header title, or above the
/// wordmark wherever the brand is introduced.
class BrkBrandMark extends StatelessWidget {
  const BrkBrandMark({super.key, this.height = 26});

  final double height;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/breaklog_logo.png', height: height);
}
