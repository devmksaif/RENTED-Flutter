import 'package:flutter/material.dart';
import 'package:rented/login_screen.dart';
import 'package:rented/register_screen.dart';
import 'home.dart';
import 'pages/favorites_page.dart';
import 'pages/chat_list_page.dart';
import 'pages/profile_page.dart';
import 'components/custom_bottom_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: '/', // starting screen
      routes: {
        '/': (context) => const MyHomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen()
        
      },
    );
  }
}
 