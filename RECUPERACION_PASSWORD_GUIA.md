# Sistema de Recuperación de Contraseña

## Resumen

Se ha implementado un sistema completo de recuperación de contraseña en 3 pasos:

1. **Verificación de Email**: El usuario ingresa su email y el sistema verifica que exista
2. **Código de Validación**: Se genera un código de 6 dígitos que se guarda en Firestore
3. **Nueva Contraseña**: El usuario ingresa su nueva contraseña

## Funcionamiento Actual (Modo Desarrollo)

### ¿Cómo funciona ahora?

Actualmente, el sistema está configurado para **modo de desarrollo**. Esto significa:

1. ✅ El usuario ingresa su email
2. ✅ El sistema verifica que el email exista en la base de datos
3. ✅ Se genera un código de 6 dígitos aleatorio
4. ✅ El código se guarda en Firestore en el campo `codigoValidacion`
5. 📱 **El código se muestra en un diálogo emergente** para que el usuario pueda verlo
6. 🔍 El código también aparece en la consola del navegador (F12)
7. ✅ El usuario ingresa el código y lo verifica
8. ✅ El usuario establece su nueva contraseña
9. ✅ Al iniciar sesión nuevamente, la contraseña se actualiza automáticamente

### ¿Por qué no se envía por SMS?

El envío de SMS real requiere:
- Configurar un servicio de terceros (Twilio, MessageBird, etc.)
- Costos por cada SMS enviado (~$0.0075 USD por mensaje)
- Proceso de verificación de la cuenta
- Configuración de Cloud Functions en Firebase

## Cómo Usar el Sistema Actual

### Para el Usuario:

1. En la pantalla de login, hacer clic en **"¿Olvidaste tu contraseña?"**
2. Ingresar el email de la cuenta
3. Hacer clic en **"Verificar email"**
4. El sistema mostrará el número de teléfono registrado (parcialmente oculto)
5. Hacer clic en **"Enviar código al teléfono"**
6. **Aparecerá un diálogo con el código de 6 dígitos** en grande
7. Copiar ese código e ingresarlo en el campo correspondiente
8. Hacer clic en **"Verificar código"**
9. Ingresar la nueva contraseña dos veces
10. Hacer clic en **"Cambiar contraseña"**
11. Regresar al login e iniciar sesión con la nueva contraseña

### Para el Desarrollador/Admin:

Si no aparece el diálogo con el código, puedes verlo en:
1. Presiona **F12** para abrir la consola del navegador
2. Busca el mensaje que dice:
   ```
   📱 CÓDIGO DE VALIDACIÓN
   Teléfono: +51xxxxxxxxx
   Código: 123456
   ```

## Archivos Modificados

### 1. [web/index.html](web/index.html)
- Agregado soporte para reCAPTCHA (requerido por Firebase Phone Auth)
- Agregado contenedor `<div id="recaptcha-container"></div>`

### 2. [lib/servicios/recuperacion_password_service.dart](lib/servicios/recuperacion_password_service.dart)
Métodos principales:
- `generarCodigoParaUsuario()`: Genera código de 6 dígitos y lo guarda en Firestore
- `enviarCodigoPorSMS()`: Muestra el código en consola y retorna éxito
- `verificarCodigo()`: Verifica que el código ingresado sea correcto
- `cambiarPassword()`: Guarda la nueva contraseña temporalmente
- `aplicarNuevaPassword()`: Aplica la nueva contraseña en Firebase Auth

### 3. [lib/pantallas/auth/recuperar_password_vista.dart](lib/pantallas/auth/recuperar_password_vista.dart)
- Interfaz de usuario con 3 pasos
- Método `_mostrarDialogoCodigoEnConsola()`: Muestra el código en un diálogo grande
- Validación de formularios
- Manejo de errores

### 4. [lib/modelos/usuario_modelo.dart](lib/modelos/usuario_modelo.dart)
Campos agregados:
- `codigoValidacion`: Almacena el código de 6 dígitos
- `nuevaPasswordTemporal`: Almacena la contraseña temporal

### 5. [firestore.rules](firestore.rules)
Reglas de seguridad que permiten:
- Actualizar `codigoValidacion` sin autenticación
- Actualizar `nuevaPasswordTemporal` sin autenticación
- Solo permite modificar estos campos específicos

