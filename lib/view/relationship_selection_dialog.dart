import 'package:flutter/material.dart';
import 'package:my_chat_app/model/relationship.dart';

class RelationshipSelectionDialog extends StatelessWidget {
  const RelationshipSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Relationship'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: RelationshipType.values.map((type) {
          return ListTile(
            title: Text(type.name),
            onTap: () {
              Navigator.of(context).pop(type);
            },
          );
        }).toList(),
      ),
    );
  }
}
