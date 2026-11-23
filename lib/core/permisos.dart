import '../models/usuario.dart';

/// Qué puede hacer cada rol con los insumos. Está en un solo lugar para que el
/// botón "+", el Detalle y las pantallas protegidas decidan siempre igual.
///
/// Sale de los requerimientos: el administrador tiene acceso total (R15), el
/// ayudante puede ver y modificar stock (R16) y el docente solo mira (R17).
/// Dar de alta, editar y dar de baja un insumo se reserva al administrador;
/// el ayudante mueve el stock pero no cambia el catálogo.
///
/// Esto decide lo que muestra la app. Que la base también lo exija es el
/// trabajo de las reglas de Firestore por rol (ver el README).
class Permisos {
  const Permisos._();

  /// Dar de alta un insumo nuevo (el botón "+" y la pantalla de Alta).
  static bool puedeDarDeAlta(UserRole rol) => rol == UserRole.administrador;

  /// Editar los datos de un insumo o darlo de baja.
  static bool puedeEditarOBaja(UserRole rol) => rol == UserRole.administrador;

  /// Registrar un consumo (salida de stock). El docente solo mira.
  static bool puedeRegistrarConsumo(UserRole rol) =>
      rol == UserRole.administrador || rol == UserRole.ayudante;
}