## Migrar a SMS Real (Producción)

### Opción 1: Twilio (Recomendado)

Los archivos ya están preparados:
- [functions/index.js](functions/index.js): Cloud Function lista para Twilio
- [TWILIO_SETUP.md](TWILIO_SETUP.md): Guía completa de configuración

**Pasos para activar**:
1. Crear cuenta en Twilio
2. Obtener credenciales (Account SID, Auth Token, Phone Number)
3. Configurar en Firebase:
   ```bash
   firebase functions:config:set twilio.account_sid="AC..."
   firebase functions:config:set twilio.auth_token="..."
   firebase functions:config:set twilio.phone_number="+1..."
   ```
4. Desplegar: `firebase deploy --only functions`
5. Modificar `enviarCodigoPorSMS()` en `recuperacion_password_service.dart` para llamar a la Cloud Function

### Opción 2: Firebase Phone Authentication

Firebase ofrece envío de SMS pero tiene limitaciones:
- ❌ Perú está bloqueado por defecto (región de alto fraude)
- Requiere verificación de negocio
- Costos similares a Twilio

### Opción 3: Otros Proveedores

Alternativas a Twilio:
- **MessageBird**: Similar a Twilio
- **Vonage (Nexmo)**: Buena cobertura en Latinoamérica
- **AWS SNS**: Si ya usas AWS

## Seguridad

✅ **Implementaciones de Seguridad**:
1. El código expira al ser usado (se borra de Firestore)
2. Solo se pueden actualizar campos específicos sin autenticación
3. La contraseña temporal se elimina después de aplicarse
4. El código es aleatorio de 6 dígitos (1 millón de combinaciones)
5. El email no puede cambiar durante la recuperación

⚠️ **Mejoras Recomendadas para Producción**:
1. Agregar expiración de tiempo al código (ej: 5 minutos)
2. Limitar intentos de verificación (máximo 3 intentos)
3. Agregar rate limiting para evitar spam
4. Implementar CAPTCHA antes de enviar código

## Testing

### Usuarios de Prueba

Para probar el sistema:
1. Asegúrate de tener un usuario registrado con email y teléfono
2. Cierra sesión
3. Haz clic en "¿Olvidaste tu contraseña?"
4. Sigue el flujo de recuperación

### Verificar en Firestore

Puedes ver el código generado en Firebase Console:
1. Ve a Firestore Database
2. Colección `usuarios`
3. Busca el documento del usuario
4. Verás el campo `codigoValidacion` con el código de 6 dígitos

## Preguntas Frecuentes

### ¿Por qué usar un diálogo en lugar de enviar SMS real?

Para desarrollo y pruebas, es más económico y práctico mostrar el código directamente. En producción, solo necesitas cambiar el método `enviarCodigoPorSMS()`.

### ¿El usuario puede usar la misma contraseña?

Sí, Firebase Auth lo permite. Sin embargo, podrías agregar validación para evitarlo.

### ¿Qué pasa si el usuario nunca usa el código?

El código permanece en Firestore hasta que:
- El usuario lo use exitosamente
- Se genere un nuevo código (reemplaza al anterior)
- Lo borres manualmente (recomendado agregar expiración automática)

### ¿Cómo agrego expiración al código?

Modifica `generarCodigoParaUsuario()` para agregar un timestamp:
```dart
await _firestore.collection('usuarios').doc(usuarioDoc.id).update({
  'codigoValidacion': codigo,
  'codigoExpiracion': DateTime.now().add(Duration(minutes: 5)),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

Luego en `verificarCodigo()`, valida que no haya expirado.

## Soporte

Para problemas o dudas:
1. Revisa la consola del navegador (F12) para ver mensajes de error
2. Verifica que Firebase esté correctamente configurado
3. Confirma que las reglas de Firestore estén desplegadas
4. Revisa los logs de Firebase Console

## Estado Actual

✅ **Funcional en Desarrollo**
- Sistema completo de recuperación de contraseña
- Código visible en diálogo emergente
- Validación de código funcional
- Cambio de contraseña exitoso

🚧 **Pendiente para Producción**
- Configurar Twilio o proveedor de SMS
- Agregar expiración de códigos
- Implementar rate limiting
- Agregar límite de intentos fallidos
