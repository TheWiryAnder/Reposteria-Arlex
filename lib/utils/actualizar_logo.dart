import 'package:cloud_firestore/cloud_firestore.dart';

/// Script temporal para actualizar el logo en Firebase
Future<void> actualizarLogoEnFirebase() async {
  try {
    print('📝 Actualizando logo en Firebase...');

    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection('informacion_negocio')
        .doc('config')
        .update({
      'logo': 'https://i.imgur.com/NwgQZo6.jpeg',
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': 'sistema',
    });

    print('✅ Logo actualizado exitosamente en Firebase');
    print('URL del logo: https://i.imgur.com/NwgQZo6.jpeg');
  } catch (e) {
    print('❌ Error al actualizar logo: $e');
  }
}
