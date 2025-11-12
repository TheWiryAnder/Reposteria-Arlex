# Sistema de Gestión de Información del Negocio

Este módulo permite gestionar toda la información de la repostería Arlex directamente desde Firebase.

## Estructura

```
informacion_negocio/
├── controladores/
│   └── informacion_controlador.dart    # Gestión de estado con Provider
├── servicios/
│   └── informacion_servicio.dart       # Conexión con Firebase
├── vistas/
│   ├── editar_informacion_vista.dart   # Vista principal de edición
│   └── sobre_nosotros_vista.dart       # Vista pública (existente)
└── componentes/
    └── informacion/                    # Componentes reutilizables
```

## Modelo de Datos

El modelo `InformacionNegocio` incluye:

### 1. Configuración del Negocio
- `aceptaPedidosOnline`: bool
- `aceptaReservas`: bool
- `costoEnvio`: double
- `iva`: double
- `montoMinimoEnvio`: int
- `radiusEntregaKm`: int
- `tiempoPreparacionMinimo`: int (en horas)

### 2. Galería e Información
- `nombre`: Nombre del negocio
- `historia`: Historia del negocio
- `mision`: Misión empresarial
- `vision`: Visión empresarial
- `valores`: Lista de valores (Calidad, Compromiso, etc.)
- `logo`: URL del logo principal
- `logoSecundario`: URL del logo secundario

### 3. Horarios de Atención
- `domingo`: Horario domingo
- `lunesViernes`: Horario lunes a viernes
- `sabado`: Horario sábado

### 4. Redes Sociales
- `facebook`: URL de Facebook
- `instagram`: URL de Instagram
- `tiktok`: URL de TikTok
- `twitter`: URL de Twitter
- `youtube`: URL de YouTube
- `slogan`: Slogan del negocio
- `telefono`: Teléfono de contacto

### 5. Contacto
- `direccion`: Dirección física
- `email`: Email de contacto
- `whatsapp`: Número de WhatsApp

## Uso

### 1. Configurar el Provider

En tu archivo `main.dart`, agrega el provider:

```dart
import 'package:provider/provider.dart';
import 'package:reposteria_arlex/features/informacion_negocio/controladores/informacion_controlador.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InformacionControlador()..cargarInformacion(),
        ),
        // ... otros providers
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Usar la Vista de Edición

Navega a la vista de edición:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EditarInformacionVista(),
  ),
);
```

### 3. Leer Información en tu App

```dart
// En cualquier widget que necesite acceso a la información:
import 'package:provider/provider.dart';

class MiWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<InformacionControlador>();

    if (controlador.isLoading) {
      return CircularProgressIndicator();
    }

    final info = controlador.informacion;

    return Text(info?.galeria.nombre ?? 'Cargando...');
  }
}
```

### 4. Escuchar Cambios en Tiempo Real

```dart
StreamBuilder<InformacionNegocio?>(
  stream: InformacionControlador().streamInformacion(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final info = snapshot.data!;
      return Text(info.galeria.nombre);
    }
    return CircularProgressIndicator();
  },
)
```

### 5. Actualizar Información Específica

```dart
final controlador = context.read<InformacionControlador>();

// Actualizar solo las redes sociales
await controlador.actualizarRedesSociales(
  RedesSociales(
    facebook: 'https://facebook.com/...',
    instagram: 'https://instagram.com/...',
    // ... otros campos
  ),
);

// Toggle pedidos online
await controlador.togglePedidosOnline(true);

// Actualizar horarios
await controlador.actualizarHorarios(
  HorarioAtencion(
    domingo: 'Cerrado',
    lunesViernes: '8:00 AM - 6:00 PM',
    sabado: '9:00 AM - 5:00 PM',
  ),
);
```

## Estructura de Firebase

```
informacion_negocio/
  └── config/
      ├── configuracion: {
      │   ├── aceptaPedidosOnline: true
      │   ├── aceptaReservas: true
      │   ├── costoEnvio: 5
      │   ├── iva: 0
      │   ├── montoMinimoEnvio: 20
      │   ├── radiusEntregaKm: 10
      │   └── tiempoPreparacionMinimo: 24
      │ }
      ├── direccion: "Calle 123 #45-67..."
      ├── email: "contacto@..."
      ├── fechaActualizacion: Timestamp
      ├── galeria: {
      │   ├── historia: "..."
      │   ├── horarioAtencion: {
      │   │   ├── domingo: "Cerrado"
      │   │   ├── lunes_viernes: "8:00 AM - 6:00 PM"
      │   │   └── sabado: "9:00 AM - 5:00 PM"
      │   │ }
      │   ├── logo: "URL..."
      │   ├── logoSecundario: "URL..."
      │   ├── mision: "..."
      │   ├── nombre: "Repostería Arlex"
      │   ├── valores: ["Calidad", "Compromiso", ...]
      │   └── vision: "..."
      │ }
      ├── redesSociales: {
      │   ├── facebook: "URL..."
      │   ├── instagram: "URL..."
      │   ├── slogan: "..."
      │   ├── telefono: "+51..."
      │   ├── tiktok: "URL..."
      │   ├── twitter: "URL..."
      │   └── youtube: "URL..."
      │ }
      └── whatsapp: "+51..."
```

## Funciones Disponibles

### InformacionServicio

- `obtenerInformacion()`: Obtiene la información actual
- `streamInformacion()`: Stream en tiempo real
- `actualizarInformacion()`: Actualiza toda la información
- `actualizarConfiguracion()`: Actualiza solo configuración
- `actualizarGaleria()`: Actualiza solo galería
- `actualizarRedesSociales()`: Actualiza solo redes sociales
- `actualizarContacto()`: Actualiza datos de contacto
- `actualizarHorarios()`: Actualiza horarios de atención
- `actualizarValores()`: Actualiza valores de la empresa
- `togglePedidosOnline()`: Activa/desactiva pedidos online
- `toggleReservas()`: Activa/desactiva reservas

### InformacionControlador

Todas las funciones del servicio están disponibles a través del controlador, con gestión de estado automática.

## Características

- ✅ Formularios completos con validación
- ✅ Tabs organizados por categoría
- ✅ Actualización en tiempo real con Firebase
- ✅ Gestión de estado con Provider
- ✅ Manejo de errores
- ✅ Indicadores de carga
- ✅ Modelo de datos fuertemente tipado
- ✅ Funciones específicas para cada tipo de actualización

## Notas

- Todas las actualizaciones incluyen automáticamente `fechaActualizacion`
- Los cambios se sincronizan inmediatamente con Firebase
- El controlador mantiene una copia local para acceso rápido
- Los valores por defecto están definidos en el servicio
