import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/model/transaction_wallet_minmax_date_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';

class CardFace extends StatelessWidget {
  final WalletModel wallet;
  final TransactionWalletMinMaxDateModel? minMaxDate;
  const CardFace({Key? key, required this.wallet, this.minMaxDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fCCY = new NumberFormat("#,##0.00", "en_US");
    
    return Center(
      child: Container(
        height: 150,
        width: 250,
        padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
              colors: <Color>[
                (wallet.enabled ? IconList.getColor(wallet.walletType.type) : secondaryDark),
                (wallet.enabled ? lighten(IconList.getDarkColor(wallet.walletType.type),0.1) : secondaryBackground),
              ]
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 30,
                    width: 30,
                    child: IconList.getIcon(wallet.walletType.type),
                  ),
                  SizedBox(width: 10,),
                  Container(
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(wallet.name),
                        Text(
                          wallet.walletType.type,
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Container(
              color: Colors.transparent,
            )),
            Container(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  wallet.currency.symbol + " " + fCCY.format(wallet.startBalance + wallet.changeBalance),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: (minMaxDate != null),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _dateText(minMaxDate!.minDate),
                      Text(
                        "•••",
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      _dateText(minMaxDate!.maxDate),
                    ],
                  )
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateText(DateTime? date) {
    final DateFormat dtDayMonthYear = DateFormat("dd MMM yyyy");
    if (date == null) {
      return const SizedBox.shrink();
    }
    else {
      return Text(
        dtDayMonthYear.format(date),
        style: const TextStyle(
          fontSize: 10,
        ),
      );
    }
  }
}