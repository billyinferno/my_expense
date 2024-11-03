import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class CategoryModalSelector extends StatefulWidget {
  final List<Widget> expense;
  final List<Widget> income;
  const CategoryModalSelector({
    super.key,
    required this.expense,
    required this.income,
  });

  @override
  State<CategoryModalSelector> createState() => _CategoryModalSelectorState();
}

class _CategoryModalSelectorState extends State<CategoryModalSelector> {
  final ScrollController _controller = ScrollController();
  final Map<PageName, TypeSlideItem> _categorySelectionItems = <PageName, TypeSlideItem> {
    PageName.expense: TypeSlideItem(
      color: accentColors[2],
      text: 'Expense',
    ),
    PageName.income: TypeSlideItem(
      color: accentColors[6],
      text: 'Income',
    ),
  };

  late PageName _resultCategoryName;

  @override
  void initState() {
    super.initState();
    
    // init variable
    _resultCategoryName = PageName.expense;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          child: TypeSlide<PageName>(
            onValueChanged: (value) {
              setState(() {
                _resultCategoryName = value;
              });
            },
            items: _categorySelectionItems,
          ),
        ),
        Expanded(
          child: GridView.count(
            controller: _controller,
            crossAxisCount: 4,
            children: (
              _resultCategoryName == PageName.expense ?
              widget.expense :
              widget.income
            ),
          ),
        ),
      ],
    );
  }
}