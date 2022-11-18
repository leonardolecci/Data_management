USE H_Accounting;

-- STORED PROCEDURE FOR CALCULATING PROFIT AND LOSS

DELIMITER $$
DROP PROCEDURE if EXISTS LL_PL_Statement;
CREATE PROCEDURE LL_PL_Statement(varCalendarYear INT)
BEGIN
    -- Declaring variables where I'll store my PL accounts
    DECLARE i INT;
    DECLARE statement_section VARCHAR(35);
    DECLARE a DOUBLE;
    DECLARE b DOUBLE;
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
    -- creating table to store the final PL statements with percentage changes
    DROP TABLE if EXISTS final_statements;
    CREATE TABLE final_statements
    (
        Account           VARCHAR(35),
        Current_Year      VARCHAR(25),
        Past_Year         VARCHAR(25),
        Percentage_Change VARCHAR(25)
    );
    -- while loop to get all the accounts of the PL statements for the specified and its previous year
    -- calculate the percentage change and storing all in the table final_statements
    WHILE i < 0
        DO
            -- getting the field to put in the table
            SET @sql =
                    'SET @field = (SELECT statement_section FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t;
            -- querying for the year specified
            SET @SQL = 'SET @amount = (SELECT IFNULL(SUM(jeli.credit), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE profit_loss_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?)';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t, @Year, @comp_id;
            DEALLOCATE PREPARE stmt;
            -- querying for year previous to specified
            SET @SQL = 'SET @amount_prev_year = (SELECT IFNULL(SUM(jeli.credit), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE profit_loss_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?)';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t, @prev_year, @comp_id;
            DEALLOCATE PREPARE stmt;
            -- converting global var into FLOAT var
            SET a = CAST(@amount AS DECIMAL(65, 2));
            SET b = CAST(@amount_prev_year AS DECIMAL(65, 2));
            SET @perc_change = CONCAT(FORMAT(IFNULL(((a - b) / b) * 100, 0), 2), '%');
            -- insert data into table
            INSERT INTO final_statements
            VALUES (@field, ROUND(@amount, 2), ROUND(@amount_prev_year, 2), @perc_change);
            SET @t = @t + 1;
            SET i = i + 1;
        END WHILE;
    SET @tr = (SELECT SUM(CAST(Current_Year AS DECIMAL(65, 2))) FROM final_statements);
    SET @trr = (SELECT SUM(Past_Year) FROM final_statements);
    SET a = CAST(@tr AS DECIMAL(65, 2));
    SET b = CAST(@trr AS DECIMAL(65, 2));
    SET @perc_change = CONCAT(FORMAT(IFNULL(((a - b) / b) * 100, 0), 2), '%');
    INSERT INTO final_statements
    VALUES ('Net Profit/Loss', CONCAT('', a), CONCAT('', b), @perc_change);

    SELECT *
    FROM final_statements;
END $$

CALL LL_PL_Statement(2017);