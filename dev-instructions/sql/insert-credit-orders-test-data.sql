-- ========================================
-- 💳 Generar solicitudes de crédito por cliente
-- ========================================
DECLARE @cid VARCHAR(16), @ctype VARCHAR(3), @risk VARCHAR(2), @auth NUMERIC(15,2), @used NUMERIC(15,2);
DECLARE client_cursor CURSOR FOR
    SELECT client_id, client_type_id, risk_category_id, credit_line_authorized_amount, credit_line_used_amount
    FROM bank.client;

OPEN client_cursor;
FETCH NEXT FROM client_cursor INTO @cid, @ctype, @risk, @auth, @used;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @remaining NUMERIC(15,2) = @used;
    DECLARE @max INT;
    IF @ctype = 'GRA' SET @max = CAST(RAND()*100 AS INT);
    ELSE IF @ctype = 'MED' SET @max = CAST(RAND()*50 AS INT);
    ELSE IF @ctype = 'PEQ' SET @max = CAST(RAND()*10 AS INT);
    ELSE SET @max = CAST(RAND()*3 AS INT);

    DECLARE @j INT = 0;
    DECLARE @accum NUMERIC(15,2) = 0;

    WHILE @j < @max AND @accum < @used
    BEGIN
        DECLARE @state VARCHAR(3);
        IF @ctype = 'GRA' SET @state = CHOOSE(CAST(RAND()*100 AS INT)+1, 'APR','APR','APR','APR','APR','APR','APR','APR','APR','PRO','DES');
        ELSE IF @ctype = 'MED' SET @state = CHOOSE(CAST(RAND()*100 AS INT)+1, 'APR','APR','APR','APR','APR','APR','APR','PRO','DES');
        ELSE IF @ctype = 'PEQ' SET @state = CHOOSE(CAST(RAND()*100 AS INT)+1, 'APR','APR','PRO','PRO','PRO','DES');
        ELSE SET @state = CHOOSE(CAST(RAND()*100 AS INT)+1, 'APR','PRO','DES','DES','DES');

        DECLARE @amount NUMERIC(15,2) = ROUND((RAND() * (@auth/10)) + 1000, 2);
        IF @accum + @amount > @used SET @amount = @used - @accum;

        DECLARE @rate NUMERIC(5,2);
        IF @ctype = 'GRA' SET @rate = ROUND(RAND() * 2.5 + 0.5, 2);
        ELSE IF @ctype = 'MED' SET @rate = ROUND(RAND() * 4 + 3, 2);
        ELSE IF @ctype = 'PEQ' SET @rate = ROUND(RAND() * 5 + 5, 2);
        ELSE SET @rate = ROUND(RAND() * 20 + 10, 2);

        DECLARE @written DATE = DATEADD(DAY, -730 + @j * 10, GETDATE());
        WHILE DATENAME(WEEKDAY, @written) IN ('Saturday', 'Sunday')
        BEGIN SET @written = DATEADD(DAY, 1, @written); END;

        DECLARE @due DATE = DATEADD(DAY, 30 + @j * 5, @written);
        WHILE DATENAME(WEEKDAY, @due) IN ('Saturday', 'Sunday')
        BEGIN SET @due = DATEADD(DAY, 1, @due); END;

        INSERT INTO bank.credit_orders (
            client_id, amount, interest_rate, due_date,
            client_type_id, risk_category_id,
            credit_line_authorized_amount, credit_line_used_amount,
            credit_state_id, author_id, written_at
        )
        VALUES (
            @cid, @amount, @rate, @due,
            @ctype, @risk, @auth, @used,
            @state, 'SYSTEM', SYSDATETIMEOFFSET()
        );

        IF @state = 'APR'
            SET @accum = @accum + @amount;

        SET @j += 1;
    END;

    FETCH NEXT FROM client_cursor INTO @cid, @ctype, @risk, @auth, @used;
END;

CLOSE client_cursor;
DEALLOCATE client_cursor;
GO