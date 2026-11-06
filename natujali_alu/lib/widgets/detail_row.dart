import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// "Label    Value" line used in summary cards.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: context.colors.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
