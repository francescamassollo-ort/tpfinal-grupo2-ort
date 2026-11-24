// Pruebas de firestore.rules con el emulador de Firebase.
//
// Cada prueba hace lo que haría la app con una persona de cada rol y comprueba
// que la regla lo deje (assertSucceeds) o lo frene (assertFails).
//
// Correrlas:  cd firestore_tests && npm install && npm test
// (hace falta Java 21 en el PATH; el emulador se baja solo la primera vez).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const REGLAS = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');

const [HOST, PUERTO] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');

let entorno;
let entornoConDominio;

async function crearEntorno(reglas, proyecto) {
  return initializeTestEnvironment({
    projectId: proyecto,
    firestore: { rules: reglas, host: HOST, port: Number(PUERTO) },
  });
}

before(async () => {
  entorno = await crearEntorno(REGLAS, 'demo-biolab');
  // Las mismas reglas con el interruptor del dominio institucional encendido.
  const encendidas = REGLAS.replace(
    /function exigeDominioInstitucional\(\) \{\s*return false;/,
    'function exigeDominioInstitucional() {\n      return true;',
  );
  if (encendidas === REGLAS) throw new Error('No encontré el interruptor del dominio en las reglas');
  entornoConDominio = await crearEntorno(encendidas, 'demo-biolab-dominio');
});

after(async () => {
  await entorno.cleanup();
  await entornoConDominio.cleanup();
});

const USUARIO = (rol, extra = {}) => ({
  nombre: `Persona ${rol}`,
  email: `${rol}@comunidadort.edu.ar`,
  rol,
  activo: true,
  puedeVerSedronar: false,
  ...extra,
});

const INSUMO = {
  nombre: 'Etanol absoluto',
  tipo: 'comprado',
  stock: 5,
  ubicacion: 'Armario 1',
  umbralMinimo: 1,
  activo: true,
};

// Quien entra: una cuenta con el mail verificado, salvo que se diga otra cosa.
function como(uid, { verificado = true, email = `${uid}@comunidadort.edu.ar`, entornoUsado } = {}) {
  return (entornoUsado ?? entorno)
    .authenticatedContext(uid, { email, email_verified: verificado })
    .firestore();
}

// Datos de partida: una persona de cada rol, una dada de baja y datos de ejemplo.
beforeEach(async () => {
  await entorno.clearFirestore();
  await entornoConDominio.clearFirestore();
  for (const e of [entorno, entornoConDominio]) {
    await e.withSecurityRulesDisabled(async (contexto) => {
      const db = contexto.firestore();
      await setDoc(doc(db, 'usuarios/admin'), USUARIO('administrador'));
      await setDoc(doc(db, 'usuarios/ayudante'), USUARIO('ayudante'));
      await setDoc(doc(db, 'usuarios/docente'), USUARIO('docente'));
      await setDoc(doc(db, 'usuarios/baja'), USUARIO('administrador', { activo: false }));
      await setDoc(doc(db, 'insumos/i1'), INSUMO);
      await setDoc(doc(db, 'movimientosStock/m1'), {
        productoId: 'i1', usuarioId: 'admin', usuarioNombre: 'Admin',
        tipo: 'entrada', cantidad: 5, fecha: new Date(),
      });
      await setDoc(doc(db, 'listaCompras/c1'), { insumoId: 'i1', cantidad: 3 });
      await setDoc(doc(db, 'listasTP/t1'), { nombre: 'TP 1', activo: true, insumos: [] });
      await setDoc(doc(db, 'ubicaciones/armario1'), { nombre: 'Armario 1' });
      await setDoc(doc(db, 'alertasVistas/docente_a1'), { usuarioId: 'docente', alertaId: 'a1' });
    });
  }
});

describe('sin sesión o con la cuenta sin verificar', () => {
  it('sin sesión no se lee ni se escribe nada', async () => {
    const db = entorno.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'insumos/i1')));
    await assertFails(getDoc(doc(db, 'usuarios/admin')));
    await assertFails(setDoc(doc(db, 'insumos/nuevo'), INSUMO));
  });

  it('con el mail sin verificar no pasa nada, ni siquiera siendo administrador', async () => {
    const db = como('admin', { verificado: false });
    await assertFails(getDoc(doc(db, 'insumos/i1')));
    await assertFails(setDoc(doc(db, 'insumos/nuevo'), INSUMO));
  });

  it('una colección que la app no usa está prohibida', async () => {
    const db = como('admin');
    await assertFails(setDoc(doc(db, 'test/x'), { a: 1 }));
    await assertFails(getDoc(doc(db, 'test/x')));
  });
});

