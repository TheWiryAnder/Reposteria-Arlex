# Guía para Crear Gráficos Dinámicos en Excel - Repostería Arlex

## 📊 Descripción General

Este documento explica cómo crear gráficos dinámicos en Microsoft Excel utilizando los datos exportados del sistema de Repostería Arlex.

## 📥 Exportación de Datos

### Cómo Descargar el Reporte

1. **Iniciar sesión** como **Administrador**
2. En el **Dashboard**, buscar la sección **"Accesos Rápidos"**
3. Hacer clic en **"Descargar Reporte Excel"** (ícono de descarga, color rojo)
4. El archivo se descargará automáticamente con el nombre: `Reporte_Reposteria_Arlex_YYYYMMDD_HHMMSS.xlsx`

## 📑 Estructura del Archivo Excel

El archivo contiene **6 hojas** con datos organizados:

### 1. **Productos**
- ID, Nombre, Categoría, Precio, Stock, Estado, Descripción
- Datos de todos los productos en el sistema

### 2. **Promociones**
- ID, Título, Descuento (%), Precio Original, Precio Descuento, Activa, Fechas
- Promociones activas e inactivas

### 3. **Pedidos**
- Número, Cliente, Total, Estado, Método de Pago, Fecha, Cantidad de Productos
- Historial completo de pedidos

### 4. **Usuarios**
- ID, Nombre, Email, Rol, Estado, Teléfono, Fecha de Registro
- Todos los usuarios del sistema

### 5. **Estadísticas**
- Resumen ejecutivo con métricas clave
- Total de pedidos, ventas, promedios
- Desglose por estado y método de pago

### 6. **Datos para Gráficos**
- Datos organizados específicamente para crear gráficos
- 4 secciones principales:
  - Ventas por Día
  - Pedidos por Estado
  - Ventas por Método de Pago
  - Productos con Bajo Stock

---

## 🎨 Cómo Crear Gráficos Dinámicos

### Gráfico 1: Ventas Diarias (Gráfico de Líneas)

**Datos a usar:** Hoja "Datos para Gráficos" → Sección "VENTAS POR DÍA"

#### Pasos:

1. **Seleccionar los datos:**
   - Columna A: Fecha
   - Columna B: Total Ventas (S/.)

2. **Insertar gráfico:**
   - Pestaña **"Insertar"**
   - Seleccionar **"Gráfico de Líneas"**
   - Elegir **"Líneas con marcadores"**

3. **Personalizar:**
   - **Título:** "Evolución de Ventas Diarias"
   - **Eje X:** "Fecha"
   - **Eje Y:** "Total Ventas (S/.)"
   - **Estilo:** Elegir colores corporativos (azul/rojo)

4. **Hacer el gráfico dinámico:**
   - Clic derecho en el gráfico → **"Seleccionar datos"**
   - Asegurarse de que el rango incluya celdas vacías para futuras fechas
   - Ejemplo: `='Datos para Gráficos'!$A$2:$B$100`

---

### Gráfico 2: Pedidos por Estado (Gráfico Circular)

**Datos a usar:** Hoja "Datos para Gráficos" → Sección "PEDIDOS POR ESTADO"

#### Pasos:

1. **Seleccionar los datos:**
   - Columna A: Estado (pendiente, completado, cancelado, etc.)
   - Columna B: Cantidad

2. **Insertar gráfico:**
   - Pestaña **"Insertar"**
   - Seleccionar **"Gráfico Circular"**
   - Elegir **"Circular 3D"** o **"Anillo"**

3. **Personalizar:**
   - **Título:** "Distribución de Pedidos por Estado"
   - **Etiquetas de datos:** Mostrar porcentajes
   - **Colores:**
     - Pendiente: Naranja
     - En proceso: Azul
     - Completado: Verde
     - Cancelado: Rojo

4. **Hacer el gráfico dinámico:**
   - Usar rango extensible: `='Datos para Gráficos'!$A$X:$B$Y`
   - Reemplazar X e Y con las filas correspondientes

---

### Gráfico 3: Ventas por Método de Pago (Gráfico de Barras)

**Datos a usar:** Hoja "Datos para Gráficos" → Sección "VENTAS POR MÉTODO DE PAGO"

#### Pasos:

1. **Seleccionar los datos:**
   - Columna A: Método de Pago (Efectivo, Tarjeta, Transferencia)
   - Columna B: Total (S/.)

2. **Insertar gráfico:**
   - Pestaña **"Insertar"**
   - Seleccionar **"Gráfico de Barras Horizontales"**
   - Elegir **"Barras agrupadas"**

3. **Personalizar:**
   - **Título:** "Ventas por Método de Pago"
   - **Eje X:** "Total (S/.)"
   - **Eje Y:** "Método de Pago"
   - **Formato de números:** Moneda (S/.)

4. **Agregar formato condicional:**
   - Colorear la barra más alta de verde
   - Usar degradados para mejor visualización

---

### Gráfico 4: Productos con Bajo Stock (Gráfico de Columnas)

**Datos a usar:** Hoja "Datos para Gráficos" → Sección "PRODUCTOS CON BAJO STOCK"

#### Pasos:

1. **Seleccionar los datos:**
   - Columna A: Producto
   - Columna B: Stock

2. **Insertar gráfico:**
   - Pestaña **"Insertar"**
   - Seleccionar **"Gráfico de Columnas"**
   - Elegir **"Columnas agrupadas"**

3. **Personalizar:**
   - **Título:** "Alerta: Productos con Stock Bajo (≤ 10 unidades)"
   - **Eje X:** "Producto"
   - **Eje Y:** "Stock Disponible"
   - **Color:** Rojo (indica alerta)

