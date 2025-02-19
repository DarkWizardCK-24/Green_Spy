import 'package:flutter/material.dart';
import 'package:green_spy/home_screen.dart';
import 'package:green_spy/menu_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Spy',
      home: MenuPage(),      
    );
  }
}


