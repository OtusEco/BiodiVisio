import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(const GeoNatureApp());
}

class GeoNatureApp extends StatelessWidget {
  const GeoNatureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoNature Mobile',
      theme: ThemeData(primarySwatch: Colors.green),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),

      home: const LoginScreen(),
    );
  }
}
