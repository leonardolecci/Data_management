USE H_Accounting;

DELIMITER $$
-- STORED PROCEDURE FOR CALCULATING BALANCE SHEET

DROP PROCEDURE if EXISTS LL_BS_Statement;

CREATE PROCEDURE LL_BS_Statement(varCalendarYear INT)
BEGIN

    -- Declaring variables where I'll store my PL accounts

    DECLARE i INT;
    DECLARE statement_section VARCHAR(35);
    DECLARE a FLOAT;
    DECLARE b FLOAT;


    -- setting year

    SET @year = varCalendarYear;
    SET @prev_year = varCalendarYear - 1;

    -- setting company id to 1

    SET @comp_id = 1;

    -- dummy var saying if we are getting values for BS (1), or PL (0)

    SET @PL_BS = 0;

    -- t is the counter to offset the returned statement section id in the WHERE subquery
    SET @t = 0;

    -- i si the counter fot he while loop
    SET i = -(SELECT COUNT(*)
              FROM statement_section
              WHERE company_id = 1
                AND is_balance_sheet_section = 0);

    DROP TABLE if EXISTS final_statements;
    CREATE TABLE final_statements
    (
        Account           VARCHAR(35),
        Current_Year      VARCHAR(25),
        Past_Year         VARCHAR(25),
        Percentage_Change VARCHAR(25)
    );

    -- trying something
    WHILE i < 0
        DO
            -- getting the field to put in the table
            SET @sql =
                    'SELECT @field := statement_section FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t;

            -- querying for the year specified

            SET @SQL = 'SELECT @amount := IFNULL(SUM(jeli.credit), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE profit_loss_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t, @Year, @comp_id;
            DEALLOCATE PREPARE stmt;

            -- querying for year previous to specified

            SET @SQL = 'SELECT @amount_prev_year := IFNULL(SUM(jeli.credit), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE profit_loss_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t, @prev_year, @comp_id;
            DEALLOCATE PREPARE stmt;

             SET a = CAST(@amount AS DECIMAL(65,2));
             SET b = CAST(@amount_prev_year AS DECIMAL(65,2));

            SET @perc_change = CONCAT(FORMAT(IFNULL(((a - b) / b) * 100, 0),2), '%');

            INSERT INTO final_statements VALUES (@field, FORMAT(@amount, 2), FORMAT(@amount_prev_year, 2), @perc_change);
            SET @t = @t + 1;
            SET i = i + 1;
        END WHILE;

    SELECT *
    FROM final_statements;
END $$


CALL LL_BS_Statement(2017);


