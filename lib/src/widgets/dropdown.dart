import 'package:flutter/material.dart';

Widget buildDropdownButton(BuildContext context, bool isCompressing, Map<String, int> items, int quality, Function onChanged) {
  return !isCompressing
      ? DropdownButtonHideUnderline(
          child: DropdownButton(
              isDense: true,
              dropdownColor: Theme.of(context).scaffoldBackgroundColor,
              style: const TextStyle(fontSize: 14),
              alignment: Alignment.centerRight,
              focusColor: Colors.transparent,
              value: quality,
              onChanged: (value) {
                if (isCompressing) return;
                onChanged(value as int);
              },
              items: items.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.value,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList()),
        )
      : items.entries
          .where((entry) => entry.value == quality)
          .map(
            (entry) => Text(
              entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          )
          .first;
}
