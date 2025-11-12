# Sistema de Configuración del Sistema - Repostería Arlex

## 📋 Resumen

Se ha implementado un **sistema completo de configuración** para el administrador, permitiendo controlar qué módulos, características y secciones se muestran a los clientes de forma dinámica desde Firebase.

---

## ✅ Archivos Creados

### 1. **Modelo de Datos**
📄 `lib/modelos/configuracion_sistema_modelo.dart`

Contiene las siguientes clases:

- **ConfiguracionSistema**: Modelo principal
- **ModulosVisibles**: Control de módulos (10 opciones)
  - Catálogo, Carrito, Pedidos, Reservas, Promociones
  - Sobre Nosotros, Contacto, Testimonios, Galería, Blog

- **CaracteristicasHabilitadas**: Características del sistema (10 opciones)
  - Registro usuarios, Login requerido
  - Comentarios y calificaciones
  - Compartir en redes, Newsletter, Cupones
  - Programa de lealtad, Notificaciones push, Chat en vivo

- **SeccionesInicio**: Control de la página de inicio (10 secciones)
  - Banner principal, Productos destacados, Promociones
  - Categorías, Testimonios, Sobre nosotros
  - Galería, Blog, Newsletter, Redes sociales

- **ConfiguracionProductos**: Visualización de productos (8 opciones)
  - Precio, Descuento, Stock, Calificaciones
  - Comentarios, Compra directa
  - Productos relacionados, Imágenes adicionales

- **ConfiguracionPedidos**: Gestión de pedidos (8 opciones)
  - Pedidos online, Reservas
  - Confirmación, Estado del pedido
  - Cancelación, Notificaciones
  - Pago online, Pago contraentrega

### 2. **Servicio de Firebase**
📄 `lib/servicios/configuracion_sistema_servicio.dart`

**Funciones principales:**
- `obtenerConfiguracion()`: Obtiene la configuración actual
- `streamConfiguracion()`: Stream en tiempo real
- `actualizarConfiguracion()`: Actualiza todo
- `actualizarModulos()`: Solo módulos
- `actualizarCaracteristicas()`: Solo características
- `actualizarSeccionesInicio()`: Solo secciones de inicio
- `actualizarConfiguracionProductos()`: Solo productos
- `actualizarConfiguracionPedidos()`: Solo pedidos
- `toggleModulo()`: Toggle rápido de módulo específico
- `toggleCaracteristica()`: Toggle rápido de característica
- `toggleSeccionInicio()`: Toggle rápido de sección
- `crearConfiguracionPorDefecto()`: Crea configuración inicial
- `restaurarPorDefecto()`: Restaura valores por defecto

### 3. **Controlador con ChangeNotifier**
📄 `lib/controladores/configuracion_sistema_controlador.dart`

**Características:**
- Gestión de estado con `ChangeNotifier`
- Cache local de configuración
- Manejo de errores y estados de carga
- Tracking de usuario que modifica
- Funciones para actualizar cada sección independientemente

### 4. **Vista de Administración**
📄 `lib/pantallas/admin/configuracion_sistema_vista.dart`

**Características de la UI:**
- 5 pestañas organizadas:
  1. **Módulos**: Control de módulos principales
  2. **Características**: Funcionalidades del sistema
  3. **Inicio**: Secciones de la página principal
  4. **Productos**: Configuración de visualización
  5. **Pedidos**: Gestión de pedidos y pagos

- Switches para activar/desactivar cada opción
- Feedback visual inmediato
- Botón de restaurar a valores por defecto
- Iconos descriptivos para cada opción
- Descripciones claras de cada funcionalidad

### 5. **Dashboard de Administrador Actualizado**
📄 `lib/pantallas/dashboards/admin_dashboard.dart`

**Mejoras implementadas:**
- Grid de tarjetas con acceso a diferentes módulos
- **Configuración del Sistema** (✅ Funcional)
- **Información del Negocio** (✅ Funcional)
- Gestión de Productos (Pendiente)
- Pedidos (Pendiente)
- Clientes (Pendiente)
- Reportes (Pendiente)
- Promociones (Pendiente)
- Categorías (Pendiente)

---

## 🗄️ Estructura de Firebase

La configuración se guarda en Firestore con esta estructura:

