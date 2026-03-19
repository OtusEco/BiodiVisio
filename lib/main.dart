import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login/login_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const BiodiVisio());
}

class BiodiVisio extends StatelessWidget {
  const BiodiVisio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BiodiVisio',
      theme: AppTheme.biodivisioTheme,

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
