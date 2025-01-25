import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget buildSelect(BuildContext context, bool isCompressing, Map<String, int> items, int quality, Function onChanged) {
  return ShadSelect(

    enabled: !isCompressing,
    initialValue: quality,
    onChanged: (value) {
      if (isCompressing) return;
      onChanged(value as int);
    },
    placeholder: Text(
      items.entries
          .where((entry) => entry.value == quality)
          .map(
            (entry) => entry.key,
          )
          .first,
      style: const TextStyle(fontSize: 14),
    ),
    options: items.entries
        .map(
          (entry) => ShadOption(
            value: entry.value,
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        )
        .toList(),
    selectedOptionBuilder: (context, value) => Text(
      items.entries
          .where((entry) => entry.value == value)
          .map(
            (entry) => entry.key,
          )
          .first,
      style: const TextStyle(fontSize: 14),
    ),
  );
}
