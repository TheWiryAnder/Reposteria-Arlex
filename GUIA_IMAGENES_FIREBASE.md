# Guía: Gestión de Imágenes para Productos

⚠️ **NOTA IMPORTANTE**: Esta guía describe cómo usar Firebase Storage, pero requiere el Plan Blaze (tarjeta de crédito).

**Para usar imágenes SIN tarjeta de crédito**, consulta la guía:
📄 **[GUIA_IMAGENES_IMGBB.md](GUIA_IMAGENES_IMGBB.md)** ← **RECOMENDADO (100% GRATIS)**

---

Esta guía te explica cómo configurar y usar Firebase Storage para almacenar las imágenes de tus productos de repostería (Requiere Plan Blaze).

## 📋 Tabla de Contenidos

1. [Configuración Inicial de Firebase Storage](#1-configuración-inicial-de-firebase-storage)
2. [Opción 1: Subir imágenes desde la aplicación](#2-opción-1-subir-imágenes-desde-la-aplicación)
3. [Opción 2: Subir imágenes desde Firebase Console](#3-opción-2-subir-imágenes-desde-firebase-console)
4. [Estructura de carpetas recomendada](#4-estructura-de-carpetas-recomendada)
5. [Reglas de seguridad](#5-reglas-de-seguridad)
6. [Solución de problemas](#6-solución-de-problemas)

---

## 1. Configuración Inicial de Firebase Storage

### Paso 1.1: Activar Firebase Storage

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto: **reposteria_arlex** (o el nombre de tu proyecto)
3. En el menú lateral izquierdo, busca **"Compilación"** → **"Storage"**
4. Haz clic en **"Comenzar"**
5. Selecciona **"Iniciar en modo de producción"** (configuraremos las reglas después)
6. Selecciona la ubicación más cercana a ti (ejemplo: `southamerica-east1` para Sudamérica)
7. Haz clic en **"Listo"**

¡Listo! Ahora tienes Firebase Storage activado.

---

## 2. Opción 1: Subir imágenes desde la aplicación

Esta es la forma **más fácil y recomendada**.

### Cómo funciona:

1. **Desde tu app Flutter**:
   - Ve a la sección de administración
   - Entra a **"Gestionar Productos"**
   - Haz clic en **"Agregar Producto"** o edita un producto existente
   - En la sección **"Imagen del Producto"**, haz clic en **"Agregar Imagen"**

2. **Opciones disponibles**:
   - **Seleccionar de Galería**: Elige una foto de tu dispositivo
   - **Tomar Foto**: Abre la cámara para tomar una foto nueva
   - **Ingresar URL**: Si ya tienes una imagen en internet, pega la URL

3. **Proceso automático**:
   - La imagen se sube automáticamente a Firebase Storage
   - Se guarda en: `productos/[categoria]/[id_producto].jpg`
   - La URL se guarda automáticamente en Firestore
   - ¡Ya está! La imagen aparecerá en tu catálogo

### Ventajas:
- ✅ Súper fácil, no necesitas conocimientos técnicos
- ✅ Todo se hace desde tu teléfono o computadora
- ✅ Las imágenes se organizan automáticamente
- ✅ No necesitas copiar y pegar URLs

---

## 3. Opción 2: Subir imágenes desde Firebase Console

Si prefieres subir las imágenes manualmente desde la web:

### Paso 3.1: Crear estructura de carpetas

1. Ve a [Firebase Console](https://console.firebase.google.com) → Tu proyecto → **Storage**
2. Verás tu bucket principal (algo como: `gs://reposteria-arlex.appspot.com`)
3. Haz clic en **"Crear carpeta"** → Nómbrala **"productos"**
4. Dentro de **"productos"**, crea subcarpetas para cada categoría:
   - `tortas`
   - `galletas`
   - `postres`
   - `pasteles`
   - `bocaditos`
   - `gaseosas`

### Paso 3.2: Subir una imagen

1. Entra a la carpeta de la categoría (ejemplo: `productos/tortas/`)
2. Haz clic en **"Subir archivo"**
3. Selecciona la imagen de tu computadora
4. Espera a que termine de subir

### Paso 3.3: Obtener la URL

1. Haz clic en la imagen que acabas de subir
2. Busca el campo **"URL de acceso de tokens"** o **"Token access URL"**
3. Copia esa URL completa (ejemplo: `https://firebasestorage.googleapis.com/v0/b/reposteria-arlex.appspot.com/o/productos%2Ftortas%2Ftorta-chocolate.jpg?alt=media&token=...`)

### Paso 3.4: Pegar la URL en el producto

1. En tu app, ve a **Gestionar Productos**
2. Crea o edita un producto
3. Haz clic en **"Agregar Imagen"** → **"Ingresar URL"**
4. Pega la URL que copiaste
5. Guarda el producto

### Ventajas:
- ✅ Útil si tienes muchas imágenes y quieres subirlas todas de una vez
- ✅ Puedes organizarlas en tu computadora primero

---

## 4. Estructura de carpetas recomendada

```
Firebase Storage
└── productos/
    ├── tortas/
    │   ├── prod_1234567890.jpg
    │   ├── prod_1234567891.jpg
    │   └── ...
    ├── galletas/
    │   ├── prod_1234567892.jpg
    │   └── ...
    ├── postres/
    │   └── ...
    ├── pasteles/
    │   └── ...
    ├── bocaditos/
    │   └── ...
    └── gaseosas/
        └── ...
```

**Notas**:
- Cada imagen se nombra automáticamente con el ID del producto
- Las carpetas se crean automáticamente cuando subes desde la app
- Formatos recomendados: JPG, PNG, WebP
- Tamaño recomendado: Máximo 2 MB por imagen

---

## 5. Reglas de seguridad

Para que todo funcione correctamente y de forma segura, configura estas reglas:

### Paso 5.1: Ir a Reglas

1. Firebase Console → Storage → **Reglas** (pestaña superior)

### Paso 5.2: Pegar estas reglas

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Permitir lectura a TODOS (para que los clientes vean las imágenes)
    match /{allPaths=**} {
      allow read: if true;
    }

    // Solo usuarios autenticados pueden subir/modificar/eliminar imágenes
    match /productos/{allPaths=**} {
      allow write: if request.auth != null;
    }
  }
}
```

### Paso 5.3: Publicar

1. Haz clic en **"Publicar"** o **"Publish"**

### ¿Qué hacen estas reglas?

- **`allow read: if true`**: Cualquiera puede ver las imágenes (necesario para tu catálogo público)
- **`allow write: if request.auth != null`**: Solo usuarios autenticados (admin/empleados) pueden subir imágenes

---

## 6. Solución de problemas

### ❌ Error: "No tienes permisos para subir archivos"

**Solución**: Revisa las reglas de seguridad (Sección 5). Asegúrate de que estés autenticado en la app.

### ❌ Error: "Error al cargar imagen"

**Causas posibles**:
1. La URL está incorrecta o incompleta
2. La imagen fue eliminada de Firebase Storage
3. Las reglas de seguridad bloquean la lectura

**Solución**:
1. Verifica que la URL comience con `https://firebasestorage.googleapis.com/...`
2. Verifica que la imagen exista en Firebase Console
3. Revisa las reglas de seguridad

### ❌ La imagen no aparece en el catálogo

**Solución**:
1. Verifica que guardaste el producto después de agregar la imagen
2. Recarga la app (ciérrala y ábrela de nuevo)
3. Verifica que el producto esté marcado como "Disponible"

### ❌ Error: "Permission denied" al subir imagen

**Solución**:
1. Asegúrate de estar iniciado sesión como admin o empleado
2. Verifica las reglas de seguridad (deben permitir `write` para usuarios autenticados)

### ❌ Las imágenes tardan mucho en cargar

**Solución**:
1. Reduce el tamaño de tus imágenes antes de subirlas (máximo 2 MB)
2. Usa formatos optimizados como WebP o JPEG con calidad 80-85%
3. Verifica tu conexión a internet

---

## 📊 Plan Gratuito de Firebase Storage

No te preocupes por los costos. El plan gratuito incluye:

- **Almacenamiento**: 5 GB gratis
- **Descargas**: 1 GB por día gratis
- **Operaciones**: 50,000 operaciones por día

**¿Es suficiente?**
- 5 GB = Aproximadamente **10,000 a 25,000 imágenes** de productos
- 1 GB/día = Aproximadamente **2,000 a 5,000 visitas** al catálogo por día

Para un negocio de repostería, esto es **MÁS que suficiente**.

---

## 💡 Consejos y Mejores Prácticas

1. **Optimiza tus imágenes antes de subirlas**:
   - Usa herramientas como [TinyPNG](https://tinypng.com/) o [Squoosh](https://squoosh.app/)
   - Tamaño recomendado: 1000x1000 píxeles
   - Peso recomendado: 200-500 KB por imagen

2. **Nombra tus archivos de forma descriptiva** (si subes manualmente):
   - ✅ `torta-chocolate-3-leches.jpg`
   - ❌ `IMG_1234.jpg`

3. **Haz backup de tus imágenes**:
   - Guarda una copia en tu computadora
   - Firebase Storage es confiable, pero siempre es bueno tener respaldo

4. **Usa imágenes de buena calidad**:
   - Buena iluminación
   - Fondo limpio y profesional
   - Muestra el producto claramente

---

## 🎯 Resumen Rápido

### Para empezar a usar imágenes HOY:

1. ✅ Activa Firebase Storage en Firebase Console
2. ✅ Configura las reglas de seguridad (copia y pega del punto 5)
3. ✅ Desde tu app: **Gestionar Productos** → **Agregar Producto** → **Agregar Imagen**
4. ✅ Selecciona una foto de tu galería
5. ✅ ¡Listo! La imagen se sube automáticamente

---

## 🆘 ¿Necesitas ayuda?

Si tienes problemas:

1. Revisa la sección **Solución de problemas** (punto 6)
2. Verifica que Firebase Storage esté activado en tu proyecto
3. Asegúrate de que las reglas de seguridad estén configuradas
4. Verifica que estés autenticado como admin o empleado

---

**Última actualización**: 2025-10-24
**Versión**: 1.0