describe('cuenta dada de baja', () => {
  it('no puede leer ni escribir nada, aunque su rol fuera administrador', async () => {
    const db = como('baja');
    await assertFails(getDoc(doc(db, 'insumos/i1')));
    await assertFails(getDoc(doc(db, 'usuarios/baja')));
    await assertFails(updateDoc(doc(db, 'insumos/i1'), { stock: 1 }));
  });
});

describe('insumos', () => {
  it('todos los roles los leen', async () => {
    for (const uid of ['admin', 'ayudante', 'docente']) {
      await assertSucceeds(getDoc(doc(como(uid), 'insumos/i1')));
      await assertSucceeds(getDocs(collection(como(uid), 'insumos')));
    }
  });

  it('una cuenta nueva, sin documento todavía, también los lee', async () => {
    await assertSucceeds(getDoc(doc(como('recienLlegada'), 'insumos/i1')));
  });

  it('el administrador da de alta, edita, da de baja y reactiva', async () => {
    const db = como('admin');
    await assertSucceeds(setDoc(doc(db, 'insumos/nuevo'), INSUMO));
    await assertSucceeds(updateDoc(doc(db, 'insumos/i1'), { ubicacion: 'Estante B', categoria: 'Alcoholes' }));
    await assertSucceeds(updateDoc(doc(db, 'insumos/i1'), { activo: false }));
    await assertSucceeds(updateDoc(doc(db, 'insumos/i1'), { activo: true }));
  });

  it('el ayudante cambia el stock pero nada más', async () => {
    const db = como('ayudante');
    await assertSucceeds(updateDoc(doc(db, 'insumos/i1'), { stock: 2 }));
    await assertFails(updateDoc(doc(db, 'insumos/i1'), { nombre: 'Otro nombre' }));
    await assertFails(updateDoc(doc(db, 'insumos/i1'), { stock: 2, ubicacion: 'Otro lugar' }));
    await assertFails(updateDoc(doc(db, 'insumos/i1'), { activo: false }));
  });

  it('el ayudante no da de alta insumos', async () => {
    await assertFails(setDoc(doc(como('ayudante'), 'insumos/nuevo'), INSUMO));
  });

  it('el docente no modifica nada', async () => {
    const db = como('docente');
    await assertFails(updateDoc(doc(db, 'insumos/i1'), { stock: 2 }));
    await assertFails(setDoc(doc(db, 'insumos/nuevo'), INSUMO));
  });

  it('nadie borra un insumo, ni el administrador (la baja es lógica)', async () => {
    await assertFails(deleteDoc(doc(como('admin'), 'insumos/i1')));
  });

  it('no se aceptan datos inválidos: stock negativo, decimal o sin nombre', async () => {
    const admin = como('admin');
    await assertFails(setDoc(doc(admin, 'insumos/malo1'), { ...INSUMO, stock: -1 }));
    await assertFails(setDoc(doc(admin, 'insumos/malo2'), { ...INSUMO, stock: 1.5 }));
    await assertFails(setDoc(doc(admin, 'insumos/malo3'), { ...INSUMO, nombre: '' }));
    await assertFails(setDoc(doc(admin, 'insumos/malo4'), { ...INSUMO, ubicacion: '' }));
    await assertFails(updateDoc(doc(como('ayudante'), 'insumos/i1'), { stock: -3 }));
  });

  it('un consumo (transacción que baja el stock y deja el movimiento) lo puede hacer el ayudante', async () => {
    const db = como('ayudante');
    await assertSucceeds(
      runTransaction(db, async (t) => {
        const ref = doc(db, 'insumos/i1');
        const actual = await t.get(ref);
        t.update(ref, { stock: actual.data().stock - 2 });
        t.set(doc(collection(db, 'movimientosStock')), {
          productoId: 'i1', usuarioId: 'ayudante', usuarioNombre: 'Ayu',
          tipo: 'salida', cantidad: 2, fecha: new Date(), motivo: 'TP 1',
        });
      }),
    );
  });

  it('una importación (tanda de insumos, movimientos y ubicaciones) la puede hacer el administrador', async () => {
    const db = como('admin');
    const lote = writeBatch(db);
    lote.set(doc(db, 'ubicaciones/armario9'), { nombre: 'Armario 9' });
    for (const i of [1, 2, 3]) {
      const ref = doc(collection(db, 'insumos'));
      lote.set(ref, { ...INSUMO, nombre: `Importado ${i}` });
      lote.set(doc(collection(db, 'movimientosStock')), {
        productoId: ref.id, usuarioId: 'admin', usuarioNombre: 'Admin',
        tipo: 'entrada', cantidad: 5, fecha: new Date(), motivo: 'Alta de insumo',
      });
    }
    await assertSucceeds(lote.commit());
  });
});

