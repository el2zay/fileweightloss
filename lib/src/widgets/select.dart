import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget buildSelect(BuildContext context, bool isCompressing, Map<String, int> items, int quality, Function onChanged) {
  logarte.log("Building select widget - IsCompressing: $isCompressing, Quality: $quality, Available items: ${items.keys.toList()}");
  
  String currentLabel = items.entries
      .where((entry) => entry.value == quality)
      .map((entry) => entry.key)
      .first;
  
  logarte.log("Current selected option: $currentLabel (value: $quality)");
  
  return ShadSelect(
    enabled: !isCompressing,
    initialValue: quality,
    onChanged: (value) {
      if (isCompressing) {
        logarte.log("Select change blocked - compression in progress");
        return;
      }
      
      String newLabel = items.entries
          .where((entry) => entry.value == value)
          .map((entry) => entry.key)
          .first;
      
      logarte.log("Select option changed from '$currentLabel' ($quality) to '$newLabel' ($value)");
      onChanged(value as int);
    },
    placeholder: Text(
      currentLabel,
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
    selectedOptionBuilder: (context, value) {
      String selectedLabel = items.entries
          .where((entry) => entry.value == value)
          .map((entry) => entry.key)
          .first;
      
      logarte.log("Displaying selected option: $selectedLabel (value: $value)");
      
      return Text(
        selectedLabel,
        style: const TextStyle(fontSize: 14),
      );
    },
  );
}