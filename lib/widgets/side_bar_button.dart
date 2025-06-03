// lib/widgets/side_bar_button.dart
import 'package:flutter/material.dart';
import 'package:perplexity/theme/color.dart';

class SideBarButton extends StatelessWidget {
  final bool collapsed;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const SideBarButton({
    super.key,
    required this.collapsed,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: collapsed ? 0.6 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 14, horizontal: 11),
              child: Icon(
                icon,
                color: AppColors.iconGrey,
                size: 30,
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: collapsed ? 0 : 100,
              child: collapsed
                  ? SizedBox.shrink()
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}