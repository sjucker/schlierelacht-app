import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_shell.dart';

const Color _festBlue = Color(0xFF2B3585);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for de_CH date formatting (weekday names) used across the app.
  await initializeDateFormatting('de_CH');
  runApp(const SchlierelachtApp());
}

class SchlierelachtApp extends StatelessWidget {
  const SchlierelachtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schliere lacht',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _festBlue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'CH')],
      locale: const Locale('de', 'CH'),
      home: const HomeShell(),
    );
  }
}
