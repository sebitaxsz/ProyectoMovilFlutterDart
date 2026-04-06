import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';   // 👈 NUEVO
import 'views/login.dart';
import 'views/register.dart';
import 'views/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),  // 👈 NUEVO
      ],
      child: MaterialApp(
        title: 'Sistema de Gestión Académica',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
          fontFamily: 'Roboto',
        ),
        home: const LoginScreen(),
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}