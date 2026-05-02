import 'package:flutter/material.dart';
import 'package:my_expense/utils/icon/my_ionicons.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Icon iconItem;
  final Icon? additionalIconItem;
  final VoidCallback onUserPress;
  final VoidCallback onActionPress;
  final VoidCallback? onAdditionalActionPress;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.iconItem,
    this.additionalIconItem,
    required this.onUserPress,
    required this.onActionPress,
    this.onAdditionalActionPress,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onUserPress,
        icon: Icon(
          MyIonicons(MyIoniconsData.person).data,
          size: 20,
        ),
      ),
      title: title,
      actions: <Widget>[
        (
          onAdditionalActionPress == null || onAdditionalActionPress == null ?
          const SizedBox.shrink() :
          IconButton(
            onPressed: onAdditionalActionPress!,
            icon: additionalIconItem!,
          )
        ),
        IconButton(
          onPressed: onActionPress,
          icon: iconItem,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
