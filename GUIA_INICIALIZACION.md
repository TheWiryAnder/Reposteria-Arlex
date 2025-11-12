# 🚀 Guía para Inicializar Datos en Firebase

## 📋 Pasos para Inicializar los Datos

### **Paso 1: Abrir la Terminal en VS Code**

1. En VS Code, abre la terminal integrada:
   - **Menú**: `Terminal` → `New Terminal`
   - **Atajo de teclado**: `Ctrl + Ñ` o `Ctrl + ~` (tecla debajo del ESC)

2. La terminal se abrirá automáticamente en el directorio de tu proyecto

### **Paso 2: Modificar temporalmente main.dart**

Abre el archivo `lib/main.dart` y busca la línea donde dice `home:`. Deberías ver algo como:

```dart
home: const AuthenticationWrapper(),
```

**Cámbialo temporalmente a:**

```dart
home: const FirebaseInitRunner(),
```

### **Paso 3: Ejecutar la Aplicación**

En la terminal que abriste, ejecuta:

```bash
flutter run -d chrome
```

**O simplemente presiona `F5` en VS Code**

### **Paso 4: Usar la Pantalla de Inicialización**

Cuando se abra la aplicación en Chrome, verás una pantalla con dos botones:

1. **Primero**, haz clic en **"Probar Conexión"**
   - Esto verificará que Firebase esté configurado correctamente
   - Deberías ver el mensaje "✅ Conexión exitosa a Firestore"

2. **Segundo**, haz clic en **"Inicializar Datos"**
   - Esto creará en Firebase:
     - ✅ 5 Categorías (Tortas, Galletas, Postres, Pasteles, Bocaditos)
     - ✅ 11 Productos de ejemplo con imágenes
     - ✅ 3 Promociones para el carrusel
     - ✅ Información del negocio

3. **Espera** a que aparezca el mensaje: "🎉 ¡Inicialización completada exitosamente!"

### **Paso 5: Revertir el cambio en main.dart**

Una vez que la inicialización esté completa:

1. Cierra la aplicación (Ctrl + C en la terminal o cierra la pestaña del navegador)

2. Vuelve a `lib/main.dart` y **revierte** el cambio:

```dart
home: const AuthenticationWrapper(),
```

3. Guarda el archivo

### **Paso 6: Ejecutar la Aplicación Normalmente**

Ahora ejecuta nuevamente:

```bash
flutter run -d chrome
```

**¡Listo!** Ahora verás:
- ✅ El carrusel con imágenes reales de Unsplash
- ✅ Productos recomendados desde Firebase
- ✅ Estadísticas reales (cuando haya datos)

---

## 🔍 Verificar los Datos en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **reposteria-arlex**
3. Ve a **Firestore Database**
4. Deberías ver las colecciones:
   - `categorias` (5 documentos)
   - `productos` (11 documentos)
   - `promociones` (3 documentos)
   - `informacion_negocio` (1 documento)

---

## ❌ Solución de Problemas

### "Error de conexión a Firestore"

**Solución:**
1. Verifica que Firestore esté habilitado en Firebase Console
2. Revisa las reglas de seguridad (deben permitir lectura/escritura)
3. Verifica tu conexión a internet

### "Ya existen datos en la base de datos"

**Solución:**
- Esto es normal si ya ejecutaste la inicialización antes
- Los datos no se duplicarán
- Si quieres reiniciar, elimina las colecciones manualmente desde Firebase Console

### "El comando flutter no se reconoce"

**Solución:**
1. Verifica que Flutter esté instalado: `flutter --version`
2. Si no está instalado, sigue la [guía de instalación de Flutter](https://docs.flutter.dev/get-started/install)

---

## 📝 Notas Importantes

- ⚠️ **Solo ejecuta la inicialización UNA VEZ**
- ✅ Los datos incluyen imágenes reales de Unsplash
- ✅ Las estadísticas se generan automáticamente cuando hay pedidos
- ✅ El carrusel ya está conectado a Firebase (no usa datos hardcodeados)

---

## 🎯 Próximos Pasos

Después de inicializar los datos:

1. **Crear un usuario administrador** en Firebase Console:
   - Ve a Authentication → Users → Add user
   - Email: `admin@reposteriaarlex.com`
   - Password: (tu contraseña)
   - Copia el UID del usuario

2. **Crear el documento de usuario en Firestore**:
   - Ve a Firestore → Colección `usuarios`
   - Crea un documento con el UID copiado
   - Campos:
     - `email`: admin@reposteriaarlex.com
     - `nombre`: Administrador
     - `rol`: admin
     - `estado`: activo
     - `createdAt`: (timestamp actual)
     - `updatedAt`: (timestamp actual)

3. **Iniciar sesión** con ese usuario en la aplicación

---

**¡Disfruta tu aplicación con datos reales de Firebase! 🎉**
