# 🚀 Instrucciones para Inicializar Firebase

## Paso 1: Ejecutar la aplicación

```bash
flutter run -d chrome
```

## Paso 2: Usar la pantalla de inicialización

1. Click en **"Probar Conexión"** primero
2. Si la conexión es exitosa, click en **"Inicializar Datos"**
3. Espera a que aparezca el mensaje de éxito

## Paso 3: Verificar en Firebase Console

Ve a https://console.firebase.google.com/project/reposteria-arlex/firestore

Deberías ver:
- ✅ Colección `categorias` con 5 documentos
- ✅ Colección `informacion_negocio` con 1 documento
- ✅ Colección `productos` con 4 documentos

## Paso 4: Revertir los cambios en main.dart

Abre `lib/main.dart` y cambia estas líneas:

**ANTES (temporal):**
```dart
home: const FirebaseInitRunner(), // TEMPORAL: Para inicializar
// home: const AuthenticationWrapper(), // ORIGINAL: Descomentar después de inicializar
```

**DESPUÉS (final):**
```dart
// home: const FirebaseInitRunner(), // TEMPORAL: Comentar después de inicializar
home: const AuthenticationWrapper(), // ORIGINAL: Descomentar después de inicializar
```

También puedes eliminar el import:
```dart
// import 'utils/firebase_init_runner.dart'; // Ya no es necesario
```

## Paso 5: Crear Usuario Administrador

### Opción A: Desde Firebase Console (Recomendado)

1. Ve a Firebase Console → Authentication → Users
2. Click en "Add user"
3. Email: `admin@reposteriaarlex.com` (o el que prefieras)
4. Password: Una contraseña segura
5. Click en "Add user"
6. **COPIA EL UID** del usuario creado

Luego, ve a Firestore:
1. Abre la colección `usuarios`
2. Click en "Add document"
3. Document ID: Pega el UID copiado
4. Agrega estos campos:
   ```
   email: admin@reposteriaarlex.com
   nombre: Administrador
   rol: admin
   estado: activo
   telefono: +573001234567 (opcional)
   fechaCreacion: [timestamp]
   fechaActualizacion: [timestamp]
   ```
5. Click en "Save"

### Opción B: Desde la App (después de revertir main.dart)

1. Ejecuta la app
2. Ve a "Registro"
3. Crea una cuenta
4. Ve a Firebase Console → Firestore → usuarios
5. Encuentra tu usuario y cambia `rol` a `admin`

## Paso 6: Probar el Login

1. Ejecuta la app: `flutter run -d chrome`
2. Haz login con el usuario admin creado
3. Deberías ver el dashboard de administración

## ✅ Checklist Final

- [ ] Aplicación ejecutada
- [ ] Conexión a Firebase probada
- [ ] Datos inicializados (categorías, info negocio, productos)
- [ ] Datos verificados en Firebase Console
- [ ] main.dart revertido a AuthenticationWrapper
- [ ] Usuario admin creado en Authentication
- [ ] Documento de usuario admin creado en Firestore
- [ ] Login exitoso con usuario admin
- [ ] Acceso al dashboard de administración

## 🆘 Problemas Comunes

### Error: "Permission denied"
- Verifica que las reglas de Firestore estén publicadas
- Verifica que el usuario esté autenticado

### Error: "Collection already exists"
- Los datos ya fueron inicializados anteriormente
- Puedes eliminar las colecciones desde Firebase Console si quieres reinicializar

### No puedo hacer login
- Verifica que el usuario exista en Authentication
- Verifica que el documento del usuario exista en Firestore
- Verifica que el rol sea "admin", "empleado" o "cliente"

---

**¡Listo! Tu base de datos Firebase está inicializada y lista para usar! 🎉**
