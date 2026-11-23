import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/interprete_de_etiqueta.dart';

void main() {
  group('una etiqueta completa', () {
    test('en español', () {
      final e = InterpreteDeEtiqueta.interpretar('''
ETANOL ABSOLUTO
Lote: A2345   Venc: 11/2027
CAS 64-17-5
Fórmula: C2H6O   PM 46,07 g/mol
Pureza 99,5%
''');

      expect(e.nombre, 'Etanol absoluto');
      expect(e.cas, '64-17-5');
      expect(e.formula, 'C2H6O');
      expect(e.pesoMolecular, 46.07);
      // "11/2027" es el mes: vence el último día.
      expect(e.fechaVencimiento, DateTime(2027, 11, 30));
      expect(e.vacia, isFalse);
    });

    test('en inglés', () {
      final e = InterpreteDeEtiqueta.interpretar('''
Sodium Chloride
CAS: 7647-14-5
Mol. Wt.: 58.44
Formula: NaCl
Exp date 2028-05-31 / Lot 123456
''');

      expect(e.nombre, 'Sodium Chloride');
      expect(e.cas, '7647-14-5');
      expect(e.formula, 'NaCl');
      expect(e.pesoMolecular, 58.44);
      expect(e.fechaVencimiento, DateTime(2028, 5, 31));
    });

    test('la fórmula sin la palabra "fórmula"', () {
      final e = InterpreteDeEtiqueta.interpretar('''
Acido acetico glacial
CH3COOH
Fecha de vencimiento: 15/03/2027
''');

      expect(e.formula, 'CH3COOH');
      expect(e.fechaVencimiento, DateTime(2027, 3, 15));
    });

    test('guarda todo el texto reconocido', () {
      const texto = 'Etanol\nLote 1';

      expect(InterpreteDeEtiqueta.interpretar(texto).texto, texto);
    });
  });

  group('número CAS', () {
    test('un CAS con su dígito de control correcto es válido', () {
      expect(InterpreteDeEtiqueta.esCasValido('64-17-5'), isTrue);
      expect(InterpreteDeEtiqueta.esCasValido('7647-14-5'), isTrue);
      expect(InterpreteDeEtiqueta.esCasValido('67-56-1'), isTrue);
    });

    test('con el dígito de control mal no es válido', () {
      expect(InterpreteDeEtiqueta.esCasValido('64-17-6'), isFalse);
      expect(InterpreteDeEtiqueta.esCasValido('7647-14-4'), isFalse);
    });

    test('lo que no tiene forma de CAS no es válido', () {
      expect(InterpreteDeEtiqueta.esCasValido('64175'), isFalse);
      expect(InterpreteDeEtiqueta.esCasValido('ab-cd-e'), isFalse);
    });

    test('un CAS mal leído por el reconocedor no se toma', () {
      final e = InterpreteDeEtiqueta.interpretar('Etanol\nCAS 64-17-6');

      expect(e.cas, isNull);
    });

    test('una fecha no se confunde con un CAS', () {
      expect(InterpreteDeEtiqueta.interpretar('Venc 2026-11-15').cas, isNull);
      expect(InterpreteDeEtiqueta.interpretar('Lote 15-11-2026').cas, isNull);
    });
  });

  group('fórmula química', () {
    test('reconoce fórmulas comunes', () {
      for (final f in ['H2O', 'C2H6O', 'CH3COOH', 'H2SO4', 'NaCl', 'Ca(OH)2', 'CaCO3', 'NH4Cl']) {
        expect(InterpreteDeEtiqueta.esFormulaQuimica(f), isTrue, reason: f);
      }
    });

    test('rechaza lo que no es una fórmula', () {
      for (final f in ['Hola', 'LOTE', 'Xy2', 'C2H6O)', '(C2H6O', '123', 'ab', '']) {
        expect(InterpreteDeEtiqueta.esFormulaQuimica(f), isFalse, reason: f);
      }
    });

    test('con la palabra "fórmula" acepta una sin números', () {
      final e = InterpreteDeEtiqueta.interpretar('Formula: NaCl\nOtro');

      expect(e.formula, 'NaCl');
    });

    test('no toma palabras comunes por fórmulas', () {
      // "CON" son C+O+N y "SON" son S+O+N: serían fórmulas si se las aceptara.
      final e = InterpreteDeEtiqueta.interpretar('MANEJAR CON CUIDADO\nSON PARA USO DE LABORATORIO\nNO TOCAR');

      expect(e.formula, isNull);
    });

    test('una fórmula común sin números se acepta sola', () {
      expect(InterpreteDeEtiqueta.interpretar('Reactivo\nHCl 37%').formula, 'HCl');
    });
  });

  group('peso molecular', () {
    test('en distintas formas de escribirlo', () {
      const casos = {
        'Peso molecular: 46,07': 46.07,
        'PM 46.07': 46.07,
        'M.W. 58.44': 58.44,
        'Mol. Wt.: 18.015': 18.015,
        'Masa molar = 180,16': 180.16,
        'Contenido 98 g/mol aprox': 98,
      };

      for (final caso in casos.entries) {
        expect(
          InterpreteDeEtiqueta.interpretar(caso.key).pesoMolecular,
          caso.value,
          reason: caso.key,
        );
      }
    });

    test('un número suelto no es un peso molecular', () {
      expect(InterpreteDeEtiqueta.interpretar('Lote 12345\n500 ml').pesoMolecular, isNull);
    });
  });

  group('fecha de vencimiento', () {
    DateTime? venc(String texto) =>
        InterpreteDeEtiqueta.interpretar('Producto\n$texto').fechaVencimiento;

    test('día, mes y año', () {
      expect(venc('Vence: 15/03/2027'), DateTime(2027, 3, 15));
      expect(venc('Vto 15-03-27'), DateTime(2027, 3, 15));
      expect(venc('Vencimiento 15.03.2027'), DateTime(2027, 3, 15));
    });

    test('solo mes y año: el último día del mes', () {
      expect(venc('Venc: 03/2027'), DateTime(2027, 3, 31));
      expect(venc('Venc: 02/2028'), DateTime(2028, 2, 29));
      expect(venc('Exp 03-27'), DateTime(2027, 3, 31));
    });

    test('año, mes y día', () {
      expect(venc('EXP 2027-03-15'), DateTime(2027, 3, 15));
    });

    test('con el mes en letras', () {
      expect(venc('VENCE: 15 NOV 2026'), DateTime(2026, 11, 15));
      expect(venc('Expiry: NOV 2026'), DateTime(2026, 11, 30));
      expect(venc('Caducidad 5 diciembre 2027'), DateTime(2027, 12, 5));
      expect(venc('Best before 10-JAN-2028'), DateTime(2028, 1, 10));
    });

    test('día y mes ambiguos se leen día/mes', () {
      expect(venc('Venc 03/04/2027'), DateTime(2027, 4, 3));
    });

    test('mes/día a la americana cuando no queda otra', () {
      // "03/25/2027" no puede ser día 3, mes 25.
      expect(venc('Exp 03/25/2027'), DateTime(2027, 3, 25));
    });

    test('la fecha en la línea de abajo de "Vencimiento"', () {
      final e = InterpreteDeEtiqueta.interpretar('Producto\nVencimiento\n12/2027');

      expect(e.fechaVencimiento, DateTime(2027, 12, 31));
    });

    test('con la elaboración en la misma línea toma la del vencimiento', () {
      expect(venc('Elab: 01/2026  Venc: 01/2028'), DateTime(2028, 1, 31));
    });

    test('una fecha de elaboración sola no es un vencimiento', () {
      expect(venc('Elab: 01/2026'), isNull);
      expect(venc('Fab. 15/03/2026'), isNull);
    });

    test('una fecha sin palabra que la anuncie no se toma', () {
      expect(venc('15/03/2027'), isNull);
    });

    test('fechas imposibles se descartan', () {
      expect(venc('Venc: 31/02/2027'), isNull);
      expect(venc('Venc: 15/13/2027'), isNull);
      expect(venc('Venc: 15/03/1999'), isNull);
    });

    test('con dos vencimientos toma el primero', () {
      expect(venc('Venc 01/2027\nExp 01/2030'), DateTime(2027, 1, 31));
    });
  });

  group('nombre y marca', () {
    test('lo que dice después de "Producto:" o "Nombre:"', () {
      expect(InterpreteDeEtiqueta.interpretar('Lote 12\nProducto: Agar LB').nombre, 'Agar LB');
      expect(InterpreteDeEtiqueta.interpretar('Nombre: Buffer TAE 1x').nombre, 'Buffer TAE 1x');
    });

    test('sin etiqueta, la primera línea que parece un nombre', () {
      final e = InterpreteDeEtiqueta.interpretar('Lote: 12345\n500 ml\nAgar nutritivo\nVenc 11/2027');

      expect(e.nombre, 'Agar nutritivo');
    });

    test('el nombre todo en mayúsculas se pasa a minúsculas', () {
      expect(InterpreteDeEtiqueta.interpretar('GLICEROL').nombre, 'Glicerol');
    });

    test('un nombre con minúsculas se deja como viene', () {
      expect(InterpreteDeEtiqueta.interpretar('Tris-HCl 1M').nombre, 'Tris-HCl 1M');
    });

    test('las líneas de datos no son el nombre', () {
      final e = InterpreteDeEtiqueta.interpretar('CAS 64-17-5\nLote A123\nVenc 11/2027\nwww.merck.com');

      expect(e.nombre, isNull);
    });

    test('la marca solo si la etiqueta la nombra', () {
      expect(InterpreteDeEtiqueta.interpretar('Etanol\nMarca: Cicarelli').marca, 'Cicarelli');
      expect(InterpreteDeEtiqueta.interpretar('Etanol\nBrand: Merck').marca, 'Merck');
      expect(InterpreteDeEtiqueta.interpretar('Etanol\nMerck').marca, isNull);
    });
  });

  group('cuando no se entiende nada', () {
    test('un texto vacío da una etiqueta vacía', () {
      final e = InterpreteDeEtiqueta.interpretar('');

      expect(e.vacia, isTrue);
      expect(e.nombre, isNull);
    });

    test('ruido sin sentido tampoco inventa datos', () {
      final e = InterpreteDeEtiqueta.interpretar('~~ ## 12 .. -- ;;');

      expect(e.vacia, isTrue);
    });
  });
}
