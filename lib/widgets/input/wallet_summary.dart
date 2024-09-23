import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class WalletSummary extends StatelessWidget {
  final String type;
  final Map<String, double> data;
  final Map<String, CurrencyModel> currencies;
  const WalletSummary({
    super.key,
    required this.type,
    required this.data,
    required this.currencies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      decoration: BoxDecoration(
        color: IconList.getDarkColor(type),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: _generateSummaryItem(),
      ),
    );
  }

  List<Widget> _generateSummaryItem() {
    List<Widget> summaryItem = [];

    CurrencyModel ccy;
    // loop thru data
    data.forEach((key, amount) {
      // get the currencies data
      if (currencies.containsKey(key)) {
        // get the currecy
        ccy = currencies[key]!;

        // then generate the row for summary item
        summaryItem.add(
          Container(
            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: textColor2,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 10,
                        color: textColor,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Text(ccy.description),
                ),
                const SizedBox(width: 10,),
                Text("${ccy.symbol}${Globals.fCCY.format(amount)}"),
              ],
            ),
          )
        );
      }
    },);

    return summaryItem;
  }
}