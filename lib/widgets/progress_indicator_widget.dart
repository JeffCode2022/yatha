import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double value;
  final double height;

  const ProgressIndicatorWidget({
    Key? key,
    required this.value,
    this.height = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.colorScheme.primary,
                AppTheme.colorScheme.secondary,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
