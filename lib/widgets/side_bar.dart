import 'package:flutter/material.dart';
import 'package:perplexity/theme/color.dart';
import 'package:perplexity/widgets/side_bar_button.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool collapsed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 64 : 164,
      color: AppColors.sideNav,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.auto_awesome_mosaic,
            color: AppColors.iconGrey,
            size: collapsed ? 40 : 50,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  collapsed
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
              children: [
                SideBarButton(
                  collapsed: collapsed,
                  icon: Icons.add,
                  text: "Home",
                ),
                SideBarButton(
                  collapsed: collapsed,
                  icon: Icons.search,
                  text: "Search",
                ),
                SideBarButton(
                  collapsed: collapsed,
                  icon: Icons.language,
                  text: "Language",
                ),
                SideBarButton(
                  collapsed: collapsed,
                  icon: Icons.auto_awesome,
                  text: "Discover",
                ),
                SideBarButton(
                  collapsed: collapsed,
                  icon: Icons.cloud_outlined,
                  text: "Library",
                ),

                const Spacer(),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                collapsed = !collapsed;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(vertical: 14),
              child: Icon(
                collapsed
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_left,
                color: AppColors.iconGrey,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
