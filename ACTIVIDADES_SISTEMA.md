# Sistema de Actividades - Guía de Implementación

## Descripción
El sistema de actividades registra eventos importantes del sistema para que los administradores puedan ver qué acciones realizan los usuarios.

## Servicio: ActividadesService

### Ubicación
`lib/servicios/actividades_service.dart`

### Método Principal
```dart
Future<void> registrarActividad({
  required String tipo,
  required String descripcion,
  required String usuarioId,
  String? usuarioNombre,
  Map<String, dynamic>? detalles,
})
```

## Tipos de Actividades

### 1. Pedido Realizado
```dart
await actividadesService.registrarActividad(
  tipo: 'pedido',
  descripcion: 'Realizó un pedido de \$${total.toStringAsFixed(2)}',
  usuarioId: userId,
  usuarioNombre: userName,
  detalles: {
    'pedidoId': pedidoId,
    'total': total,
    'cantidadProductos': cantidadProductos,
  },
);
```

**Dónde agregarlo:**
- `lib/pantallas/principal/cart_screen.dart` - Después de crear un pedido exitoso

### 2. Nuevo Registro de Usuario
```dart
await actividadesService.registrarActividad(
  tipo: 'registro',
  descripcion: 'Nuevo usuario registrado',
  usuarioId: userId,
  usuarioNombre: '${nombres} ${apellidos}',
  detalles: {
    'email': email,
    'rol': rol,
  },
);
```

**Dónde agregarlo:**
- `lib/pantallas/auth/registro_vista.dart` - Después del registro exitoso

### 3. Cambio de Credenciales
```dart
await actividadesService.registrarActividad(
  tipo: 'credenciales',
  descripcion: 'Cambió su contraseña',
  usuarioId: userId,
  usuarioNombre: userName,
);
```

**Dónde agregarlo:**
- `lib/pantallas/principal/profile_screen.dart` - Al cambiar contraseña
- Al actualizar email (si existe esa funcionalidad)

### 4. Notificación Enviada (por el usuario)
```dart
await actividadesService.registrarActividad(
  tipo: 'notificacion',
  descripcion: 'Envió una notificación: "${tituloNotificacion}"',
  usuarioId: userId,
  usuarioNombre: userName,
  detalles: {
    'titulo': tituloNotificacion,
    'destinatarios': cantidadDestinatarios,
  },
);
```

**Dónde agregarlo:**
- Cuando el admin envía notificaciones masivas

### 5. Otros Eventos Importantes

#### Actualización de Perfil
```dart
await actividadesService.registrarActividad(
  tipo: 'perfil',
  descripcion: 'Actualizó su información de perfil',
  usuarioId: userId,
  usuarioNombre: userName,
);
```

#### Cancelación de Pedido
```dart
await actividadesService.registrarActividad(
  tipo: 'pedido',
  descripcion: 'Canceló un pedido #${pedidoId}',
  usuarioId: userId,
  usuarioNombre: userName,
  detalles: {
    'pedidoId': pedidoId,
    'razon': razon,
  },
);
```

## Ejemplo de Integración

### En CartScreen (al realizar un pedido)

```dart
import '../../servicios/actividades_service.dart';

class _CartScreenState extends State<CartScreen> {
  final ActividadesService _actividadesService = ActividadesService();

  Future<void> _realizarPedido() async {
    try {
      // ... código existente para crear el pedido ...

      // Registrar actividad
      final authProvider = AuthProvider.instance;
      await _actividadesService.registrarActividad(
        tipo: 'pedido',
        descripcion: 'Realizó un pedido de S/. ${total.toStringAsFixed(2)}',
        usuarioId: authProvider.currentUser!.id,
        usuarioNombre: authProvider.currentUser!.nombreCompleto,
        detalles: {
          'pedidoId': pedidoId,
          'total': total,
          'metodoPago': metodoPago,
          'cantidadProductos': items.length,
        },
      );

      // ... resto del código ...
    } catch (e) {
      // ...
    }
  }
}
```

### En RegistroVista (al registrar usuario)

```dart
import '../../servicios/actividades_service.dart';

class _RegistroVistaState extends State<RegistroVista> {
  final ActividadesService _actividadesService = ActividadesService();

  Future<void> _registrarUsuario() async {
    try {
      // ... código existente para registrar ...

      // Registrar actividad
      await _actividadesService.registrarActividad(
        tipo: 'registro',
        descripcion: 'Nuevo usuario registrado',
        usuarioId: userId,
        usuarioNombre: '$nombres $apellidos',
        detalles: {
          'email': email,
          'rol': 'cliente',
        },
      );

      // ... resto del código ...
    } catch (e) {
      // ...
    }
  }
}
```

## Visualización

### Dashboard del Administrador
- **Ubicación**: Sección "Actividad Reciente" en el home del admin
- **Muestra**: Últimas 5 actividades
- **Actualización**: En tiempo real (StreamBuilder)

### Pantalla Completa de Actividades
- **Ubicación**: `lib/pantallas/principal/actividades_screen.dart`
- **Acceso**: Botón "Ver todas" en la sección de Actividad Reciente
- **Características**:
  - Todas las actividades del sistema
  - Filtros por tipo
  - Ordenadas por fecha descendente
  - Actualización en tiempo real

## Base de Datos

### Colección Firebase
`actividades_sistema`

### Estructura de Documento
```json
{
  "tipo": "pedido",
  "descripcion": "Realizó un pedido de S/. 45.00",
  "usuarioId": "abc123",
  "usuarioNombre": "Juan Pérez",
  "detalles": {
    "pedidoId": "PED001",
    "total": 45.00,
    "cantidadProductos": 3
  },
  "fecha": Timestamp,
  "fechaCreacion": "2025-01-15T10:30:00.000Z"
}
```

## Notas Importantes

1. **No confundir actividades con acciones**: Las actividades son eventos significativos del sistema, no simples clics o navegación.

2. **Registrar solo eventos importantes**: Pedidos, registros, cambios de credenciales, notificaciones, etc.

3. **Incluir información contextual**: Usuario que realizó la acción, timestamp, detalles relevantes.

4. **Limpieza automática**: El servicio incluye un método para limpiar actividades mayores a 90 días (opcional).

5. **Rendimiento**: Las consultas están indexadas por fecha para mejor performance.
