-- Listas base enriquecidas
DECLARE @rubros TABLE (nombre NVARCHAR(50));
INSERT INTO @rubros VALUES
('Transporte'), ('Minería'), ('Aviación'), ('Educación'),
('Librerías'), ('Supermercados'), ('Abarrotes'),
('Construcción'), ('Agroindustria'), ('Pesca'), ('Tecnología'), ('Textiles');

DECLARE @tipos_empresa TABLE (sigla NVARCHAR(10));
INSERT INTO @tipos_empresa VALUES ('SAC'), ('SA'), ('EIRL'), ('SRL'), ('SCRL');

DECLARE @nombres_base TABLE (nombre NVARCHAR(100));
-- Santos peruanos
INSERT INTO @nombres_base VALUES ('Santa Rosa'), ('San Martín de Porres'), ('San Juan Macías'), ('San Francisco Solano');
-- Provincias y distritos
INSERT INTO @nombres_base VALUES ('Cusco'), ('Tacna'), ('Piura'), ('Chiclayo'), ('Huancayo'), ('Arequipa'), ('Trujillo'), ('Iquitos'), ('Puno'), ('Ayacucho'),
('Miraflores'), ('San Borja'), ('Surco'), ('San Miguel'), ('Los Olivos'), ('Callao'), ('La Molina'), ('Villa El Salvador'), ('San Juan de Lurigancho'), ('Comas');
-- Playas
INSERT INTO @nombres_base VALUES ('Máncora'), ('Punta Sal'), ('Las Pocitas'), ('Zorritos'), ('Asia'), ('Cerro Azul'), ('San Bartolo'), ('Punta Hermosa'), ('Pucusana'), ('La Herradura'),
('El Silencio'), ('Santa María'), ('Naplo'), ('Puerto Viejo'), ('Las Sombrillas');
-- Minerales
INSERT INTO @nombres_base VALUES ('Oro'), ('Plata'), ('Cobre'), ('Zinc'), ('Estaño'), ('Molibdeno'), ('Hierro'), ('Litio'), ('Antimonio'), ('Bismuto');
-- Peces
INSERT INTO @nombres_base VALUES ('Anchoveta'), ('Bonito'), ('Jurel'), ('Caballa'), ('Mero'), ('Lenguado'), ('Corvina'), ('Pejerrey'), ('Lisa'), ('Chita'),
('Robalo'), ('Trucha'), ('Sardina'), ('Bagre'), ('Tollo');
-- Papas medievales
INSERT INTO @nombres_base VALUES ('Gregorio I'), ('León III'), ('Inocencio III'), ('Urbano II'), ('Bonifacio VIII'), ('Alejandro III'), ('Celestino V'), ('Silvestre II'), ('Benedicto IX'), ('Juan XII');
-- Países y capitales de África y Oceanía
INSERT INTO @nombres_base VALUES ('El Cairo'), ('Nairobi'), ('Lusaka'), ('Maputo'), ('Harare'), ('Kampala'), ('Yaundé'), ('Suva'), ('Apia'), ('Honiara'),
('Port Moresby'), ('Numea'), ('Antananarivo'), ('Victoria'), ('Windhoek'), ('Banjul'), ('Lilongwe'), ('Majuro'), ('Tarawa'), ('Funafuti');

-- Control de RUCs únicos
DECLARE @used_rucs TABLE (ruc VARCHAR(16));

