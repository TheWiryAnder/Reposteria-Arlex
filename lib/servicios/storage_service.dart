import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Servicio para gestionar el almacenamiento de imágenes en Firebase Storage
///
/// GUÍA DE USO:
///
/// 1. CONFIGURAR FIREBASE STORAGE (Solo una vez):
///    - Ve a Firebase Console: https://console.firebase.google.com
///    - Selecciona tu proyecto
///    - En el menú lateral, haz clic en "Storage"
///    - Haz clic en "Comenzar"
///    - Acepta las reglas de seguridad predeterminadas
///
/// 2. CREAR CARPETA DE PRODUCTOS (Recomendado):
///    - Una vez en Storage, verás tu bucket (gs://tu-proyecto.appspot.com)
///    - Haz clic en "Crear carpeta" y nómbrala "productos"
///    - Dentro de "productos" puedes crear subcarpetas por categoría si quieres:
///      - productos/tortas/
///      - productos/galletas/
///      - productos/postres/
///      etc.
///
/// 3. SUBIR IMÁGENES MANUALMENTE (Desde Firebase Console):
///    - Entra a la carpeta "productos"
///    - Haz clic en "Subir archivo"
///    - Selecciona la imagen de tu computadora
///    - Una vez subida, haz clic en la imagen
///    - Copia la URL de descarga (algo como: https://firebasestorage.googleapis.com/...)
///    - Pega esa URL en el campo "URL de imagen" al crear/editar un producto
///
/// 4. SUBIR IMÁGENES DESDE LA APP (Este servicio):
///    - Usa el selector de imágenes en la pantalla de agregar/editar producto
///    - Las imágenes se subirán automáticamente a Firebase Storage
///    - La URL se guardará automáticamente en el producto
///
/// 5. REGLAS DE SEGURIDAD RECOMENDADAS:
///    Ve a Storage > Reglas y usa estas reglas:
///    ```
///    rules_version = '2';
///    service firebase.storage {
///      match /b/{bucket}/o {
///        // Permitir lectura a todos
///        match /{allPaths=**} {
///          allow read: if true;
///        }
///
///        // Solo usuarios autenticados pueden subir/modificar/eliminar
///        match /productos/{allPaths=**} {
///          allow write: if request.auth != null;
///        }
///      }
///    }
///    ```
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Seleccionar imagen desde galería
  Future<File?> seleccionarImagenGaleria() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Calidad 85% para reducir tamaño sin perder mucha calidad
      );

      if (imagen != null) {
        return File(imagen.path);
      }
      return null;
    } catch (e) {
      throw Exception('Error al seleccionar imagen: $e');
    }
  }

  /// Seleccionar imagen desde cámara
  Future<File?> tomarFoto() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (imagen != null) {
        return File(imagen.path);
      }
      return null;
    } catch (e) {
      throw Exception('Error al tomar foto: $e');
    }
  }

  /// Subir imagen de producto a Firebase Storage
  ///
  /// [archivoImagen] - El archivo de imagen a subir
  /// [productoId] - ID del producto (se usa para nombrar el archivo)
  /// [categoria] - Categoría del producto (opcional, para organizar en carpetas)
  ///
  /// Retorna la URL de descarga de la imagen subida
  Future<String> subirImagenProducto({
    required File archivoImagen,
    required String productoId,
    String? categoria,
  }) async {
    try {
      // Obtener la extensión del archivo
      final extension = path.extension(archivoImagen.path);

      // Crear la ruta en Firebase Storage
      // Ejemplo: productos/tortas/prod_123.jpg
      String rutaStorage = 'productos/';

      if (categoria != null && categoria.isNotEmpty) {
        // Limpiar el nombre de la categoría para usar como carpeta
        final categoriaNormalizada = categoria
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        rutaStorage += '$categoriaNormalizada/';
      }

      rutaStorage += '$productoId$extension';

      // Referencia al archivo en Storage
      final Reference ref = _storage.ref().child(rutaStorage);

      // Metadatos de la imagen
      final metadata = SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {
          'productoId': productoId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Subir el archivo
      final UploadTask uploadTask = ref.putFile(archivoImagen, metadata);

      // Esperar a que termine la subida
      final TaskSnapshot snapshot = await uploadTask;

      // Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Eliminar imagen de producto
  ///
  /// [imagenUrl] - URL de la imagen a eliminar
  Future<bool> eliminarImagenProducto(String imagenUrl) async {
    try {
      if (imagenUrl.isEmpty) return false;

      // Obtener la referencia desde la URL
      final Reference ref = _storage.refFromURL(imagenUrl);

      // Eliminar el archivo
      await ref.delete();

      return true;
    } catch (e) {
      // Si el archivo no existe, considerarlo como éxito
      if (e.toString().contains('object-not-found')) {
        return true;
      }
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Actualizar imagen de producto (elimina la anterior y sube la nueva)
  ///
  /// [archivoNuevaImagen] - Archivo de la nueva imagen
  /// [productoId] - ID del producto
  /// [categoria] - Categoría del producto
  /// [imagenUrlAnterior] - URL de la imagen anterior (se eliminará)
  ///
  /// Retorna la URL de la nueva imagen
  Future<String> actualizarImagenProducto({
    required File archivoNuevaImagen,
    required String productoId,
    String? categoria,
    String? imagenUrlAnterior,
  }) async {
    try {
      // Eliminar la imagen anterior si existe
      if (imagenUrlAnterior != null && imagenUrlAnterior.isNotEmpty) {
        try {
          await eliminarImagenProducto(imagenUrlAnterior);
        } catch (e) {
          // Continuar aunque falle la eliminación de la imagen anterior
          // No es crítico si no se puede eliminar la imagen anterior
        }
      }

      // Subir la nueva imagen
      final nuevaUrl = await subirImagenProducto(
        archivoImagen: archivoNuevaImagen,
        productoId: productoId,
        categoria: categoria,
      );

      return nuevaUrl;
    } catch (e) {
      throw Exception('Error al actualizar imagen: $e');
    }
  }

  /// Obtener información de una imagen
  Future<Map<String, dynamic>?> obtenerInfoImagen(String imagenUrl) async {
    try {
      if (imagenUrl.isEmpty) return null;

      final Reference ref = _storage.refFromURL(imagenUrl);
      final FullMetadata metadata = await ref.getMetadata();

      return {
        'nombre': metadata.name,
        'tamaño': metadata.size,
        'tipo': metadata.contentType,
        'created': metadata.timeCreated,
        'updated': metadata.updated,
      };
    } catch (e) {
      return null;
    }
  }

  /// Listar todas las imágenes en una carpeta
  Future<List<String>> listarImagenesCategoria(String categoria) async {
    try {
      final categoriaNormalizada = categoria
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      final Reference ref = _storage.ref().child('productos/$categoriaNormalizada');
      final ListResult result = await ref.listAll();

      final List<String> urls = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      return [];
    }
  }
}
