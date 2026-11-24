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
La app pide **iniciar sesión** (o crear una cuenta) antes de mostrar nada: ver "Inicio de sesión". La primera vez hay que registrarse con un mail institucional de ORT y una contraseña segura (8 caracteres, mayúscula, minúscula, número y símbolo), y después verificar el mail con el enlace que llega por correo.

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
- La app arranca en **Bienvenida** si no hay una sesión iniciada, y en **Inventario** si la hay. Ver "Inicio de sesión".
- **Dentro del `AppShell`** (barra inferior y menú lateral, que muestra opciones según el rol): Inventario, Detalle de insumo (`/insumo/:id`), Alta de insumo, Alertas, Trabajos prácticos, Usuarios y Perfil.
- **Fuera del `AppShell`**, a pantalla completa: Welcome, Login, Register, **Historial**, **Lista de compras**, **Registro de consumo** y **Escáner**.

### Decisiones de navegación
- **Historial, Lista de compras, Registro de consumo y Escáner** van fuera del `AppShell` porque en el diseño no llevan la barra inferior del shell. Lista de compras tiene además su propio botón flotante circular. La flecha de volver regresa a la pantalla anterior o, si no hay, a Inventario.
- **Alertas** va dentro del `AppShell` porque el diseño lleva la barra inferior, pero sin el botón flotante: el shell recibe la ruta actual (`location`) y lo esconde solo en `/alertas`.

## Seguimiento de pantallas
⏳ Placeholder: la ruta existe y la pantalla todavía no está hecha · 🚧 En construcción: interfaz armada, sin datos reales de Firebase · 🎭 Demostración: funciona con datos de ejemplo · 🔍 En revisión: hecha en una rama, todavía sin mergear a `dev` · ✅ Funcional: con datos reales (de Firebase o calculados a partir de ellos); las acciones que dependen de decisiones pendientes quedan indicadas

### Acceso
| Pantalla | Ruta | Estado |
|---|---|---|
| Bienvenida | `/welcome` | ✅ Funcional (lleva a ingresar o a registrarse) |
| Iniciar sesión | `/login` | ✅ Funcional (mail y contraseña con Firebase Authentication) |
| Registro | `/register` | ✅ Funcional (crea la cuenta; las contraseñas se escriben ocultas) |

### Inventario
| Pantalla | Ruta | Estado |
|---|---|---|
| Inventario | `/inventario` | ✅ Funcional (lee los insumos de Firestore, con buscador, filtros y tarjetas) |
| Buscar y filtrar | `/inventario/filtro` | ⏳ Placeholder (hoy el filtro es un diálogo dentro de Inventario) |
| Detalle de insumo | `/insumo/:id` | ✅ Funcional (lee el insumo de Firestore en tiempo real; Editar y Baja funcionan, ver "Editar y dar de baja un insumo"; Historial abre los movimientos de ese insumo y Registrar consumo navega a su pantalla) |
| Alta de insumo | `/insumo/alta` | ✅ Funcional (formulario de alta que guarda en Firestore; "Escanear código de barras" completa los datos, ver "Escáner de código de barras"; el botón "Buscar duplicados" avisa si ya existe algo parecido, ver "Duplicados al dar de alta") |
| Escáner | `/scanner` | ✅ Funcional, ver "Escáner de código de barras" (cámara a pantalla completa; busca el código en nuestros insumos y, si no está, en UPCitemdb y PubChem; "Sumar stock", "Usar estos datos" o "Cargar a mano") |
| Registro de consumo | `/consumo` | ✅ Funcional, ver "Registro de consumo" (lista de insumos con cuánto retirar de cada uno y "Confirmar salida"; con `/consumo?insumo=ID` abre con ese insumo ya elegido) |

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
| Usuarios | `/usuarios` | ✅ Hecha (solo administrador) |
| Importar desde Excel | `/importar` | ✅ Hecha (solo administrador), ver "Importar el inventario desde Excel" |
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
- **Qué operaciones hay:** `registrarEntrada`, `registrarSalida` (no deja sacar más de lo que hay), `registrarSalidas`
  (varios insumos a la vez, todo o nada, ver "Registro de consumo"), `registrarAjuste` (deja
  el stock en un valor y guarda la diferencia con signo) y `registrarAlta` (el insumo nuevo más una entrada por su stock
  inicial, con el motivo "Alta de insumo"; si el stock inicial es 0 no hay movimiento).
