import 'package:isar/isar.dart';

int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    var codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit;
    hash *= 0x100000001b3;
  }
  return hash;
}
