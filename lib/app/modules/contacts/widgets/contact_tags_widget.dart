import 'package:flutter/material.dart';
import '../../../common widgets/custom_chip.dart';

class ContactTagsWidget extends StatelessWidget {
  final List<String> tags; // now tag names, not IDs

  const ContactTagsWidget({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Text(
        'No tags',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) => CustomChip(label: tag)).toList(),
    );
  }
}
