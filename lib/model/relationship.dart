import 'package:flutter/material.dart';

enum RelationshipType {
  lover,
  closeFriend,
  sibling,
}

extension RelationshipExtension on RelationshipType {
  String get name {
    switch (this) {
      case RelationshipType.lover: return 'Lover';
      case RelationshipType.closeFriend: return 'Close Friend';
      case RelationshipType.sibling: return 'Sibling';
    }
  }

  Color get primaryColor {
    switch (this) {
      case RelationshipType.lover: return Colors.pink.shade300;
      case RelationshipType.closeFriend: return Colors.blue.shade300;
      case RelationshipType.sibling: return Colors.green.shade300;
    }
  }

  Color get accentColor {
    switch (this) {
      case RelationshipType.lover: return Colors.pink.shade100;
      case RelationshipType.closeFriend: return Colors.blue.shade100;
      case RelationshipType.sibling: return Colors.green.shade100;
    }
  }

  Color get textColor {
    switch (this) {
      case RelationshipType.lover: return Colors.black87;
      case RelationshipType.closeFriend: return Colors.black87;
      case RelationshipType.sibling: return Colors.black87;
    }
  }

  // Example of chat bubble style properties
  BorderRadiusGeometry get chatBubbleRadius {
    return BorderRadius.circular(12.0);
  }

  EdgeInsetsGeometry get chatBubblePadding {
    return const EdgeInsets.all(10.0);
  }
}
