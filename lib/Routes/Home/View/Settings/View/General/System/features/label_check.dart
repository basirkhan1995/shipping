import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color? activeColor;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  const LabeledCheckbox({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
            ),
            Flexible(
              child: Text(
                title,
                style: textStyle ?? Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}