import 'package:flutter/material.dart';

class LoginStyle {
  static const decorationInput = InputDecoration(
    filled: true,
    fillColor: Color.fromRGBO(197, 197, 197, 0.425),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colors.white54, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colors.white54, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
    ),
  );

  static const textStyleLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1E293B),
  );

  static const buttonStyle = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Color(0xFF3B82F6)),
    padding: WidgetStatePropertyAll(EdgeInsets.all(16)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
  );
}
