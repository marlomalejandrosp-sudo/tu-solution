# Tu Solution

Aplicación Android (Flutter) para llevar el control de un taller de reparación de equipos electrónicos: recepción de equipos, órdenes de reparación, técnicos responsables, trabajos, repuestos e inventario.

Parcial 2 de Dispositivos Móviles · Marlom Sánchez · Ingeniería Informática, 3.er año.

- Funciona **sin conexión** y guarda todo en el teléfono (SQLite con Drift).
- Sin autenticación: la usan únicamente los técnicos del taller.
- Datos de ejemplo cargados la primera vez que se abre (3 técnicos, clientes, equipos, órdenes e inventario).

## Tecnologías

| Pieza | Paquete |
|---|---|
| Base de datos local | `drift` + `drift_flutter` (SQLite) |
| Estado | `flutter_riverpod` |
| Navegación | `go_router` |
| Interfaz | Material 3, tipografía Poppins, tema claro y oscuro |

## Arquitectura (MVVM + Riverpod)

```
lib/
├─ data/          Modelo: tablas Drift, base de datos y TallerRepository
├─ models/        Modelo: enums y "vistas" (OrdenVista, CargaTecnico...)
├─ providers/     Riverpod: streams de la base y datos derivados
├─ viewmodels/    ViewModel: TallerViewModel (acciones) y Notifiers de filtros/tema
├─ views/         Vista: una carpeta por pantalla (solo dibujan y llaman al ViewModel)
├─ widgets/       Componentes y formularios reutilizables
├─ router/        Rutas con go_router
├─ core/          Formato, validadores, avisos, colores de estado
└─ theme/         Tema Material 3
```

Flujo de datos: **Drift → TallerRepository → StreamProvider → pantalla**. Las pantallas observan los providers con `ref.watch`; cuando cambia la base de datos, Drift emite de nuevo y la interfaz se actualiza sola. Las acciones (tomar una orden, usar un repuesto...) van en sentido contrario: **pantalla → TallerViewModel → TallerRepository → Drift**.

## Modelo de datos

`Clientes` 1─N `Equipos` 1─N `Ordenes` ─ `Tecnicos` (responsable, opcional)
`Ordenes` 1─N `Trabajos` (mano de obra) · `Ordenes` N─M `Repuestos` mediante `RepuestosUsados` (cantidad y precio al momento del uso).

## Reglas del taller

- Un mismo **equipo** puede volver muchas veces (cada visita es una orden nueva) y un mismo **cliente** puede tener varios equipos.
- Estados de la orden: *Recibida → En reparación → Lista → Entregada*, o *Cancelada*.
- **Un técnico "toma" la orden**: queda como responsable y pasa a *En reparación*. La comprobación se hace dentro de una transacción, así que si dos técnicos intentan tomar la misma orden, el segundo recibe el aviso "Esta orden ya la tomó …". Se puede **liberar** para que la tome otro.
- Solo una orden *En reparación* admite trabajos y repuestos.
- Un equipo no puede tener dos órdenes abiertas a la vez.
- Al usar un repuesto, las **existencias bajan** en la misma transacción; si no alcanzan, no se guarda nada. Al quitarlo o cancelar la orden, vuelven al inventario.
- **Alerta de existencias bajas**: un repuesto con existencias ≤ su mínimo aparece como "por agotarse".
- **Total** = mano de obra + repuestos (dinero en pesos enteros).
- No se puede marcar *Lista* una orden sin al menos un trabajo.

## Qué muestra la app

- **Inicio**: órdenes abiertas, órdenes sin responsable, listas para entregar, repuestos por agotarse, carga de trabajo por técnico.
- **Órdenes**: filtro por estado, por técnico y búsqueda; cada tarjeta muestra el estado y quién la tiene.
- **Detalle de orden**: responsable, falla, trabajos, repuestos, total y acciones según el estado.
- **Equipos / Clientes**: fichas con el **historial** de órdenes de cada equipo y de cada cliente.
- **Inventario**: filtro por todos / por agotarse / agotados, reposición y alerta.

## Cómo ejecutarlo

Requisitos: Flutter 3.x instalado y un teléfono Android con depuración USB (o un emulador).

```powershell
git clone https://github.com/marlomalejandrosp-sudo/tu-solution.git
cd tu-solution
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

El paso de `build_runner` genera `app_database.g.dart` (código de Drift); sin él el proyecto no compila.

> La tipografía Poppins está en `assets/fonts/` y declarada en `pubspec.yaml`.

## Capturas

Están en la carpeta [`capturas/`](capturas):

1. `01_inicio.png` – panel del taller
2. `02_ordenes.png` – lista de órdenes con filtros
3. `03_detalle_orden.png` – orden en reparación con trabajos y repuestos
4. `04_nueva_orden.png` – recepción de un equipo
5. `05_tomar_orden.png` – elección del técnico responsable
6. `06_equipo_historial.png` – historial de un equipo
7. `07_cliente.png` – cliente con sus equipos y órdenes
8. `08_inventario.png` – inventario con alertas
9. `09_tema_oscuro.png` – tema oscuro

## Decisiones de diseño

- **El dinero son enteros** (pesos), así no hay errores de redondeo.
- **El precio del repuesto se copia a la orden** (`precioUnitario`): si el precio del inventario cambia después, las órdenes viejas conservan su total.
- **Las reglas viven en el repositorio, dentro de transacciones**, no en la pantalla: así no dependen de lo que la interfaz crea que sabe (por ejemplo, de una lista que quedó desactualizada).
- **Las pantallas de detalle usan su propio stream por id** (`family`), de modo que siempre muestran el dato actual.
- **Los colores salen solo del `ColorScheme`**, por eso el tema oscuro funciona sin tocar las pantallas.
