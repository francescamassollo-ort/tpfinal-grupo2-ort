# BioLab ORT

Sistema de gestión de insumos para los laboratorios de biotecnología del Instituto ORT Argentina.
Hoy el inventario se lleva en una planilla de Excel que se actualiza cada tres meses, sin historial de
movimientos ni alertas de stock. Esta app lo reemplaza.

Proyecto final, Tecnicatura Superior en Sistemas Informáticos, ORT 2026.

App móvil hecha con Flutter y Firebase.

**Figma:** https://www.figma.com/design/6vWt7ArXtRAsP8k7vZOlB8/TPFinal?node-id=0-1
**Repositorio:** https://github.com/francescamassollo-ort/tpfinal-grupo2-ort

## Integrantes
- Daiana Gimenez Torrico
- Francesca Rocío Massollo
- Joaquín González Fuentes
- Mariano Izarriaga
- Nahuel Ezequiel Di Paolo

## Cómo ejecutar desde cero

### Requisitos
| | Recomendado |
|---|---|
| Flutter | **3.41.6 o superior**, estable. Está verificado que `dev` compila con la 3.41.6 (Dart 3.11.4, el mínimo que exige el proyecto, `^3.11.4`). El `pubspec.lock` lo generó una 3.47, así que también se puede usar esa |
| JDK | **17 o 21**. El JDK 25 que trae la última versión de Android Studio no funciona con el Gradle del proyecto |
| Android Studio | Última versión estable, con el Android SDK y las **Android SDK Command-line Tools** (SDK Manager, pestaña SDK Tools) |
| Dispositivo de prueba | Emulador de Android (probado en Pixel 7 con Android 16, API 36) o un teléfono con depuración USB |
| Windows | **Modo de desarrollador** activado (Configuración, Para programadores) |
| Git | Cualquier versión reciente |

La app está configurada para **Android**. No corre en el navegador ni en escritorio.

### 1. Instalar Flutter
1. Seguir la guía oficial: https://docs.flutter.dev/install
2. Verificar con `flutter --version` que sea la 3.41.6 o una posterior, y revisar el resto con `flutter doctor`.

### 2. Usar un JDK 17 o 21
Si la terminal usa el JDK de Android Studio y es el 25, indicarle a Flutter cuál usar (una sola vez):

```
flutter config --jdk-dir="C:\ruta\al\jdk-21"
```

### 3. Clonar el repositorio
```
git clone https://github.com/francescamassollo-ort/tpfinal-grupo2-ort.git
cd tpfinal-grupo2-ort
```

### 4. Instalar las dependencias
```
flutter pub get
```

### 5. Abrir el emulador
1. En Android Studio: **Tools, Device Manager**, crear un dispositivo (por ejemplo Pixel 7) y arrancarlo con ▶.
2. Confirmar que Flutter lo ve y copiar su identificador:
   ```
   flutter devices
   ```

### 6. Ejecutar la app
```
flutter run -d <identificador-del-emulador>
```
La app arranca en **Inventario**: el login todavía no está conectado a Firebase, así que no se piden credenciales.

Firebase ya viene configurado en el repositorio (`android/app/google-services.json` y
`lib/firebase_options.dart`), no hace falta crear nada.

### 7. Correr las pruebas
```
flutter test
```
Las pruebas están en `test/` y cubren la lógica que no depende de Firebase (por ahora, la lista de compras, las alertas, el historial y la predicción de stock).

