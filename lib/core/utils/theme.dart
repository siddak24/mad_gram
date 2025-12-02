import 'package:flutter/material.dart';

// The main colors for the MadGram Theme
const primaryColor = Colors.white; // Dominant foreground color
const secondaryColor = Colors.grey; // Subdued text/icon color
const mobileBackgroundColor = Colors.black; // Deep black background
const webBackgroundColor = Color.fromRGBO(18, 18, 18, 1);

// 🌟 NEW ACCENT COLORS 🌟
const pinkAccent = Color.fromRGBO(219, 44, 116, 1); // A vibrant pink
const blueColor = Color.fromRGBO(0, 149, 246, 1); // Keeping blue for links/actions

final ThemeData madGramTheme = ThemeData.dark().copyWith(
  // 1. Core Background and Surface Colors
  scaffoldBackgroundColor: mobileBackgroundColor,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,       // Used for text/icons
    secondary: pinkAccent,       // 🌟 Used for accents (like progress bars)
    surface: mobileBackgroundColor,
  ),

  // 2. AppBar Style
  appBarTheme: const AppBarTheme(
    backgroundColor: mobileBackgroundColor,
    foregroundColor: primaryColor,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    iconTheme: IconThemeData(color: primaryColor),
  ),

  // 3. Text Input Fields (TextField/TextFormField)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: mobileBackgroundColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: secondaryColor, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: primaryColor, width: 1.0),
    ),
    hintStyle: const TextStyle(color: secondaryColor, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),

  // 4. Bottom Navigation Bar Style
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: mobileBackgroundColor,
    selectedItemColor: primaryColor,
    unselectedItemColor: secondaryColor,
    type: BottomNavigationBarType.fixed,
  ),

  // 5. Button Theme (Ensures ElevatedButtons use the pink accent)
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: pinkAccent, // Default text button color is pink
    ),
  ),
);