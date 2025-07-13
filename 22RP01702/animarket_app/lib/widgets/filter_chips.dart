import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FilterChips extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onSelected;

  const FilterChips({
    Key? key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: selectedIndex == index,
              selectedColor: kPrimaryGreen,
              backgroundColor: kLightGreen.withOpacity(0.2),
              labelStyle: TextStyle(
                color: selectedIndex == index ? Colors.white : kPrimaryGreen,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}