### Problemas conocidos
| Síntoma | Causa y solución |
|---|---|
| `Module was compiled with an incompatible version of Kotlin` en la tarea `:firebase_auth:compileDebugKotlin` | Es de una versión vieja del proyecto: `firebase_auth` necesita Kotlin 2.4. Ya está resuelto en `dev` (plugin de Kotlin 2.4.0 y `jvmTarget` con `compilerOptions`). Si aparece, actualizar la rama con `dev` |
| Error de Gradle que solo muestra un número de versión, como `25.0.2` | Gradle está usando el JDK 25. Usar un JDK 17 o 21 (paso 2) |
| `Building with plugins requires symlink support` | Falta activar el Modo de desarrollador de Windows y abrir una terminal nueva |
| La app abre pero queda en blanco o en el logo de Flutter, con `channel-error` de Firebase en el log | No se registraron los plugins. Correr `flutter clean`, `flutter pub get` y volver a compilar |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` al instalar | El emulador se quedó sin espacio. Desinstalar la app, compilar solo para x86_64 (`--target-platform android-x64`) o usar **Wipe Data** en el Device Manager |
| `this and base files have different roots` al compilar Kotlin (Windows) | El proyecto y la caché de paquetes de Flutter están en discos distintos. Agregar `--android-project-arg="kotlin.incremental=false"` al compilar, o poner el proyecto en el mismo disco que `%LOCALAPPDATA%\Pub\Cache` |
| `flutter doctor` dice "Android license status unknown" | Probar `flutter doctor --android-licenses`. Si el emulador y la compilación andan, se puede ignorar |

### Versiones
| Componente | Versión |
|---|---|
| Flutter | 3.41.6 o superior (el lock lo generó una 3.47) |
| Dart | 3.11.4 o superior (mínimo `^3.11.4`) |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.4.0 |
| Plugin Google Services | 4.3.15 |
| Java (compilación) | 17 |
| firebase_core | ^5.0.0 |
| firebase_auth | ^7.0.1 |
| cloud_firestore | ^7.0.0 |
| flutter_riverpod | ^3.3.2 |
| go_router | ^17.5.0 |
| google_fonts | ^8.2.1 |

## Estructura del proyecto
Todo el código está en `lib/`.

| Carpeta | Contenido |
|---|---|
| `core/` | Tema, colores, textos (`AppStrings`), estilos de texto, rutas (`app_router.dart`) y el `AppShell` con la barra inferior y el menú lateral |
| `widgets/` | Componentes reutilizables: fondo decorativo, encabezado de pantalla, tarjeta con contorno, botón de acción, fila de Compartir y Descargar, selector de formato (PDF o Excel), selector de cantidad, tarjeta de insumo, y los botones y campos de las pantallas de acceso |
| `screens/<área>/` | Pantallas de cada flujo: `auth`, `inventario`, `consumo`, `historial`, `alertas`, `compras`, `tp`, `usuarios`, `perfil` |
| `providers/` | Estado de la app con Riverpod |
| `models/` | Modelos de dominio: `Insumo`, `TrabajoPractico`, `ListaCompra`, `Alerta`, `AlertaVista`, `MovimientoStock` y los de la predicción de stock (`PrediccionStock` y `VentanaPrediccion`) |
| `services/` | Acceso a Firestore: `InsumoService` (colección `insumos`), `TpService` (colección `listasTP`), `ListaCompraService` (colección `listaCompras`) `HistorialService` (colección `movimientosStock`, solo lectura: los movimientos los escribe `StockService`, junto con el cambio de stock) y `AlertasVistasService` (colección `alertasVistas`: qué alertas ya vio cada persona). `AlertaService` y `StockPredictionService` no usan Firestore: generan las alertas y las predicciones de stock a partir de los insumos, los movimientos y los trabajos prácticos. `ListaCompraExportador` y `HistorialExportador` arman el PDF y el CSV de la lista de compras y del historial (con lo que comparten en `ExportacionComun`) y `ArchivoService` los comparte o los guarda en el teléfono |

Las pruebas unitarias están en `test/` (fuera de `lib/`).

## Navegación
- La app arranca en **Inventario**. El login queda para el final.
- **Dentro del `AppShell`** (barra inferior y menú lateral, que muestra opciones según el rol): Inventario, Detalle de insumo (`/insumo/:id`), Alta de insumo, Consumo, Alertas, Trabajos prácticos, Usuarios y Perfil.
- **Fuera del `AppShell`**, a pantalla completa: Welcome, Login, Register, **Historial** y **Lista de compras**.

### Decisiones de navegación
- **Historial y Lista de compras** van fuera del `AppShell` porque en el diseño no llevan la barra inferior del shell. Lista de compras tiene además su propio botón flotante circular. La flecha de volver regresa a la pantalla anterior o, si no hay, a Inventario.
- **Alertas** va dentro del `AppShell` porque el diseño lleva la barra inferior, pero sin el botón flotante: el shell recibe la ruta actual (`location`) y lo esconde solo en `/alertas`.

## Seguimiento de pantallas
⏳ Placeholder: la ruta existe y la pantalla todavía no está hecha · 🚧 En construcción: interfaz armada, sin datos reales de Firebase · 🎭 Demostración: funciona con datos de ejemplo · 🔍 En revisión: hecha en una rama, todavía sin mergear a `dev` · ✅ Funcional: con datos reales (de Firebase o calculados a partir de ellos); las acciones que dependen de decisiones pendientes quedan indicadas

### Acceso
| Pantalla | Ruta | Estado |
|---|---|---|
| Bienvenida | `/welcome` | 🚧 En construcción |
| Iniciar sesión | `/login` | 🚧 En construcción (todavía no usa `AuthService`) |
| Registro | `/register` | 🚧 En construcción (todavía no usa `AuthService`) |

### Inventario
| Pantalla | Ruta | Estado |
|---|---|---|
| Inventario | `/inventario` | ✅ Funcional (lee los insumos de Firestore, con buscador, filtros y tarjetas) |
| Buscar y filtrar | `/inventario/filtro` | ⏳ Placeholder (hoy el filtro es un diálogo dentro de Inventario) |
| Detalle de insumo | `/insumo/:id` | ✅ Funcional (lee el insumo de Firestore en tiempo real; Editar y Baja avisan "Próximamente"; Historial y Registrar consumo navegan a sus pantallas) |
| Alta de insumo | `/insumo/alta` | ✅ Funcional (formulario de alta que guarda en Firestore; el botón "Buscar duplicados" avisa si ya existe algo parecido, ver "Duplicados al dar de alta") |
| Escáner | `/scanner` | ⏳ Placeholder |
| Consumo | `/consumo` | ✅ Funcional (registra una salida de stock; con `/consumo?insumo=ID` abre con ese insumo ya elegido) |

### Historial, alertas y compras
| Pantalla | Ruta | Estado |
|---|---|---|
| Historial de movimientos | `/historial` | ✅ Funcional (lee la colección `movimientosStock` de Firestore en tiempo real, los últimos 500, y muestra el nombre del insumo; cada alta con stock, consumo, entrada o ajuste deja su movimiento, ver "Movimientos de stock"; panel de filtros por tipo, insumo y fechas; Compartir y Descargar en PDF o CSV, con lo que se ve: si hay filtros puestos solo salen esos movimientos y el archivo lo aclara) |
| Alertas | `/alertas` | ✅ Funcional (alertas calculadas desde los insumos (sin stock, stock bajo, vencido y vencimiento cercano) y desde la predicción de stock (se agotaría antes de la próxima compra y no alcanza para un trabajo práctico, en naranja); tocar una alerta abre el detalle del insumo; cada alerta se puede marcar como vista, y queda en la lista pero atenuada; se pueden filtrar por tipo y por estado, ver "Filtro de alertas") |
| Lista de compras | `/compras` | ✅ Funcional (colección `listaCompras` de Firestore: cantidad editable con mínimo 1; sugerencias del sistema para los insumos con stock bajo; agregar a mano un insumo desde un panel (solo se ofrecen los que no están en la lista); menú en cada ítem para marcarlo como comprado o descartarlo, con Deshacer (la lista muestra solo los pendientes, así que el ítem sale); Compartir y Descargar en PDF o CSV; buscar y papelera todavía sin acción) |

### Trabajos prácticos
| Pantalla | Ruta | Estado |
|---|---|---|
| Lista de trabajos prácticos | `/tp` | ⏳ Placeholder (el modelo, el servicio y el provider de `TrabajoPractico` ya están) |
| Detalle de trabajo práctico | `/tp/detalle` | ⏳ Placeholder |
| Nuevo trabajo práctico | `/tp/nuevo` | ⏳ Placeholder |

### Administración
| Pantalla | Ruta | Estado |
|---|---|---|
| Usuarios | `/usuarios` | ⏳ Placeholder |
| Perfil | `/perfil` | ⏳ Placeholder |

## Predicción de stock
Estima cuándo se agota cada insumo antes de la próxima compra institucional (requerimiento A02). Se ve en la
pantalla de Alertas: `alertasProvider` suma los avisos de `prediccionStockProvider` a los de los insumos.
Todavía no se usa en las sugerencias de Lista de compras.

- **Dos avisos por insumo, cada uno con su motivo (en naranja, porque son pronósticos):** "Se agotaría el 03/12, antes de
  la próxima compra" (por el ritmo de consumo) y "No alcanza para Química 3 (20/11)" (por un trabajo práctico
  planificado). Si el insumo ya está sin stock no se repite el primero, porque "Sin stock" ya lo dice.
- **La predicción no frena las alertas:** mientras carga, o si falla la lectura de los movimientos, Alertas muestra
  igual las de los insumos.

- **Promedio de consumo, no aprendizaje automático.** Se calcula cuántas unidades por día se vienen consumiendo (solo
  cuentan las salidas) y con eso cuántos días alcanza el stock. Se recalcula con cada movimiento nuevo, así que mejora
  a medida que hay historial, sin entrenar ningún modelo. Con tan pocos datos un modelo no le ganaría a un promedio.
- **Cruce con los trabajos prácticos.** Suma lo que piden los TP activos entre hoy y la próxima compra y avisa cuál es el
  primer TP para el que no alcanza el stock. Es un aviso aparte del ritmo de consumo y no se suman, porque el consumo
  pasado ya incluye los TP anteriores.
- **Autoajuste de la ventana.** Elige entre mirar 30 o 60 días de consumo: "predice el pasado" en las últimas semanas con
  cada ventana, lo compara con lo que realmente se consumió y se queda con la que menos se equivocó. Si hay poca
  historia usa 30.

Supuestos pendientes de confirmar:
- La compra institucional es el 1 de julio y el 1 de diciembre (el requerimiento dice solo "julio / diciembre").
- La cantidad que pide un TP está en la misma unidad que el stock, igual que en `TpService.verificarDisponibilidad`.
- Mientras no haya movimientos de salida registrados (por ejemplo, en una base nueva), la predicción da una lista vacía y el autoajuste usa 30 días.

## Movimientos de stock
Cada cambio de stock deja un movimiento en la colección `movimientosStock` (es lo que muestra el Historial y lo que
usa la predicción). Lo escribe `StockService`:

- **Una sola transacción:** el stock nuevo del insumo y su movimiento se guardan juntos. Si una de las dos escrituras
  falla, no se guarda ninguna: no queda un stock cambiado sin su movimiento ni al revés. La lectura del stock va dentro
  de la transacción, así dos consumos a la vez no se pisan.
- **Qué operaciones hay:** `registrarEntrada`, `registrarSalida` (no deja sacar más de lo que hay), `registrarAjuste` (deja
  el stock en un valor y guarda la diferencia con signo) y `registrarAlta` (el insumo nuevo más una entrada por su stock
  inicial, con el motivo "Alta de insumo"; si el stock inicial es 0 no hay movimiento).
- **Cómo se guarda la cantidad:** positiva en entradas y salidas (el sentido lo da el tipo) y con signo en los ajustes.
- **Quién lo hizo:** el id y el nombre de la persona se guardan en el movimiento. El nombre sale del documento de la persona
  en `usuarios`, o del nombre o el email de su cuenta de Firebase; sin sesión figura "Sin sesión" (hoy el login todavía no
  está conectado). Para que salga el nombre del documento, el registro tiene que crear `usuarios/{uid}`.
- **Las cuentas se prueban solas:** validar, calcular el stock que queda y armar el movimiento está en `StockLogica`, sin
  Firestore. La transacción en sí no tiene prueba automática y se probó a mano.
- Los errores (cantidad inválida, stock insuficiente, insumo inexistente) son `StockException` con un mensaje listo para
  mostrar.
- Las reglas de Firestore (#46) tienen que permitir escribir en `insumos` y en `movimientosStock`.

## Alertas vistas
Cada alerta se puede marcar como vista desde la pantalla de Alertas. Queda en la lista, atenuada, y la campana de la
barra inferior deja de contarla (el color de la campana también mira solo las que no se vieron).

- **Es por persona.** Se guarda en la colección `alertasVistas`, un documento por persona y alerta (id
  `{usuarioId}_{alertaId}`). Lo que marca una persona no cambia lo que ven las demás.
- **El login todavía no está conectado**, así que hoy todos comparten el id `sin-sesion` y en la práctica se comparte. Cuando
  se conecte, el id sale de la sesión de Firebase (`usuarioActualIdProvider`) y pasa a ser por persona sin tocar nada más.
- **Las alertas se calculan, no se guardan:** lo único que se guarda es la marca. Cuando una alerta deja de existir (por
  ejemplo, se repone el stock) su marca se borra sola, así que si vuelve a aparecer lo hace como nueva.
- **La limpieza es conservadora:** solo borra cuando los insumos, los movimientos, los trabajos prácticos y las marcas
  terminaron de cargar y sin errores. Si no, una alerta que todavía no llegó parecería "inexistente" y se perdería una
  marca válida.
- **Si no se pueden leer las marcas, no se esconde ninguna alerta:** todas se ven como nuevas.

Pendiente de acordar: el nombre de la colección `alertasVistas` tiene que coincidir con las reglas de Firestore (#46), y
no está definido si algunas alertas deberían verlas solo ciertos roles (los requisitos no lo dicen).

## Filtro de alertas
El ícono de filtros de la pantalla de Alertas abre un panel con dos opciones (el diseño dibuja el ícono pero no define
qué opciones tiene, así que se eligieron estas):

- **Tipo de alerta:** todos o uno de los seis (sin stock, stock bajo, vencido, vencimiento cercano, se agotaría antes de la
  próxima compra, no alcanza para un trabajo práctico).
- **Estado:** todas, sin ver o vistas (usa las marcas de "Alertas vistas").

- **Solo cambia la lista, no la campana:** el número y el color de la campana siguen contando todas las alertas sin ver,
  estén filtradas o no.
- Un punto sobre el ícono avisa que hay un filtro puesto. Si ninguna alerta coincide, la pantalla lo dice y ofrece "Limpiar
  filtros" (si no hay ninguna alerta, dice que no hay y no ofrece limpiar).
- Se filtra en memoria, sobre las alertas ya calculadas, igual que el filtro del Historial.
- **El filtro se guarda mientras la app está abierta** (`filtroAlertasProvider`) y se pierde al cerrarla.
## Duplicados al dar de alta

Antes de guardar un insumo nuevo, el formulario de Alta tiene un botón **"Buscar duplicados"** (requerimiento A10). Usa lo que ya se escribió (nombre, tipo, marca y código de barras) y abre una ventana:

- **Comparación de texto** (siempre, instantánea y sin internet): encuentra insumos con el mismo código de barras o con un nombre muy parecido. Para eso usa `DuplicateDetectionService.buscarSimilares`.
- **Sinónimos con IA** (solo si hay clave, ver "Servicios externos"): mientras tanto muestra "Buscando sinónimos con IA…" y, cuando termina, suma los insumos que la IA cree que son el mismo producto con otro nombre ("etanol" y "alcohol etílico"), marcados como "Sugerido por la IA". Si la IA falla o no está configurada, la ventana lo dice y deja el resultado de la comparación de texto.
- Cada coincidencia trae **"Cargarle un consumo"**, que deja el alta y abre Consumo con ese insumo ya elegido (`/consumo?insumo=ID`). El botón **"Es distinto, seguir cargando"** vuelve al formulario sin perder lo escrito.

**Qué se le manda a la IA:** solo los nombres de los insumos (el existente y el que se está cargando), nunca stock, ubicaciones ni códigos de barras. El modelo propone y las reglas deciden: cada sugerencia se valida con las mismas reglas que la comparación de texto.

**Cuota:** cada vez que se toca el botón y hay clave se hace hasta una consulta por cada tipo de insumo (comprado y solución), y más si hay más de 250 de un tipo. No hay límite ni memoria de lo ya consultado.

**Proveedor de IA:** la app habla con la IA a través de la interfaz `ModeloDeLenguaje`. Se usa **Gemini** si hay clave (`GEMINI_API_KEY`); si además hay clave de Groq, Groq queda de **respaldo** y se usa solo cuando Gemini falla (por ejemplo, límite diario agotado). Con una sola clave se usa esa. Para sumar otro proveedor hay que escribir un cliente nuevo que implemente la interfaz y sumarlo en `elegirModeloDeLenguaje` (`sinonimos_provider.dart`). Los textos que ve la persona no nombran al proveedor.

## Servicios externos

La app puede usar servicios de terceros para funciones de IA y datos quimicos. Ninguno es obligatorio para compilar ni ejecutar: si falta la clave, la funcion simplemente no activa.

### Gemini (deteccion de sinonimos, proveedor principal)

Gemini es el modelo de lenguaje que usa la deteccion de sinonimos al dar de alta un insumo (requerimiento A10): se dispara desde el boton "Buscar duplicados" del formulario de Alta.

**Configurar la clave:**
1. Crear una clave en [Google AI Studio](https://aistudio.google.com/apikey) (plan gratuito, sin tarjeta).
2. Copiar `env.example.json` a `env.json` (si todavia no existe) y completar `GEMINI_API_KEY`.
3. `env.json` esta en `.gitignore` y **nunca** debe subirse al repositorio.

**Ejecutar con la clave:**
```
flutter run --dart-define-from-file=env.json -d <id-del-emulador>
```

**Cambiar el modelo** (opcional): setear `GEMINI_MODEL` en `env.json`. El valor por defecto es `gemini-3.5-flash-lite`. Los nombres disponibles para una clave se ven en Google AI Studio, o listandolos con la API (`GET /v1beta/models`). Si el limite diario no alcanza, probar con otro "flash-lite".

**Limites del plan gratuito:** los define Google por proyecto y por modelo, y cambian con el tiempo. Ver la tabla real de la clave en Google AI Studio (icono de uso y limites). Si se agota, la app usa Groq de respaldo, si hay clave.

**Privacidad:** en el plan gratuito Google puede usar lo que se le envia para mejorar sus productos. La app solo envia nombres de insumos.

**Aviso de seguridad:** igual que con Groq, la clave queda embebida en el binario compilado. Para la demo alcanza.

### Groq (deteccion de sinonimos, respaldo)

Groq es el modelo de lenguaje de respaldo: se usa si no hay clave de Gemini, o cuando Gemini falla y hay clave de Groq. Esta detras de la interfaz `ModeloDeLenguaje`, asi que se puede cambiar por otro proveedor sin tocar las pantallas.

**Configurar la clave:**
1. Copiar `env.example.json` a `env.json` en la raiz del proyecto.
2. Completar `GROQ_API_KEY` con la clave de la consola de Groq.
3. `env.json` esta en `.gitignore` y **nunca** debe subirse al repositorio.

**Ejecutar con la clave:**
```
flutter run --dart-define-from-file=env.json -d <id-del-emulador>
```

**Cambiar el modelo** (opcional): setear `GROQ_MODEL` en `env.json`. El valor por defecto es `openai/gpt-oss-20b`.

**Limites del plan gratuito** (verificar en la consola de Groq; el limite es por organizacion, no por usuario):

| Recurso | Limite aproximado |
|---|---|
| Pedidos | 30/min, 1.000/dia |
| Tokens | 8.000/min, 200.000/dia |

**Aviso de seguridad:** la clave queda embebida en el binario compilado. Para la demo alcanza. Una version publicada en la Play Store necesitaria un servidor intermedio para no exponer la clave.

**Sin clave:** la app no falla; la deteccion de duplicados usa solo comparacion de texto.

### PubChem (autocompletar formula y peso molecular)

PubChem es una base de datos publica de compuestos quimicos. La app la usa para completar automaticamente la formula quimica y el peso molecular al dar de alta un insumo.

- No necesita clave ni configuracion extra.
- Se busca por nombre del compuesto o numero CAS. Ejemplo probado: `64-17-5` devuelve Ethanol.
- Los nombres de los compuestos vienen en ingles.
- **No permite buscar por codigo de barras directamente.**

### Codigo de barras (pendiente de implementacion)

La integracion de codigo de barras no esta implementada todavia. El flujo previsto cuando se desarrolle:

1. Base propia (si el insumo ya figura en el inventario local).
2. **UPCitemdb:** endpoint de prueba `https://api.upcitemdb.com/prod/trial/lookup?upc=...` sin clave, 100 consultas por dia. Para uso real puede requerir cuenta de pago (no verificado).
3. **PubChem** (por nombre o numero CAS si UPCitemdb devuelve un nombre quimico).
4. Carga manual si no se encuentra en ninguna fuente.

