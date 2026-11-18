import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_locale.dart';

// Una app mínima con la misma configuración de idioma que MainApp.
Widget _app({Locale? localeDelCelular}) {
  return MaterialApp(
    locale: localeDelCelular ?? appLocale,
    supportedLocales: appSupportedLocales,
    localizationsDelegates: appLocalizationsDelegates,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 11, 17),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            ),
            child: const Text('abrir calendario'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('Flutter tiene los textos de Material en español de Argentina', () {
    expect(GlobalMaterialLocalizations.delegate.isSupported(appLocale), isTrue);
  });

  testWidgets('el calendario muestra sus botones en español', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('abrir calendario'));
    await tester.pumpAndSettle();

    // Así los escribe Flutter en español: el botón principal en mayúsculas.
    expect(find.text('ACEPTAR'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    // Antes de este cambio salían en inglés.
    expect(find.text('OK'), findsNothing);
    expect(find.text('CANCEL'), findsNothing);
  });

  testWidgets('el idioma queda en español aunque el celular esté en inglés',
      (tester) async {
    // Con un solo idioma soportado, Flutter usa ese aunque el sistema pida
    // otro. Así se simula un celular configurado en inglés.
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) => Text(
            MaterialLocalizations.of(context).okButtonLabel,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );

    expect(find.text('ACEPTAR'), findsOneWidget);
  });
}
