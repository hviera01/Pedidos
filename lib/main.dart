import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();

  final authRepository = AuthRepository();
  await authRepository.loadSession();

  runApp(
    ChangeNotifierProvider.value(
      value: authRepository,
      child: const ShirtManagerApp(),
    ),
  );
}

class ShirtManagerApp extends StatelessWidget {
  const ShirtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(context);

    return MaterialApp.router(
      title: 'Gestor de Camisas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}