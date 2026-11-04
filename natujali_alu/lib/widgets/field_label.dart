import 'package:flutter/material.dart';

/// Bold label shown above a form field, with an optional hint on the right.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
