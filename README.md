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
| `models/` | Modelos de dominio: `Insumo`, `TrabajoPractico`, `ListaCompra`, `Alerta`, `MovimientoStock` y los de la predicción de stock (`PrediccionStock` y `VentanaPrediccion`) |
| `services/` | Acceso a Firestore: `InsumoService` (colección `insumos`), `TpService` (colección `listasTP`), `ListaCompraService` (colección `listaCompras`) y `HistorialService` (colección `movimientosStock`, solo lectura: los movimientos los escribe quien cambia el stock). `AlertaService` y `StockPredictionService` no usan Firestore: generan las alertas y las predicciones de stock a partir de los insumos, los movimientos y los trabajos prácticos. `ListaCompraExportador` arma el PDF y el CSV de la lista de compras y `ArchivoService` los comparte o los guarda en el teléfono |

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
| Alta de insumo | `/insumo/alta` | ⏳ Placeholder |
| Escáner | `/scanner` | ⏳ Placeholder |
| Consumo | `/consumo` | ⏳ Placeholder |

### Historial, alertas y compras
| Pantalla | Ruta | Estado |
|---|---|---|
| Historial de movimientos | `/historial` | ✅ Funcional (lee la colección `movimientosStock` de Firestore en tiempo real, los últimos 500, y muestra el nombre del insumo; aparece vacío hasta que Alta y Consumo registren movimientos; filtros, Compartir y Descargar todavía sin acción) |
| Alertas | `/alertas` | ✅ Funcional (alertas calculadas desde los insumos: sin stock, stock bajo, vencido y vencimiento cercano; tocar una alerta abre el detalle del insumo; el filtro y marcar como vista todavía sin acción) |
| Lista de compras | `/compras` | ✅ Funcional (colección `listaCompras` de Firestore: cantidad editable con mínimo 1 y sugerencias del sistema para los insumos con stock bajo; buscar, papelera, agregar a mano, Compartir y Descargar todavía sin acción) |

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
Estima cuándo se agota cada insumo antes de la próxima compra institucional (requerimiento A02). Hoy es lógica
sin pantalla: `StockPredictionService` y `prediccionStockProvider` ya están, falta mostrarlas (por ejemplo en Alertas
o en las sugerencias de Lista de compras, que necesita una decisión de diseño).

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
- Mientras Alta y Consumo no registren movimientos, la predicción da una lista vacía y el autoajuste usa 30 días.

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
