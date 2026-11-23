import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/models/usuario_actual.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/services/usuario_actual_service.dart';

DatosDeSesion _sesion({String? nombre, String? email}) =>
    (uid: 'u1', nombre: nombre, email: email);

Usuario _usuario(String nombre) => Usuario(
      id: 'u1',
      nombre: nombre,
      email: 'doc@ort.edu.ar',
      rol: UserRole.docente,
    );

void main() {
  group('UsuarioActualService.resolver', () {
    test('prefiere el nombre del documento de usuarios', () {
      final usuario = UsuarioActualService.resolver(
        sesion: _sesion(nombre: 'De la cuenta', email: 'a@b.com'),
        nombreDelDocumento: 'Del documento',
      );

      expect(usuario, const UsuarioActual(id: 'u1', nombre: 'Del documento'));
    });

    test('sin documento usa el nombre de la cuenta', () {
      final usuario = UsuarioActualService.resolver(
        sesion: _sesion(nombre: 'De la cuenta', email: 'a@b.com'),
      );

      expect(usuario.nombre, 'De la cuenta');
    });

    test('sin nombre usa el email', () {
      final usuario = UsuarioActualService.resolver(
        sesion: _sesion(email: 'a@b.com'),
      );

      expect(usuario.nombre, 'a@b.com');
    });

    test('sin nada que mostrar dice "Sin nombre", pero conserva el id', () {
      final usuario = UsuarioActualService.resolver(sesion: _sesion());

      expect(usuario, const UsuarioActual(id: 'u1', nombre: 'Sin nombre'));
    });

    test('un nombre vacío o de solo espacios no cuenta', () {
      final usuario = UsuarioActualService.resolver(
        sesion: _sesion(nombre: '   ', email: 'a@b.com'),
        nombreDelDocumento: '',
      );

      expect(usuario.nombre, 'a@b.com');
    });

    test('recorta los espacios de los extremos', () {
      final usuario = UsuarioActualService.resolver(
        sesion: _sesion(),
        nombreDelDocumento: '  Ana  ',
      );

      expect(usuario.nombre, 'Ana');
    });
  });

  group('UsuarioActualService.obtener', () {
    test('sin sesión devuelve "Sin sesión" y no busca nada', () async {
      var busquedas = 0;
      final servicio = UsuarioActualService(
        sesion: () => null,
        buscarUsuario: (uid) async {
          busquedas++;
          return null;
        },
      );

      expect(await servicio.obtener(), UsuarioActual.sinSesion);
      expect(busquedas, 0);
    });

    test('el usuario sin sesión usa el mismo id que el resto de la app', () {
      expect(UsuarioActual.sinSesion.id, usuarioSinSesion);
    });

    test('con sesión busca el documento con el id de la cuenta', () async {
      String? buscado;
      final servicio = UsuarioActualService(
        sesion: () => _sesion(nombre: 'De la cuenta'),
        buscarUsuario: (uid) async {
          buscado = uid;
          return _usuario('Ana Pérez');
        },
      );

      final usuario = await servicio.obtener();

      expect(buscado, 'u1');
      expect(usuario, const UsuarioActual(id: 'u1', nombre: 'Ana Pérez'));
    });

    test('si todavía no existe el documento usa lo de la sesión', () async {
      final servicio = UsuarioActualService(
        sesion: () => _sesion(email: 'a@b.com'),
        buscarUsuario: (uid) async => null,
      );

      expect((await servicio.obtener()).nombre, 'a@b.com');
    });

    test('si no se puede leer el documento no falla y usa lo de la sesión',
        () async {
      final servicio = UsuarioActualService(
        sesion: () => _sesion(nombre: 'De la cuenta'),
        buscarUsuario: (uid) async => throw Exception('permission-denied'),
      );

      final usuario = await servicio.obtener();

      expect(usuario, const UsuarioActual(id: 'u1', nombre: 'De la cuenta'));
    });
  });
}
