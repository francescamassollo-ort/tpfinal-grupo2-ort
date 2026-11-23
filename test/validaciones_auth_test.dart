import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/auth_logic/validaciones_auth.dart';

void main() {
  group('ingreso', () {
    test('con mail y contraseña no hay problema', () {
      expect(
        ValidacionesAuth.ingreso(email: 'ana@comunidadort.edu.ar', password: 'abc123'),
        isNull,
      );
    });

    test('sin mail avisa', () {
      expect(
        ValidacionesAuth.ingreso(email: '', password: 'abc123'),
        ValidacionesAuth.avisoEmailVacio,
      );
    });

    test('un mail de solo espacios cuenta como vacío', () {
      expect(
        ValidacionesAuth.ingreso(email: '   ', password: 'abc123'),
        ValidacionesAuth.avisoEmailVacio,
      );
    });

    test('sin contraseña avisa', () {
      expect(
        ValidacionesAuth.ingreso(email: 'ana@x.com', password: ''),
        ValidacionesAuth.avisoContrasenaVacia,
      );
    });

    test('con los dos vacíos avisa primero del mail', () {
      expect(
        ValidacionesAuth.ingreso(email: '', password: ''),
        ValidacionesAuth.avisoEmailVacio,
      );
    });
  });

  group('registro', () {
    String? registro(String email, String password, String confirmacion) =>
        ValidacionesAuth.registro(
          email: email,
          password: password,
          confirmacion: confirmacion,
        );

    test('con todo bien no hay problema', () {
      expect(registro('ana@x.com', 'abc123', 'abc123'), isNull);
    });

    test('un mail institucional largo es válido', () {
      // Tiene más de 20 caracteres: antes se rechazaba por eso.
      const mail = 'prueba@comunidadort.edu.ar';
      expect(mail.length, greaterThan(20));
      expect(registro(mail, 'abc123', 'abc123'), isNull);

      expect(registro('42841225@comunidadort.edu.ar', 'abc123', 'abc123'), isNull);
    });

    test('un mail larguísimo tampoco se rechaza acá', () {
      final mail = '${'a' * 80}@comunidadort.edu.ar';

      expect(registro(mail, 'abc123', 'abc123'), isNull);
    });

    test('sin mail avisa', () {
      expect(registro('', 'abc123', 'abc123'), ValidacionesAuth.avisoEmailVacio);
      expect(registro('  ', 'abc123', 'abc123'), ValidacionesAuth.avisoEmailVacio);
    });

    test('sin alguna de las contraseñas avisa', () {
      expect(registro('ana@x.com', '', 'abc123'), ValidacionesAuth.avisoContrasenaVacia);
      expect(registro('ana@x.com', 'abc123', ''), ValidacionesAuth.avisoContrasenaVacia);
    });

    test('si no coinciden avisa', () {
      expect(
        registro('ana@x.com', 'abc123', 'abc124'),
        ValidacionesAuth.avisoNoCoinciden,
      );
    });

    test('las contraseñas se comparan tal cual, con mayúsculas y espacios', () {
      expect(registro('ana@x.com', 'Abc123', 'abc123'), ValidacionesAuth.avisoNoCoinciden);
      expect(registro('ana@x.com', 'abc123 ', 'abc123'), ValidacionesAuth.avisoNoCoinciden);
    });

    test('lo que depende de Firebase no se revisa acá', () {
      // Contraseña corta o mail mal escrito: lo explica AuthService con el
      // motivo exacto que devuelve Firebase.
      expect(registro('esto-no-es-un-mail', '123', '123'), isNull);
    });
  });
}
