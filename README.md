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
| Flutter | **3.47.x estable** (trae Dart 3.13). Es la versión con la que está generado el `pubspec.lock`. El proyecto exige como mínimo Dart `^3.11.4` |
| JDK | **17 o 21**. El JDK 25 que trae la última versión de Android Studio no funciona con el Gradle del proyecto |
| Android Studio | Última versión estable, con el Android SDK y las **Android SDK Command-line Tools** (SDK Manager, pestaña SDK Tools) |
| Dispositivo de prueba | Emulador de Android (probado en Pixel 7 con Android 16, API 36) o un teléfono con depuración USB |
| Windows | **Modo de desarrollador** activado (Configuración, Para programadores) |
| Git | Cualquier versión reciente |

La app está configurada para **Android**. No corre en el navegador ni en escritorio.

### 1. Instalar Flutter
1. Seguir la guía oficial: https://docs.flutter.dev/install
2. Verificar con `flutter --version` que sea la 3.47.x, y revisar el resto con `flutter doctor`.

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

### Problemas conocidos
| Síntoma | Causa y solución |
|---|---|
| `Module was compiled with an incompatible version of Kotlin` en la tarea `:firebase_auth:compileDebugKotlin` | **Pendiente de arreglar en el proyecto.** `firebase_auth` ya no compila con el Kotlin 2.2.20 de `android/settings.gradle.kts`. Se reprodujo en una copia limpia de `dev` con Flutter 3.47. Una solución probada con Flutter 3.41.6: subir el plugin `org.jetbrains.kotlin.android` a 2.3.21 y, en `android/app/build.gradle.kts`, reemplazar `kotlinOptions { jvmTarget = ... }` por `kotlin { compilerOptions { jvmTarget.set(JvmTarget.JVM_17) } }` |
| Error de Gradle que solo muestra un número de versión, como `25.0.2` | Gradle está usando el JDK 25. Usar un JDK 17 o 21 (paso 2) |
| `Building with plugins requires symlink support` | Falta activar el Modo de desarrollador de Windows y abrir una terminal nueva |
| La app abre pero queda en blanco o en el logo de Flutter, con `channel-error` de Firebase en el log | No se registraron los plugins. Correr `flutter clean`, `flutter pub get` y volver a compilar |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` al instalar | El emulador se quedó sin espacio. Desinstalar la app, compilar solo para x86_64 (`--target-platform android-x64`) o usar **Wipe Data** en el Device Manager |
| `this and base files have different roots` al compilar Kotlin (Windows) | El proyecto y la caché de paquetes de Flutter están en discos distintos. Agregar `--android-project-arg="kotlin.incremental=false"` al compilar, o poner el proyecto en el mismo disco que `%LOCALAPPDATA%\Pub\Cache` |
| `flutter doctor` dice "Android license status unknown" | Probar `flutter doctor --android-licenses`. Si el emulador y la compilación andan, se puede ignorar |

### Versiones
| Componente | Versión |
|---|---|
| Flutter | 3.47.x |
| Dart | 3.13 (mínimo `^3.11.4`) |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 (ver problema conocido de `firebase_auth`) |
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
| `widgets/` | Componentes reutilizables: fondo decorativo, encabezado de pantalla, tarjeta con contorno, botón de acción, fila de Compartir y Descargar, selector de cantidad, tarjeta de insumo, y los botones y campos de las pantallas de acceso |
| `screens/<área>/` | Pantallas de cada flujo: `auth`, `inventario`, `consumo`, `historial`, `alertas`, `compras`, `tp`, `usuarios`, `perfil` |
| `providers/` | Estado de la app con Riverpod |
| `models/` | Modelos de dominio: `Insumo` y `TrabajoPractico` |
| `services/` | Acceso a Firestore: `InsumoService` (colección `insumos`) y `TpService` (colección `listasTP`) |

## Navegación
- La app arranca en **Inventario**. El login queda para el final.
- **Dentro del `AppShell`** (barra inferior y menú lateral, que muestra opciones según el rol): Inventario, Insumos, Consumo, Alertas, Trabajos prácticos, Usuarios y Perfil.
- **Fuera del `AppShell`**, a pantalla completa: Welcome, Login, Register, **Historial** y **Lista de compras**.

### Decisiones de navegación
- **Historial y Lista de compras** van fuera del `AppShell` porque en el diseño no llevan la barra inferior del shell. Lista de compras tiene además su propio botón flotante circular. La flecha de volver regresa a la pantalla anterior o, si no hay, a Inventario.
- **Alertas** tendrá que ajustar su lugar cuando se construya: el diseño lleva barra inferior pero no el botón flotante del shell.

## Seguimiento de pantallas
⏳ Placeholder: la ruta existe y la pantalla todavía no está hecha · 🚧 En construcción: interfaz armada, sin datos reales de Firebase · 🎭 Demostración: funciona con datos de ejemplo · 🔍 En revisión: hecha en una rama, todavía sin mergear a `dev` · ✅ Funcional: con datos reales de Firebase

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
| Detalle de insumo | `/insumo` | ⏳ Placeholder |
| Alta de insumo | `/insumo/alta` | ⏳ Placeholder |
| Escáner | `/scanner` | ⏳ Placeholder |
| Consumo | `/consumo` | ⏳ Placeholder |

### Historial, alertas y compras
| Pantalla | Ruta | Estado |
|---|---|---|
| Historial de movimientos | `/historial` | 🎭 Demostración (6 movimientos de ejemplo; filtros, Compartir y Descargar todavía sin acción) |
| Alertas | `/alertas` | ⏳ Placeholder |
| Lista de compras | `/compras` | 🔍 En revisión (`feat/compras`: 4 ítems de ejemplo con cantidad editable, cantidad mínima 1; sugerencias, buscar, papelera, agregar, Compartir y Descargar sin acción) |

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

## Flujo de trabajo
- Ramas: `main` (entregable), `dev` (integración) y `feat/<nombre>` por cada funcionalidad.
- Cada funcionalidad se desarrolla en su rama y entra a `dev` por Pull Request. De `dev` a `main` se pasa cuando el conjunto está estable.
- El trabajo se organiza con Issues y Milestones por funcionalidad (Historial, Alertas y Compras, etc.), con las etiquetas `modelo`, `servicio`, `pantalla` e `infra`.
- Cada Pull Request enlaza su issue con `Part of #N`.

## Uso de IA
Parte del desarrollo (las pantallas de Historial y Lista de compras y sus componentes compartidos) se hizo
con Claude (Anthropic) como asistente. Lo que propuso se revisó, se compiló y se probó en el emulador antes
de subirlo.

- **Por pasos chicos:** antes de escribir, se acordaba qué archivos cambiaban y en cuántos commits.
- **Verificación:** después de cada paso se corría `flutter analyze` y se probaba la app en el emulador.
- **Git lo manejamos nosotros:** ramas, commits, pushes y Pull Requests los hizo una persona del equipo.
- **Qué no hizo la IA:** no tomó decisiones de alcance o diseño sin consultar, ni tocó el trabajo de otros integrantes.
