import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  final Color backgroundColor;

  const ProgressIndicatorWidget({
    Key? key,
    required this.value,
    this.height = 4.0,
    required this.color,
    this.backgroundColor = const Color(0xFFE0E0E0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
