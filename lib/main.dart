import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_logic/auth_service.dart';

import 'core/app_locale.dart';
import 'core/app_router.dart';
import 'widgets/logo_ort.dart';
import 'core/theme.dart';
import 'widgets/guardia_de_cuenta.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // Cierra la sesión de quien fue dado de baja, en cualquier pantalla.
      builder: (context, child) => GuardiaDeCuenta(
        // El logo va arriba de cada pantalla; se actualiza con la ruta.
        child: ListenableBuilder(
          listenable: appRouter.routerDelegate,
          builder: (context, _) => PantallaConLogo(
            ruta: appRouter.routerDelegate.currentConfiguration.uri.path,
            child: child ?? const SizedBox(),
          ),
        ),
      ),
      theme: appTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
      locale: appLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
    );
  }
}
