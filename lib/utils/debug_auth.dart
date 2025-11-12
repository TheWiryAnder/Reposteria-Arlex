import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider_simple.dart' as app_auth;

/// Utilidad para depurar problemas de autenticación
class DebugAuth {
  static Future<Map<String, dynamic>> verificarEstadoAutenticacion() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final authProvider = app_auth.AuthProvider.instance;
    final localUser = authProvider.currentUser;

    final resultado = {
      'firebaseAuthActivo': firebaseUser != null,
      'firebaseAuthUid': firebaseUser?.uid,
      'firebaseAuthEmail': firebaseUser?.email,
      'authProviderActivo': localUser != null,
      'authProviderUserId': localUser?.id,
      'authProviderEmail': localUser?.email,
      'coinciden': firebaseUser?.uid == localUser?.id,
    };

    print('═══════════════════════════════════════════════════════');
    print('DEBUG AUTH - Estado de Autenticación');
    print('═══════════════════════════════════════════════════════');
    print('Firebase Auth activo: ${resultado['firebaseAuthActivo']}');
    if (firebaseUser != null) {
      print('  - UID: ${firebaseUser.uid}');
      print('  - Email: ${firebaseUser.email}');
    }
    print('');
    print('AuthProvider activo: ${resultado['authProviderActivo']}');
    if (localUser != null) {
      print('  - User ID: ${localUser.id}');
      print('  - Email: ${localUser.email}');
      print('  - Nombre: ${localUser.nombre}');
    }
    print('');
    print('¿Los IDs coinciden? ${resultado['coinciden']}');
    print('═══════════════════════════════════════════════════════');

    return resultado;
  }

  static Future<void> imprimirDiagnostico() async {
    await verificarEstadoAutenticacion();
  }
}