describe('movimientos de stock', () => {
  const MOV = (usuarioId, extra = {}) => ({
    productoId: 'i1', usuarioId, usuarioNombre: 'X',
    tipo: 'salida', cantidad: 1, fecha: new Date(), ...extra,
  });

  it('todos los roles los leen', async () => {
    for (const uid of ['admin', 'ayudante', 'docente']) {
      await assertSucceeds(getDocs(collection(como(uid), 'movimientosStock')));
    }
  });

  it('administrador y ayudante los crean, firmados con su propio id', async () => {
    await assertSucceeds(setDoc(doc(como('admin'), 'movimientosStock/n1'), MOV('admin')));
    await assertSucceeds(setDoc(doc(como('ayudante'), 'movimientosStock/n2'), MOV('ayudante')));
  });

  it('nadie firma un movimiento a nombre de otra persona', async () => {
    await assertFails(setDoc(doc(como('ayudante'), 'movimientosStock/n3'), MOV('admin')));
  });

  it('el docente no crea movimientos', async () => {
    await assertFails(setDoc(doc(como('docente'), 'movimientosStock/n4'), MOV('docente')));
  });

  it('un movimiento nunca se edita ni se borra', async () => {
    await assertFails(updateDoc(doc(como('admin'), 'movimientosStock/m1'), { cantidad: 99 }));
    await assertFails(deleteDoc(doc(como('admin'), 'movimientosStock/m1')));
  });

  it('un tipo o una cantidad inválidos se rechazan', async () => {
    const db = como('admin');
    await assertFails(setDoc(doc(db, 'movimientosStock/n5'), MOV('admin', { tipo: 'regalo' })));
    await assertFails(setDoc(doc(db, 'movimientosStock/n6'), MOV('admin', { cantidad: 1.5 })));
  });
});

describe('lista de compras', () => {
  it('administrador y ayudante la leen y la modifican', async () => {
    for (const uid of ['admin', 'ayudante']) {
      const db = como(uid);
      await assertSucceeds(getDoc(doc(db, 'listaCompras/c1')));
      await assertSucceeds(updateDoc(doc(db, 'listaCompras/c1'), { cantidad: 5 }));
      await assertSucceeds(setDoc(doc(db, `listaCompras/${uid}`), { insumoId: 'i1', cantidad: 1 }));
    }
  });

  it('el docente no tiene acceso', async () => {
    const db = como('docente');
    await assertFails(getDoc(doc(db, 'listaCompras/c1')));
    await assertFails(setDoc(doc(db, 'listaCompras/x'), { insumoId: 'i1', cantidad: 1 }));
  });
});

