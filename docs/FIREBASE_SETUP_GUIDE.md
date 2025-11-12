# Guía de Configuración Firebase para Repostería Arlex

## 📋 Tabla de Contenidos
1. [Prerrequisitos](#prerrequisitos)
2. [Crear Proyecto Firebase](#crear-proyecto-firebase)
3. [Configurar Firebase Web](#configurar-firebase-web)
4. [Habilitar Servicios](#habilitar-servicios)
5. [Configurar Reglas de Seguridad](#configurar-reglas-de-seguridad)
6. [Crear Índices](#crear-índices)
7. [Integrar con Flutter](#integrar-con-flutter)
8. [Datos Iniciales](#datos-iniciales)

---

## 1️⃣ Prerrequisitos

- ✅ Cuenta de Google
- ✅ Flutter instalado (versión 3.0+)
- ✅ Proyecto Flutter configurado
- ✅ Acceso a internet

---

## 2️⃣ Crear Proyecto Firebase

### Paso 1: Acceder a Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en **"Agregar proyecto"** o **"Add project"**

### Paso 2: Configurar el Proyecto
1. **Nombre del proyecto**: `reposteria-arlex` (o el nombre que prefieras)
2. Haz clic en **Continuar**
3. **Google Analytics**: Puedes habilitarlo (recomendado) o deshabilitarlo
   - Si lo habilitas, selecciona o crea una cuenta de Analytics
4. Haz clic en **Crear proyecto**
5. Espera a que se cree el proyecto (1-2 minutos)
6. Haz clic en **Continuar**

---

## 3️⃣ Configurar Firebase Web

### Paso 1: Agregar App Web
1. En la página principal de tu proyecto, haz clic en el ícono **Web** (`</>`)
2. **Nombre de la app**: `Repostería Arlex Web`
3. **NO** marques "Also set up Firebase Hosting" por ahora
4. Haz clic en **Registrar app**

### Paso 2: Obtener Configuración
Copia la configuración que aparece (la necesitarás después):

```javascript
const firebaseConfig = {
  apiKey: "AIza....",
  authDomain: "reposteria-arlex.firebaseapp.com",
  projectId: "reposteria-arlex",
  storageBucket: "reposteria-arlex.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef",
  measurementId: "G-XXXXXXXXXX"
};
```

⚠️ **IMPORTANTE**: Guarda esta configuración en un lugar seguro. La usaremos más adelante.

---

## 4️⃣ Habilitar Servicios

### A. Habilitar Authentication

1. En el menú lateral, ve a **Build → Authentication**
2. Haz clic en **Comenzar** o **Get started**
3. Habilita los siguientes métodos de inicio de sesión:

#### Email/Password
1. Haz clic en **Correo electrónico/contraseña**
2. **Habilitar** el primer toggle (Email/Password)
3. **NO** habilites "Email link (passwordless sign-in)" por ahora
4. Haz clic en **Guardar**

#### Google (Opcional pero recomendado)
1. Haz clic en **Google**
2. **Habilitar** el toggle
3. Selecciona un **correo de soporte** para el proyecto
4. Haz clic en **Guardar**

### B. Habilitar Firestore Database

1. En el menú lateral, ve a **Build → Firestore Database**
2. Haz clic en **Crear base de datos** o **Create database**
3. **Modo de inicio**:
   - Selecciona **Empezar en modo de producción** (Production mode)
   - Haz clic en **Siguiente**
4. **Ubicación de Cloud Firestore**:
   - Selecciona la región más cercana (ej: `us-east1` para EE.UU. Este)
   - Para Latinoamérica: `southamerica-east1` (São Paulo)
5. Haz clic en **Habilitar**
6. Espera 1-2 minutos mientras se crea la base de datos

### C. Habilitar Storage (para imágenes)

1. En el menú lateral, ve a **Build → Storage**
2. Haz clic en **Comenzar** o **Get started**
3. **Reglas de seguridad**:
   - Selecciona **Empezar en modo de producción**
   - Haz clic en **Siguiente**
4. **Ubicación**:
   - Selecciona la misma ubicación que Firestore
5. Haz clic en **Listo**

---

## 5️⃣ Configurar Reglas de Seguridad

### A. Reglas de Firestore

1. Ve a **Firestore Database → Reglas**
2. Reemplaza todo el contenido con las siguientes reglas:

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

3. Haz clic en **Publicar**

### B. Reglas de Storage

1. Ve a **Storage → Reglas**
2. Reemplaza todo el contenido con:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
             firestore.get(/databases/(default)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }

    // Imágenes de productos (solo admins pueden subir)
    match /productos/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Imágenes del negocio (solo admins)
    match /negocio/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Imágenes de reseñas (usuarios autenticados)
    match /reseñas/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Imágenes de perfiles (usuarios autenticados)
    match /usuarios/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

3. Haz clic en **Publicar**

---

## 6️⃣ Crear Índices Compuestos

Los índices se crearán automáticamente cuando intentes hacer queries complejas, pero puedes crearlos manualmente:

1. Ve a **Firestore Database → Índices**
2. Haz clic en **Agregar índice** para cada uno:

### Índice 1: productos
- Colección: `productos`
- Campos:
  - `categoriaId` - Ascending
  - `disponible` - Ascending
  - `fechaCreacion` - Descending

### Índice 2: productos (destacados)
- Colección: `productos`
- Campos:
  - `destacado` - Ascending
  - `disponible` - Ascending

### Índice 3: pedidos
- Colección: `pedidos`
- Campos:
  - `clienteId` - Ascending
  - `fechaPedido` - Descending

### Índice 4: pedidos (por estado)
- Colección: `pedidos`
- Campos:
  - `estado` - Ascending
  - `fechaPedido` - Descending

### Índice 5: notificaciones
- Colección: `notificaciones`
- Campos:
  - `usuarioId` - Ascending
  - `leida` - Ascending
  - `fechaCreacion` - Descending

### Índice 6: reseñas
- Colección: `reseñas`
- Campos:
  - `productoId` - Ascending
  - `aprobada` - Ascending
  - `fechaCreacion` - Descending

---

## 7️⃣ Integrar con Flutter

### Paso 1: Instalar Firebase CLI

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Verificar instalación
firebase --version
```

### Paso 2: Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Paso 3: Iniciar sesión en Firebase

```bash
firebase login
```

### Paso 4: Configurar Firebase en el proyecto Flutter

```bash
# Desde la raíz del proyecto
cd "c:\Users\USUARIO\Documents\CLASES 2025-2\INGENIERIA DE SOFTWARE 2\Project\reposteria_arlex"

# Configurar Firebase
flutterfire configure
```

Selecciona:
1. El proyecto Firebase que creaste (`reposteria-arlex`)
2. Plataformas: Web (por ahora)

Esto creará el archivo `lib/firebase_options.dart` automáticamente.

### Paso 5: Agregar dependencias

Abre `pubspec.yaml` y agrega:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0

  # State Management
  provider: ^6.1.1
```

### Paso 6: Instalar dependencias

```bash
flutter pub get
```

### Paso 7: Inicializar Firebase en main.dart

Actualiza tu archivo `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

---

## 8️⃣ Datos Iniciales

### Crear Usuario Administrador Inicial

1. Ve a **Authentication → Users**
2. Haz clic en **Agregar usuario**
3. Ingresa:
   - **Email**: admin@reposteriaarlex.com
   - **Password**: (una contraseña segura)
4. Haz clic en **Agregar usuario**
5. **Copia el UID** que se genera

### Crear documento de usuario en Firestore

1. Ve a **Firestore Database → Datos**
2. Haz clic en **Iniciar colección**
3. **ID de colección**: `usuarios`
4. **ID del documento**: (pega el UID que copiaste)
5. Agrega los siguientes campos:

```
id: (el UID)
nombre: "Administrador"
email: "admin@reposteriaarlex.com"
telefono: "+573001234567"
rol: "admin"
estado: "activo"
emailVerificado: true
fechaCreacion: (timestamp actual)
fechaActualizacion: (timestamp actual)
ultimoAcceso: (timestamp actual)
preferencias: {
  notificaciones: true,
  newsletter: true
}
```

6. Haz clic en **Guardar**

### Crear Información del Negocio

1. En Firestore, haz clic en **Iniciar colección**
2. **ID de colección**: `informacion_negocio`
3. **ID del documento**: `config`
4. Agrega los campos básicos:

```
nombre: "Repostería Arlex"
slogan: "Endulzando tus momentos especiales"
email: "contacto@reposteriaarlex.com"
telefono: "+573001234567"
whatsapp: "+573001234567"
direccion: "Calle 123 #45-67, Ciudad"
horarioAtencion: {
  lunes_viernes: "8:00 AM - 6:00 PM",
  sabado: "9:00 AM - 5:00 PM",
  domingo: "Cerrado"
}
historia: "Tu historia aquí..."
mision: "Tu misión aquí..."
vision: "Tu visión aquí..."
valores: ["Calidad", "Compromiso", "Innovación"]
redesSociales: {
  facebook: "",
  instagram: "",
  tiktok: "",
  twitter: "",
  youtube: ""
}
configuracion: {
  aceptaPedidosOnline: true,
  tiempoPreparacionMinimo: 24,
  montoMinimoEnvio: 20,
  costoEnvio: 5,
  radiusEntregaKm: 10,
  iva: 0,
  aceptaReservas: true
}
fechaActualizacion: (timestamp actual)
actualizadoPor: (UID del admin)
```

5. Haz clic en **Guardar**

### Crear Categorías Iniciales

Repite el proceso para crear documentos en la colección `categorias`:

#### Categoría 1: Tortas
```
id: "cat_tortas"
nombre: "Tortas"
descripcion: "Deliciosas tortas para toda ocasión"
icono: "cake"
orden: 1
activa: true
fechaCreacion: (timestamp)
fechaActualizacion: (timestamp)
creadoPor: (UID admin)
```

#### Categoría 2: Galletas
```
id: "cat_galletas"
nombre: "Galletas"
descripcion: "Galletas artesanales crujientes"
icono: "cookie"
orden: 2
activa: true
fechaCreacion: (timestamp)
fechaActualizacion: (timestamp)
creadoPor: (UID admin)
```

#### Categoría 3: Postres
```
id: "cat_postres"
nombre: "Postres"
descripcion: "Exquisitos postres caseros"
icono: "emoji_food_beverage"
orden: 3
activa: true
fechaCreacion: (timestamp)
fechaActualizacion: (timestamp)
creadoPor: (UID admin)
```

#### Categoría 4: Pasteles
```
id: "cat_pasteles"
nombre: "Pasteles"
descripcion: "Pasteles individuales y porciones"
icono: "cake_outlined"
orden: 4
activa: true
fechaCreacion: (timestamp)
fechaActualizacion: (timestamp)
creadoPor: (UID admin)
```

#### Categoría 5: Bocaditos
```
id: "cat_bocaditos"
nombre: "Bocaditos"
descripcion: "Pequeños bocados dulces"
icono: "breakfast_dining"
orden: 5
activa: true
fechaCreacion: (timestamp)
fechaActualizacion: (timestamp)
creadoPor: (UID admin)
```

---

## ✅ Verificación Final

### Checklist de Configuración

- [ ] Proyecto Firebase creado
- [ ] App Web registrada
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore Database creado
- [ ] Storage habilitado
- [ ] Reglas de seguridad configuradas (Firestore y Storage)
- [ ] Índices compuestos creados
- [ ] Firebase CLI instalado
- [ ] FlutterFire CLI instalado
- [ ] `firebase_options.dart` generado
- [ ] Dependencias instaladas en Flutter
- [ ] Usuario admin creado
- [ ] Documento de información del negocio creado
- [ ] Categorías iniciales creadas

### Prueba de Conexión

Crea un archivo de prueba `lib/test_firebase.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> testFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  // Probar lectura de información del negocio
  final doc = await firestore.collection('informacion_negocio').doc('config').get();

  if (doc.exists) {
    print('✅ Firebase conectado correctamente');
    print('Nombre del negocio: ${doc.data()?['nombre']}');
  } else {
    print('❌ No se encontró la información del negocio');
  }
}
```

---

## 🚀 Próximos Pasos

1. **Crear servicios Firebase** en Flutter
2. **Implementar autenticación** con Firebase Auth
3. **Migrar datos** de mock a Firestore
4. **Configurar Cloud Functions** (opcional, para lógica backend)
5. **Configurar Firebase Hosting** (opcional, para deployment)

---

## 📞 Soporte

Si encuentras problemas:

1. **Documentación oficial**: [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
2. **FlutterFire**: [FlutterFire Documentation](https://firebase.flutter.dev/)
3. **StackOverflow**: Etiqueta `flutter` + `firebase`

---

## ⚠️ Recordatorios Importantes

1. **NUNCA** compartas las credenciales de Firebase en repositorios públicos
2. **SIEMPRE** usa variables de entorno para datos sensibles
3. **Configura** límites de lectura/escritura en Firebase Console (Presupuesto y alertas)
4. **Habilita** App Check para protección adicional en producción
5. **Mantén** actualizadas las dependencias de Firebase

---

**¡Firebase configurado exitosamente! 🎉**
