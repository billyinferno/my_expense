import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class BarButton extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final Color? activeColor;
  final Color? inactiveColor;
  final String text;
  final VoidCallback onTap;

  const BarButton({super.key, required this.index, required this.currentIndex, required this.icon, this.activeColor, this.inactiveColor, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color currActiveColor = (activeColor ?? accentColors[1]);
    Color currInactiveColor = (inactiveColor ?? Colors.white);

    return Expanded(
      child: GestureDetector(
        onTap: (() {
          onTap();
        }),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: (currentIndex == index ? currActiveColor : currInactiveColor),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    color: (currentIndex == index ? currActiveColor : currInactiveColor),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ); 
  }
}