describe('trabajos prácticos', () => {
  it('todos los roles los leen', async () => {
    for (const uid of ['admin', 'ayudante', 'docente']) {
      await assertSucceeds(getDoc(doc(como(uid), 'listasTP/t1')));
    }
  });

  it('administrador y docente los crean y editan; el ayudante no', async () => {
    for (const uid of ['admin', 'docente']) {
      const db = como(uid);
      await assertSucceeds(setDoc(doc(db, `listasTP/${uid}`), { nombre: 'Nuevo', activo: true, insumos: [] }));
      await assertSucceeds(updateDoc(doc(db, 'listasTP/t1'), { activo: false }));
    }
    const ayudante = como('ayudante');
    await assertFails(setDoc(doc(ayudante, 'listasTP/x'), { nombre: 'Nuevo', activo: true, insumos: [] }));
    await assertFails(updateDoc(doc(ayudante, 'listasTP/t1'), { nombre: 'Otro' }));
  });

  it('un TP no se borra: la baja es lógica', async () => {
    await assertFails(deleteDoc(doc(como('admin'), 'listasTP/t1')));
  });
});

describe('ubicaciones', () => {
  it('todos las leen', async () => {
    await assertSucceeds(getDocs(collection(como('docente'), 'ubicaciones')));
  });

  it('solo el administrador las agrega, y nadie las edita ni las borra', async () => {
    await assertSucceeds(setDoc(doc(como('admin'), 'ubicaciones/estanteb'), { nombre: 'Estante B' }));
    await assertFails(setDoc(doc(como('ayudante'), 'ubicaciones/estantec'), { nombre: 'Estante C' }));
    await assertFails(updateDoc(doc(como('admin'), 'ubicaciones/armario1'), { nombre: 'Otro' }));
    await assertFails(deleteDoc(doc(como('admin'), 'ubicaciones/armario1')));
  });
});

describe('usuarios', () => {
  const NUEVO = (uid, extra = {}) => ({
    nombre: 'Ana Pérez',
    email: `${uid}@comunidadort.edu.ar`,
    rol: 'docente',
    activo: true,
    puedeVerSedronar: false,
    ...extra,
  });

  it('una cuenta nueva crea su propio documento como docente', async () => {
    await assertSucceeds(setDoc(doc(como('nueva'), 'usuarios/nueva'), NUEVO('nueva')));
  });

  it('nadie puede crearse un rol más alto, ni inactivo, ni con Sedronar, ni con campos de más', async () => {
    const db = como('nueva');
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { rol: 'administrador' })));
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { rol: 'ayudante' })));
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { puedeVerSedronar: true })));
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { activo: false })));
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { extra: 1 })));
  });

  it('no se crea el documento de otra persona ni con el mail de otra', async () => {
    const db = como('nueva');
    await assertFails(setDoc(doc(db, 'usuarios/otra'), NUEVO('otra')));
    await assertFails(setDoc(doc(db, 'usuarios/nueva'), NUEVO('nueva', { email: 'admin@comunidadort.edu.ar' })));
  });

  it('cada persona lee el suyo y solo el administrador lee los de todos', async () => {
    await assertSucceeds(getDoc(doc(como('docente'), 'usuarios/docente')));
    await assertFails(getDoc(doc(como('docente'), 'usuarios/admin')));
    await assertFails(getDocs(collection(como('docente'), 'usuarios')));
    await assertSucceeds(getDoc(doc(como('admin'), 'usuarios/docente')));
    await assertSucceeds(getDocs(collection(como('admin'), 'usuarios')));
  });

  it('el administrador cambia roles, da de baja y reactiva', async () => {
    const db = como('admin');
    await assertSucceeds(updateDoc(doc(db, 'usuarios/docente'), { rol: 'ayudante' }));
    await assertSucceeds(updateDoc(doc(db, 'usuarios/docente'), { activo: false }));
    await assertSucceeds(updateDoc(doc(db, 'usuarios/docente'), { activo: true }));
  });

  it('cada persona cambia su nombre pero no su rol, ni su baja, ni el de otro', async () => {
    const db = como('docente');
    await assertSucceeds(updateDoc(doc(db, 'usuarios/docente'), { nombre: 'Nuevo Nombre' }));
    await assertFails(updateDoc(doc(db, 'usuarios/docente'), { rol: 'administrador' }));
    await assertFails(updateDoc(doc(db, 'usuarios/docente'), { puedeVerSedronar: true }));
    await assertFails(updateDoc(doc(db, 'usuarios/docente'), { nombre: 'X', rol: 'administrador' }));
    await assertFails(updateDoc(doc(db, 'usuarios/ayudante'), { nombre: 'Intruso' }));
    await assertFails(updateDoc(doc(db, 'usuarios/docente'), { nombre: '' }));
  });

  it('el ayudante tampoco se sube el rol', async () => {
    await assertFails(updateDoc(doc(como('ayudante'), 'usuarios/ayudante'), { rol: 'administrador' }));
  });

  it('nadie borra a un usuario: la baja es lógica', async () => {
    await assertFails(deleteDoc(doc(como('admin'), 'usuarios/docente')));
  });
});

