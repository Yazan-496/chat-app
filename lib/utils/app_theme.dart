import 'package:flutter/material.dart';

enum ThemeModeType {
  system,
  light,
  dark,
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey.shade100,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      labelLarge: TextStyle(color: Colors.white),
    ),
    // Add more light theme specific properties
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blueGrey,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    cardColor: Colors.grey.shade800,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
      labelLarge: TextStyle(color: Colors.white),
    ),
    // Add more dark theme specific properties
  );
}

