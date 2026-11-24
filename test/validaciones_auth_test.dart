import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/auth_logic/validaciones_auth.dart';

const _mail = 'ana@comunidadort.edu.ar';
const _clave = 'Abcdef1!';

void main() {
  group('ingreso', () {
    test('con mail y contraseña no hay problema', () {
      expect(
        ValidacionesAuth.ingreso(email: _mail, password: 'abc123'),
        isNull,
      );
    });

    test('no exige mail institucional ni contraseña fuerte: son cuentas viejas', () {
      expect(
        ValidacionesAuth.ingreso(email: 'ana@gmail.com', password: 'abc'),
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
        ValidacionesAuth.ingreso(email: _mail, password: ''),
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

  group('mail institucional', () {
    test('acepta los dos dominios de ORT', () {
      expect(ValidacionesAuth.esMailInstitucional('ana@comunidadort.edu.ar'), isTrue);
      expect(ValidacionesAuth.esMailInstitucional('ana@ort.edu.ar'), isTrue);
    });

    test('no distingue mayúsculas ni cuenta los espacios de los extremos', () {
      expect(ValidacionesAuth.esMailInstitucional('  Ana@ComunidadORT.edu.ar '), isTrue);
    });

    test('rechaza otros dominios', () {
      expect(ValidacionesAuth.esMailInstitucional('ana@gmail.com'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional('ana@hotmail.com.ar'), isFalse);
    });

    test('rechaza dominios que solo se le parecen', () {
      expect(ValidacionesAuth.esMailInstitucional('ana@miort.edu.ar'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional('ana@ort.edu.ar.falso.com'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional('ana@alumnos.ort.edu.ar'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional('ort.edu.ar'), isFalse);
    });

    test('rechaza un mail sin nombre o con más de una arroba', () {
      expect(ValidacionesAuth.esMailInstitucional('@ort.edu.ar'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional('ana@gmail.com@ort.edu.ar'), isFalse);
      expect(ValidacionesAuth.esMailInstitucional(''), isFalse);
    });
  });

  group('contraseña segura', () {
    test('una contraseña con todo cumple todos los requisitos', () {
      expect(ValidacionesAuth.requisitosFaltantes(_clave), isEmpty);
    });

    test('vacía no cumple ninguno', () {
      expect(
        ValidacionesAuth.requisitosFaltantes(''),
        RequisitoContrasena.values,
      );
    });

    test('dice exactamente qué le falta', () {
      expect(
        ValidacionesAuth.requisitosFaltantes('abcdefgh'),
        [
          RequisitoContrasena.mayuscula,
          RequisitoContrasena.numero,
          RequisitoContrasena.simbolo,
        ],
      );
      expect(
        ValidacionesAuth.requisitosFaltantes('Ab1!'),
        [RequisitoContrasena.largo],
      );
      expect(
        ValidacionesAuth.requisitosFaltantes('ABCDEFG1!'),
        [RequisitoContrasena.minuscula],
      );
    });

    test('el largo mínimo es 8: 7 no alcanza y 8 sí', () {
      expect(ValidacionesAuth.cumple(RequisitoContrasena.largo, 'Abcde1!'), isFalse);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.largo, 'Abcdef1!'), isTrue);
    });

    test('reconoce mayúsculas y minúsculas con tilde y la ñ', () {
      expect(ValidacionesAuth.cumple(RequisitoContrasena.mayuscula, 'Ñandú'), isTrue);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.mayuscula, 'ñandú'), isFalse);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.minuscula, 'ÁÉÑ'), isFalse);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.minuscula, 'ÁÉÑá'), isTrue);
    });

    test('un espacio no cuenta como símbolo, un signo sí', () {
      expect(ValidacionesAuth.cumple(RequisitoContrasena.simbolo, 'abc def'), isFalse);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.simbolo, 'abc_def'), isTrue);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.simbolo, r'abc$'), isTrue);
      expect(ValidacionesAuth.cumple(RequisitoContrasena.simbolo, 'abc¿'), isTrue);
    });

    test('las letras y los números no son símbolos', () {
      expect(ValidacionesAuth.cumple(RequisitoContrasena.simbolo, 'Abc123ñ'), isFalse);
    });
  });

  group('registro', () {
    String? registro(
      String email,
      String password,
      String confirmacion, {
      String nombre = 'Ana Pérez',
    }) =>
        ValidacionesAuth.registro(
          nombre: nombre,
          email: email,
          password: password,
          confirmacion: confirmacion,
        );

    test('con todo bien no hay problema', () {
      expect(registro(_mail, _clave, _clave), isNull);
    });

    test('un mail institucional largo es válido', () {
      // Tiene más de 20 caracteres: antes se rechazaba por eso.
      const mail = 'prueba@comunidadort.edu.ar';
      expect(mail.length, greaterThan(20));
      expect(registro(mail, _clave, _clave), isNull);

      expect(registro('42841225@comunidadort.edu.ar', _clave, _clave), isNull);
    });

    test('un mail larguísimo tampoco se rechaza por el largo', () {
      final mail = '${'a' * 80}@comunidadort.edu.ar';

      expect(registro(mail, _clave, _clave), isNull);
    });

    test('sin mail avisa', () {
      expect(registro('', _clave, _clave), ValidacionesAuth.avisoEmailVacio);
      expect(registro('  ', _clave, _clave), ValidacionesAuth.avisoEmailVacio);
    });

    test('con un mail que no es institucional avisa', () {
      expect(
        registro('ana@gmail.com', _clave, _clave),
        ValidacionesAuth.avisoMailNoInstitucional,
      );
      expect(
        registro('esto-no-es-un-mail', _clave, _clave),
        ValidacionesAuth.avisoMailNoInstitucional,
      );
    });

    test('sin alguna de las contraseñas avisa', () {
      expect(registro(_mail, '', _clave), ValidacionesAuth.avisoContrasenaVacia);
      expect(registro(_mail, _clave, ''), ValidacionesAuth.avisoContrasenaVacia);
    });

    test('si no coinciden avisa', () {
      expect(
        registro(_mail, _clave, 'Abcdef1?'),
        ValidacionesAuth.avisoNoCoinciden,
      );
    });

    test('las contraseñas se comparan tal cual, con mayúsculas y espacios', () {
      expect(registro(_mail, 'Abcdef1!', 'abcdef1!'), ValidacionesAuth.avisoNoCoinciden);
      expect(registro(_mail, 'Abcdef1! ', 'Abcdef1!'), ValidacionesAuth.avisoNoCoinciden);
    });

    test('una contraseña débil avisa aunque coincida', () {
      expect(registro(_mail, 'abc123', 'abc123'), ValidacionesAuth.avisoContrasenaDebil);
      expect(registro(_mail, 'abcdefgh', 'abcdefgh'), ValidacionesAuth.avisoContrasenaDebil);
      expect(registro(_mail, 'Abcdefg1', 'Abcdefg1'), ValidacionesAuth.avisoContrasenaDebil);
    });

    test('sin nombre avisa', () {
      expect(registro(_mail, _clave, _clave, nombre: ''), ValidacionesAuth.avisoNombre);
      expect(registro(_mail, _clave, _clave, nombre: '   '), ValidacionesAuth.avisoNombre);
    });

    test('un número no es un nombre', () {
      expect(
        registro(_mail, _clave, _clave, nombre: '42841225'),
        ValidacionesAuth.avisoNombre,
      );
    });

    test('el nombre se revisa antes que el mail', () {
      expect(
        registro('ana@gmail.com', _clave, _clave, nombre: ''),
        ValidacionesAuth.avisoNombre,
      );
    });

    test('nombres con tildes, ñ, guiones y apellidos compuestos son válidos', () {
      for (final nombre in ['José Ñandú', 'María-José de la Torre', "O'Brien", 'Li']) {
        expect(registro(_mail, _clave, _clave, nombre: nombre), isNull, reason: nombre);
      }
    });

    test('un nombre larguísimo se rechaza', () {
      expect(
        registro(_mail, _clave, _clave, nombre: 'a' * 61),
        ValidacionesAuth.avisoNombre,
      );
      expect(registro(_mail, _clave, _clave, nombre: 'a' * 60), isNull);
    });

    test('el mail se revisa antes que las contraseñas', () {
      expect(
        registro('ana@gmail.com', 'abc', 'xyz'),
        ValidacionesAuth.avisoMailNoInstitucional,
      );
    });
  });
}