### Seguridad

- Las reglas de Firestore estan abiertas hoy (issue #46). Mientras no esten cerradas, no guardar claves ni tokens en Firestore.
- Antes de cada `git push`, verificar que no queden claves en el repositorio:

  ```
  git grep gsk_
  ```

## Flujo de trabajo
- Ramas: `main` (entregable), `dev` (integración) y `feat/<nombre>` por cada funcionalidad.
- Cada funcionalidad se desarrolla en su rama y entra a `dev` por Pull Request. De `dev` a `main` se pasa cuando el conjunto está estable.
- El trabajo se organiza con Issues y Milestones por funcionalidad (Historial, Alertas y Compras, etc.), con las etiquetas `modelo`, `servicio`, `pantalla` e `infra`.
- Cada Pull Request enlaza su issue con `Part of #N`.

## Uso de IA
Parte del desarrollo (las pantallas de Historial, Lista de compras y Alertas, sus modelos, servicios y pruebas,
y los componentes compartidos) se hizo con Claude (Anthropic) como asistente. Lo que propuso se revisó, se compiló y se probó en el emulador antes
de subirlo.

- **Por pasos chicos:** antes de escribir, se acordaba qué archivos cambiaban y en cuántos commits.
- **Verificación:** después de cada paso se corría `flutter analyze` y se probaba la app en el emulador.
- **Git lo manejamos nosotros:** ramas, commits, pushes y Pull Requests los hizo una persona del equipo.
- **Qué no hizo la IA:** no tomó decisiones de alcance o diseño sin consultar, ni tocó el trabajo de otros integrantes.
