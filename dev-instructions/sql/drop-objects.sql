-- Eliminar triggers si existen
DROP TRIGGER IF EXISTS bank.trg_iud_client;
DROP TRIGGER IF EXISTS bank.trg_iud_credit_orders;

-- Eliminar tablas de trazabilidad si existen
DROP TABLE IF EXISTS bank.client_atl;
DROP TABLE IF EXISTS bank.credit_orders_atl;

-- Eliminar tablas de negocio si existen
DROP TABLE IF EXISTS bank.credit_orders;
DROP TABLE IF EXISTS bank.client;

-- Eliminar tablas de parámetros si existen
DROP TABLE IF EXISTS bank_params.credit_states;
DROP TABLE IF EXISTS bank_params.client_types;
DROP TABLE IF EXISTS bank_params.risk_categories;

-- Eliminar esquemas si existen
DROP SCHEMA IF EXISTS bank;
DROP SCHEMA IF EXISTS bank_params;