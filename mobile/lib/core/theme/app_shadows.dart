import 'package:flutter/material.dart';

abstract class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0,0,0,.05)
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,.06)
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,.08)
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];
}
