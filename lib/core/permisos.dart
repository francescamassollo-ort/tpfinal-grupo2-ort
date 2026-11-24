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

  /// Importar el inventario desde un Excel (carga inicial).
  static bool puedeImportar(UserRole rol) => rol == UserRole.administrador;

  /// Sumar stock a un insumo que ya existe (llegó una compra o una donación):
  /// una entrada de stock. Es lo mismo que registrar un consumo: el
  /// administrador y el ayudante modifican el stock, el docente solo mira.
  static bool puedeSumarStock(UserRole rol) =>
      rol == UserRole.administrador || rol == UserRole.ayudante;

  /// Ver y modificar la gestión de usuarios (roles y bajas de cuentas).
  static bool puedeGestionarUsuarios(UserRole rol) => rol == UserRole.administrador;

  /// Usar la lista de compras: el docente no la ve.
  static bool puedeVerCompras(UserRole rol) => rol != UserRole.docente;

  /// Crear, editar y eliminar trabajos prácticos: los arma el docente y el
  /// administrador; el ayudante solo los ve.
  static bool puedeEditarTps(UserRole rol) =>
      rol == UserRole.administrador || rol == UserRole.docente;

  /// Registrar un consumo (salida de stock). El docente solo mira.
  static bool puedeRegistrarConsumo(UserRole rol) =>
      rol == UserRole.administrador || rol == UserRole.ayudante;
}