- **Cómo se guarda la cantidad:** positiva en entradas y salidas (el sentido lo da el tipo) y con signo en los ajustes.
- **Quién lo hizo:** el id y el nombre de la persona se guardan en el movimiento. El nombre sale del documento de la persona
  en `usuarios`, o del nombre o el email de su cuenta de Firebase; sin sesión figura "Sin sesión" (con el login conectado no
  debería pasar). Para que salga el nombre del documento, el registro tiene que crear `usuarios/{uid}`.
- **Las cuentas se prueban solas:** validar, calcular el stock que queda y armar el movimiento está en `StockLogica`, sin
  Firestore. La transacción en sí no tiene prueba automática y se probó a mano.
- Los errores (cantidad inválida, stock insuficiente, insumo inexistente) son `StockException` con un mensaje listo para
  mostrar.
- Las reglas de Firestore (#46) tienen que permitir escribir en `insumos` y en `movimientosStock`.

## Registro de consumo
La pantalla sigue el diseño ("Registro de consumo" del prototipo): una lista de insumos, cada uno con cuánto hay
disponible y un selector de cuánto retirar, un enlace "+ Agregar otro insumo" y el botón "Confirmar salida".

- **Varios insumos en una sola salida.** Cada fila tiene un selector que nunca baja de 1 ni pasa de lo disponible. Una fila
  se saca de la lista deslizándola hacia la izquierda.
- **"+ Agregar otro insumo"** abre un buscador (sin mirar mayúsculas ni tildes) con los insumos que tienen stock y todavía
  no están en la lista.
- **El motivo no está en el diseño, pero se necesita** (TP, Clase, Investigación u Otro, con un detalle obligatorio). Queda
  debajo de la lista, antes del botón, y es el mismo para todas las líneas de la salida.
- **Confirmar es todo o nada.** `StockService.registrarSalidas` guarda todo en una sola transacción: si falta stock de un
  solo insumo, no se registra ninguno y el aviso dice de cuál ("No hay stock suficiente de ..."). Cada línea deja su propio
  movimiento de salida en el historial.
- **Después de confirmar** la lista queda vacía para poder cargar otro consumo.
- **Cómo se llega:** desde el detalle de un insumo ("Registrar consumo") se abre ya con ese insumo; también desde el aviso de
  duplicados del Alta ("Cargarle un consumo"). Un id que no corresponde a ningún insumo se ignora.
- Va fuera del `AppShell`, sin barra inferior ni botón flotante, como en el diseño.

## Alertas vistas
Cada alerta se puede marcar como vista desde la pantalla de Alertas. Queda en la lista, atenuada, y la campana de la
barra inferior deja de contarla (el color de la campana también mira solo las que no se vieron).

- **Es por persona.** Se guarda en la colección `alertasVistas`, un documento por persona y alerta (id
  `{usuarioId}_{alertaId}`). Lo que marca una persona no cambia lo que ven las demás.
- **Con el login conectado, el id sale de la sesión de Firebase** (`usuarioActualIdProvider`), así que cada persona tiene sus
  propias marcas. El id fijo `sin-sesion` queda solo como respaldo si no hubiera sesión.
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
## Escáner de código de barras
Desde el Alta, el botón **"Escanear código de barras"** abre la cámara a pantalla completa (sin barra inferior, como en el
diseño). Al leer un código lo busca en capas y se queda con la primera que lo conoce (`BarcodeService`):

1. **Nuestros insumos** (`Insumo.codigoBarras`). Si ya está cargado, la pantalla muestra su nombre y su stock con dos
   botones: **"Sumar stock"** (pide cuántas unidades y registra una entrada de "Reposición", en vez de crear un duplicado)
   y **"Editar"** (abre su detalle). Un código UPC-A de 12 cifras y su versión EAN-13 (con un 0 delante) cuentan como el
   mismo.
2. **UPCitemdb**, una base gratuita de productos comerciales (sin clave, unas 100 consultas por día): devuelve el nombre y
   la marca.
3. **PubChem**, con ese nombre: completa la **fórmula** y el **peso molecular**. PubChem no busca por código de barras, solo
   por nombre o por número CAS, por eso se consulta después de tener un nombre.
4. **Si nadie lo conoce**, el escáner dice "No encontramos este código" y **"Cargar a mano"** vuelve al Alta con solo el
   código escrito. No es un error: los reactivos de laboratorio suelen no estar en bases públicas.

- **Los datos externos son una sugerencia:** el nombre se puede corregir antes de **"Usar estos datos"**, que vuelve al Alta
  con todo completado. El Alta solo llena los campos que están vacíos, así que un escaneo nunca pisa lo que ya se escribió, y
  la marca, la fórmula y el peso molecular solo se completan en insumos comprados.
- **El sistema aprende solo:** cuando se da de alta el insumo con su código, la próxima vez que se escanee se encuentra en la
  capa 1. No hace falta una colección aparte ni reglas nuevas en Firestore.
- **Si internet falla** (sin conexión, límite de consultas diario agotado), la pantalla lo dice y se carga a mano: no es lo
  mismo que "el código no existe".
- **Qué sale a internet:** solo el código leído (a UPCitemdb) y el nombre del producto (a PubChem). Sin claves.
- **Se puede sumar otra fuente** (por ejemplo EAN-Search, que pide un token y su cuota gratis no está confirmada) agregando una
  capa en `BarcodeService`.
- **La cámara** usa `mobile_scanner` y solo lee códigos de barras de productos (EAN, UPC, Code 128, 39 y 93). Pide el permiso
  de cámara la primera vez; si se rechaza, la pantalla lo explica.
- **La calidad de los datos de UPCitemdb es variable.** Cubre productos comerciales, no reactivos de laboratorio, y a veces
  devuelve avisos de tiendas online o un producto que no tiene nada que ver: en una prueba a mano, el código EAN de una
  gaseosa devolvió "2 Packs Of 24 X 330ml Coke Cans" y un código inventado devolvió un producto cualquiera. Por eso el nombre
  sale editable, la hoja avisa "Datos de una base pública: revisalos antes de usarlos" y no se aplica nada hasta tocar
  "Usar estos datos". PubChem, en cambio, es confiable cuando reconoce el nombre (Ethanol da C2H6O y 46,07), pero un nombre
  comercial largo no lo reconoce y en ese caso queda solo el nombre.
- **Qué se probó y qué no:** las pruebas automáticas usan una cámara falsa y un servidor falso (así dan siempre lo mismo y no
  gastan las consultas diarias de UPCitemdb). Se comprobó una vez a mano contra las APIs reales que el formato de las
  respuestas coincide con lo que lee el servicio. Falta probar la lectura real con la cámara, que necesita un celular físico.

## Editar y dar de baja un insumo
Solo para el administrador (ver "Roles"). Desde el Detalle de un insumo:

- **Editar** (lápiz) abre el mismo formulario del Alta, con los datos del insumo cargados (`/insumo/editar/:id`). **No se edita
  el stock:** cambia solo con movimientos (consumos y entradas), para que el Historial siempre explique cada cambio; el formulario
  lo dice. Tampoco se cambia el **tipo** (comprado o solución), porque cambiaría qué campos tiene. Los datos que el formulario no
  muestra (origen, cantidad por envase, materia, alarma de vencimiento) se conservan tal cual.
- **Dar de baja** (tacho) pide confirmar y es una **baja lógica**: el insumo queda con `activo: false` y deja de aparecer en el
  inventario, las alertas, las compras, los trabajos prácticos y el buscador. **No se borra**, porque sus movimientos del
  Historial tienen que seguir mostrando de qué insumo eran (el Historial usa `insumosConBajasProvider`). Los insumos anteriores a
  este campo cuentan como activos. Para reactivar uno hay que poner `activo` en `true` desde la consola (todavía no hay botón).
- **Historial** abre la pantalla de movimientos ya filtrada por ese insumo (R13) y, al volver, limpia el filtro.

## Importar el inventario desde Excel
Solo para el administrador: **"Importar desde Excel"** en el menú lateral (R19, carga inicial). Se trabaja con una **plantilla de
formato fijo**, igual para todos:

1. **Descargar plantilla.** Es un Excel con la hoja **Insumos** (los títulos de las columnas), una hoja de **Instrucciones** y una
   de **Ubicaciones** con las que ya existen en la app, para copiar el texto tal cual.
2. **Completarla**, un insumo por fila.
3. **Elegir el archivo completado.** Antes de guardar se ve cuántos insumos se cargan, cuáles se saltan por repetidos, cuántas
   ubicaciones son nuevas y **qué filas tienen errores y por qué**. **Nada se guarda hasta confirmar.**

**Las columnas** (`PlantillaDeInsumos`; se reconocen en cualquier orden y con algunos títulos equivalentes, como "Lugar" o "Stock"):

| Columna | | Qué va |
|---|---|---|
| Nombre | obligatoria | El nombre del insumo |
| Ubicación | obligatoria | Dónde está guardado ("Laboratorio 404 - Armario 1 - Estante A") |
| Cantidad | obligatoria | Número entero; **0 si no hay** |
| Stock mínimo | | Desde cuánto se avisa que hay que reponer; si falta, **1** |
| Unidad, Categoría, Fórmula, Marca | | Texto. Si falta la categoría, la app la sugiere con sus reglas |
| Código interno | | El código del laboratorio (Al-01, S2…); no es el de barras |
| Peso molecular | | Número mayor a 0 |
| Otros nombres | | Separados por coma |
| Sedronar | | "Sí" si es una sustancia controlada; vacío o "No" si no |

**Cómo se valida.** Una fila con errores **no se carga**, pero no frena a las demás; la pantalla dice "Fila 7: falta la ubicación; la
cantidad "mucha" no es un número". Se corrige en el Excel y se vuelve a subir. Si el archivo **no es la plantilla** (no tiene
la columna Nombre) o le falta una columna obligatoria, lo dice y no carga nada.

