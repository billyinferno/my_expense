import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Icon iconItem;
  final VoidCallback onUserPress;
  final VoidCallback onActionPress;

  const HomeAppBar({super.key, required this.title, required this.iconItem, required this.onUserPress, required this.onActionPress});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onUserPress,
        icon: const Icon(
          Ionicons.person,
          size: 20,
        ),
      ),
      title: title,
      actions: <Widget>[
        IconButton(
            onPressed: onActionPress,
            icon: iconItem,),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
