-- ========================================
-- 🏗️ Creación de esquemas
-- ========================================
GO
CREATE SCHEMA bank_params;
GO
CREATE SCHEMA bank;
GO

-- ========================================
-- 📋 Tablas de Parámetros
-- ========================================
CREATE TABLE bank_params.credit_states (
    credit_state_id VARCHAR(3) NOT NULL,
    credit_state_description VARCHAR(32) NOT NULL,
    author_id VARCHAR(16) NOT NULL,
    written_at DATETIMEOFFSET(2) NOT NULL,
    CONSTRAINT pk_credsta PRIMARY KEY (credit_state_id)
);
GO

CREATE TABLE bank_params.client_types (
    client_type_id VARCHAR(3) NOT NULL,
    client_type_description VARCHAR(32) NOT NULL,
    author_id VARCHAR(16) NOT NULL,
    written_at DATETIMEOFFSET(2) NOT NULL,
    CONSTRAINT pk_clityp PRIMARY KEY (client_type_id)
);
GO

CREATE TABLE bank_params.risk_categories (
    risk_category_id VARCHAR(2) NOT NULL,
    risk_category_description VARCHAR(32) NOT NULL,
    author_id VARCHAR(16) NOT NULL,
    written_at DATETIMEOFFSET(2) NOT NULL,
    CONSTRAINT pk_rskcat PRIMARY KEY (risk_category_id)
);
GO

-- ========================================
-- 🧾 Tablas de Negocio
-- ========================================
CREATE TABLE bank.client (
    client_id VARCHAR(16) NOT NULL,
    client_name VARCHAR(256) NOT NULL,
    client_type_id VARCHAR(3) NOT NULL,
    risk_category_id VARCHAR(2) NOT NULL,
    credit_line_authorized_amount NUMERIC(15,2) NOT NULL,
    credit_line_used_amount NUMERIC(15,2) NOT NULL,
    author_id VARCHAR(16) NOT NULL,
    written_at DATETIMEOFFSET(2) NOT NULL,
    CONSTRAINT pk_cli PRIMARY KEY (client_id),
    CONSTRAINT fk_clityp_cli FOREIGN KEY (client_type_id) REFERENCES bank_params.client_types(client_type_id),
    CONSTRAINT fk_rskcat_cli FOREIGN KEY (risk_category_id) REFERENCES bank_params.risk_categories(risk_category_id)
);
GO

CREATE TABLE bank.credit_orders (
    credit_order_id INT IDENTITY(1,1) NOT NULL,
    client_id VARCHAR(16) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL,
    due_date DATE NOT NULL,
    client_type_id VARCHAR(3) NOT NULL,
    risk_category_id VARCHAR(2) NOT NULL,
    credit_line_authorized_amount NUMERIC(15,2) NOT NULL,
    credit_line_used_amount NUMERIC(15,2) NOT NULL,
    credit_state_id VARCHAR(3) NOT NULL,
    author_id VARCHAR(16) NOT NULL,
    written_at DATETIMEOFFSET(2) NOT NULL,
    CONSTRAINT pk_creord PRIMARY KEY (credit_order_id),
    CONSTRAINT fk_cli_creord FOREIGN KEY (client_id) REFERENCES bank.client(client_id),
    CONSTRAINT fk_clityp_creord FOREIGN KEY (client_type_id) REFERENCES bank_params.client_types(client_type_id),
    CONSTRAINT fk_rskcat_creord FOREIGN KEY (risk_category_id) REFERENCES bank_params.risk_categories(risk_category_id),
    CONSTRAINT fk_credsta_creord FOREIGN KEY (credit_state_id) REFERENCES bank_params.credit_states(credit_state_id)
);
GO

