# 🔥 Guía de Configuración de Firebase - Repostería Arlex

## ✅ Estado Actual

- ✅ Firebase configurado en el proyecto
- ✅ `firebase_options.dart` generado correctamente
- ✅ Proyecto Firebase: **reposteria-arlex**
- ✅ Inicialización en `main.dart` completada
- ✅ Script de inicialización de datos creado

## 📋 Pasos Pendientes para Completar la Configuración

### 1️⃣ Habilitar Firebase Authentication

1. Ve a [Firebase Console](https://console.firebase.google.com/project/reposteria-arlex)
2. En el menú lateral, selecciona **"Authentication"** (Autenticación)
3. Click en **"Get started"** o **"Comenzar"**
4. En la pestaña **"Sign-in method"** (Método de inicio de sesión):
   - Click en **"Email/Password"**
   - **Activa** el proveedor Email/Password
   - Click en **"Save"** (Guardar)

### 2️⃣ Habilitar Cloud Firestore

1. En Firebase Console, selecciona **"Firestore Database"**
2. Click en **"Create database"** (Crear base de datos)
3. Selecciona el modo:
   - **Producción**: Selecciona **"Start in production mode"**
   - Luego configuraremos las reglas de seguridad
4. Selecciona la ubicación:
   - Recomendado: **us-central1** (para mejor rendimiento en América)
5. Click en **"Enable"** (Habilitar)

### 3️⃣ Configurar Reglas de Seguridad de Firestore

Una vez creada la base de datos:

1. Ve a la pestaña **"Rules"** (Reglas)
2. Reemplaza las reglas actuales con las siguientes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }

    function isEmployee() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol in ['admin', 'empleado'];
    }

    // Usuarios
    match /usuarios/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // Información del negocio (público en lectura)
    match /informacion_negocio/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Categorías (público en lectura)
    match /categorias/{categoriaId} {
      allow read: if true;
      allow write: if isEmployee();
    }

    // Productos (público en lectura)
    match /productos/{productoId} {
      allow read: if true;
      allow write: if isEmployee();
    }

    // Pedidos
    match /pedidos/{pedidoId} {
      allow read: if isOwner(resource.data.usuarioId) || isEmployee();
      allow create: if isAuthenticated();
      allow update: if isEmployee();
      allow delete: if isAdmin();

      // Historial de pedidos (subcollection)
      match /historial/{historialId} {
        allow read: if isOwner(get(/databases/$(database)/documents/pedidos/$(pedidoId)).data.usuarioId) || isEmployee();
        allow write: if isEmployee();
      }
    }

    // Carritos
    match /carritos/{userId} {
      allow read, write: if isOwner(userId);
    }

    // Promociones (público en lectura)
    match /promociones/{promocionId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Reseñas
    match /reseñas/{reseñaId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.usuarioId) || isAdmin();
      allow delete: if isAdmin();
    }

    // Notificaciones
    match /notificaciones/{notificacionId} {
      allow read: if isOwner(resource.data.usuarioId);
      allow write: if isEmployee();
    }

    // Inventario movimientos
    match /inventario_movimientos/{movimientoId} {
      allow read, write: if isEmployee();
    }

    // Configuración del sistema
    match /configuracion_sistema/{configId} {
      allow read: if isEmployee();
      allow write: if isAdmin();
    }

    // Estadísticas
    match /estadisticas/{estadisticaId} {
      allow read, write: if isEmployee();
    }
  }
}
```

3. Click en **"Publish"** (Publicar)

### 4️⃣ Habilitar Firebase Storage (Opcional)

Si deseas permitir la subida de imágenes:

1. En Firebase Console, selecciona **"Storage"**
2. Click en **"Get started"** (Comenzar)
3. Acepta las reglas predeterminadas
4. Selecciona la misma ubicación que Firestore
5. Click en **"Done"** (Listo)

**Reglas de Storage recomendadas:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Imágenes de productos (solo admin puede escribir)
    match /productos/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                     get(/databases/(default)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }

    // Imágenes de perfil (usuarios pueden subir su propia foto)
    match /usuarios/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Imágenes del negocio (solo admin)
    match /negocio/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                     get(/databases/(default)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }
  }
}
```

### 5️⃣ Crear Usuario Administrador

Hay dos opciones:

#### Opción A: Desde Firebase Console (Recomendado)

1. Ve a **Authentication > Users** (Usuarios)
2. Click en **"Add user"** (Agregar usuario)
3. Ingresa:
   - **Email**: tu email (ej: `admin@reposteriaarlex.com`)
   - **Password**: una contraseña segura