4. **Agregar línea de referencia:**
   - Insertar línea horizontal en Y=10 (umbral de bajo stock)
   - Color: Naranja punteado

---

## 📈 Creación de Tablas Dinámicas

### Tabla Dinámica 1: Ventas por Categoría

1. **Ir a la hoja "Productos"**
2. **Insertar Tabla Dinámica:**
   - Pestaña **"Insertar"** → **"Tabla Dinámica"**
   - Seleccionar todo el rango de datos
   - Nueva hoja de cálculo

3. **Configurar campos:**
   - **Filas:** Categoría
   - **Valores:** Precio (Suma)
   - **Valores:** Nombre (Contar)

4. **Resultado:**
   - Total de ingresos por categoría
   - Cantidad de productos por categoría

### Tabla Dinámica 2: Análisis de Pedidos por Cliente

1. **Ir a la hoja "Pedidos"**
2. **Insertar Tabla Dinámica**
3. **Configurar campos:**
   - **Filas:** Cliente Nombre
   - **Valores:** Total (Suma)
   - **Valores:** Número (Contar)

4. **Ordenar:**
   - Por total descendente
   - Identificar mejores clientes

---

## 🔄 Automatización con Macros (Opcional)

### Macro para Actualizar Todos los Gráficos

```vba
Sub ActualizarGraficos()
    Dim ws As Worksheet
    Dim cht As ChartObject

    ' Recorrer todas las hojas
    For Each ws In ThisWorkbook.Worksheets
        ' Recorrer todos los gráficos en cada hoja
        For Each cht In ws.ChartObjects
            cht.Chart.Refresh
        Next cht
    Next ws

    MsgBox "Todos los gráficos han sido actualizados", vbInformation
End Sub
```

**Para usar:**
1. Presionar **Alt + F11** (abrir editor VBA)
2. **Insertar** → **Módulo**
3. Pegar el código
4. Cerrar editor
5. Ejecutar desde **Ver** → **Macros** → **ActualizarGraficos**

---

## 💡 Consejos y Mejores Prácticas

### 1. **Formato de Fechas**
- Asegurarse de que Excel reconozca las fechas correctamente
- Formato recomendado: `dd/mm/yyyy`

### 2. **Rangos Dinámicos**
- Usar tablas de Excel (Ctrl + T) para rangos automáticos
- Los gráficos se actualizarán automáticamente

### 3. **Plantilla de Dashboard**
- Crear una hoja "Dashboard" nueva
- Copiar todos los gráficos ahí
- Organizarlos en un diseño limpio

### 4. **Actualización de Datos**
- Descargar nuevo reporte mensualmente
- Copiar y pegar los datos en la misma estructura
- Los gráficos se actualizarán automáticamente

### 5. **Exportar a PDF**
- Para presentaciones: **Archivo** → **Exportar** → **Crear PDF/XPS**
- Seleccionar solo la hoja "Dashboard"

---

## 📊 Ejemplo de Dashboard Completo

### Layout Recomendado:

```
┌─────────────────────────────────────────────────┐
│  DASHBOARD - REPOSTERÍA ARLEX                   │
│  Período: [Rango de fechas]                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐  ┌──────────────┐           │
│  │  Ventas por  │  │  Pedidos por │           │
│  │     Día      │  │    Estado    │           │
│  │  (Líneas)    │  │  (Circular)  │           │
│  └──────────────┘  └──────────────┘           │
│                                                 │
│  ┌──────────────┐  ┌──────────────┐           │
│  │  Ventas por  │  │  Stock Bajo  │           │
│  │ Método Pago  │  │  (Alerta)    │           │
│  │  (Barras)    │  │  (Columnas)  │           │
│  └──────────────┘  └──────────────┘           │
│                                                 │
│  ┌─────────────────────────────────┐          │
│  │  MÉTRICAS CLAVE                 │          │
│  │  • Total Ventas: S/. X,XXX      │          │
│  │  • Pedidos: XXX                 │          │
│  │  • Ticket Promedio: S/. XX      │          │
│  └─────────────────────────────────┘          │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Interpretación de Gráficos

### Gráfico de Ventas Diarias
- **Tendencia ascendente:** Crecimiento del negocio ✅
- **Picos:** Días con promociones o eventos especiales
- **Valles:** Días de baja demanda (optimizar inventario)

### Gráfico de Pedidos por Estado
- **Muchos "completados":** Buen servicio ✅
- **Muchos "pendientes":** Posible cuello de botella ⚠️
- **Muchos "cancelados":** Investigar causas ❌

### Gráfico de Ventas por Método de Pago
- **Efectivo dominante:** Considerar incentivos para pagos digitales
- **Diversificación:** Mejor flujo de caja

### Gráfico de Stock Bajo
- **Productos populares:** Aumentar stock
- **Reabastecer pronto:** Evitar pérdidas de venta

---

## 📞 Soporte

Si tienes problemas creando los gráficos:

1. Verificar que Excel esté actualizado
2. Asegurar que los datos se descargaron correctamente
3. Consultar tutoriales de Microsoft sobre gráficos dinámicos
4. Contactar al equipo técnico

---

## 🔄 Versiones y Actualizaciones

**Versión 1.0** - Diciembre 2024
- Implementación inicial del sistema de reportes
- 6 hojas de datos
- 4 tipos de gráficos recomendados

---

¡Con estos gráficos dinámicos podrás tomar mejores decisiones para Repostería Arlex! 🎂📊
