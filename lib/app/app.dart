import 'package:flutter/material.dart';
import 'package:paste_content/presentation/screens/fact_check_screen.dart';
import 'package:paste_content/presentation/screens/url-checker.dart';
// import 'package:paste_content/presentation/screens/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(useMaterial3: true),
      title: "Paste Content",
      home: UrlChecker(), // const FactCheckScreen() // const HomeScreen(),
    );
  }
}
