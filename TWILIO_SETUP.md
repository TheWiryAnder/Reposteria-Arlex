# Configuración de Twilio para envío de SMS

## Paso 1: Crear cuenta en Twilio

1. Ve a [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
2. Regístrate con tu correo electrónico
3. Verifica tu número de teléfono personal
4. Completa el cuestionario inicial (selecciona "SMS" como caso de uso)

## Paso 2: Obtener credenciales de Twilio

Una vez en el Dashboard de Twilio:

1. **Account SID**: Lo encuentras en el Dashboard principal
2. **Auth Token**: También está en el Dashboard (haz clic en "Show" para verlo)
3. **Número de teléfono Twilio**:
   - Ve a "Phone Numbers" → "Manage" → "Buy a number"
   - Filtra por país (Perú o cualquier país que permita enviar SMS a Perú)
   - Compra un número (cuesta aprox. $1/mes)
   - **Nota**: En la cuenta de prueba, puedes enviar SMS solo a números verificados

## Paso 3: Verificar números de destino (solo para cuenta de prueba)

Si usas la cuenta gratuita de prueba:

1. Ve a "Phone Numbers" → "Manage" → "Verified Caller IDs"
2. Agrega tu número personal peruano (+51xxxxxxxxx)
3. Twilio te enviará un código de verificación
4. Ingresa el código para verificar el número

**Nota**: Con la cuenta de prueba solo puedes enviar SMS a números verificados. Para enviar a cualquier número, necesitas:
- Actualizar a cuenta de pago ($0 de costo inicial, solo pagas por uso)
- El costo es aproximadamente $0.0075 USD por SMS enviado

## Paso 4: Configurar credenciales en Firebase

Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
# Configurar Account SID
firebase functions:config:set twilio.account_sid="TU_ACCOUNT_SID_AQUI"

# Configurar Auth Token
firebase functions:config:set twilio.auth_token="TU_AUTH_TOKEN_AQUI"

# Configurar número de teléfono Twilio
firebase functions:config:set twilio.phone_number="+15551234567"
```

Reemplaza los valores con tus credenciales reales de Twilio.

## Paso 5: Desplegar Cloud Function

```bash
firebase deploy --only functions
```

## Paso 6: Probar el envío de SMS

Una vez desplegada la función, prueba el flujo de recuperación de contraseña:

1. Ve a la pantalla de recuperación de contraseña
2. Ingresa un email registrado
3. Haz clic en "Enviar código al teléfono"
4. Deberías recibir el SMS con el código de 6 dígitos

## Costos de Twilio

- **Cuenta de prueba**: Gratis, pero solo puede enviar SMS a números verificados
- **Cuenta de pago**:
  - Sin costo de activación
  - ~$0.0075 USD por SMS enviado a Perú
  - ~$1 USD/mes por mantener el número de teléfono

## Solución de problemas

### Error: "Unverified numbers"
- Verifica el número de destino en Twilio Console
- O actualiza a cuenta de pago

### Error: "Invalid credentials"
- Verifica que copiaste correctamente el Account SID y Auth Token
- Vuelve a ejecutar los comandos `firebase functions:config:set`

### Error: "Forbidden region"
- Algunos números de Twilio no pueden enviar SMS a ciertos países
- Compra un número que explícitamente permita enviar SMS a Perú

### Ver logs de la Cloud Function
```bash
firebase functions:log
```

## Referencias

- [Documentación de Twilio SMS](https://www.twilio.com/docs/sms)
- [Precios de Twilio](https://www.twilio.com/pricing/messaging)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
