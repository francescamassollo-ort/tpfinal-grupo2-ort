import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma de la app: español de Argentina.
///
/// Todos los textos propios de la app están escritos en español. Esto hace que
/// también estén en español los textos que pone Flutter por su cuenta: el
/// calendario ("Aceptar", "Cancelar", los meses), el menú de copiar y pegar y
/// los avisos de accesibilidad. Se fuerza el idioma para que sea el mismo aunque
/// el celular esté en inglés.
const Locale appLocale = Locale('es', 'AR');

const List<Locale> appSupportedLocales = [appLocale];

const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
