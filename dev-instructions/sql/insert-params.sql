-- ========================================
-- 📌 Insertar valores en bank_params.credit_states
-- ========================================
INSERT INTO bank_params.credit_states (
    credit_state_id, credit_state_description, author_id, written_at
) VALUES
('PRO', 'EN PROCESO', 'SYSTEM', SYSDATETIMEOFFSET()),
('APR', 'APROBADO', 'SYSTEM', SYSDATETIMEOFFSET()),
('DES', 'DESAPROBADO', 'SYSTEM', SYSDATETIMEOFFSET());
GO

-- ========================================
-- 📌 Insertar valores en bank_params.client_types
-- ========================================
INSERT INTO bank_params.client_types (
    client_type_id, client_type_description, author_id, written_at
) VALUES
('MIC', 'MICRO EMPRESA', 'SYSTEM', SYSDATETIMEOFFSET()),
('PEQ', 'PEQUEÑA EMPRESA', 'SYSTEM', SYSDATETIMEOFFSET()),
('MED', 'MEDIANA EMPRESA', 'SYSTEM', SYSDATETIMEOFFSET()),
('GRA', 'GRAN EMPRESA', 'SYSTEM', SYSDATETIMEOFFSET());
GO

-- ========================================
-- 📌 Insertar valores en bank_params.risk_categories
-- ========================================
INSERT INTO bank_params.risk_categories (
    risk_category_id, risk_category_description, author_id, written_at
) VALUES
('NO', 'NORMAL', 'SYSTEM', SYSDATETIMEOFFSET()),
('PP', 'PROBLEMA POTENCIAL', 'SYSTEM', SYSDATETIMEOFFSET()),
('DE', 'DEFICIENTE', 'SYSTEM', SYSDATETIMEOFFSET()),
('DU', 'DUDOSO', 'SYSTEM', SYSDATETIMEOFFSET()),
('PE', 'PÉRDIDA', 'SYSTEM', SYSDATETIMEOFFSET());
GO