import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Displays a bytes value with a label below it.
class BytesText extends StatelessWidget {
  final int bytes;
  final String label;

  const BytesText({super.key, required this.bytes, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(formatBytes(bytes),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
