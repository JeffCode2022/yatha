import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double height;
  final double width;
  final Alignment alignment;
  final BoxBorder border;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.height = double.infinity,
    this.width = double.infinity,
    this.alignment = Alignment.center,
    this.border = const Border.fromBorderSide(
      BorderSide(color: Colors.white, width: 1.5),
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      constraints: BoxConstraints(
        minHeight: height == double.infinity ? 0 : height,
        minWidth: width == double.infinity ? 0 : width,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor.withOpacity(0.5),
                  backgroundColor.withOpacity(0.2),
                ],
              ),
            ),
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    );
  }
}
