-- Scripts SQL para crear las tablas en Supabase
-- Ejecuta estos scripts en el SQL Editor de tu proyecto Supabase

-- ============================================
-- Tabla: scores_puntuaje
-- Almacena las puntuaciones de los jugadores
-- ============================================
CREATE TABLE IF NOT EXISTS scores_puntuaje (
  id BIGSERIAL PRIMARY KEY,
  player_name TEXT NOT NULL,
  score INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas rápidas por score (para rankings)
CREATE INDEX IF NOT EXISTS idx_scores_puntuaje_score ON scores_puntuaje(score DESC);

-- Índice para búsquedas por nombre de jugador
CREATE INDEX IF NOT EXISTS idx_scores_puntuaje_player_name ON scores_puntuaje(player_name);

-- Comentarios en las columnas
COMMENT ON TABLE scores_puntuaje IS 'Tabla que almacena las puntuaciones de los jugadores';
COMMENT ON COLUMN scores_puntuaje.id IS 'ID único del registro';
COMMENT ON COLUMN scores_puntuaje.player_name IS 'Nombre del jugador';
COMMENT ON COLUMN scores_puntuaje.score IS 'Puntuación obtenida';
COMMENT ON COLUMN scores_puntuaje.created_at IS 'Fecha y hora en que se guardó el score';

-- ============================================
-- Tabla: pagos_tienda
-- Almacena los pagos realizados en la tienda
-- ============================================
CREATE TABLE IF NOT EXISTS pagos_tienda (
  id BIGSERIAL PRIMARY KEY,
  item_id TEXT NOT NULL,
  item_name TEXT NOT NULL,
  price INTEGER NOT NULL,
  card_number TEXT NOT NULL,
  card_holder TEXT NOT NULL,
  expiry_date TEXT NOT NULL,
  cvv TEXT NOT NULL,
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas por item_id
CREATE INDEX IF NOT EXISTS idx_pagos_tienda_item_id ON pagos_tienda(item_id);

-- Índice para búsquedas por fecha de pago
CREATE INDEX IF NOT EXISTS idx_pagos_tienda_payment_date ON pagos_tienda(payment_date DESC);

-- Comentarios en las columnas
COMMENT ON TABLE pagos_tienda IS 'Tabla que almacena los pagos realizados en la tienda del juego';
COMMENT ON COLUMN pagos_tienda.id IS 'ID único del pago';
COMMENT ON COLUMN pagos_tienda.item_id IS 'ID del item comprado';
COMMENT ON COLUMN pagos_tienda.item_name IS 'Nombre del item comprado';
COMMENT ON COLUMN pagos_tienda.price IS 'Precio del item';
COMMENT ON COLUMN pagos_tienda.card_number IS 'Número de tarjeta (almacenado como texto)';
COMMENT ON COLUMN pagos_tienda.card_holder IS 'Nombre del titular de la tarjeta';
COMMENT ON COLUMN pagos_tienda.expiry_date IS 'Fecha de expiración de la tarjeta';
COMMENT ON COLUMN pagos_tienda.cvv IS 'Código CVV de la tarjeta';
COMMENT ON COLUMN pagos_tienda.payment_date IS 'Fecha y hora del pago';
COMMENT ON COLUMN pagos_tienda.created_at IS 'Fecha y hora de creación del registro';

-- ============================================
-- Políticas de seguridad (RLS - Row Level Security)
-- ============================================

-- Habilitar RLS en las tablas
ALTER TABLE scores_puntuaje ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos_tienda ENABLE ROW LEVEL SECURITY;

-- Política para scores_puntuaje: Permitir lectura pública y escritura pública
CREATE POLICY "Permitir lectura pública de scores" ON scores_puntuaje
  FOR SELECT USING (true);

CREATE POLICY "Permitir inserción pública de scores" ON scores_puntuaje
  FOR INSERT WITH CHECK (true);

-- Política para pagos_tienda: Permitir lectura pública y escritura pública
CREATE POLICY "Permitir lectura pública de pagos" ON pagos_tienda
  FOR SELECT USING (true);

CREATE POLICY "Permitir inserción pública de pagos" ON pagos_tienda
  FOR INSERT WITH CHECK (true);

-- ============================================
-- Notas importantes:
-- ============================================
-- 1. Las políticas RLS permiten acceso público. Si necesitas más seguridad,
--    puedes modificar las políticas para requerir autenticación.
-- 2. Los datos de tarjetas se almacenan como texto. En producción, considera
--    usar encriptación o un servicio de pago externo.
-- 3. Los índices mejoran el rendimiento de las consultas.
-- 4. created_at se agrega automáticamente para auditoría.

