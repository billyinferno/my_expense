import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';

class MyItemList extends StatelessWidget {
  final String type;
  final Color iconColor;
  final Widget icon;
  final String title;
  final TextStyle? titleStyle;
  final String subTitle;
  final TextStyle? subTitleStyle;
  final String? description;
  final TextStyle? descriptionStyle;
  final String symbol;
  final double amount;
  final NumberFormat? amountFormat;
  final Color? amountColor;
  final String? symbolTo;
  final double? amountTo;
  final NumberFormat? amountFormatTo;
  final Color? amountColorTo;
  final EdgeInsets? padding;
  final Color? borderColor;
  const MyItemList({
    super.key,
    required this.iconColor,
    required this.icon,
    required this.type,
    required this.title,
    this.titleStyle,
    required this.subTitle,
    this.subTitleStyle,
    this.description,
    this.descriptionStyle,
    required this.symbol,
    required this.amount,
    this.amountFormat,
    this.amountColor,
    this.symbolTo,
    this.amountTo,
    this.amountFormatTo,
    this.amountColorTo,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat nf = (amountFormat ?? NumberFormat("#,##0.00", "en_US"));
    final NumberFormat nfTo = (amountFormatTo ?? NumberFormat("#,##0.00", "en_US"));

    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (borderColor ?? primaryLight)
          )
        )
      ),
      padding: (padding ?? const EdgeInsets.fromLTRB(10, 5, 10, 5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: iconColor,
            ),
            child: icon,
          ),
          const SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: (titleStyle ?? const TextStyle(color: textColor)),
                ),
                Text(
                  subTitle,
                  style: (subTitleStyle ?? const TextStyle(
                    fontSize: 12,
                    color: textColor2,
                  )),
                  overflow: TextOverflow.ellipsis,
                ),
                _getDescription(),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$symbol ${nf.format(amount)}",
                style: TextStyle(
                  color: (amountColor ?? textColor)
                ),
              ),
              Visibility(
                visible: (symbolTo != null && amountTo != null),
                child: Text(
                  "${symbolTo ?? ''} ${nfTo.format(amountTo ?? 0)}",
                  style: TextStyle(
                    color: lighten((amountColorTo ?? (amountColor ?? textColor)), 0.25),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getDescription() {
    if (description == null) {
      return const SizedBox.shrink();
    }
    else {
      if (description!.isEmpty) {
        return const SizedBox.shrink();
      }
    }

    return Text(
      (description ?? ''),
      style: (descriptionStyle ?? const TextStyle(
        fontSize: 10,
        color: textColor2,
      )),
      overflow: TextOverflow.ellipsis,
    );
  }
}