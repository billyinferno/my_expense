import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class Wallet extends StatelessWidget {
  final WalletModel wallet;
  final Function() onTap;
  final Function()? onLongPress;
  const Wallet({
    super.key,
    required this.wallet,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {    
    return GestureDetector(
      onTap: () {
        // call the on tap function
        onTap();
      },
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: <Color>[
              (wallet.enabled ? IconList.getColor(wallet.walletType.type) : secondaryDark),
              (wallet.enabled ? IconList.getDarkColor(wallet.walletType.type).lighten(amount: 0.1) : secondaryBackground),
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
                (wallet.futureAmount == 0 ? "" : "${wallet.currency.symbol} ${Globals.fCCY.format(wallet.futureAmount)}"),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${wallet.currency.symbol} ${Globals.fCCY.format(wallet.startBalance + wallet.changeBalance + (wallet.futureAmount * -1))}",
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