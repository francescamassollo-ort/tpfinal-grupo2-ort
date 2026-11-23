import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/auth_logic/auth_service.dart';

/// Un AuthService sin Firebase para las pruebas de las pantallas de acceso:
/// anota lo que se le pide y devuelve lo que la prueba diga.
class AuthFalso extends Fake implements AuthService {
  /// Qué contestan las operaciones (false = Firebase la rechazó).
  bool registrar = true;
  bool ingresar = true;
  bool recuperar = true;
  bool verificarMail = true;
  bool entrarConGoogle = true;

  /// Si el mail ya está verificado cuando se lo comprueba.
  bool mailYaVerificado = false;

  String? email = 'ana@comunidadort.edu.ar';

  final registros = <String>[];
  final ingresos = <String>[];
  final recuperaciones = <String>[];
  int verificacionesEnviadas = 0;
  int comprobaciones = 0;
  int cierresDeSesion = 0;
  int ingresosConGoogle = 0;

  @override
  String? get emailActual => email;

  @override
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    registros.add('$email|$password');
    return registrar;
  }

  @override
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    ingresos.add('$email|$password');
    return ingresar;
  }

  @override
  Future<bool> signInWithGoogle() async {
    ingresosConGoogle++;
    return entrarConGoogle;
  }

  @override
  Future<bool> sendPasswordReset(String email) async {
    recuperaciones.add(email);
    return recuperar;
  }

  @override
  Future<bool> sendEmailVerification() async {
    verificacionesEnviadas++;
    return verificarMail;
  }

  @override
  Future<bool> mailVerificado() async {
    comprobaciones++;
    return mailYaVerificado;
  }

  @override
  Future<void> signOut() async {
    cierresDeSesion++;
  }
}
