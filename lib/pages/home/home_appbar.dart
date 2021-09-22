import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Icon iconItem;
  final VoidCallback onUserPress;
  final VoidCallback onActionPress;

  HomeAppBar({required this.title, required this.iconItem, required this.onUserPress, required this.onActionPress});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onUserPress,
        icon: Icon(
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
  Size get preferredSize => new Size.fromHeight(AppBar().preferredSize.height);
}
