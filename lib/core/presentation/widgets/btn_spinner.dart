import 'package:flutter/material.dart';

/// A small circular loading indicator sized for use inside buttons.
/// Defaults to white at 14×14 with 2px stroke — the standard button-loading pattern.
class BtnSpinner extends StatelessWidget {
  const BtnSpinner({super.key, this.size = 14, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
