-- ========================================
-- 🧹 Eliminación de datos de prueba en esquema bank
-- ========================================

-- Eliminar datos de trazabilidad primero para evitar conflictos de FK
DELETE FROM bank.credit_orders_atl;
DELETE FROM bank.client_atl;

-- Eliminar datos de negocio
DELETE FROM bank.credit_orders;
DELETE FROM bank.client;
GO