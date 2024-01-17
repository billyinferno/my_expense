import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';

class Wallet extends StatelessWidget {
  final WalletModel wallet;
  const Wallet({Key? key, required this.wallet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fCCY = new NumberFormat("#,##0.00", "en_US");
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/wallet/transaction', arguments: wallet);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 10),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  width: 30,
                  child: IconList.getIcon(wallet.walletType.type),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        wallet.walletType.type,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 10),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                (wallet.futureAmount == 0 ? "" : wallet.currency.symbol + " " + fCCY.format(wallet.futureAmount)),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                wallet.currency.symbol + " " + fCCY.format(wallet.startBalance + wallet.changeBalance + (wallet.futureAmount * -1)),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        width: double.infinity,
      ),
    );
  }
}