```
configuracion_sistema/
  └── config/
      ├── modulos: {
      │   ├── catalogo: true
      │   ├── carrito: true
      │   ├── pedidos: true
      │   ├── reservas: true
      │   ├── promociones: true
      │   ├── sobreNosotros: true
      │   ├── contacto: true
      │   ├── testimonios: true
      │   ├── blog: false
      │   └── galeria: true
      │ }
      ├── caracteristicas: {
      │   ├── registroUsuarios: true
      │   ├── loginRequerido: false
      │   ├── comentariosProductos: true
      │   ├── calificacionProductos: true
      │   ├── compartirRedes: true
      │   ├── newsletter: true
      │   ├── cupones: true
      │   ├── programaLealtad: false
      │   ├── notificacionesPush: false
      │   └── chatEnVivo: false
      │ }
      ├── seccionesInicio: {
      │   ├── bannerPrincipal: true
      │   ├── productosDestacados: true
      │   ├── promociones: true
      │   ├── categorias: true
      │   ├── testimonios: true
      │   ├── sobreNosotros: true
      │   ├── galeria: true
      │   ├── blog: false
      │   ├── newsletter: true
      │   └── redesSociales: true
      │ }
      ├── productos: {
      │   ├── mostrarPrecio: true
      │   ├── mostrarDescuento: true
      │   ├── mostrarStock: true
      │   ├── mostrarCalificaciones: true
      │   ├── mostrarComentarios: true
      │   ├── permitirCompraDirecta: true
      │   ├── mostrarProductosRelacionados: true
      │   └── mostrarImagenesAdicionales: true
      │ }
      ├── pedidos: {
      │   ├── permitirPedidosOnline: true
      │   ├── permitirReservas: true
      │   ├── requerirConfirmacion: true
      │   ├── mostrarEstadoPedido: true
      │   ├── permitirCancelacion: true
      │   ├── notificarCliente: true
      │   ├── permitirPagoOnline: false
      │   └── permitirPagoContraentrega: true
      │ }
      ├── fechaActualizacion: Timestamp
      └── modificadoPor: "user_id"
```

---

## 🚀 Cómo Usar

### 1. Acceder al Módulo de Configuración

1. Inicia sesión como **administrador**
2. Desde el dashboard de admin, haz clic en la tarjeta **"Configuración del Sistema"**
3. Se abrirá la vista con 5 pestañas

### 2. Modificar Configuración

**Opción A: Toggle Individual**
- Simplemente activa/desactiva el switch de cualquier opción
- Los cambios se guardan inmediatamente en Firebase
- Aparece un mensaje de confirmación

**Opción B: Restaurar Por Defecto**
- Clic en el menú (⋮) en la esquina superior derecha
- Selecciona "Restaurar por defecto"
- Confirma la acción
- Toda la configuración se restaura a valores iniciales

### 3. Usar la Configuración en Tu App

```dart
import 'package:provider/provider.dart';
import 'package:reposteria_arlex/controladores/configuracion_sistema_controlador.dart';

// En tu widget
class MiWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracionSistemaControlador>();

    // Verificar si un módulo está habilitado
    if (config.modulos?.catalogo ?? false) {
      return CatalogoWidget();
    }

    // Verificar características
    if (config.caracteristicas?.comentariosProductos ?? false) {
      return ComentariosWidget();
    }

    // Verificar secciones de inicio
    if (config.seccionesInicio?.productosDestacados ?? false) {
      return ProductosDestacadosWidget();
    }

    return SizedBox.shrink();
  }
}
```

### 4. Stream en Tiempo Real

```dart
StreamBuilder<ConfiguracionSistema?>(
  stream: ConfiguracionSistemaControlador().streamConfiguracion(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final config = snapshot.data!;
      // Usar la configuración
      return MyWidget(config: config);
    }
    return CircularProgressIndicator();
  },
)
```

---

## 📊 Casos de Uso

### Caso 1: Desactivar Módulo Temporalmente
**Situación:** Necesitas hacer mantenimiento al módulo de pedidos
1. Ve a **Configuración del Sistema** → **Módulos**
2. Desactiva "Pedidos"
3. Los clientes ya no verán el módulo de pedidos
4. Reactívalo cuando el mantenimiento termine

### Caso 2: Activar Nueva Característica
**Situación:** Quieres probar el sistema de cupones
1. Ve a **Características**
2. Activa "Cupones de Descuento"
3. La funcionalidad de cupones se habilita inmediatamente
4. Monitorea el rendimiento y desactiva si es necesario

### Caso 3: Personalizar Página de Inicio
**Situación:** Quieres una página más simple
1. Ve a **Inicio**
2. Desactiva "Blog", "Newsletter", etc.
3. La página de inicio solo mostrará las secciones activas
4. Experimenta hasta encontrar la mejor combinación

### Caso 4: Configurar Visualización de Productos
**Situación:** No quieres mostrar stock a los clientes
1. Ve a **Productos**
2. Desactiva "Mostrar Stock"
3. El inventario se oculta pero sigue funcionando internamente

### Caso 5: Gestión de Pedidos
**Situación:** Solo quieres aceptar reservas, no pedidos directos
1. Ve a **Pedidos**
2. Desactiva "Permitir Pedidos Online"
3. Mantén activo "Permitir Reservas"
4. Los clientes solo podrán hacer reservas

---

## 🎯 Beneficios del Sistema

