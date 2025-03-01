import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class CardFace extends StatelessWidget {
  final WalletModel wallet;
  final TransactionWalletMinMaxDateModel? minMaxDate;
  const CardFace({super.key, required this.wallet, this.minMaxDate});

  @override
  Widget build(BuildContext context) {    
    return Center(
      child: Container(
        height: 150,
        width: 250,
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
              colors: <Color>[
                (wallet.enabled ? IconList.getColor(wallet.walletType.type) : secondaryDark),
                (wallet.enabled ? IconList.getDarkColor(wallet.walletType.type).lighten(amount: 0.1) : secondaryBackground),
              ]
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconList.getIcon(wallet.walletType.type),
                const SizedBox(width: 10,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        wallet.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        wallet.walletType.type,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(child: SizedBox()),
            Visibility(
              visible: (wallet.futureAmount != 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${wallet.currency.symbol} ${Globals.fCCY.format(wallet.futureAmount)}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${wallet.currency.symbol} ${Globals.fCCY.format(wallet.startBalance + wallet.changeBalance + (wallet.futureAmount * -1))}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            (minMaxDate == null ? const SizedBox.shrink() : _generateMinMaxDate()),
          ],
        ),
      ),
    );
  }

  Widget _generateMinMaxDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 20,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _dateText(minMaxDate!.minDate),
            const Text(
              "•••",
              style: TextStyle(
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            _dateText(minMaxDate!.maxDate),
          ],
        )
      ],
    );
  }

  Widget _dateText(DateTime? date) {
    if (date == null) {
      return const SizedBox.shrink();
    }
    else {
      return Text(
        Globals.dfddMMMyyyy.formatLocal(date),
        style: const TextStyle(
          fontSize: 10,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}