-- ========================================
-- 👥 Insertar 100 clientes ficticios en bank.client
-- ========================================
DECLARE @i INT = 0;
WHILE @i < 100
BEGIN
    -- Generar RUC ficticio único
    DECLARE @client_id VARCHAR(16) = '20' + RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 10000000000 AS VARCHAR), 10);

    -- Nombre ficticio de empresa
    DECLARE @name NVARCHAR(256) =
        'Empresa ' +
        CHOOSE((@i % 15) + 1, 'Oro', 'Cobre', 'Zinc', 'Anchoveta', 'Mero', 'Papa León', 'Papa Gregorio', 'Arequipa', 'Piura', 'Tacna', 'Lima', 'Mozambique', 'Fiyi', 'El Cairo') +
        ' y ' +
        CHOOSE((@i % 10) + 1, 'Supermercados', 'Minería', 'Educación', 'Transporte', 'Aviación', 'Abarrotes', 'Pesca', 'Librerías', 'Consultoría', 'Servicios') +
        ' ' +
        CHOOSE((@i % 5) + 1, 'SA', 'SAC', 'EIRL', 'SRL', 'SCRL');

    -- Tipo de cliente según distribución
    DECLARE @ctype VARCHAR(3);
    IF @i < 5 SET @ctype = 'GRA';
    ELSE IF @i < 30 SET @ctype = 'MED';
    ELSE IF @i < 70 SET @ctype = 'PEQ';
    ELSE SET @ctype = 'MIC';

    -- Categoría de riesgo según tipo
    DECLARE @risk VARCHAR(2);
    IF @ctype = 'GRA'
        SET @risk = CHOOSE(CAST(RAND()*100 AS INT)+1,
            'NO','NO','NO','NO','NO','NO','NO','NO','NO','NO',
            'PP','PP',
            'DE',
            'DU',
            'PE');
    ELSE IF @ctype = 'MED'
        SET @risk = CHOOSE(CAST(RAND()*100 AS INT)+1,
            'NO','NO','NO','NO','NO','NO','NO','NO','NO','NO',
            'PP','PP','PP',
            'DE','DE',
            'DU',
            'PE','PE');
    ELSE IF @ctype = 'PEQ'
        SET @risk = CHOOSE(CAST(RAND()*100 AS INT)+1,
            'NO','NO','NO','NO','NO',
            'PP','PP','PP','PP','PP','PP',
            'DE','DE',
            'DU','DU',
            'PE','PE');
    ELSE
        SET @risk = CHOOSE(CAST(RAND()*100 AS INT)+1,
            'NO','NO',
            'PP','PP','PP','PP','PP','PP',
            'DE','DE','DE','DE',
            'DU','DU','DU',
            'PE','PE','PE');

    -- Línea de crédito autorizada
    DECLARE @auth NUMERIC(15,2);
    IF @ctype = 'GRA' SET @auth = ROUND((RAND() * (50000000 - 12000000) + 12000000)/1000,0)*1000;
    ELSE IF @ctype = 'MED' SET @auth = ROUND((RAND() * (12000000 - 9000000) + 9000000)/1000,0)*1000;
    ELSE IF @ctype = 'PEQ' SET @auth = ROUND((RAND() * (9000000 - 800000) + 800000)/1000,0)*1000;
    ELSE SET @auth = ROUND((RAND() * (800000 - 10000) + 10000)/1000,0)*1000;

    -- Línea de crédito usada (hasta 5% más)
    DECLARE @used NUMERIC(15,2) = ROUND(@auth * (RAND() * 1.05), 2);

    -- Insertar cliente
    INSERT INTO bank.client (
        client_id, client_name, client_type_id, risk_category_id,
        credit_line_authorized_amount, credit_line_used_amount,
        author_id, written_at
    )
    VALUES (
        @client_id, @name, @ctype, @risk,
        @auth, @used, 'SYSTEM', SYSDATETIMEOFFSET()
    );

    SET @i += 1;
END;
GO