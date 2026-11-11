/// Un ítem de la lista de compras tal como lo muestra la pantalla.
///
/// Es un modelo de presentación. Cuando exista el modelo de dominio de la
/// lista de compras, se arma un ItemCompra a partir de él sin tocar la
/// pantalla.
class ItemCompra {
  const ItemCompra({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.cantidadSolicitada,
  });

  final String id;
  final String nombre;

  /// Unidades que hay hoy en el laboratorio. Cambiar la cantidad a comprar
  /// no modifica este valor.
  final int stock;

  /// Unidades que se piden. Puede ser mayor que el stock.
  final int cantidadSolicitada;

  /// Texto del stock para mostrar debajo del nombre, por ejemplo "Stock: 10 u.".
  String get stockTexto => 'Stock: $stock u.';

  ItemCompra copyWith({int? cantidadSolicitada}) {
    return ItemCompra(
      id: id,
      nombre: nombre,
      stock: stock,
      cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
    );
  }
}
