import 'package:flutter/material.dart';

class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({super.key, this.isChecked = false, this.size = 28});

  final bool isChecked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isChecked ? const Color(0xFF169B54) : const Color(0xFF6B7280);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isChecked ? color : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.8),
      ),
      child: isChecked
          ? Icon(Icons.check_rounded, size: size - 8, color: Colors.white)
          : null,
    );
  }
}
