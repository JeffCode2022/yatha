import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final double height;
  final double width;
  final double borderRadius;
  final bool isOutlined;

  const AnimatedButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.color = AppTheme.primaryColor,
    this.textColor = Colors.white,
    this.height = 56,
    this.width = double.infinity,
    this.borderRadius = 12,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width,
              decoration: widget.isOutlined
                  ? BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: widget.color,
                        width: 2,
                      ),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: widget.color.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    )
                  : BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: widget.color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.isOutlined ? widget.color : widget.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