**Qué no duplica.** Un insumo se salta si ya hay otro **activo** con el mismo nombre y la misma ubicación (sin mirar mayúsculas,
tildes ni espacios), o si aparece antes en el mismo archivo. Por eso, si algo falla a mitad, se puede volver a subir el mismo
archivo y se carga solo lo que falta. Las ubicaciones se escriben como ya están en la lista, y las que faltan se agregan.

Cada insumo con stock deja su **entrada en el Historial** ("Alta de insumo"), igual que al darlo de alta a mano. Se guarda por
tandas de hasta 200 insumos, con una barra de avance.

## Duplicados al dar de alta

Mientras se escribe el **nombre** de un insumo nuevo, aparecen debajo del campo hasta 3 insumos que ya existen con un nombre
parecido (sin mirar mayúsculas, tildes ni espacios; los que empiezan igual primero). Tocar uno abre su detalle. Si no hay
ninguno, dice que se va a agregar como nuevo. Con menos de 2 letras no sugiere nada, y mientras no se cargaron los insumos
no dice nada (afirmar que no hay ninguno sería engañoso). No frena la carga: es un aviso.

Antes de guardar un insumo nuevo, el formulario de Alta tiene además un botón **"Buscar duplicados"** (requerimiento A10). Usa lo que ya se escribió (nombre, tipo, marca y código de barras) y abre una ventana:

