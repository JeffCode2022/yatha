import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool showIcon;

  const StatusBadge({
    Key? key,
    required this.status,
    this.fontSize = 12,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Al día':
      case 'Pagada':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Vencido':
      case 'Vencida':
        color = AppTheme.tertiaryColor;
        icon = Icons.error;
        break;
      default:
        color = AppTheme.secondaryColor;
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              size: fontSize + 2,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

