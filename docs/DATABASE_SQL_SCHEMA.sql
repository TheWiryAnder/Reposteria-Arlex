-- ============================================================================
-- BASE DE DATOS RELACIONAL SQL - REPOSTERÍA ARLEX
-- ============================================================================
-- Este script SQL es una representación relacional de la estructura Firebase
-- Para propósitos de visualización y comprensión de las relaciones
-- ============================================================================

-- ============================================================================
-- 1. TABLA: usuarios
-- Almacena información de todos los usuarios del sistema
-- ============================================================================
CREATE TABLE usuarios (
    id VARCHAR(128) PRIMARY KEY,                -- UID de Firebase Auth
    nombre VARCHAR(255) NOT NULL,               -- Nombre completo
    email VARCHAR(255) NOT NULL UNIQUE,         -- Email único
    telefono VARCHAR(20),                       -- Teléfono de contacto
    rol ENUM('admin', 'empleado', 'cliente') NOT NULL DEFAULT 'cliente',
    estado ENUM('activo', 'inactivo', 'suspendido') NOT NULL DEFAULT 'activo',
    email_verificado BOOLEAN DEFAULT FALSE,     -- Estado de verificación

    -- Datos adicionales (principalmente para clientes)
    direccion TEXT,
    fecha_nacimiento DATE,

    -- Preferencias (JSON en SQL, objeto en Firebase)
    notificaciones_activas BOOLEAN DEFAULT TRUE,
    newsletter_activo BOOLEAN DEFAULT FALSE,

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP,

    -- Índices
    INDEX idx_email (email),
    INDEX idx_rol_estado (rol, estado),
    INDEX idx_fecha_creacion (fecha_creacion DESC)
);