- **Comparación de texto** (siempre, instantánea y sin internet): encuentra insumos con el mismo código de barras o con un nombre muy parecido. Para eso usa `DuplicateDetectionService.buscarSimilares`.
- **Sinónimos con IA** (solo si hay clave, ver "Servicios externos"): mientras tanto muestra "Buscando sinónimos con IA…" y, cuando termina, suma los insumos que la IA cree que son el mismo producto con otro nombre ("etanol" y "alcohol etílico"), marcados como "Sugerido por la IA". Si la IA falla o no está configurada, la ventana lo dice y deja el resultado de la comparación de texto.
- Cada coincidencia trae **"Cargarle un consumo"**, que deja el alta y abre Consumo con ese insumo ya elegido (`/consumo?insumo=ID`). El botón **"Es distinto, seguir cargando"** vuelve al formulario sin perder lo escrito.

**Qué se le manda a la IA:** solo los nombres de los insumos (el existente y el que se está cargando), nunca stock, ubicaciones ni códigos de barras. El modelo propone y las reglas deciden: cada sugerencia se valida con las mismas reglas que la comparación de texto.

**Cuota:** cada vez que se toca el botón y hay clave se hace hasta una consulta por cada tipo de insumo (comprado y solución), y más si hay más de 250 de un tipo. No hay límite ni memoria de lo ya consultado.

**Proveedor de IA:** la app habla con la IA a través de la interfaz `ModeloDeLenguaje`. Se usa **Gemini** si hay clave (`GEMINI_API_KEY`); si además hay clave de Groq, Groq queda de **respaldo** y se usa solo cuando Gemini falla (por ejemplo, límite diario agotado). Con una sola clave se usa esa. Para sumar otro proveedor hay que escribir un cliente nuevo que implemente la interfaz y sumarlo en `elegirModeloDeLenguaje` (`sinonimos_provider.dart`). Los textos que ve la persona no nombran al proveedor.

## Categoría sugerida al dar de alta

