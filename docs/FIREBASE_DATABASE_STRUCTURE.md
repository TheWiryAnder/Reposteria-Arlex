# Estructura de Base de Datos Firebase Firestore - Repostería Arlex

## 📋 Índice
1. [Colecciones Principales](#colecciones-principales)
2. [Diagrama de Relaciones](#diagrama-de-relaciones)
3. [Reglas de Seguridad](#reglas-de-seguridad)
4. [Índices Compuestos](#índices-compuestos)

---

## 🗂️ Colecciones Principales

### 1. **usuarios** (users)
Almacena la información de todos los usuarios del sistema (clientes, empleados, administradores).

```javascript
usuarios/{userId}
{
  id: string,                    // UID de Firebase Auth
  nombre: string,                // Nombre completo
  email: string,                 // Email único
  telefono: string,              // Teléfono de contacto
  rol: string,                   // "admin" | "empleado" | "cliente"
  estado: string,                // "activo" | "inactivo" | "suspendido"
  emailVerificado: boolean,      // Estado de verificación de email

  // Datos adicionales según rol
  direccion: string,             // Solo para clientes
  fechaNacimiento: timestamp,    // Solo para clientes

  // Metadatos
  fechaCreacion: timestamp,
  fechaActualizacion: timestamp,
  ultimoAcceso: timestamp,

  // Preferencias
  preferencias: {
    notificaciones: boolean,
    newsletter: boolean
  }
}
```

**Índices:**
- `email` (ascendente)
- `rol` (ascendente) + `estado` (ascendente)
- `fechaCreacion` (descendente)

---

### 2. **informacion_negocio** (business_info)
Documento único con toda la información del negocio.

```javascript
informacion_negocio/config
{
  // Información básica
  nombre: string,                // "Repostería Arlex"
  slogan: string,                // Slogan del negocio
  logo: string,                  // URL del logo
  logoSecundario: string,        // URL del logo alternativo

  // Historia y valores
  historia: string,              // Historia del negocio
  mision: string,                // Misión
  vision: string,                // Visión
  valores: array<string>,        // ["Calidad", "Compromiso", ...]

  // Contacto
  telefono: string,
  email: string,
  whatsapp: string,
  direccion: string,
  horarioAtencion: {
    lunes_viernes: string,       // "8:00 AM - 6:00 PM"
    sabado: string,
    domingo: string
  },

  // Redes sociales
  redesSociales: {
    facebook: string,            // URL
    instagram: string,
    tiktok: string,
    twitter: string,
    youtube: string
  },

  // Configuración de negocio
  configuracion: {
    aceptaPedidosOnline: boolean,
    tiempoPreparacionMinimo: number,    // En horas
    montoMinimoEnvio: number,
    costoEnvio: number,
    radiusEntregaKm: number,
    iva: number,                        // Porcentaje de IVA
    aceptaReservas: boolean
  },

  // Galería
  galeria: array<{
    url: string,
    descripcion: string,
    orden: number
  }>,

  // Metadatos
  fechaActualizacion: timestamp,
  actualizadoPor: string         // UID del usuario que actualizó
}
```

---

### 3. **categorias** (categories)
Categorías de productos.

```javascript
categorias/{categoriaId}
{
  id: string,
  nombre: string,                // "Tortas", "Galletas", etc.
  descripcion: string,
  icono: string,                 // Nombre del icono Material
  imagen: string,                // URL de imagen opcional
  orden: number,                 // Para ordenar en el UI
  activa: boolean,

  // Metadatos
  fechaCreacion: timestamp,
  fechaActualizacion: timestamp,
  creadoPor: string              // UID del admin
}
```

**Índices:**
- `activa` (ascendente) + `orden` (ascendente)

---

### 4. **productos** (products)
Todos los productos disponibles.

```javascript
productos/{productoId}
{
  id: string,
  nombre: string,
  descripcion: string,
  precio: number,
  categoriaId: string,           // Referencia a categorias/{id}
  categoriaNombre: string,       // Desnormalizado para queries rápidas

  // Imágenes
  imagenes: array<{
    url: string,
    principal: boolean,
    orden: number
  }>,

  // Inventario
  stock: number,
  stockMinimo: number,           // Alerta de stock bajo
  requierePreparacion: boolean,
  tiempoPreparacionHoras: number,

  // Estado
  disponible: boolean,
  destacado: boolean,            // Para mostrar en página principal

  // Detalles adicionales
  peso: number,                  // En gramos
  porciones: number,             // Número de porciones
  ingredientes: array<string>,
  alergenos: array<string>,      // Información de alérgenos

  // Metadatos
  fechaCreacion: timestamp,
  fechaActualizacion: timestamp,
  creadoPor: string,

  // Estadísticas
  totalVendidos: number,
  calificacionPromedio: number,
  numeroCalificaciones: number
}
```

**Índices:**
- `categoriaId` (ascendente) + `disponible` (ascendente)
- `destacado` (ascendente) + `disponible` (ascendente)
- `disponible` (ascendente) + `fechaCreacion` (descendente)

---

### 5. **pedidos** (orders)
Pedidos realizados por los clientes.

```javascript
pedidos/{pedidoId}
{
  id: string,
  numeroPedido: string,          // "ORD-2025-0001" (generado automáticamente)

  // Cliente
  clienteId: string,             // UID del usuario
  clienteNombre: string,         // Desnormalizado
  clienteEmail: string,
  clienteTelefono: string,

  // Items del pedido
  items: array<{
    productoId: string,
    productoNombre: string,
    cantidad: number,
    precioUnitario: number,
    subtotal: number,
    notasEspeciales: string
  }>,

  // Totales
  subtotal: number,
  iva: number,
  costoEnvio: number,
  descuento: number,
  total: number,

  // Entrega
  metodoEntrega: string,         // "domicilio" | "tienda"
  direccionEntrega: string,
  coordenadas: {                 // Opcional para entregas
    lat: number,
    lng: number
  },

  // Pago
  metodoPago: string,            // "efectivo" | "transferencia" | "tarjeta"
  estadoPago: string,            // "pendiente" | "pagado" | "rechazado"
  referenciaPago: string,        // Para transferencias/tarjetas

  // Estado del pedido
  estado: string,                // "pendiente" | "confirmado" | "preparando" |
                                 // "listo" | "en_camino" | "entregado" | "cancelado"

  // Notas
  notasCliente: string,
  notasInternas: string,         // Solo visible para empleados/admin

  // Fechas importantes
  fechaPedido: timestamp,
  fechaConfirmacion: timestamp,
  fechaPreparacion: timestamp,
  fechaEntrega: timestamp,
  fechaCancelacion: timestamp,

  // Historial de estados (subcollection)
  // Ver: pedidos/{pedidoId}/historial/{historialId}

  // Asignación
  preparadoPor: string,          // UID del empleado
  entregadoPor: string,          // UID del repartidor

  // Calificación (opcional)
  calificacion: number,          // 1-5 estrellas
  comentarioCalificacion: string,
  fechaCalificacion: timestamp
}
```

**Subcollection: historial**
```javascript
pedidos/{pedidoId}/historial/{historialId}
{
  id: string,
  estado: string,
  comentario: string,
  usuarioId: string,
  usuarioNombre: string,
  fecha: timestamp
}
```

**Índices:**
- `clienteId` (ascendente) + `fechaPedido` (descendente)
- `estado` (ascendente) + `fechaPedido` (descendente)
- `fechaPedido` (descendente)
- `numeroPedido` (ascendente)

---

### 6. **carritos** (carts)
Carritos de compra activos (temporal, se limpia después de 7 días).

```javascript
carritos/{usuarioId}
{
  usuarioId: string,             // UID del usuario
  items: array<{
    productoId: string,
    productoNombre: string,
    productoPrecio: number,
    productoImagen: string,
    cantidad: number,
    notasEspeciales: string
  }>,

  total: number,
  cantidadTotal: number,

  fechaActualizacion: timestamp,
  fechaExpiracion: timestamp     // 7 días después de última actualización
}
```

**Índices:**
- `fechaExpiracion` (ascendente) - Para limpieza automática

---

### 7. **notificaciones** (notifications)
Notificaciones para usuarios.

```javascript
notificaciones/{notificacionId}
{
  id: string,
  usuarioId: string,             // UID del destinatario
  tipo: string,                  // "pedido" | "sistema" | "promocion"
  titulo: string,
  mensaje: string,

  // Datos adicionales según tipo
  pedidoId: string,              // Si es notificación de pedido
  link: string,                  // URL opcional

  // Estado
  leida: boolean,
  fechaLectura: timestamp,

  // Metadatos
  fechaCreacion: timestamp,
  creadoPor: string              // "sistema" o UID
}
```

**Índices:**
- `usuarioId` (ascendente) + `leida` (ascendente) + `fechaCreacion` (descendente)

---

### 8. **promociones** (promotions)
Promociones y descuentos activos.

```javascript
promociones/{promocionId}
{
  id: string,
  nombre: string,
  descripcion: string,
  imagen: string,

  // Tipo de descuento
  tipoDescuento: string,         // "porcentaje" | "monto_fijo"
  valorDescuento: number,

  // Condiciones
  montoMinimo: number,           // Monto mínimo para aplicar
  productosAplicables: array<string>, // IDs de productos (vacío = todos)
  categoriasAplicables: array<string>, // IDs de categorías

  // Código de cupón (opcional)
  codigoCupon: string,
  usosMaximos: number,           // 0 = ilimitado
  usosActuales: number,
  usuarioMaxUsos: number,        // Usos por usuario

  // Vigencia
  fechaInicio: timestamp,
  fechaFin: timestamp,
  activa: boolean,

  // Metadatos
  fechaCreacion: timestamp,
  creadoPor: string
}
```

**Índices:**
- `activa` (ascendente) + `fechaFin` (descendente)
- `codigoCupon` (ascendente)

---

### 9. **reseñas** (reviews)
Reseñas de productos.

```javascript
reseñas/{reseñaId}
{
  id: string,
  productoId: string,
  productoNombre: string,

  // Usuario
  usuarioId: string,
  usuarioNombre: string,

  // Reseña
  calificacion: number,          // 1-5
  titulo: string,
  comentario: string,
  imagenes: array<string>,       // URLs de imágenes opcionales

  // Verificación
  compraVerificada: boolean,     // ¿El usuario compró el producto?
  pedidoId: string,              // Referencia al pedido

  // Estado
  aprobada: boolean,             // Moderación
  reportada: boolean,

  // Metadatos
  fechaCreacion: timestamp,
  fechaActualizacion: timestamp
}
```

**Índices:**
- `productoId` (ascendente) + `aprobada` (ascendente) + `fechaCreacion` (descendente)
- `usuarioId` (ascendente) + `fechaCreacion` (descendente)

---

### 10. **inventario_movimientos** (inventory_movements)
Historial de movimientos de inventario.

```javascript
inventario_movimientos/{movimientoId}
{
  id: string,
  productoId: string,
  productoNombre: string,

  // Movimiento
  tipo: string,                  // "entrada" | "salida" | "ajuste" | "venta"
  cantidad: number,              // Positivo = entrada, Negativo = salida
  stockAnterior: number,
  stockNuevo: number,

  // Razón
  razon: string,                 // "compra" | "venta" | "devolución" | "merma" | "ajuste"
  referencia: string,            // ID de pedido, compra, etc.
  notas: string,

  // Usuario responsable
  realizadoPor: string,          // UID
  realizadoPorNombre: string,

  // Metadatos
  fecha: timestamp
}
```

**Índices:**
- `productoId` (ascendente) + `fecha` (descendente)
- `tipo` (ascendente) + `fecha` (descendente)

---

### 11. **configuracion_sistema** (system_config)
Configuraciones generales del sistema.

```javascript
configuracion_sistema/settings
{
  // Email
  emailConfig: {
    smtpHost: string,
    smtpPort: number,
    emailSoporte: string,
    nombreRemitente: string
  },

  // SMS/WhatsApp
  whatsappConfig: {
    apiKey: string,
    numeroNegocio: string,
    mensajesActivos: boolean
  },

  // Pagos
  pasarelasPago: {
    mercadoPago: {
      activo: boolean,
      publicKey: string,
      // accessToken en Cloud Functions por seguridad
    },
    paypal: {
      activo: boolean,
      clientId: string
    }
  },

  // Mantenimiento
  modoMantenimiento: boolean,
  mensajeMantenimiento: string,

  // Versión
  versionApp: string,
  ultimaActualizacion: timestamp
}
```

---

### 12. **estadisticas** (statistics)
Estadísticas del negocio (se actualiza con Cloud Functions).

```javascript
estadisticas/{periodo}  // formato: "2025-01", "2025-01-15", "2025"
{
  periodo: string,
  tipo: string,                  // "diario" | "mensual" | "anual"

  // Ventas
  totalVentas: number,
  numeroOrdenes: number,
  ticketPromedio: number,

  // Productos
  productosMasVendidos: array<{
    productoId: string,
    nombre: string,
    cantidad: number,
    ingresos: number
  }>,

  // Clientes
  nuevosClientes: number,
  clientesRecurrentes: number,

  // Por categoría
  ventasPorCategoria: map<string, number>,

  // Métodos de pago
  ventasPorMetodoPago: map<string, number>,

  fecha: timestamp
}
```

---

## 📊 Diagrama de Relaciones

```
usuarios (1) ──────── (N) pedidos
    │                      │
    │                      │
    └── (1) carritos       └── (N) historial (subcollection)
    │
    └── (N) notificaciones
    │
    └── (N) reseñas

categorias (1) ──────── (N) productos
                              │
                              ├── (N) reseñas
                              │
                              └── (N) inventario_movimientos

productos (N) ──────── (N) pedidos.items (embedded)
                │
                └── (N) carritos.items (embedded)

promociones (N) ──────── (N) pedidos (via código/condiciones)

informacion_negocio (1 documento único)
configuracion_sistema (1 documento único)
estadisticas (1 por periodo)
```

---

## 🔒 Reglas de Seguridad Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }

    function isEmpleado() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'empleado';
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Usuarios
    match /usuarios/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // Información del negocio (público en lectura)
    match /informacion_negocio/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Categorías (público en lectura)
    match /categorias/{categoriaId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Productos (público en lectura)
    match /productos/{productoId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Pedidos
    match /pedidos/{pedidoId} {
      allow read: if isOwner(resource.data.clienteId) || isAdmin() || isEmpleado();
      allow create: if isAuthenticated();
      allow update: if isAdmin() || isEmpleado();
      allow delete: if isAdmin();

      // Historial (subcollection)
      match /historial/{historialId} {
        allow read: if isOwner(get(/databases/$(database)/documents/pedidos/$(pedidoId)).data.clienteId) ||
                       isAdmin() || isEmpleado();
        allow write: if isAdmin() || isEmpleado();
      }
    }

    // Carritos
    match /carritos/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }

    // Notificaciones
    match /notificaciones/{notificacionId} {
      allow read: if isOwner(resource.data.usuarioId);
      allow write: if isAdmin();
    }

    // Promociones (público en lectura)
    match /promociones/{promocionId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Reseñas
    match /reseñas/{reseñaId} {
      allow read: if resource.data.aprobada == true || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.usuarioId) || isAdmin();
      allow delete: if isAdmin();
    }

    // Inventario (solo admin y empleados)
    match /inventario_movimientos/{movimientoId} {
      allow read: if isAdmin() || isEmpleado();
      allow write: if isAdmin();
    }

    // Configuración (solo admin)
    match /configuracion_sistema/{document} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }

    // Estadísticas (solo admin y empleados)
    match /estadisticas/{periodo} {
      allow read: if isAdmin() || isEmpleado();
      allow write: if false; // Solo Cloud Functions
    }
  }
}
```

---

## 🔍 Índices Compuestos Requeridos

Estos índices deben crearse en Firebase Console:

### Colección: `productos`
1. `categoriaId` (Ascending) + `disponible` (Ascending)
2. `destacado` (Ascending) + `disponible` (Ascending)
3. `disponible` (Ascending) + `fechaCreacion` (Descending)

### Colección: `pedidos`
1. `clienteId` (Ascending) + `fechaPedido` (Descending)
2. `estado` (Ascending) + `fechaPedido` (Descending)
3. `estado` (Ascending) + `metodoEntrega` (Ascending) + `fechaPedido` (Descending)

### Colección: `notificaciones`
1. `usuarioId` (Ascending) + `leida` (Ascending) + `fechaCreacion` (Descending)

### Colección: `reseñas`
1. `productoId` (Ascending) + `aprobada` (Ascending) + `fechaCreacion` (Descending)

### Colección: `inventario_movimientos`
1. `productoId` (Ascending) + `fecha` (Descending)

---

## 📝 Notas Importantes

### Desnormalización Estratégica
Algunos campos se duplican intencionalmente para optimizar consultas:
- `clienteNombre`, `clienteEmail` en pedidos
- `categoriaNombre` en productos
- `productoNombre` en items de pedidos/carritos

### Limpieza Automática
Configurar Cloud Functions para:
- Eliminar carritos expirados (>7 días)
- Archivar pedidos antiguos (>6 meses)
- Limpiar notificaciones leídas (>30 días)

### Escalabilidad
- Usar paginación en todas las listas
- Limitar arrays a <50 elementos
- Considerar sharding para contadores de alta concurrencia

### Backup
- Configurar exportaciones automáticas diarias
- Mantener backups por 30 días mínimo
