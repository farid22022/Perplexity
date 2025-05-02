import 'package:flutter/material.dart';
import 'package:perplexity/theme/color.dart';

class SideBarButton extends StatelessWidget {
  final bool collapsed;
  final IconData icon;
  final String text;
  const SideBarButton({
    super.key,   
    required this.collapsed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 14, horizontal: 11),
          child: Icon(
            icon, 
            color: AppColors.iconGrey, 
            size: 30
            ),
        ),
        collapsed
            ? SizedBox(width: 10)
            : Text(
              text,
              style: TextStyle(
                fontSize: 20,
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
      ],
    );
  }
}