Debajo del campo **Categoría** del Alta aparece **"Categoría sugerida: X"** con un botón **"Usar"** (requerimiento #25). Se
calcula con lo que ya se escribió, en este orden, y se queda con la primera que acierta (`CategorySuggestionService`):

1. **Insumos parecidos que ya existen:** si hay uno con el mismo nombre (o que lo contiene), se sugiere su categoría. Es la
   más confiable porque respeta cómo ya se cargó el inventario.
2. **Reglas por nombre:** palabras como "etanol", "guante", "agar" o "enzima" apuntan a una categoría (Alcoholes y
   solventes, Material descartable, Medios de cultivo, Enzimas, Buffers y soluciones, Ácidos y bases, Sales, Metales,
   Colorantes, Material de vidrio).
3. **Reglas por fórmula:** por ejemplo, una fórmula terminada en "COOH" es un ácido.
4. **IA (opcional):** si no hay sugerencia y hay clave de IA, aparece **"Sugerir categoría con IA"**. Solo se le manda el
   nombre, la fórmula y los nombres de las categorías que ya existen; elige una o propone una nueva (corta, en plural). Si
   coincide con una existente, se usa la escritura de la existente.

- **Es una sugerencia:** nunca se aplica sola. Si la categoría ya tiene texto, no se muestra nada.
- **Sin clave de IA** las capas 1 a 3 funcionan igual, sin internet.

## Validación del Alta

El formulario de Alta revisa los datos antes de guardar (`ValidacionesAlta`, con sus propias pruebas):

- **Cantidad inicial:** un número entero de 0 en adelante (el stock se cuenta en unidades enteras).
- **Stock mínimo:** un número de 0 en adelante; acepta **coma o punto** decimal ("0,5" y "0.5"), porque en el teclado del
  celular sale la coma.
- **Peso molecular** (opcional): si se escribe, tiene que ser un número mayor que 0; un texto ya no rompe el guardado, avisa
  en el campo.
- **Nombre y ubicación** son obligatorios (sin contar espacios).
- **Fechas:** el vencimiento no puede ser anterior a la elaboración.

## Leer la etiqueta con la cámara

El botón **"Leer etiqueta con la cámara"** del Alta (requerimiento #24) saca una foto a la etiqueta del frasco y completa el
formulario con lo que se entienda: **nombre, marca, fórmula, peso molecular y vencimiento**.

1. `image_picker` abre la cámara y devuelve la foto, reducida a 2000 px de ancho (una foto más grande no lee mejor).
2. `LectorMlKit` reconoce el texto con **ML Kit de Google**, que corre **en el teléfono**: la foto no sale del equipo y no
   hace falta internet.
3. `InterpreteDeEtiqueta` busca en el texto la fórmula química, el peso molecular ("PM 46,07 g/mol"), el vencimiento
   ("Venc: 11/2027", "Expira 30-11-2027"), el número CAS (validando su dígito verificador), la marca (cuando dice "Marca:",
   "Fabricante:" o similar) y el nombre.
4. Si la etiqueta trae un **número CAS** y falta la fórmula o el peso molecular, `OcrService` los consulta en **PubChem**
   (`BarcodeService.datosQuimicos`). Si PubChem no responde, queda lo que se leyó. Solo se manda el número CAS.

- **Todo queda editable y se avisa que se revise:** reconocer texto en una foto se equivoca (una "O" por un "0", por ejemplo).
- **Solo llena campos vacíos**, igual que el escáner: una lectura nunca pisa lo que la persona ya escribió. En una solución
  preparada solo se completa el nombre y el vencimiento (la marca, la fórmula y el peso molecular son de insumos comprados).
- **Fechas:** con "mm/aaaa" se toma el **último día del mes**. Solo se toma una fecha si está junto a una palabra de
  vencimiento (venc, expira, caduca, best before...), para no confundirla con la de elaboración o un lote.
- **Si algo falla** (sin permiso de cámara, foto sin texto, lector caído) la pantalla lo dice sin mostrar detalles técnicos.
- **Qué se probó y qué no:** las pruebas automáticas usan una cámara y un lector falsos con textos de etiqueta de ejemplo
  (el intérprete, el servicio y el formulario). **Falta probar la lectura real con un celular físico:** el emulador no tiene
  una cámara que enfoque una etiqueta, y la calidad de ML Kit depende de la luz y del enfoque.
- **Versiones de Flutter:** `google_mlkit_text_recognition` está fijado en la serie `^0.16.0` porque la 1.x pide Dart 3.12
  (Flutter 3.44 o más) y el proyecto admite Flutter 3.41.6. Al compilar con 3.41.6, Flutter puede reescribir `pubspec.lock`;
  esos cambios no hay que commitearlos.

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

- Las reglas de Firestore estan abiertas hasta el **31/01/2027** (issue #46): cualquiera que tenga los datos del proyecto
  puede leer y escribir. Mientras esten abiertas, no guardar claves ni tokens en Firestore. Ver "Reglas de Firestore".
- Antes de cada `git push`, verificar que no queden claves en el repositorio:

  ```
  git grep gsk_
  git grep AIza
  ```

  La primera busca claves de Groq y la segunda las de Gemini. En `lib/firebase_options.dart` aparece una clave que empieza con
  `AIza`: es la de Firebase, que genera la propia herramienta y se sube a proposito. No es una filtracion.

## Inicio de sesión
La app usa **Firebase Authentication** con mail y contraseña (`AuthService`, en `lib/services/auth_logic/`).

- **Sin sesión no se ve nada:** el router redirige a Bienvenida (`/welcome`) desde cualquier pantalla que no sea Bienvenida,
  Ingresar o Registrarse. Con sesión iniciada, esas tres pantallas redirigen a Inventario. El router se entera de los cambios de
  sesión con `GoRouterRefreshStream` (en `lib/core/`), por eso al ingresar o cerrar sesión va solo a donde corresponde.
- **Cerrar sesión** está al final del menú lateral.
- **Los errores se explican en español** con el motivo que devuelve Firebase (mail mal escrito, cuenta repetida, contraseña
  incorrecta, demasiados intentos) en un cartel rojo que sale de `AuthService`. Las comprobaciones previas (campos vacíos,
  mail institucional, contraseña segura) están en `ValidacionesAuth` y se prueban solas.
- **No se limita el largo del mail:** los institucionales (`usuario@comunidadort.edu.ar`) tienen más de 20 caracteres.
- **El rol de cada persona** sale de su documento en `usuarios/{uid}` (ver "Roles").

### Seguridad del acceso
- **Nombre y apellido:** el registro lo pide (obligatorio, con alguna letra, hasta 60 caracteres) y lo guarda como nombre de la
  cuenta de Firebase. Con ese nombre se ve a la persona en Usuarios, en el Historial y como docente de un trabajo práctico.
  Con Google se usa el de la cuenta de Google. Las cuentas creadas antes de este campo quedan con lo que va antes de la `@` del
  mail (un número, en los mails de alumnos) hasta que se pueda editar el nombre desde Perfil, que todavía no está hecho.
- **Mail institucional (R14):** para **registrarse** hace falta un mail de `@comunidadort.edu.ar` o `@ort.edu.ar` (el dominio
  tiene que ser exactamente uno de esos: `ana@miort.edu.ar` o `ana@alumnos.ort.edu.ar` no valen). Los dominios están en
  `ValidacionesAuth.dominiosInstitucionales`. **Ingresar** no exige el dominio, porque hay cuentas creadas antes de esta regla.
- **Contraseña segura:** al registrarse tiene que tener **al menos 8 caracteres, una mayúscula, una minúscula, un número y un
  símbolo**. La pantalla muestra la lista de requisitos y los va tildando mientras se escribe. Ingresar no la vuelve a exigir.
- **Verificar el mail:** al registrarse se manda un correo con un enlace, y hasta que se verifica el router solo deja ver la
  pantalla "Verificá tu mail" (con "Ya verifiqué", "Reenviar el correo" y "Usar otra cuenta"). **También le pasa a cualquier
  cuenta anterior que nunca verificó su mail:** al ingresar la pantalla le pide verificar. El rol y el documento
  `usuarios/{uid}` solo se crean para cuentas con el mail verificado.
- **Continuar con Google:** botón en el ingreso y en el registro. Abre la hoja de Google en el navegador (no hace falta tener
  la cuenta cargada en el celular) y usa `firebase_auth` (`signInWithProvider`), sin dependencias nuevas. Solo valen cuentas con
  mail institucional de ORT: si entra otra, la app cierra la sesión en el acto (y borra la cuenta si se acababa de crear), y esa
  sesión no llega a tener rol ni documento en `usuarios`. Con Google el mail ya viene verificado, así que no pasa por "Verificá
  tu mail". Si se cancela la hoja de Google no se muestra ningún error.
- **Olvidé mi contraseña:** el botón del ingreso manda un correo para elegir una contraseña nueva, con el mail que ya se
  escribió. El aviso es el mismo exista o no una cuenta con ese mail, para que nadie averigüe qué mails están registrados.

**Qué todavía hace cumplir solo la app, no el servidor:** el dominio del mail y las reglas de la contraseña se comprueban en el
celular, así que alguien que hable directo con Firebase se las salta. Para que también las haga cumplir el servidor:
1. En la consola de Firebase, Authentication > Configuración > **Política de contraseñas**: activar la exigencia con los mismos
   requisitos (8 caracteres, mayúscula, minúscula, número y símbolo).
2. Restringir el dominio del mail con una función de bloqueo (Authentication > Configuración > Funciones de bloqueo) o con las
   reglas de Firestore por rol (issue #46).

**Para que Google funcione en cada compu** hay que cargar la huella SHA-1 de **su** `debug.keystore` en la consola de Firebase
(Configuración del proyecto > Tus apps > la app Android > Agregar huella digital); si no, el botón falla en esa máquina. Se
obtiene con:

```powershell
& "<carpeta del JDK>\bin\keytool.exe" -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android | Select-String "SHA1|SHA256"
```

La app todavía no tiene firma de publicación propia: cuando se genere, hay que cargar también su huella y bajar de nuevo
`android/app/google-services.json`.

**Pendiente:** el **cierre de sesión por inactividad**, que figuraba entre las mitigaciones del plan de riesgos, y que el
servidor (y no solo la app) rechace las cuentas de Google que no son de ORT, con una función de bloqueo.
- Antes de mostrarla al profesor conviene crear una cuenta de prueba: el registro escribe en Firebase de verdad.

## Roles
Hay tres roles: **administrador**, **ayudante** y **docente**. Cada persona tiene un documento `usuarios/{uid}` con su
`nombre`, `email`, `rol`, `activo` y `puedeVerSedronar` (el `uid` es el de su cuenta de Firebase). `roleProvider` lee el rol
de ese documento (`RolDeSesionService`, en `lib/services/`) y la app decide con él qué se ve y qué se puede hacer.

- **Una cuenta nueva es docente**, el rol que menos puede hacer. **Nadie se vuelve administrador solo.**
- **El documento se crea al iniciar sesión**, no al registrarse: así también lo tienen las cuentas que existían antes de que
  hubiera documentos. Si ya existe no se toca (se crea dentro de una transacción), por eso volver a entrar nunca pisa un rol
  que alguien cambió. El nombre arranca con el de la cuenta de Firebase, o con lo que va antes de la `@` del mail.
- **Mientras se averigua el rol, si no hay sesión o si falla la lectura** (sin conexión, sin permiso) vale **docente**: es
  mejor mostrar de menos un instante que dejar ver o tocar lo que no corresponde.
- **El rol se actualiza solo:** si alguien lo cambia en Firestore mientras la persona usa la app, el menú y los botones se
  actualizan sin cerrar sesión. Una persona dada de baja (`activo: false`) vale docente.
- **Qué ve cada rol en el menú lateral:** el docente ve Inventario, Historial y Lista para trabajos prácticos; el ayudante
  suma Lista de compras; el administrador suma Usuarios.

**Qué puede hacer cada rol con los insumos** (`Permisos`, en `lib/core/permisos.dart`, es el único lugar donde se decide):

| | Administrador | Ayudante | Docente |
|---|---|---|---|
| Ver inventario, detalle e historial | sí | sí | sí |
| Registrar consumo (salida de stock) | sí | sí | no |
| Dar de alta un insumo (botón "+" y pantalla de Alta) | sí | no | no |
| Editar o dar de baja un insumo | sí | no | no |

Sale de los requerimientos: R15 (administrador, acceso total), R16 (ayudante, "ver y modificar stock") y R17 (docente, solo
lectura). Los requerimientos no dicen qué rol da de alta, edita o da de baja (R01 y R06); **se reservó al administrador por
interpretación**: el ayudante mueve el stock, pero no cambia el catálogo. Si el cliente decide otra cosa, se cambia solo en
`Permisos`. El docente puede además marcar insumos para un trabajo práctico (R17), eso se maneja en su propia pantalla.

Los botones de lo que no se puede hacer se esconden, y las pantallas de Alta, Escáner y Consumo se protegen además con
`SoloConPermiso`, que muestra "No tenés permiso para usar esta pantalla" si el rol no corresponde.

**Cómo hacer al primer administrador** (hay que hacerlo una vez, a mano):
1. Iniciar sesión en la app con esa cuenta, para que se cree su documento.
2. En la consola de Firebase: Firestore Database > Datos > colección `usuarios` > el documento de esa persona (el id es su
   `uid`, que figura en Authentication > Usuarios).
3. Cambiar el campo `rol` de `docente` a `administrador`. La app lo toma sola.

Con un administrador ya hecho, los demás roles se cambian desde la pantalla **Usuarios** (ver abajo), sin tocar la consola.

### Gestión de usuarios
Solo para administradores (el menú lateral la oculta a los demás y la pantalla además se protege sola). Lista a los usuarios
activos con su rol y permite **cambiar el rol** y **dar de baja**:

- **Reglas:** nadie se cambia el rol ni se da de baja a sí mismo, y no se puede dejar al sistema sin ningún administrador. La
  lista que se ve es la de usuarios activos; si todavía no cargó, ante la duda no se toca a un administrador.
- **La baja bloquea, no borra.** El documento queda con `activo: false` y la persona **ya no puede usar la app**: si estaba
  adentro se le cierra la sesión en el momento y se le avisa ("Tu cuenta fue dada de baja"), y si intenta volver a ingresar se le
  cierra de nuevo (`GuardiaDeCuenta`). No se borra nada porque el Historial guarda quién hizo cada movimiento y esos datos tienen
  que seguir existiendo. Para volver a darle acceso hay que poner `activo` en `true` desde la consola (todavía no hay botón).
- **Si no se puede saber** (sin conexión), no se bloquea a nadie: dejar sin acceso a todos por un corte de internet sería peor.
- **El id de la persona sigue a la sesión** (`usuarioActualIdProvider`): si alguien cierra sesión y entra otra persona sin cerrar la
  app, las alertas vistas y las protecciones de arriba pasan a ser las de la nueva persona.

**Qué todavía no protege:** esto decide lo que **muestra la app**, no lo que **permite la base**. Las reglas de Firestore
siguen abiertas hasta el 31/01/2027 (ver "Reglas de Firestore"), así que alguien que hable directo con la base podría cambiarse
el rol, o saltarse el bloqueo de una cuenta dada de baja. Las reglas por rol son el siguiente paso (issue #46) y recién ahí el
rol es una barrera de verdad.

## Reglas de Firestore
Las reglas de seguridad de la base estan en [`firestore.rules`](firestore.rules). **Guardar el archivo no las aplica:** hay que
publicarlas en la consola de Firebase (Firestore Database > Reglas) o con
`firebase deploy --only firestore:rules --project proyecto-final-ort-d54c1` (`firebase.json` ya apunta al archivo).

- **Hoy:** `allow read, write: if request.time < timestamp.date(2027, 1, 31)`. Es el "modo de prueba" de Firebase: abierto a
  cualquiera hasta esa fecha.
- **Se vencen.** El modo de prueba original (21/10/2026) duraba 30 dias. Cuando vencio, **toda la app dejo de leer y escribir a
  la vez** (Inventario quedaba cargando para siempre y el error era `permission-denied`), sin importar la rama. Se renovo el
  23/11/2026 hasta el 31/01/2027. **Hay que renovarlas o cambiarlas antes de esa fecha.**
- **Si algo "no carga" de golpe en todas las pantallas,** mirar primero esta fecha antes de buscar un error en el codigo.
- **Proximo paso:** cuando el login este conectado, pedir sesion iniciada (`request.auth != null`); mas adelante, reglas por
  rol leyendo `usuarios/{uid}` (para eso el registro tiene que crear ese documento).
- Las colecciones que usa la app son `insumos`, `movimientosStock`, `listaCompras`, `listasTP`, `usuarios` y `alertasVistas`;
  las que todavia no existen en la consola se crean solas la primera vez que se escribe en ellas.

## Flujo de trabajo
- Ramas: `main` (entregable), `dev` (integración) y `feat/<nombre>` por cada funcionalidad.
- Cada funcionalidad se desarrolla en su rama y entra a `dev` por Pull Request. De `dev` a `main` se pasa cuando el conjunto está estable.
- El trabajo se organiza con Issues y Milestones por funcionalidad (Historial, Alertas y Compras, etc.), con las etiquetas `modelo`, `servicio`, `pantalla` e `infra`.
- Cada Pull Request enlaza su issue con `Part of #N`.

## Uso de IA
Parte del desarrollo (las pantallas de Historial, Lista de compras y Alertas, sus modelos, servicios y pruebas,
y los componentes compartidos) se hizo con Claude (Anthropic) como asistente. Lo que propuso se revisó, se compiló y se probó en el emulador antes
de subirlo.

- **IA dentro de la app:** la app usa un modelo de lenguaje (Gemini, con Groq de respaldo) para dos cosas, siempre como
  **sugerencia** que la persona acepta o descarta: detectar insumos duplicados con otro nombre ("Duplicados al dar de alta") y
  sugerir la categoría de un insumo nuevo ("Categoría sugerida al dar de alta"). Solo reciben nombres y fórmulas, nunca
  stock, ubicaciones ni datos de personas, y sin clave de IA la app sigue andando con comparación de texto y reglas. La
  **lectura de etiquetas con la cámara** usa ML Kit, que corre en el teléfono y no manda la foto a ningún servidor.
- **Por pasos chicos:** antes de escribir, se acordaba qué archivos cambiaban y en cuántos commits.
- **Verificación:** después de cada paso se corría `flutter analyze` y se probaba la app en el emulador.
- **Git lo manejamos nosotros:** ramas, commits, pushes y Pull Requests los hizo una persona del equipo.
- **Qué no hizo la IA:** no tomó decisiones de alcance o diseño sin consultar, ni tocó el trabajo de otros integrantes.
