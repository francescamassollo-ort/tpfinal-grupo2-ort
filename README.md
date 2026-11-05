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
| Flutter | 3.41.x estable (trae Dart 3.11.4; el proyecto exige Dart `^3.11.4`) |
| JDK | **17 o 21**. El JDK 25 que trae la última versión de Android Studio no funciona con el Gradle del proyecto |
| Android Studio | Última versión estable, con el Android SDK y las **Android SDK Command-line Tools** (SDK Manager, pestaña SDK Tools) |
| Dispositivo de prueba | Emulador de Android (probado en Pixel 7 con Android 16, API 36) o un teléfono con depuración USB |
| Windows | **Modo de desarrollador** activado (Configuración, Para programadores) |
| Git | Cualquier versión reciente |

La app está configurada para **Android**. No corre en el navegador ni en escritorio.

### 1. Instalar Flutter
1. Seguir la guía oficial: https://docs.flutter.dev/install
2. Verificar con `flutter --version` que sea la 3.41.x, y revisar el resto con `flutter doctor`.

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
La app arranca en **Inventario**: el login queda para el final, por eso todavía no pide credenciales.

Firebase ya viene configurado en el repositorio (`android/app/google-services.json` y
`lib/firebase_options.dart`), no hace falta crear nada.

### Problemas conocidos
| Síntoma | Causa y solución |
|---|---|
| Error de Gradle que solo muestra un número de versión, como `25.0.2` | Gradle está usando el JDK 25. Usar un JDK 17 o 21 (paso 2) |
| `Building with plugins requires symlink support` | Falta activar el Modo de desarrollador de Windows y abrir una terminal nueva |
| La app abre pero queda en blanco o en el logo de Flutter, con `channel-error` de Firebase en el log | No se registraron los plugins. Correr `flutter clean`, `flutter pub get` y volver a compilar |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` al instalar | El emulador se quedó sin espacio. Desinstalar la app o usar **Wipe Data** en el Device Manager |
| `flutter doctor` dice "Android license status unknown" | Probar `flutter doctor --android-licenses`. Si el emulador y la compilación andan, se puede ignorar |

### Versiones
| Componente | Versión |
|---|---|
| Flutter | 3.41.x |
| Dart | 3.11.4 |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Plugin Google Services | 4.3.15 |
| Java (compilación) | 17 |
| firebase_core | ^5.0.0 |
| cloud_firestore | ^7.0.0 |
| flutter_riverpod | ^3.3.2 |
| go_router | ^17.5.0 |
| google_fonts | ^8.2.1 |

## Estructura del proyecto
Todo el código está en `lib/`.

| Carpeta | Contenido |
|---|---|
| `core/` | Tema, colores, textos (`AppStrings`), estilos de texto, rutas (`app_router.dart`) y el `AppShell` con la barra inferior y el menú lateral |
| `widgets/` | Componentes reutilizables: fondo decorativo, encabezado de pantalla, tarjeta con contorno, botón de acción, fila de Compartir y Descargar |
| `screens/<área>/` | Pantallas de cada flujo: `auth`, `inventario`, `consumo`, `historial`, `alertas`, `compras`, `tp`, `usuarios`, `perfil` |
| `providers/` | Estado de la app con Riverpod (por ahora el rol del usuario y el historial) |
| `models/` | Modelos de dominio (en construcción) |
| `services/` | Acceso a Firebase (en construcción) |

## Navegación
- La app arranca en **Inventario**. El login queda para el final.
- **Dentro del `AppShell`** (barra inferior y menú lateral, que muestra opciones según el rol): Inventario, Insumos, Consumo, Alertas, Lista de compras, Trabajos prácticos, Usuarios y Perfil.
- **Fuera del `AppShell`**, a pantalla completa: Welcome, Login, Register y **Historial**.

### Decisiones de navegación
- **Historial** va fuera del `AppShell` porque en el diseño no lleva barra inferior ni botón flotante. La flecha de volver regresa a la pantalla anterior o, si no hay, a Inventario.
- Lista de compras y Alertas tendrán que ajustar su lugar en el `AppShell` cuando se construyan, porque el diseño de cada una cambia qué barra y qué botón flotante muestran.

## Seguimiento de pantallas
🚧 Provisoria: la ruta existe y la pantalla está en construcción · 🎭 Demostración: funciona con datos de ejemplo · ✅ Funcional: con datos reales de Firebase · ⏳ Pendiente: sin ruta todavía

### Acceso
| Pantalla | Ruta | Estado |
|---|---|---|
| Bienvenida | `/welcome` | 🚧 Provisoria |
| Iniciar sesión | `/login` | 🚧 Provisoria |
| Registro | `/register` | 🚧 Provisoria |

### Inventario
| Pantalla | Ruta | Estado |
|---|---|---|
| Inventario | `/inventario` | 🚧 Provisoria |
| Buscar y filtrar | `/inventario/filtro` | 🚧 Provisoria |
| Detalle de insumo | `/insumo` | 🚧 Provisoria |
| Alta de insumo | `/insumo/alta` | 🚧 Provisoria |
| Escáner | `/scanner` | 🚧 Provisoria |
| Consumo | `/consumo` | 🚧 Provisoria |

### Historial, alertas y compras
| Pantalla | Ruta | Estado |
|---|---|---|
| Historial de movimientos | `/historial` | 🎭 Demostración (6 movimientos de ejemplo; filtros, Compartir y Descargar todavía sin acción) |
| Alertas | `/alertas` | 🚧 Provisoria |
| Lista de compras | `/compras` | 🚧 Provisoria |

### Trabajos prácticos
| Pantalla | Ruta | Estado |
|---|---|---|
| Lista de trabajos prácticos | `/tp` | 🚧 Provisoria |
| Detalle de trabajo práctico | `/tp/detalle` | 🚧 Provisoria |
| Nuevo trabajo práctico | `/tp/nuevo` | 🚧 Provisoria |

### Administración
| Pantalla | Ruta | Estado |
|---|---|---|
| Usuarios | `/usuarios` | 🚧 Provisoria |
| Perfil | `/perfil` | 🚧 Provisoria |

## Flujo de trabajo
- Ramas: `main` (entregable), `dev` (integración) y `feat/<nombre>` por cada funcionalidad.
- Cada funcionalidad se desarrolla en su rama y entra a `dev` por Pull Request. De `dev` a `main` se pasa cuando el conjunto está estable.
- El trabajo se organiza con Issues y Milestones por funcionalidad (Historial, Alertas y Compras, etc.), con las etiquetas `modelo`, `servicio`, `pantalla` e `infra`.
- Cada Pull Request enlaza su issue con `Part of #N`.

## Uso de IA
Parte del desarrollo (la pantalla de Historial y los componentes compartidos) se hizo con Claude
(Anthropic) como asistente. Lo que propuso se revisó, se compiló y se probó en el emulador antes de
subirlo.

- **Por pasos chicos:** antes de escribir, se acordaba qué archivos cambiaban y en cuántos commits.
- **Verificación:** después de cada paso se corría `flutter analyze` y se probaba la app en el emulador.
- **Git lo manejamos nosotros:** ramas, commits, pushes y Pull Requests los hizo una persona del equipo.
- **Qué no hizo la IA:** no tomó decisiones de alcance o diseño sin consultar, ni tocó el trabajo de otros integrantes.
