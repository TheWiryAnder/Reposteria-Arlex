import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'init_firebase_data.dart';

/// Pantalla para ejecutar la inicialización de datos de Firebase
/// Esta es una pantalla temporal que se puede usar para inicializar la base de datos
class FirebaseInitRunner extends StatefulWidget {
  const FirebaseInitRunner({super.key});

  @override
  State<FirebaseInitRunner> createState() => _FirebaseInitRunnerState();
}

class _FirebaseInitRunnerState extends State<FirebaseInitRunner> {
  bool _isInitializing = false;
  bool _isCompleted = false;
  String _message = '';
  List<String> _logs = [];

  Future<void> _initializeFirebase() async {
    setState(() {
      _isInitializing = true;
      _logs.clear();
      _message = 'Iniciando...';
    });

    try {
      // Verificar si ya hay datos
      _addLog('🔍 Verificando estado de la base de datos...');
      final hasDatos = await InitFirebaseData.yaTieneDatos();

      if (hasDatos) {
        _addLog('⚠️ Ya existen datos en la base de datos');
        _addLog('Si deseas reinicializar, primero elimina los datos desde Firebase Console');
        setState(() {
          _message = 'La base de datos ya tiene datos';
          _isInitializing = false;
        });
        return;
      }

      _addLog('✅ Base de datos vacía, procediendo con la inicialización...');

      // Crear categorías
      _addLog('📁 Creando categorías...');
      await InitFirebaseData.crearCategorias();
      _addLog('✅ Categorías creadas');

      // Crear información del negocio
      _addLog('🏪 Creando información del negocio...');
      await InitFirebaseData.crearInformacionNegocio();
      _addLog('✅ Información del negocio creada');

      // Crear productos de ejemplo
      _addLog('🍰 Creando productos de ejemplo...');
      await InitFirebaseData.crearProductosEjemplo();
      _addLog('✅ Productos de ejemplo creados');

      _addLog('');
      _addLog('🎉 ¡Inicialización completada exitosamente!');
      _addLog('');
      _addLog('📝 Próximos pasos:');
      _addLog('1. Ve a Firebase Console > Authentication');
      _addLog('2. Crea un usuario administrador con el email de tu elección');
      _addLog('3. Ve a Firestore > Colección "usuarios"');
      _addLog('4. Crea un documento con el UID del usuario');
      _addLog('5. Agrega los campos: email, nombre, rol="admin", estado="activo"');

      setState(() {
        _message = '¡Inicialización completada!';
        _isCompleted = true;
        _isInitializing = false;
      });
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() {
        _message = 'Error en la inicialización';
        _isInitializing = false;
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isInitializing = true;
      _logs.clear();
      _message = 'Probando conexión...';
    });

    try {
      _addLog('🔗 Probando conexión a Firestore...');

      final firestore = FirebaseFirestore.instance;

      // Intentar leer una colección
      final snapshot = await firestore.collection('categorias').limit(1).get();

      _addLog('✅ Conexión exitosa a Firestore');
      _addLog('📊 Documentos en "categorias": ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        _addLog('💡 La colección está vacía, puedes ejecutar la inicialización');
      } else {
        _addLog('ℹ️ Ya hay datos en la colección');
      }

      setState(() {
        _message = 'Conexión exitosa';
        _isInitializing = false;
      });
    } catch (e) {
      _addLog('❌ Error de conexión: $e');
      _addLog('');
      _addLog('💡 Posibles soluciones:');
      _addLog('1. Verifica que Firestore esté habilitado en Firebase Console');
      _addLog('2. Verifica las reglas de seguridad de Firestore');
      _addLog('3. Verifica tu conexión a internet');

      setState(() {
        _message = 'Error de conexión';
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicialización de Firebase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Inicialización',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message.isEmpty ? 'Listo para inicializar' : _message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_isInitializing)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInitializing ? null : _testConnection,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Probar Conexión'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInitializing || _isCompleted ? null : _initializeFirebase,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Inicializar Datos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Logs:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No hay logs todavía',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
