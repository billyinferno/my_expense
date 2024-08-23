import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/_index.g.dart';

class Wallet extends StatelessWidget {
  final WalletModel wallet;
  const Wallet({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final fCCY = NumberFormat("#,##0.00", "en_US");
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/wallet/transaction', arguments: wallet);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: <Color>[
              (wallet.enabled ? IconList.getColor(wallet.walletType.type) : secondaryDark),
              (wallet.enabled ? lighten(IconList.getDarkColor(wallet.walletType.type),0.1) : secondaryBackground),
            ]
          ),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: IconList.getIcon(wallet.walletType.type),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        wallet.walletType.type,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 10),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                (wallet.futureAmount == 0 ? "" : "${wallet.currency.symbol} ${fCCY.format(wallet.futureAmount)}"),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${wallet.currency.symbol} ${fCCY.format(wallet.startBalance + wallet.changeBalance + (wallet.futureAmount * -1))}",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}