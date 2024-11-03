import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final bool showText;
  const CategoryItem({
    super.key,
    required this.category,
    this.showText = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // check if this is expense or income
    Color iconColor = IconColorList.getColor(category.name, category.type);
    Icon icon = IconColorList.getIcon(category.name, category.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: iconColor,
            border: Border.all(
              color: (isSelected ? accentColors[4] : Colors.transparent),
              width: 2.0,
              style: BorderStyle.solid,
            )
          ),
          child: icon,
        ),
        Visibility(
          visible: showText,
          child: const SizedBox(height: 10,)
        ),
        Visibility(
          visible: showText,
          child: Text(
            category.name,
            style: const TextStyle(
              fontSize: 10,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}