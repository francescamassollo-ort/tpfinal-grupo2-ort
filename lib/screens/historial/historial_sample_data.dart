import 'movimiento_item.dart';

/// Datos de ejemplo de la pantalla de Historial, tomados del diseño de Figma.
/// Se reemplazan por los movimientos reales cuando esté el servicio de stock.
const List<MovimientoItem> historialSampleData = [
  MovimientoItem(
    id: 'm1',
    elementoNombre: 'Elemento 34',
    usuarioNombre: 'Juan Perez',
    fechaEtiqueta: 'Hoy 14:32',
    delta: -10,
  ),
  MovimientoItem(
    id: 'm2',
    elementoNombre: 'Elemento 12',
    usuarioNombre: 'Jana Fisdel',
    fechaEtiqueta: 'Hoy 10:12',
    delta: 19,
    destacado: true,
  ),
  MovimientoItem(
    id: 'm3',
    elementoNombre: 'Elemento 7',
    usuarioNombre: 'Juan Perez',
    fechaEtiqueta: 'Ayer 16:40',
    delta: -1,
  ),
  MovimientoItem(
    id: 'm4',
    elementoNombre: 'Elemento 11',
    usuarioNombre: 'Juan Perez',
    fechaEtiqueta: '22/09 09:02',
    delta: 7,
    destacado: true,
  ),
  MovimientoItem(
    id: 'm5',
    elementoNombre: 'Elemento 1',
    usuarioNombre: 'Daiana Gimenez',
    fechaEtiqueta: '21/09 08:10',
    delta: -3,
  ),
  MovimientoItem(
    id: 'm6',
    elementoNombre: 'Elemento 23',
    usuarioNombre: 'Jana Fisdel',
    fechaEtiqueta: '21/09 08:09',
    delta: -20,
  ),
];
