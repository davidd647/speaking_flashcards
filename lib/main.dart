import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // allows fixation on portrait mode
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/screens/study_session.dart';
import 'package:speaking_flashcards/screens/batch_add.dart';
import 'package:speaking_flashcards/screens/browse.dart';
import 'package:speaking_flashcards/screens/languages.dart';
import 'package:speaking_flashcards/screens/settings.dart';
import 'package:speaking_flashcards/screens/stats.dart';
import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';

const appName = 'Speaking Flashcards';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Consumer(
      builder: (context, theme, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (ctx) => ProviderSessionLogic()),
          ChangeNotifierProvider(create: (ctx) => ProviderSettings()),
        ],
        child: MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.ubuntuTextTheme(Theme.of(context).textTheme).apply(),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
            useMaterial3: true,
          ),
          home: const StudySession(),
          routes: {
            StudySession.routeName: (ctx) => const StudySession(),
            Stats.routeName: (ctx) => const Stats(),
            Settings.routeName: (ctx) => const Settings(),
            Languages.routeName: (ctx) => const Languages(),
            Browse.routeName: (ctx) => const Browse(),
            BatchAdd.routeName: (ctx) => const BatchAdd(),
          },
        ),
      ),
    );
  }
}
