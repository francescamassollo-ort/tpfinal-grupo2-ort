import 'insumo.dart';

/// Lo que se averiguó de un código de barras escaneado.
sealed class ResultadoCodigo {
  const ResultadoCodigo();
}

/// El código es de un insumo que ya está cargado. En vez de crear un duplicado,
/// se le puede sumar stock.
class CodigoEnInventario extends ResultadoCodigo {
  const CodigoEnInventario(this.insumo);

  final Insumo insumo;
}

/// El código no está cargado, pero una base externa lo conoce. Los datos son
/// una sugerencia: se pueden corregir antes de usarlos.
class CodigoConocido extends ResultadoCodigo {
  const CodigoConocido({
    required this.nombre,
    this.marca,
    this.formula,
    this.pesoMolecular,
  });

  final String nombre;
  final String? marca;

  /// Fórmula química (por ejemplo "C2H6O"), si PubChem reconoció el nombre.
  final String? formula;

  /// Peso molecular, si PubChem reconoció el nombre.
  final double? pesoMolecular;
}

/// No se encontró nada del código: se carga a mano. Que un código no esté en
/// ninguna base es lo normal en reactivos de laboratorio, no es un error.
///
/// Si la búsqueda en internet no pudo hacerse (sin conexión, límite de
/// consultas agotado), [aviso] explica por qué, para que la persona sepa que no
/// es que el código no exista. Null si se buscó bien y simplemente no está.
class CodigoSinResultado extends ResultadoCodigo {
  const CodigoSinResultado({this.aviso});

  final String? aviso;
}