describe('alertas vistas', () => {
  it('cada persona marca y desmarca solo las suyas', async () => {
    const db = como('ayudante');
    await assertSucceeds(setDoc(doc(db, 'alertasVistas/ayudante_a1'), { usuarioId: 'ayudante', alertaId: 'a1' }));
    await assertSucceeds(deleteDoc(doc(db, 'alertasVistas/ayudante_a1')));
  });

  it('no se marca a nombre de otra persona', async () => {
    const db = como('ayudante');
    await assertFails(setDoc(doc(db, 'alertasVistas/docente_a2'), { usuarioId: 'docente', alertaId: 'a2' }));
    await assertFails(setDoc(doc(db, 'alertasVistas/ayudante_a2'), { usuarioId: 'docente', alertaId: 'a2' }));
  });

  it('se leen las propias (con el filtro que usa la app) y no las de otra persona', async () => {
    const propias = query(collection(como('docente'), 'alertasVistas'), where('usuarioId', '==', 'docente'));
    await assertSucceeds(getDocs(propias));
    await assertFails(getDoc(doc(como('ayudante'), 'alertasVistas/docente_a1')));
    await assertFails(deleteDoc(doc(como('ayudante'), 'alertasVistas/docente_a1')));
  });
});

describe('interruptor del dominio institucional', () => {
  it('apagado (como se entrega), una cuenta verificada de otro dominio entra', async () => {
    const db = como('admin', { email: 'alguien@gmail.com' });
    await assertSucceeds(getDoc(doc(db, 'insumos/i1')));
  });

  it('encendido, solo entran cuentas de ORT', async () => {
    const ort = como('admin', { entornoUsado: entornoConDominio });
    const ort2 = como('docente', { email: 'ana@ort.edu.ar', entornoUsado: entornoConDominio });
    const otra = como('admin', { email: 'alguien@gmail.com', entornoUsado: entornoConDominio });
    const parecida = como('admin', { email: 'alguien@miort.edu.ar', entornoUsado: entornoConDominio });
    const subdominio = como('admin', { email: 'alguien@ort.edu.ar.falso.com', entornoUsado: entornoConDominio });

    await assertSucceeds(getDoc(doc(ort, 'insumos/i1')));
    await assertSucceeds(getDoc(doc(ort2, 'insumos/i1')));
    await assertFails(getDoc(doc(otra, 'insumos/i1')));
    await assertFails(getDoc(doc(parecida, 'insumos/i1')));
    await assertFails(getDoc(doc(subdominio, 'insumos/i1')));
    await assertFails(updateDoc(doc(otra, 'insumos/i1'), { stock: 1 }));
  });
});
