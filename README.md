# 🍰 Repostería Arlex - Sistema de Gestión

Sistema completo de gestión para repostería con Flutter y Firebase.

## 📋 Descripción

Aplicación web/móvil para la gestión integral de una repostería, incluyendo:
- 🛒 Catálogo de productos
- 📦 Gestión de pedidos
- 👥 Administración de usuarios (Admin, Empleado, Cliente)
- 📊 Dashboard con estadísticas
- 💰 Reportes financieros
- 📱 Interfaz responsive

## 🚀 Estado del Proyecto

### ✅ Completado

- ✅ Arquitectura del proyecto implementada
- ✅ Integración con Firebase (Auth, Firestore, Storage)
- ✅ Sistema de autenticación completo
- ✅ Gestión de productos y categorías
- ✅ Sistema de pedidos con estados
- ✅ Carrito de compras
- ✅ Dashboard administrativo
- ✅ Panel de métricas y estadísticas
- ✅ Gestión financiera y reportes
- ✅ Configuración de Firebase completada
- ✅ Script de inicialización de datos

### 🔧 Configuración Requerida

Para usar la aplicación, necesitas completar la configuración de Firebase:

**📖 [Ver Guía Completa de Configuración](CONFIGURACION_FIREBASE.md)**

Pasos principales:
1. Habilitar Firebase Authentication (Email/Password)
2. Crear Cloud Firestore
3. Configurar reglas de seguridad
4. Crear usuario administrador
5. Ejecutar inicialización de datos

## 🛠️ Tecnologías

- **Framework**: Flutter 3.9+
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Firebase Storage
- **State Management**: Provider
- **Lenguaje**: Dart

## 📦 Instalación Rápida

1. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

2. **Configurar Firebase** - [Ver guía completa](CONFIGURACION_FIREBASE.md)

3. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome
   ```

## 📁 Estructura del Proyecto

```
lib/
├── admin/                  # Módulos de administración
├── compartidos/            # Componentes compartidos
├── modelos/                # Modelos de datos
├── pantallas/              # Pantallas principales
├── providers/              # State management
├── servicios/              # Servicios Firebase
└── utils/                  # Utilidades
```

## 🔑 Roles de Usuario

- **Cliente**: Ver catálogo, realizar pedidos
- **Empleado**: + Gestionar pedidos, ver estadísticas
- **Administrador**: + CRUD completo, reportes, configuración

## 📚 Documentación

- [Configuración de Firebase](CONFIGURACION_FIREBASE.md)
- [Estructura de la Base de Datos](docs/FIREBASE_DATABASE_STRUCTURE.md)
- [Guía de Integración](docs/FIREBASE_INTEGRATION_GUIDE.md)

---

**Desarrollado con ❤️ usando Flutter y Firebase**