1. **Control Total**: El administrador decide qué se muestra
2. **Cambios Instantáneos**: Sin necesidad de actualizar la app
3. **Flexible**: Activa/desactiva funciones según necesidad
4. **Seguro**: Solo administradores tienen acceso
5. **Auditable**: Se registra quién y cuándo modificó
6. **Fácil de Usar**: Interfaz intuitiva con switches
7. **Organizado**: 5 pestañas bien estructuradas
8. **Responsive**: Funciona en todos los dispositivos

---

## 📱 Integración en la Aplicación

### Para usar en widgets cliente:

```dart
// Ejemplo 1: Mostrar u ocultar módulo
Consumer<ConfiguracionSistemaControlador>(
  builder: (context, config, child) {
    if (!(config.modulos?.promociones ?? false)) {
      return SizedBox.shrink(); // Ocultar si está desactivado
    }
    return PromocionesWidget();
  },
)

// Ejemplo 2: Verificar antes de navegar
void navegarACatalogo(BuildContext context) {
  final config = context.read<ConfiguracionSistemaControlador>();

  if (!(config.modulos?.catalogo ?? false)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Módulo no disponible')),
    );
    return;
  }

  Navigator.push(context, ...);
}

// Ejemplo 3: Funcionalidad condicional
Widget buildComentarios() {
  final config = context.watch<ConfiguracionSistemaControlador>();

  if (!(config.caracteristicas?.comentariosProductos ?? false)) {
    return Text('Comentarios deshabilitados');
  }

  return ComentariosSection();
}
```

---

## 🔐 Seguridad

- Solo usuarios con rol **administrador** pueden acceder
- Se registra el ID del usuario que modifica
- Se registra timestamp de cada cambio
- Los cambios son instantáneos pero reversibles
- Función de restaurar por defecto disponible

---

## 📈 Valores por Defecto

Todos los módulos y características vienen **activados por defecto**, excepto:
- Blog (experimental)
- Programa de Lealtad (experimental)
- Notificaciones Push (experimental)
- Chat en Vivo (experimental)
- Pago Online (requiere configuración adicional)

---

## 🔄 Sincronización

- Los cambios se guardan **inmediatamente en Firebase**
- El sistema usa **Streams** para actualizaciones en tiempo real
- El controlador mantiene un **cache local** para acceso rápido
- Si hay error, se muestra mensaje y se mantiene el estado anterior

---

## 🛠️ Mantenimiento

### Agregar Nueva Opción de Configuración

1. **Actualizar el modelo** (`configuracion_sistema_modelo.dart`)
2. **Agregar función en servicio** (`configuracion_sistema_servicio.dart`)
3. **Agregar función en controlador** (`configuracion_sistema_controlador.dart`)
4. **Agregar switch en la vista** (`configuracion_sistema_vista.dart`)

### Ejemplo: Agregar nueva característica "modo_mantenimiento"

```dart
// 1. En el modelo
class CaracteristicasHabilitadas {
  final bool modoMantenimiento; // ← Nueva propiedad

  CaracteristicasHabilitadas({
    // ... otras propiedades
    this.modoMantenimiento = false, // ← Valor por defecto
  });
}

// 2. En la vista, agregar un nuevo switch
_buildSwitchCard(
  'Modo Mantenimiento',
  'Muestra mensaje de mantenimiento a los clientes',
  Icons.build,
  caracteristicas.modoMantenimiento,
  (value) => controlador.toggleCaracteristica('modoMantenimiento', value),
),
```

---

## ✅ Estado del Proyecto

**Módulos Completamente Funcionales:**
- ✅ Configuración del Sistema (5 pestañas, 46+ opciones)
- ✅ Información del Negocio (4 pestañas)
- ✅ Dashboard de Administrador (Grid de módulos)

**Próximos Módulos:**
- ⏳ Gestión de Productos
- ⏳ Gestión de Pedidos
- ⏳ Gestión de Clientes
- ⏳ Reportes y Estadísticas
- ⏳ Promociones
- ⏳ Categorías

---

## 📝 Notas Importantes

1. **La configuración afecta solo a la interfaz de cliente**, no elimina datos
2. **Desactivar un módulo no borra la información asociada**
3. **Los cambios son reversibles en cualquier momento**
4. **Se recomienda probar cambios antes de aplicarlos en producción**
5. **El sistema crea automáticamente la configuración si no existe**

---

## 🎓 Documentación Adicional

- Ver [IMPLEMENTACION_INFORMACION_NEGOCIO.md](IMPLEMENTACION_INFORMACION_NEGOCIO.md) para el módulo de información del negocio
- Ver [README.md](lib/features/informacion_negocio/README.md) para detalles del sistema de información

---

**Estado:** ✅ Sistema Completo y Funcional
**Versión:** 1.0.0
**Fecha:** 2025-10-15
**Desarrollado para:** Repostería Arlex