-- ============================================================================
-- 2. TABLA: informacion_negocio
-- Documento único con toda la información del negocio
-- ============================================================================
CREATE TABLE informacion_negocio (
    id INT PRIMARY KEY DEFAULT 1,               -- Siempre será 1 (único registro)

    -- Información básica
    nombre VARCHAR(255) NOT NULL,               -- "Repostería Arlex"
    slogan VARCHAR(500),                        -- Slogan del negocio
    logo_url TEXT,                              -- URL del logo principal
    logo_secundario_url TEXT,                   -- URL del logo alternativo

    -- Historia y valores
    historia TEXT,                              -- Historia del negocio
    mision TEXT,                                -- Misión
    vision TEXT,                                -- Visión
    valores TEXT,                               -- JSON array: ["Calidad", "Compromiso", ...]

    -- Contacto
    telefono VARCHAR(20),
    email VARCHAR(255),
    whatsapp VARCHAR(20),
    direccion TEXT,
    horario_lunes_viernes VARCHAR(50),          -- "8:00 AM - 6:00 PM"
    horario_sabado VARCHAR(50),
    horario_domingo VARCHAR(50),

    -- Redes sociales
    facebook_url TEXT,
    instagram_url TEXT,
    tiktok_url TEXT,
    twitter_url TEXT,
    youtube_url TEXT,

    -- Configuración de negocio
    acepta_pedidos_online BOOLEAN DEFAULT TRUE,
    tiempo_preparacion_minimo_horas INT DEFAULT 24,
    monto_minimo_envio DECIMAL(10, 2) DEFAULT 20.00,
    costo_envio DECIMAL(10, 2) DEFAULT 5.00,
    radius_entrega_km INT DEFAULT 10,
    porcentaje_iva DECIMAL(5, 2) DEFAULT 0.00,
    acepta_reservas BOOLEAN DEFAULT TRUE,

    -- Metadatos
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    actualizado_por VARCHAR(128),               -- UID del usuario

    -- Constraint para asegurar un solo registro
    CONSTRAINT chk_single_record CHECK (id = 1),

    FOREIGN KEY (actualizado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 3. TABLA: galeria_negocio
-- Imágenes de la galería del negocio (relación 1:N con informacion_negocio)
-- ============================================================================
CREATE TABLE galeria_negocio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    url TEXT NOT NULL,                          -- URL de la imagen
    descripcion VARCHAR(500),                   -- Descripción de la imagen
    orden INT DEFAULT 0,                        -- Orden de visualización
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_orden (orden)
);

-- ============================================================================
-- 4. TABLA: categorias
-- Categorías de productos
-- ============================================================================
CREATE TABLE categorias (
    id VARCHAR(50) PRIMARY KEY,                 -- "cat_tortas", "cat_galletas"
    nombre VARCHAR(100) NOT NULL,               -- "Tortas", "Galletas"
    descripcion TEXT,
    icono VARCHAR(50),                          -- Nombre del icono Material
    imagen_url TEXT,                            -- URL de imagen opcional
    orden INT DEFAULT 0,                        -- Para ordenar en el UI
    activa BOOLEAN DEFAULT TRUE,

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    creado_por VARCHAR(128),                    -- UID del admin

    INDEX idx_activa_orden (activa, orden),
    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 5. TABLA: productos
-- Todos los productos disponibles
-- ============================================================================
CREATE TABLE productos (
    id VARCHAR(50) PRIMARY KEY,                 -- "torta_1", "galleta_1"
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    categoria_id VARCHAR(50) NOT NULL,
    categoria_nombre VARCHAR(100),              -- Desnormalizado para queries rápidas

    -- Inventario
    stock INT DEFAULT 0,
    stock_minimo INT DEFAULT 5,                 -- Alerta de stock bajo
    requiere_preparacion BOOLEAN DEFAULT FALSE,
    tiempo_preparacion_horas INT DEFAULT 0,

    -- Estado
    disponible BOOLEAN DEFAULT TRUE,
    destacado BOOLEAN DEFAULT FALSE,            -- Para mostrar en página principal

    -- Detalles adicionales
    peso_gramos INT,                            -- Peso en gramos
    porciones INT,                              -- Número de porciones
    ingredientes TEXT,                          -- JSON array
    alergenos TEXT,                             -- JSON array

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    creado_por VARCHAR(128),

    -- Estadísticas
    total_vendidos INT DEFAULT 0,
    calificacion_promedio DECIMAL(3, 2) DEFAULT 0.00,
    numero_calificaciones INT DEFAULT 0,

    -- Índices
    INDEX idx_categoria_disponible (categoria_id, disponible),
    INDEX idx_destacado (destacado, disponible),
    INDEX idx_disponible_fecha (disponible, fecha_creacion DESC),

    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT,
    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 6. TABLA: imagenes_productos
-- Imágenes de productos (relación 1:N con productos)
-- ============================================================================
CREATE TABLE imagenes_productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    es_principal BOOLEAN DEFAULT FALSE,         -- Imagen principal del producto
    orden INT DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_producto (producto_id),
    INDEX idx_producto_principal (producto_id, es_principal),

    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ============================================================================
-- 7. TABLA: pedidos
-- Pedidos realizados por los clientes
-- ============================================================================
CREATE TABLE pedidos (
    id VARCHAR(50) PRIMARY KEY,                 -- "ped_abc123"
    numero_pedido VARCHAR(20) NOT NULL UNIQUE,  -- "ORD-2025-0001"

    -- Cliente
    cliente_id VARCHAR(128) NOT NULL,
    cliente_nombre VARCHAR(255),                -- Desnormalizado
    cliente_email VARCHAR(255),                 -- Desnormalizado
    cliente_telefono VARCHAR(20),               -- Desnormalizado

    -- Totales
    subtotal DECIMAL(10, 2) NOT NULL,
    iva DECIMAL(10, 2) DEFAULT 0.00,
    costo_envio DECIMAL(10, 2) DEFAULT 0.00,
    descuento DECIMAL(10, 2) DEFAULT 0.00,
    total DECIMAL(10, 2) NOT NULL,

    -- Entrega
    metodo_entrega ENUM('domicilio', 'tienda') NOT NULL,
    direccion_entrega TEXT,
    coordenadas_lat DECIMAL(10, 8),             -- Latitud
    coordenadas_lng DECIMAL(11, 8),             -- Longitud

    -- Pago
    metodo_pago ENUM('efectivo', 'transferencia', 'tarjeta') NOT NULL,
    estado_pago ENUM('pendiente', 'pagado', 'rechazado') DEFAULT 'pendiente',
    referencia_pago VARCHAR(255),               -- Para transferencias/tarjetas

    -- Estado del pedido
    estado ENUM(
        'pendiente',
        'confirmado',
        'preparando',
        'listo',
        'en_camino',
        'entregado',
        'cancelado'
    ) DEFAULT 'pendiente',

    -- Notas
    notas_cliente TEXT,
    notas_internas TEXT,                        -- Solo visible para empleados/admin

    -- Fechas importantes
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion TIMESTAMP NULL,
    fecha_preparacion TIMESTAMP NULL,
    fecha_entrega TIMESTAMP NULL,
    fecha_cancelacion TIMESTAMP NULL,

    -- Asignación
    preparado_por VARCHAR(128),                 -- UID del empleado
    entregado_por VARCHAR(128),                 -- UID del repartidor

    -- Calificación
    calificacion INT,                           -- 1-5 estrellas
    comentario_calificacion TEXT,
    fecha_calificacion TIMESTAMP NULL,

    -- Índices
    INDEX idx_cliente_fecha (cliente_id, fecha_pedido DESC),
    INDEX idx_estado_fecha (estado, fecha_pedido DESC),
    INDEX idx_numero_pedido (numero_pedido),
    INDEX idx_fecha_pedido (fecha_pedido DESC),

    FOREIGN KEY (cliente_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (preparado_por) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (entregado_por) REFERENCES usuarios(id) ON DELETE SET NULL,

    CONSTRAINT chk_calificacion CHECK (calificacion IS NULL OR (calificacion >= 1 AND calificacion <= 5))
);

-- ============================================================================
-- 8. TABLA: items_pedido
-- Items individuales de cada pedido (relación N:M con productos)
-- ============================================================================
CREATE TABLE items_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id VARCHAR(50) NOT NULL,
    producto_id VARCHAR(50) NOT NULL,
    producto_nombre VARCHAR(255) NOT NULL,      -- Desnormalizado
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,    -- Precio al momento de la compra
    subtotal DECIMAL(10, 2) NOT NULL,           -- cantidad * precio_unitario
    notas_especiales TEXT,

    INDEX idx_pedido (pedido_id),
    INDEX idx_producto (producto_id),

    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,

    CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0)
);

-- ============================================================================
-- 9. TABLA: historial_pedidos
-- Historial de cambios de estado de pedidos
-- ============================================================================
CREATE TABLE historial_pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id VARCHAR(50) NOT NULL,
    estado VARCHAR(50) NOT NULL,
    comentario TEXT,
    usuario_id VARCHAR(128),
    usuario_nombre VARCHAR(255),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_pedido_fecha (pedido_id, fecha DESC),

    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 10. TABLA: carritos
-- Carritos de compra activos (temporal)
-- ============================================================================
CREATE TABLE carritos (
    usuario_id VARCHAR(128) PRIMARY KEY,        -- Un carrito por usuario
    total DECIMAL(10, 2) DEFAULT 0.00,
    cantidad_total INT DEFAULT 0,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,                 -- 7 días después de última actualización

    INDEX idx_expiracion (fecha_expiracion),

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ============================================================================
-- 11. TABLA: items_carrito
-- Items del carrito de cada usuario
-- ============================================================================
CREATE TABLE items_carrito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id VARCHAR(128) NOT NULL,
    producto_id VARCHAR(50) NOT NULL,
    producto_nombre VARCHAR(255) NOT NULL,      -- Desnormalizado
    producto_precio DECIMAL(10, 2) NOT NULL,    -- Desnormalizado
    producto_imagen_url TEXT,                   -- Desnormalizado
    cantidad INT NOT NULL DEFAULT 1,
    notas_especiales TEXT,
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_usuario (usuario_id),
    INDEX idx_producto (producto_id),

    FOREIGN KEY (usuario_id) REFERENCES carritos(usuario_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,

    UNIQUE KEY unique_user_product (usuario_id, producto_id),
    CONSTRAINT chk_cantidad_carrito CHECK (cantidad > 0)
);

-- ============================================================================
-- 12. TABLA: notificaciones
-- Notificaciones para usuarios
-- ============================================================================
CREATE TABLE notificaciones (
    id VARCHAR(50) PRIMARY KEY,
    usuario_id VARCHAR(128) NOT NULL,
    tipo ENUM('pedido', 'sistema', 'promocion') NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,

    -- Datos adicionales
    pedido_id VARCHAR(50),                      -- Si es notificación de pedido
    link TEXT,                                  -- URL opcional

    -- Estado
    leida BOOLEAN DEFAULT FALSE,
    fecha_lectura TIMESTAMP NULL,

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    creado_por VARCHAR(128),                    -- "sistema" o UID

    INDEX idx_usuario_leida_fecha (usuario_id, leida, fecha_creacion DESC),

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 13. TABLA: promociones
-- Promociones y descuentos activos
-- ============================================================================
CREATE TABLE promociones (
    id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    imagen_url TEXT,

    -- Tipo de descuento
    tipo_descuento ENUM('porcentaje', 'monto_fijo') NOT NULL,
    valor_descuento DECIMAL(10, 2) NOT NULL,

    -- Condiciones
    monto_minimo DECIMAL(10, 2) DEFAULT 0.00,

    -- Código de cupón
    codigo_cupon VARCHAR(50) UNIQUE,
    usos_maximos INT DEFAULT 0,                 -- 0 = ilimitado
    usos_actuales INT DEFAULT 0,
    usuario_max_usos INT DEFAULT 1,             -- Usos por usuario

    -- Vigencia
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    activa BOOLEAN DEFAULT TRUE,

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    creado_por VARCHAR(128),

    INDEX idx_activa_fecha_fin (activa, fecha_fin DESC),
    INDEX idx_codigo (codigo_cupon),

    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE SET NULL,

    CONSTRAINT chk_valor_positivo CHECK (valor_descuento > 0),
    CONSTRAINT chk_fechas CHECK (fecha_fin > fecha_inicio)
);

-- ============================================================================
-- 14. TABLA: productos_promocion
-- Relación N:M entre promociones y productos
-- ============================================================================
CREATE TABLE productos_promocion (
    promocion_id VARCHAR(50) NOT NULL,
    producto_id VARCHAR(50) NOT NULL,

    PRIMARY KEY (promocion_id, producto_id),

    FOREIGN KEY (promocion_id) REFERENCES promociones(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ============================================================================
-- 15. TABLA: categorias_promocion
-- Relación N:M entre promociones y categorías
-- ============================================================================
CREATE TABLE categorias_promocion (
    promocion_id VARCHAR(50) NOT NULL,
    categoria_id VARCHAR(50) NOT NULL,

    PRIMARY KEY (promocion_id, categoria_id),

    FOREIGN KEY (promocion_id) REFERENCES promociones(id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE CASCADE
);

-- ============================================================================
-- 16. TABLA: usos_promocion
-- Registro de usos de cupones por usuario
-- ============================================================================
CREATE TABLE usos_promocion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    promocion_id VARCHAR(50) NOT NULL,
    usuario_id VARCHAR(128) NOT NULL,
    pedido_id VARCHAR(50) NOT NULL,
    fecha_uso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_promocion_usuario (promocion_id, usuario_id),

    FOREIGN KEY (promocion_id) REFERENCES promociones(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
);

-- ============================================================================
-- 17. TABLA: reseñas
-- Reseñas de productos
-- ============================================================================
CREATE TABLE reseñas (
    id VARCHAR(50) PRIMARY KEY,
    producto_id VARCHAR(50) NOT NULL,
    producto_nombre VARCHAR(255),               -- Desnormalizado

    -- Usuario
    usuario_id VARCHAR(128) NOT NULL,
    usuario_nombre VARCHAR(255),                -- Desnormalizado

    -- Reseña
    calificacion INT NOT NULL,                  -- 1-5
    titulo VARCHAR(255),
    comentario TEXT,

    -- Verificación
    compra_verificada BOOLEAN DEFAULT FALSE,
    pedido_id VARCHAR(50),                      -- Referencia al pedido

    -- Estado
    aprobada BOOLEAN DEFAULT FALSE,             -- Moderación
    reportada BOOLEAN DEFAULT FALSE,

    -- Metadatos
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_producto_aprobada (producto_id, aprobada, fecha_creacion DESC),
    INDEX idx_usuario (usuario_id, fecha_creacion DESC),

    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE SET NULL,

    CONSTRAINT chk_calificacion_resena CHECK (calificacion >= 1 AND calificacion <= 5)
);

-- ============================================================================
-- 18. TABLA: imagenes_reseñas
-- Imágenes adjuntas a reseñas
-- ============================================================================
CREATE TABLE imagenes_reseñas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reseña_id VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_reseña (reseña_id),

    FOREIGN KEY (reseña_id) REFERENCES reseñas(id) ON DELETE CASCADE
);

-- ============================================================================
-- 19. TABLA: inventario_movimientos
-- Historial de movimientos de inventario
-- ============================================================================
CREATE TABLE inventario_movimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id VARCHAR(50) NOT NULL,
    producto_nombre VARCHAR(255),               -- Desnormalizado

    -- Movimiento
    tipo ENUM('entrada', 'salida', 'ajuste', 'venta') NOT NULL,
    cantidad INT NOT NULL,                      -- Positivo = entrada, Negativo = salida
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,

    -- Razón
    razon ENUM('compra', 'venta', 'devolucion', 'merma', 'ajuste') NOT NULL,
    referencia VARCHAR(50),                     -- ID de pedido, compra, etc.
    notas TEXT,

    -- Usuario responsable
    realizado_por VARCHAR(128),
    realizado_por_nombre VARCHAR(255),

    -- Metadatos
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_producto_fecha (producto_id, fecha DESC),
    INDEX idx_tipo_fecha (tipo, fecha DESC),

    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    FOREIGN KEY (realizado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 20. TABLA: configuracion_sistema
-- Configuraciones generales del sistema (un solo registro)
-- ============================================================================
CREATE TABLE configuracion_sistema (
    id INT PRIMARY KEY DEFAULT 1,

    -- Email
    smtp_host VARCHAR(255),
    smtp_port INT,
    email_soporte VARCHAR(255),
    nombre_remitente VARCHAR(255),

    -- WhatsApp
    whatsapp_api_key TEXT,
    whatsapp_numero VARCHAR(20),
    whatsapp_activo BOOLEAN DEFAULT FALSE,

    -- Pagos - MercadoPago
    mercadopago_activo BOOLEAN DEFAULT FALSE,
    mercadopago_public_key TEXT,

    -- Pagos - PayPal
    paypal_activo BOOLEAN DEFAULT FALSE,
    paypal_client_id TEXT,

    -- Mantenimiento
    modo_mantenimiento BOOLEAN DEFAULT FALSE,
    mensaje_mantenimiento TEXT,

    -- Versión
    version_app VARCHAR(20),
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_config_single CHECK (id = 1)
);

-- ============================================================================
-- 21. TABLA: estadisticas
-- Estadísticas del negocio por periodo
-- ============================================================================
CREATE TABLE estadisticas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    periodo VARCHAR(20) NOT NULL,               -- "2025-01", "2025-01-15", "2025"
    tipo ENUM('diario', 'mensual', 'anual') NOT NULL,

    -- Ventas
    total_ventas DECIMAL(12, 2) DEFAULT 0.00,
    numero_ordenes INT DEFAULT 0,
    ticket_promedio DECIMAL(10, 2) DEFAULT 0.00,

    -- Clientes
    nuevos_clientes INT DEFAULT 0,
    clientes_recurrentes INT DEFAULT 0,

    -- Datos adicionales en JSON (por limitaciones SQL)
    productos_mas_vendidos TEXT,               -- JSON array
    ventas_por_categoria TEXT,                 -- JSON object
    ventas_por_metodo_pago TEXT,               -- JSON object

    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY unique_periodo_tipo (periodo, tipo),
    INDEX idx_periodo (periodo),
    INDEX idx_tipo_periodo (tipo, periodo DESC)
);

-- ============================================================================
-- 22. TABLA: productos_mas_vendidos
-- Productos más vendidos por periodo (normalizado)
-- ============================================================================
CREATE TABLE productos_mas_vendidos_periodo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estadistica_id INT NOT NULL,
    producto_id VARCHAR(50) NOT NULL,
    producto_nombre VARCHAR(255) NOT NULL,
    cantidad_vendida INT NOT NULL,
    ingresos DECIMAL(10, 2) NOT NULL,
    ranking INT,                                -- Posición en el ranking

    INDEX idx_estadistica (estadistica_id),

    FOREIGN KEY (estadistica_id) REFERENCES estadisticas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Actualizar stock después de crear un pedido
DELIMITER //
CREATE TRIGGER trg_after_item_pedido_insert
AFTER INSERT ON items_pedido
FOR EACH ROW
BEGIN
    UPDATE productos
    SET stock = stock - NEW.cantidad,
        total_vendidos = total_vendidos + NEW.cantidad
    WHERE id = NEW.producto_id;

    -- Registrar movimiento de inventario
    INSERT INTO inventario_movimientos (
        producto_id, producto_nombre, tipo, cantidad,
        stock_anterior, stock_nuevo, razon, referencia
    )
    SELECT
        NEW.producto_id,
        p.nombre,
        'venta',
        -NEW.cantidad,
        p.stock + NEW.cantidad,
        p.stock,
        'venta',
        NEW.pedido_id
    FROM productos p
    WHERE p.id = NEW.producto_id;
END//
DELIMITER ;

-- Trigger: Actualizar total del carrito
DELIMITER //
CREATE TRIGGER trg_after_item_carrito_change
AFTER INSERT ON items_carrito
FOR EACH ROW
BEGIN
    UPDATE carritos
    SET total = (
            SELECT IFNULL(SUM(producto_precio * cantidad), 0)
            FROM items_carrito
            WHERE usuario_id = NEW.usuario_id
        ),
        cantidad_total = (
            SELECT IFNULL(SUM(cantidad), 0)
            FROM items_carrito
            WHERE usuario_id = NEW.usuario_id
        ),
        fecha_actualizacion = CURRENT_TIMESTAMP,
        fecha_expiracion = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 7 DAY)
    WHERE usuario_id = NEW.usuario_id;
END//
DELIMITER ;

-- Trigger: Actualizar calificación promedio del producto
DELIMITER //
CREATE TRIGGER trg_after_reseña_insert
AFTER INSERT ON reseñas
FOR EACH ROW
BEGIN
    UPDATE productos
    SET calificacion_promedio = (
            SELECT AVG(calificacion)
            FROM reseñas
            WHERE producto_id = NEW.producto_id AND aprobada = TRUE
        ),
        numero_calificaciones = (
            SELECT COUNT(*)
            FROM reseñas
            WHERE producto_id = NEW.producto_id AND aprobada = TRUE
        )
    WHERE id = NEW.producto_id;
END//
DELIMITER ;

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Vista: Pedidos con información completa
CREATE VIEW vista_pedidos_completos AS
SELECT
    p.*,
    u.nombre as cliente_nombre_actual,
    u.email as cliente_email_actual,
    COUNT(DISTINCT ip.id) as total_items,
    SUM(ip.cantidad) as total_productos
FROM pedidos p
LEFT JOIN usuarios u ON p.cliente_id = u.id
LEFT JOIN items_pedido ip ON p.id = ip.pedido_id
GROUP BY p.id;

-- Vista: Productos con stock bajo
CREATE VIEW vista_productos_stock_bajo AS
SELECT
    p.id,
    p.nombre,
    p.stock,
    p.stock_minimo,
    c.nombre as categoria_nombre
FROM productos p
INNER JOIN categorias c ON p.categoria_id = c.id
WHERE p.stock <= p.stock_minimo AND p.disponible = TRUE;

-- Vista: Estadísticas de ventas del mes actual
CREATE VIEW vista_ventas_mes_actual AS
SELECT
    DATE(fecha_pedido) as fecha,
    COUNT(*) as numero_pedidos,
    SUM(total) as total_ventas,
    AVG(total) as ticket_promedio
FROM pedidos
WHERE YEAR(fecha_pedido) = YEAR(CURRENT_DATE)
    AND MONTH(fecha_pedido) = MONTH(CURRENT_DATE)
    AND estado NOT IN ('cancelado')
GROUP BY DATE(fecha_pedido)
ORDER BY fecha DESC;

-- Vista: Top 10 productos más vendidos
CREATE VIEW vista_top_productos AS
SELECT
    p.id,
    p.nombre,
    p.categoria_nombre,
    p.precio,
    p.total_vendidos,
    p.calificacion_promedio,
    p.numero_calificaciones
FROM productos p
WHERE p.disponible = TRUE
ORDER BY p.total_vendidos DESC
LIMIT 10;

-- ============================================================================
-- DATOS INICIALES (SEEDS)
-- ============================================================================

-- Usuario Administrador
INSERT INTO usuarios (
    id, nombre, email, telefono, rol, estado,
    email_verificado, fecha_creacion
) VALUES (
    'admin_001',
    'Administrador',
    'admin@reposteriaarlex.com',
    '+573001234567',
    'admin',
    'activo',
    TRUE,
    CURRENT_TIMESTAMP
);

-- Información del Negocio
INSERT INTO informacion_negocio (
    id, nombre, slogan, email, telefono, whatsapp,
    direccion, horario_lunes_viernes, horario_sabado, horario_domingo,
    historia, mision, vision, valores,
    acepta_pedidos_online, tiempo_preparacion_minimo_horas,
    monto_minimo_envio, costo_envio, radius_entrega_km,
    actualizado_por
) VALUES (
    1,
    'Repostería Arlex',
    'Endulzando tus momentos especiales',
    'contacto@reposteriaarlex.com',
    '+573001234567',
    '+573001234567',
    'Calle 123 #45-67, Ciudad',
    '8:00 AM - 6:00 PM',
    '9:00 AM - 5:00 PM',
    'Cerrado',
    'Historia de Repostería Arlex...',
    'Endulzar la vida de nuestros clientes con productos de la más alta calidad',
    'Ser la repostería líder en la región',
    '["Calidad", "Compromiso", "Innovación", "Pasión", "Servicio"]',
    TRUE,
    24,
    20.00,
    5.00,
    10,
    'admin_001'
);

-- Categorías
INSERT INTO categorias (id, nombre, descripcion, icono, orden, activa, creado_por) VALUES
('cat_tortas', 'Tortas', 'Deliciosas tortas para toda ocasión', 'cake', 1, TRUE, 'admin_001'),
('cat_galletas', 'Galletas', 'Galletas artesanales crujientes', 'cookie', 2, TRUE, 'admin_001'),
('cat_postres', 'Postres', 'Exquisitos postres caseros', 'emoji_food_beverage', 3, TRUE, 'admin_001'),
('cat_pasteles', 'Pasteles', 'Pasteles individuales y porciones', 'cake_outlined', 4, TRUE, 'admin_001'),
('cat_bocaditos', 'Bocaditos', 'Pequeños bocados dulces', 'breakfast_dining', 5, TRUE, 'admin_001');

-- Configuración del Sistema
INSERT INTO configuracion_sistema (
    id, email_soporte, nombre_remitente,
    modo_mantenimiento, version_app
) VALUES (
    1,
    'soporte@reposteriaarlex.com',
    'Repostería Arlex',
    FALSE,
    '1.0.0'
);

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================

-- Esta estructura SQL representa la base de datos relacional equivalente
-- a la estructura Firebase Firestore documentada.
--
-- DIFERENCIAS CLAVE entre SQL y Firebase:
-- 1. Firebase no tiene JOINs nativos (usa desnormalización)
-- 2. Firebase usa subcollections (representadas aquí como tablas relacionadas)
-- 3. Firebase almacena arrays y objetos nativamente (aquí usamos JSON o tablas)
-- 4. Firebase tiene mejor escalabilidad horizontal
-- 5. SQL tiene mejor integridad referencial y transacciones ACID
--
-- Para usar esta estructura:
-- 1. Crea la base de datos: CREATE DATABASE reposteria_arlex;
-- 2. Selecciona la base de datos: USE reposteria_arlex;
-- 3. Ejecuta este script completo
-- 4. Verifica las tablas: SHOW TABLES;
-- 5. Verifica los datos iniciales: SELECT * FROM usuarios;
