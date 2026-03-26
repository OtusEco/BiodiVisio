/*
 * BiodiVisio - open-source mobile application to visualize naturalist data
 * Copyright (C) 2026 OtusEco
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * Contact:
 * Email: biodivisio@outlook.fr
 * GitHub: https://github.com/OtusEco/BiodiVisio
 */

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/theme.dart';
import 'login/login_screen.dart';

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
