import 'package:flutter/material.dart';

// Define your color constants
const kLightPrimaryColor = Color.fromRGBO(219, 105, 55, 1);
const kDarkPrimaryColor = Color.fromRGBO(135, 189, 186, 1);
const kDarkBgColor = Color.fromRGBO(19, 28, 33, 1);
const kLightBgColor = Color.fromRGBO(255, 255, 255, 1);
const kTextHighlightColor = Color.fromRGBO(175, 72, 48, 1);
const kDarkAppBarColor = Color.fromRGBO(135, 189, 186, 1);
// Degradation of Light Orange
const kLightOrange1 = Color.fromRGBO(255, 123, 0, 1); // Hex: FF7B00
const kLightOrange2 = Color.fromRGBO(255, 136, 0, 1); // Hex: FF8800
const kLightOrange3 = Color.fromRGBO(255, 149, 0, 1); // Hex: FF9500
const kLightOrange4 = Color.fromRGBO(255, 162, 0, 1); // Hex: FFA200
const kLightOrange5 = Color.fromRGBO(255, 170, 0, 1); // Hex: FFAA00
const kLightOrange6 = Color.fromRGBO(255, 183, 0, 1); // Hex: FFB700
const kLightOrange7 = Color.fromRGBO(255, 195, 0, 1); // Hex: FFC300
const kLightOrange8 = Color.fromRGBO(255, 208, 0, 1); // Hex: FFD000
const kLightOrange9 = Color.fromRGBO(255, 221, 0, 1); // Hex: FFDD00
const kLightOrange10 = Color.fromRGBO(255, 234, 0, 1); // Hex: FFEA00

class AppThemes {
  // Define the Light Theme
  static final lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: kLightBgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kLightPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: kLightPrimaryColor,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.black54,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: kLightPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightOrange7,
        elevation: 1.0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kLightPrimaryColor,
      unselectedItemColor: Colors.black54,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kLightOrange7,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: kTextHighlightColor, width: 2.0),
      ),
      hintStyle: TextStyle(
        color: kLightPrimaryColor, // Set hint text color for light theme
        fontSize: 14,
      ),
    ),
    iconTheme: const IconThemeData(color: kLightOrange7),
  );

  // Define the Dark Theme
  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: kDarkBgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkAppBarColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: kDarkPrimaryColor,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.white54,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: kDarkPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDarkPrimaryColor,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kDarkPrimaryColor,
      unselectedItemColor: Colors.white70,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kDarkPrimaryColor,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kDarkAppBarColor,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: kTextHighlightColor, width: 2.0),
      ),
    ),
  );
}