-- Generación de clientes
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    DECLARE @client_type_id VARCHAR(3);
    DECLARE @risk_category_id VARCHAR(2);
    DECLARE @client_id VARCHAR(16);
    DECLARE @client_name NVARCHAR(256);
    DECLARE @authorized NUMERIC(15,2);
    DECLARE @used NUMERIC(15,2);

    -- Distribución por tipo
    SET @client_type_id = CASE
        WHEN @i <= 50 THEN 'GRA'
        WHEN @i <= 300 THEN 'MED'
        WHEN @i <= 700 THEN 'PEQ'
        ELSE 'MIC'
    END;

    -- RUC único
    WHILE 1 = 1
    BEGIN
        SET @client_id = CONCAT('20', FORMAT(ABS(CHECKSUM(NEWID())) % 10000000000, '0000000000'));
        IF NOT EXISTS (SELECT 1 FROM @used_rucs WHERE ruc = @client_id)
        BEGIN
            INSERT INTO @used_rucs VALUES (@client_id);
            BREAK;
        END;
    END;

    -- Nombre (puede repetirse)
    DECLARE @rubro NVARCHAR(50);
    DECLARE @tipo NVARCHAR(10);
    DECLARE @nombre1 NVARCHAR(100);
    DECLARE @nombre2 NVARCHAR(100);

    SELECT TOP 1 @rubro = nombre FROM @rubros ORDER BY NEWID();
    SELECT TOP 1 @tipo = sigla FROM @tipos_empresa ORDER BY NEWID();
    SELECT TOP 1 @nombre1 = nombre FROM @nombres_base ORDER BY NEWID();
    SELECT TOP 1 @nombre2 = nombre FROM @nombres_base ORDER BY NEWID();

    SET @client_name = CONCAT(@rubro, ' ', @nombre1, ' y ', @nombre2, ' ', @tipo);

    -- Categoría de riesgo
    SELECT @risk_category_id = CASE @client_type_id
        WHEN 'GRA' THEN CASE 
            WHEN RAND() < 0.80 THEN 'NO'
            WHEN RAND() < 0.90 THEN 'PP'
            WHEN RAND() < 0.95 THEN 'DE'
            WHEN RAND() < 0.98 THEN 'DU'
            ELSE 'PE' END
        WHEN 'MED' THEN CASE 
            WHEN RAND() < 0.70 THEN 'NO'
            WHEN RAND() < 0.85 THEN 'PP'
            WHEN RAND() < 0.95 THEN 'DE'
            WHEN RAND() < 0.96 THEN 'DU'
            ELSE 'PE' END
        WHEN 'PEQ' THEN CASE 
            WHEN RAND() < 0.50 THEN 'NO'
            WHEN RAND() < 0.80 THEN 'PP'
            WHEN RAND() < 0.85 THEN 'DE'
            WHEN RAND() < 0.90 THEN 'DU'
            ELSE 'PE' END
        WHEN 'MIC' THEN CASE 
            WHEN RAND() < 0.20 THEN 'NO'
            WHEN RAND() < 0.60 THEN 'PP'
            WHEN RAND() < 0.80 THEN 'DE'
            WHEN RAND() < 0.90 THEN 'DU'
            ELSE 'PE' END
    END;

    -- Monto autorizado
    SELECT @authorized = CASE @client_type_id
        WHEN 'GRA' THEN ROUND((12000 + FLOOR(RAND() * (50000 - 12000 + 1))) * 1000, 0)
        WHEN 'MED' THEN ROUND((9000 + FLOOR(RAND() * (12000 - 9000 + 1))) * 1000, 0)
        WHEN 'PEQ' THEN ROUND((800 + FLOOR(RAND() * (9000 - 800 + 1))) * 1000, 0)
        WHEN 'MIC' THEN ROUND((10 + FLOOR(RAND() * (800 - 10 + 1))) * 1000, 0)
    END;

    -- Monto usado
    SET @used = ROUND(@authorized * (RAND() * 1.05), 2);

    -- Insertar cliente
    INSERT INTO bank.client (
        client_id, client_name, client_type_id, risk_category_id,
        credit_line_authorized_amount, credit_line_used_amount,
        author_id, written_at
    )
    VALUES (
        @client_id, @client_name, @client_type_id, @risk_category_id,
        @authorized, @used,
        'SYSTEM',
        SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SA Pacific Standard Time'
    );

    SET @i += 1;
END;
GO