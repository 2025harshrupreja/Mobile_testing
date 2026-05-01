import 'package:flutter/material.dart';

/// Shown when the app can only access MediaStore (no full filesystem access).
class LimitationsBanner extends StatelessWidget {
  const LimitationsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Access is limited to MediaStore. Files in private app directories '
              'cannot be read or deleted without explicit permission. '
              'Deletion is only enabled where MediaStore/SAF permits.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