4. Click en **"Add user"**
5. **IMPORTANTE**: Copia el **User UID** que aparece en la lista

Luego, ve a **Firestore Database**:

1. Click en **"Start collection"** (Iniciar colección)
2. Collection ID: `usuarios`
3. Document ID: Pega el **User UID** copiado anteriormente
4. Agrega los siguientes campos:
   - `email` (string): tu email
   - `nombre` (string): Tu Nombre
   - `rol` (string): `admin`
   - `estado` (string): `activo`
   - `telefono` (string): (opcional)
   - `fechaCreacion` (timestamp): Click en "Insert timestamp"
   - `fechaActualizacion` (timestamp): Click en "Insert timestamp"

#### Opción B: Desde la Aplicación

Una vez ejecutada la inicialización de datos (paso 6), puedes crear el usuario desde la pantalla de registro y luego actualizar su rol en Firestore manualmente.

### 6️⃣ Ejecutar Inicialización de Datos

#### Opción A: Usando la pantalla de inicialización

1. Abre el archivo `lib/main.dart`
2. Temporalmente, cambia la pantalla inicial a `FirebaseInitRunner`:

```dart
import 'utils/firebase_init_runner.dart';

// En MyApp, cambia:
home: const FirebaseInitRunner(), // Temporal para inicializar
```

3. Ejecuta la aplicación:
   ```bash
   flutter run -d chrome
   ```

4. En la pantalla que aparece:
   - Click en **"Probar Conexión"** para verificar que Firestore está funcionando
   - Si la conexión es exitosa, click en **"Inicializar Datos"**

5. Una vez completada la inicialización, **revierte el cambio** en `main.dart`

#### Opción B: Usando Firebase Console

Puedes crear manualmente las colecciones y documentos siguiendo la estructura en:
`docs/FIREBASE_DATABASE_STRUCTURE.md`

### 7️⃣ Verificar la Instalación

1. Ve a Firebase Console > Firestore Database
2. Deberías ver las siguientes colecciones:
   - ✅ `categorias` (5 documentos)
   - ✅ `informacion_negocio` (1 documento)
   - ✅ `productos` (4 documentos de ejemplo)
   - ✅ `usuarios` (1 documento - tu admin)

3. Ejecuta la aplicación:
   ```bash
   flutter run -d chrome
   ```

4. Intenta hacer login con el usuario administrador creado

## 🎯 Próximos Pasos

Una vez completada la configuración:

1. **Probar el Login**: Inicia sesión con el usuario administrador
2. **Explorar el Dashboard**: Verifica que puedes acceder al panel de administración
3. **Crear Productos**: Agrega productos desde el panel de administración
4. **Gestionar Pedidos**: Prueba el flujo completo de pedidos
5. **Personalizar**: Actualiza la información del negocio desde el panel

## 🆘 Solución de Problemas

### Error: "Firestore permission denied"
- Verifica que las reglas de seguridad estén publicadas correctamente
- Asegúrate de estar autenticado con un usuario válido

### Error: "Firebase not initialized"
- Verifica que `Firebase.initializeApp()` esté en el `main()` antes de `runApp()`
- Verifica que `firebase_options.dart` existe

### Error al crear usuario: "Email already in use"
- El email ya existe, usa otro email o elimina el usuario desde Firebase Console

### No aparecen datos en la app
- Verifica que la inicialización de datos se haya completado exitosamente
- Revisa los logs en la consola de Flutter
- Verifica las reglas de Firestore

## 📚 Documentación Adicional

- [Estructura de la Base de Datos](docs/FIREBASE_DATABASE_STRUCTURE.md)
- [Guía de Configuración Firebase](docs/FIREBASE_SETUP_GUIDE.md)
- [Guía de Integración](docs/FIREBASE_INTEGRATION_GUIDE.md)
- [Resumen Firebase](docs/RESUMEN_FIREBASE.md)

## ✅ Checklist Final

Antes de considerar la configuración completa, verifica:

- [ ] Firebase Authentication habilitado
- [ ] Firestore Database creado
- [ ] Reglas de seguridad configuradas
- [ ] Usuario administrador creado
- [ ] Documento de usuario en Firestore con rol "admin"
- [ ] Datos iniciales creados (categorías, info negocio, productos)
- [ ] Login exitoso desde la aplicación
- [ ] Acceso al dashboard de administración

---

**¡Listo! Tu aplicación de Repostería Arlex está conectada a Firebase y lista para usar! 🎉**
