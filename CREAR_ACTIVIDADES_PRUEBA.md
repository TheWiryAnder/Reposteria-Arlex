# Crear Actividades de Prueba

## Opción 1: Usar Firebase Console (Recomendado)

1. Ve a Firebase Console: https://console.firebase.google.com/
2. Selecciona tu proyecto
3. Ve a Firestore Database
4. Crea una nueva colección llamada: `actividades_sistema`
5. Agrega los siguientes documentos:

### Documento 1 - Pedido
```
tipo: "pedido"
descripcion: "Realizó un pedido de S/. 125.50"
usuarioId: "user123"
usuarioNombre: "María González"
fecha: [Timestamp] (selecciona fecha actual)
fechaCreacion: "2025-01-15T14:30:00.000Z"
detalles: {
  pedidoId: "PED001",
  total: 125.50,
  cantidadProductos: 3
}
```

### Documento 2 - Registro
```
tipo: "registro"
descripcion: "Nuevo usuario registrado"
usuarioId: "user124"
usuarioNombre: "Carlos Pérez"
fecha: [Timestamp] (selecciona fecha actual - 1 hora)
fechaCreacion: "2025-01-15T13:15:00.000Z"
detalles: {
  email: "carlos@email.com",
  rol: "cliente"
}
```

### Documento 3 - Credenciales
```
tipo: "credenciales"
descripcion: "Cambió su contraseña"
usuarioId: "user125"
usuarioNombre: "Ana Torres"
fecha: [Timestamp] (selecciona fecha actual - 2 horas)
fechaCreacion: "2025-01-15T12:00:00.000Z"
detalles: {}
```

### Documento 4 - Notificación
```
tipo: "notificacion"
descripcion: "Envió una notificación: 'Promoción de Verano'"
usuarioId: "admin001"
usuarioNombre: "Admin Sistema"
fecha: [Timestamp] (selecciona fecha actual - 3 horas)
fechaCreacion: "2025-01-15T11:00:00.000Z"
detalles: {
  titulo: "Promoción de Verano",
  destinatarios: 45
}
```

### Documento 5 - Pedido
```
tipo: "pedido"
descripcion: "Realizó un pedido de S/. 85.00"
usuarioId: "user126"
usuarioNombre: "Luis Ramírez"
fecha: [Timestamp] (selecciona fecha actual - 5 horas)
fechaCreacion: "2025-01-15T09:30:00.000Z"
detalles: {
  pedidoId: "PED002",
  total: 85.00,
  cantidadProductos: 2
}
```

## Opción 2: Código Dart (Para desarrolladores)

Puedes crear un widget temporal que ejecute este código al presionar un botón:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> crearActividadesPrueba() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('actividades_sistema');

  // Actividad 1: Pedido
  await collection.add({
    'tipo': 'pedido',
    'descripcion': 'Realizó un pedido de S/. 125.50',
    'usuarioId': 'user123',
    'usuarioNombre': 'María González',
    'fecha': Timestamp.now(),
    'fechaCreacion': DateTime.now().toIso8601String(),
    'detalles': {
      'pedidoId': 'PED001',
      'total': 125.50,
      'cantidadProductos': 3,
    },
  });

  // Actividad 2: Registro
  await collection.add({
    'tipo': 'registro',
    'descripcion': 'Nuevo usuario registrado',
    'usuarioId': 'user124',
    'usuarioNombre': 'Carlos Pérez',
    'fecha': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))),
    'fechaCreacion': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
    'detalles': {
      'email': 'carlos@email.com',
      'rol': 'cliente',
    },
  });

  // Actividad 3: Cambio de credenciales
  await collection.add({
    'tipo': 'credenciales',
    'descripcion': 'Cambió su contraseña',
    'usuarioId': 'user125',
    'usuarioNombre': 'Ana Torres',
    'fecha': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
    'fechaCreacion': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
    'detalles': {},
  });

  // Actividad 4: Notificación
  await collection.add({
    'tipo': 'notificacion',
    'descripcion': 'Envió una notificación: "Promoción de Verano"',
    'usuarioId': 'admin001',
    'usuarioNombre': 'Admin Sistema',
    'fecha': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 3))),
    'fechaCreacion': DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
    'detalles': {
      'titulo': 'Promoción de Verano',
      'destinatarios': 45,
    },
  });

  // Actividad 5: Otro pedido
  await collection.add({
    'tipo': 'pedido',
    'descripcion': 'Realizó un pedido de S/. 85.00',
    'usuarioId': 'user126',
    'usuarioNombre': 'Luis Ramírez',
    'fecha': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5))),
    'fechaCreacion': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
    'detalles': {
      'pedidoId': 'PED002',
      'total': 85.00,
      'cantidadProductos': 2,
    },
  });

  print('✅ 5 actividades de prueba creadas exitosamente');
}
```

## Verificar que Funciona

Después de crear las actividades:

1. Inicia sesión como **administrador**
2. Ve al **Dashboard** (pantalla de inicio)
3. Desplázate hasta la sección **"Actividad Reciente"**
4. Deberías ver las 5 actividades que creaste
5. Haz clic en **"Ver todas"** para ver la pantalla completa con filtros

## Integración Real

Una vez que veas que funciona con datos de prueba, puedes integrar el registro automático de actividades en:

1. **CartScreen** - Al finalizar un pedido
2. **RegistroVista** - Al registrar un nuevo usuario
3. **ProfileScreen** - Al cambiar contraseña
4. Cualquier otra acción importante del sistema

Consulta el archivo `ACTIVIDADES_SISTEMA.md` para ver ejemplos de código.