-- ========================================
-- 🧩 Tablas de Trazabilidad
-- ========================================
CREATE TABLE bank.client_atl (
    atl_written_at DATETIMEOFFSET(2) NOT NULL,
    atl_app_name NVARCHAR(128) NOT NULL,
    atl_host_name NVARCHAR(128) NOT NULL,
    atl_user SYSNAME NOT NULL,
    atl_action VARCHAR(3) NOT NULL,
    client_id VARCHAR(16),
    client_name VARCHAR(256),
    client_type_id VARCHAR(3),
    risk_category_id VARCHAR(2),
    credit_line_authorized_amount NUMERIC(15,2),
    credit_line_used_amount NUMERIC(15,2),
    author_id VARCHAR(16),
    written_at DATETIMEOFFSET(2)
);
GO

CREATE TABLE bank.credit_orders_atl (
    atl_written_at DATETIMEOFFSET(2) NOT NULL,
    atl_app_name NVARCHAR(128) NOT NULL,
    atl_host_name NVARCHAR(128) NOT NULL,
    atl_user SYSNAME NOT NULL,
    atl_action VARCHAR(3) NOT NULL,
    credit_order_id INT,
    client_id VARCHAR(16),
    amount NUMERIC(15,2),
    interest_rate NUMERIC(5,2),
    due_date DATE,
    client_type_id VARCHAR(3),
    risk_category_id VARCHAR(2),
    credit_line_authorized_amount NUMERIC(15,2),
    credit_line_used_amount NUMERIC(15,2),
    credit_state_id VARCHAR(3),
    author_id VARCHAR(16),
    written_at DATETIMEOFFSET(2)
);
GO

-- ========================================
-- 🔁 Triggers de Trazabilidad
-- ========================================
CREATE TRIGGER bank.trg_iud_client
ON bank.client
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @action VARCHAR(3) = CASE
        WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPD'
        WHEN EXISTS(SELECT * FROM inserted) THEN 'INS'
        ELSE 'DEL' END;

    INSERT INTO bank.client_atl (
        atl_written_at, atl_app_name, atl_host_name, atl_user, atl_action,
        client_id, client_name, client_type_id, risk_category_id,
        credit_line_authorized_amount, credit_line_used_amount,
        author_id, written_at
    )
    SELECT
        SYSDATETIMEOFFSET(), APP_NAME(), HOST_NAME(), CURRENT_USER, @action,
        COALESCE(i.client_id, d.client_id),
        COALESCE(i.client_name, d.client_name),
        COALESCE(i.client_type_id, d.client_type_id),
        COALESCE(i.risk_category_id, d.risk_category_id),
        COALESCE(i.credit_line_authorized_amount, d.credit_line_authorized_amount),
        COALESCE(i.credit_line_used_amount, d.credit_line_used_amount),
        COALESCE(i.author_id, d.author_id),
        COALESCE(i.written_at, d.written_at)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.client_id = d.client_id;
END;
GO

CREATE TRIGGER bank.trg_iud_credit_orders
ON bank.credit_orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @action VARCHAR(3) = CASE
        WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPD'
        WHEN EXISTS(SELECT * FROM inserted) THEN 'INS'
        ELSE 'DEL' END;

    INSERT INTO bank.credit_orders_atl (
        atl_written_at, atl_app_name, atl_host_name, atl_user, atl_action,
        credit_order_id, client_id, amount, interest_rate, due_date,
        client_type_id, risk_category_id, credit_line_authorized_amount,
        credit_line_used_amount, credit_state_id, author_id, written_at
    )
    SELECT
        SYSDATETIMEOFFSET(), APP_NAME(), HOST_NAME(), CURRENT_USER, @action,
        COALESCE(i.credit_order_id, d.credit_order_id),
        COALESCE(i.client_id, d.client_id),
        COALESCE(i.amount, d.amount),
        COALESCE(i.interest_rate, d.interest_rate),
        COALESCE(i.due_date, d.due_date),
        COALESCE(i.client_type_id, d.client_type_id),
        COALESCE(i.risk_category_id, d.risk_category_id),
        COALESCE(i.credit_line_authorized_amount, d.credit_line_authorized_amount),
        COALESCE(i.credit_line_used_amount, d.credit_line_used_amount),
        COALESCE(i.credit_state_id, d.credit_state_id),
        COALESCE(i.author_id, d.author_id),
        COALESCE(i.written_at, d.written_at)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.credit_order_id = d.credit_order_id;
END;
GO