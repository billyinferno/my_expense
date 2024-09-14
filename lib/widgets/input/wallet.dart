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
    // calculate the wallet usage
    double walletUsage = wallet.startBalance + wallet.changeBalance + (wallet.futureAmount * -1);
    Color walletColor = IconList.getColor(wallet.walletType.type);
    Color walletDarkColor = IconList.getDarkColor(wallet.walletType.type);

    // calculate the progress bar for the limit
    int percentageUse = -1;
    if (wallet.limit > 0) {
      // we got limit, now check the wallet usage with the limit
      percentageUse = ((walletUsage.makePositive() / wallet.limit) * 100).toInt();
    }

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
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: <Color>[
              (wallet.enabled ? walletColor : secondaryDark),
              (wallet.enabled ? walletDarkColor.lighten(amount: 0.1) : secondaryBackground),
            ]
          ),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  (wallet.futureAmount == 0 ? "" : "${wallet.currency.symbol} ${Globals.fCCY.format(wallet.futureAmount)}"),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            (
              percentageUse < 0 ?
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "${wallet.currency.symbol} ${Globals.fCCY.format(walletUsage)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ) :
              _buildUsageBarChar(
                walletUsage: walletUsage,
                percentageUse: percentageUse,
                barColor: walletDarkColor,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageBarChar({
    required double walletUsage,
    required int percentageUse,
    required Color barColor,
  }) {
    // get the correct end color for the linear gradient on the limit bar
    Color endColor = Colors.green[900]!;
    if (percentageUse >= 90) {
      endColor = Colors.red[900]!;
    }
    else if (percentageUse >= 80) {
      endColor = Colors.red[700]!;
    }
    else if (percentageUse >= 70) {
      endColor = Colors.red;
    }
    else if (percentageUse >= 60) {
      endColor = Colors.orange[900]!;
    }
    else if (percentageUse >= 50) {
      endColor = Colors.orange[700]!;
    }
    else if (percentageUse >= 40) {
      endColor = Colors.orange;
    }
    else if (percentageUse >= 30) {
      endColor = Colors.yellow;
    }
    else if (percentageUse >= 20) {
      endColor = Colors.green;
    }
    else if (percentageUse >= 10) {
      endColor = Colors.green[700]!;
    }
    else {
      endColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: barColor.darken(amount: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: (100 - percentageUse),
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Expanded(
                  flex: percentageUse,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [endColor, barColor]
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 0, 7, 0),
            child: Text(
              "${wallet.currency.symbol} ${Globals.fCCY.format(walletUsage)}",
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}