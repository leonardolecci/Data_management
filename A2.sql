USE H_Accounting;

-- STORED PROCEDURE FOR CALCULATING PROFIT AND LOSS

DELIMITER $$
DROP PROCEDURE if EXISTS LL_PL_Statement;
CREATE PROCEDURE LL_PL_Statement(varCalendarYear INT)
BEGIN
    -- declaring variables
    DECLARE i INT DEFAULT 0;
    DECLARE statement_section VARCHAR(35);
    -- a,b will be used to calculate the percentage change
    DECLARE a DOUBLE DEFAULT 0;
    DECLARE b DOUBLE DEFAULT 0;
    -- setting year in a global variable to be used in prepared statement SQL
    SET @year = varCalendarYear;
    SET @prev_year = varCalendarYear - 1;
    -- setting company id to 1
    SET @comp_id = 1;
    -- dummy var saying if we are getting values for BS (1), or PL (0)
    SET @PL_BS = 0;
    -- t is the counter to offset the returned statement section id in the WHERE sub-query
    SET @t = 0;
    -- i si the counter fot he while loop
    SET i = -(SELECT COUNT(*)
              FROM statement_section
              WHERE company_id = 1
                AND is_balance_sheet_section = 0);
    -- creating table to store the final PL statements with percentage changes
    DROP TABLE if EXISTS final_PL_statements;
    CREATE TABLE final_PL_statements
    (
        Account           VARCHAR(35),
        Current_Year      DOUBLE,
        Past_Year         DOUBLE,
        Percentage_Change VARCHAR(35)
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
                             AND je.company_id = ?
                             AND cancelled = 0)';
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
                             AND je.company_id = ?
                             AND cancelled = 0)';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @PL_BS, @comp_id, @t, @prev_year, @comp_id;
            DEALLOCATE PREPARE stmt;
            -- calculating percentage change
            SET @percentage_change =
                    CONCAT(FORMAT(IFNULL(((@amount - @amount_prev_year) / @amount_prev_year) * 100, 0), 2), '%');
            -- insert data into table
            INSERT INTO final_PL_statements
            VALUES (@field, ROUND(@amount, 2), ROUND(@amount_prev_year, 2), @percentage_change);
            SET @t = @t + 1;
            SET i = i + 1;
        END WHILE;
    -- calculating Net Profit(loss) and its percentage change and putting it into the table


    SET a = (SELECT (SELECT Current_Year FROM final_PL_statements LIMIT 1) - SUM(IFNULL(Current_Year, 0))
             FROM final_PL_statements
             WHERE Account != 'NET PROFIT/LOSS'
               AND Account != 'REVENUE');

    SET b = (SELECT (SELECT Past_Year FROM final_PL_statements LIMIT 1) - SUM(IFNULL(Past_Year, 0))
             FROM final_PL_statements
             WHERE Account != 'NET PROFIT/LOSS'
               AND Account != 'REVENUE');
    SET @percentage_change = CONCAT(FORMAT(IFNULL(((a - b) / b) * 100, 0), 2), '%');
    INSERT INTO final_PL_statements
    VALUES ('NET PROFIT/LOSS', ROUND(a, 2), ROUND(b, 2), @percentage_change);
    SELECT Account, FORMAT(Current_Year, 2) AS Current_Year, FORMAT(Past_Year, 2) AS Past_Year, Percentage_Change
    FROM final_PL_statements;
END $$


-- CREATING PROCEDURE FOR THE BALANCE SHEET


DELIMITER $$
DROP PROCEDURE if EXISTS LL_BS_Statement;
CREATE PROCEDURE LL_BS_Statement(varCalendarYear INT)
BEGIN
    -- Declaring variables
    DECLARE i INT DEFAULT 0;
    DECLARE statement_section VARCHAR(35);
    DECLARE total_asset_cy DOUBLE DEFAULT 0;
    DECLARE total_liabilities_equity_cy DOUBLE DEFAULT 0;
    DECLARE total_asset_py DOUBLE DEFAULT 0;
    DECLARE total_liabilities_equity_py DOUBLE DEFAULT 0;
    -- setting year as a global variable to be used in the prepared statements SQL
    SET @year = varCalendarYear;
    SET @prev_year = varCalendarYear - 1;
    -- setting company id to 1
    SET @comp_id = 1;
    -- dummy var saying if we are getting values for BS (1), or PL (0)
    SET @BS = 1;
    -- t is the counter to offset the returned statement section id in the WHERE subquery
    SET @t = 0;
    -- i si the counter fot he while loop
    SET i = -(SELECT COUNT(*)
              FROM statement_section
              WHERE company_id = 1
                AND is_balance_sheet_section = 1);
    -- creating table to store the final BS statement with percentage changes
    DROP TABLE if EXISTS final_BS_statements;
    CREATE TABLE final_BS_statements
    (
        Account           VARCHAR(35),
        Current_Year      DOUBLE,
        Past_Year         DOUBLE,
        Percentage_Change VARCHAR(25)
    );
    -- while loop to get all the accounts of the BS statements for the specified and its previous year
    -- calculate the percentage change and storing all in the table final_BS_statements
    WHILE i < 0
        DO
            -- getting the field to put in the table
            SET @sql =
                    'SET @field = (SELECT statement_section FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)';
            PREPARE stmt FROM @sql;
            EXECUTE stmt USING @BS, @comp_id, @t;
            -- IF statement to see if it is an asset or liabilities/equity to be calculated
            IF @field LIKE ('%ASSETS%') THEN
                -- assets --> debit - credit
                SET @SQL = 'SET @amount = (SELECT IFNULL((SUM(jeli.debit) - SUM(jeli.credit)), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE balance_sheet_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?
                             AND cancelled = 0)';
                PREPARE stmt FROM @sql;
                EXECUTE stmt USING @BS, @comp_id, @t, @Year, @comp_id;
                DEALLOCATE PREPARE stmt;
                -- querying for year previous to specified
                SET @SQL = 'SET @amount_prev_year = (SELECT IFNULL((SUM(jeli.debit) - SUM(jeli.credit)), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE balance_sheet_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?
                             AND cancelled = 0)';
                PREPARE stmt FROM @sql;
                EXECUTE stmt USING @BS, @comp_id, @t, @prev_year, @comp_id;
                DEALLOCATE PREPARE stmt;

            ELSE
                -- Liability/equity --> credit - debit
                SET @SQL = 'SET @amount = (SELECT IFNULL((SUM(jeli.credit) - SUM(jeli.debit)), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE balance_sheet_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?
                             AND cancelled = 0)';
                PREPARE stmt FROM @sql;
                EXECUTE stmt USING @BS, @comp_id, @t, @Year, @comp_id;
                DEALLOCATE PREPARE stmt;
                -- querying for year previous to specified
                SET @SQL = 'SET @amount_prev_year = (SELECT IFNULL((SUM(jeli.credit) - SUM(jeli.debit)), 0)
                           FROM account
                                    INNER JOIN journal_entry_line_item AS jeli
                                               ON account.account_id = jeli.account_id
                                    INNER JOIN journal_entry AS je
                                               ON jeli.journal_entry_id = je.journal_entry_id
                           WHERE balance_sheet_section_id = (SELECT statement_section_id FROM statement_section WHERE is_balance_sheet_section = ? AND company_id = ? LIMIT ?, 1)
                             AND YEAR(je.entry_date) = ?
                             AND je.company_id = ?
                             AND cancelled = 0)';
                PREPARE stmt FROM @sql;
                EXECUTE stmt USING @BS, @comp_id, @t, @prev_year, @comp_id;
                DEALLOCATE PREPARE stmt;

            END IF;
            -- calculating percentage change
            SET @percentage_change =
                    CONCAT(FORMAT(IFNULL(((@amount - @amount_prev_year) / @amount_prev_year) * 100, 0), 2), '%');
            -- insert data into table
            INSERT INTO final_BS_statements
            VALUES (@field, ROUND(@amount, 2), ROUND(@amount_prev_year, 2), @percentage_change);
            SET @t = @t + 1;
            SET i = i + 1;
        END WHILE;
    -- calculating variable for TA, TLE for year specified
    SET total_asset_cy = (SELECT SUM(current_year) FROM final_BS_statements WHERE Account LIKE '%ASSETS%');
    SET total_asset_py = (SELECT SUM(past_year) FROM final_BS_statements WHERE Account LIKE '%ASSETS%');
    -- calculating percentage change for total assets
    SET @percentage_change =
            CONCAT(FORMAT(IFNULL(((total_asset_cy - total_asset_py) / total_asset_py) * 100, 0), 2), '%');
    INSERT INTO final_BS_statements
    VALUES ('TOTAL ASSETS', ROUND(total_asset_cy, 2), ROUND(total_asset_py, 2), @percentage_change);
    -- calculating variable for TA, TLE for previous year
    SET total_liabilities_equity_cy =
            (SELECT SUM(current_year) FROM final_BS_statements WHERE Account NOT LIKE '%ASSETS%');
    SET total_liabilities_equity_py =
            (SELECT SUM(past_year) FROM final_BS_statements WHERE Account NOT LIKE '%ASSETS%');
    -- calculating percentage change for total liabilities and equity
    SET @percentage_change = CONCAT(FORMAT(IFNULL(((total_liabilities_equity_cy - total_liabilities_equity_py) /
                                                   total_liabilities_equity_py) * 100, 0), 2), '%');
    INSERT INTO final_BS_statements
    VALUES ('TOTAL LIABILITIES AND EQUITY', ROUND(total_liabilities_equity_cy, 2),
            ROUND(total_liabilities_equity_py, 2), @percentage_change);
    SELECT Account, FORMAT(Current_Year, 2) AS Current_Year, FORMAT(Past_Year, 2) AS Past_Year, Percentage_Change
    FROM final_BS_statements;
END $$

-- CREATING PROCEDURE TO CALCULATE CASH FLOW STATEMENT
DELIMITER $$
DROP PROCEDURE if EXISTS LL_CF_Statement;
CREATE PROCEDURE LL_CF_Statement(varCalendarYear INT)
BEGIN
    -- DECLARING VARIABLES
    DECLARE net_income DOUBLE DEFAULT 0;
    DECLARE deferred_liabilities DOUBLE DEFAULT 0;
    DECLARE working_capital_cy DOUBLE DEFAULT 0;
    DECLARE working_capital_py DOUBLE DEFAULT 0;
    DECLARE change_working_capital DOUBLE DEFAULT 0;
    DECLARE CF_operating_activities DOUBLE DEFAULT 0;
    DECLARE issued_debt_equity DOUBLE DEFAULT 0;
    DECLARE dividends_paid DOUBLE DEFAULT 0;
    DECLARE repurchase_debt_equity DOUBLE DEFAULT 0;
    DECLARE CF_financing_activities DOUBLE DEFAULT 0;
    DECLARE purchase_sale_ppe DOUBLE DEFAULT 0;
    DECLARE purchase_sale_marketable_securities DOUBLE DEFAULT 0;
    DECLARE CF_investing_activities DOUBLE DEFAULT 0;
    DECLARE purchase_sale_business DOUBLE DEFAULT 0;
    DECLARE total_CF DOUBLE DEFAULT 0;

-- CALLING THE STORED PROCEDURES FOR PL AND BS FOR THE SPECIFIED YEAR
    CALL LL_BS_Statement(varCalendarYear);
    CALL LL_PL_Statement(varCalendarYear);

-- CREATING TABLE FOR CASH FLOW STATEMENT
    DROP TABLE if EXISTS final_CF_statement;
    CREATE TABLE final_CF_statement
    (
        Account      VARCHAR(100),
        Current_Year DOUBLE
    );

    -- CALCULATING CASH FLOW FROM OPERATING ACTIVITIES
    -- get net income
    SET net_income = (SELECT Current_Year FROM final_PL_statements WHERE Account = 'NET PROFIT/LOSS');
    INSERT INTO final_CF_statement
    VALUES ('Net Income', net_income);
    -- get non-cash expenses (deferred liabilities)
    SET deferred_liabilities = (SELECT Current_Year FROM final_BS_statements WHERE Account = 'DEFERRED LIABILITIES');
    INSERT INTO final_CF_statement
    VALUES ('Deferred Liabilities', deferred_liabilities);
    -- get change in net working capital
    SET working_capital_cy = (SELECT Current_Year FROM final_BS_statements WHERE Account = 'CURRENT ASSETS') -
                             (SELECT Current_Year FROM final_BS_statements WHERE Account = 'CURRENT LIABILITIES');
    SET working_capital_py = (SELECT Past_Year FROM final_BS_statements WHERE Account = 'CURRENT ASSETS') -
                             (SELECT Past_Year FROM final_BS_statements WHERE Account = 'CURRENT LIABILITIES');
    SET change_working_capital = working_capital_cy - working_capital_py;
    INSERT INTO final_CF_statement
    VALUES ('Change in Net Working Capital', change_working_capital);
    SET CF_operating_activities = net_income + deferred_liabilities - change_working_capital;
    INSERT INTO final_CF_statement
    VALUES ('CASH FLOW FROM OPERATING ACTIVITIES', CF_operating_activities);

    -- CALCULATING CASH FLOW FROM FINANCING ACTIVITIES
    -- get Cash Inflows From Issuing Equity or Debt
    SET issued_debt_equity = (
        -- calculating if there is any short term debt
            (SELECT IFNULL(SUM(debt), 0)
             FROM (SELECT IF(SUM(credit) - SUM(debit) < 0, 0, SUM(credit) - SUM(debit)) AS debt
                   FROM journal_entry
                            INNER JOIN journal_entry_line_item jeli
                                       on journal_entry.journal_entry_id = jeli.journal_entry_id
                            INNER JOIN account a on jeli.account_id = a.account_id
                   WHERE journal_entry.company_id = @comp_id
                     AND balance_sheet_section_id = 64
                     AND (journal_entry LIKE '%loan%' OR journal_entry LIKE '%debt%')
                     AND cancelled = 0
                     AND YEAR(entry_date) = varCalendarYear
                   GROUP BY account) AS shortd) +
            -- calculating if there is any long term debt
            (SELECT IFNULL(SUM(debt), 0)
             FROM (SELECT IF(SUM(credit) - SUM(debit) < 0, 0, SUM(credit) - SUM(debit)) AS debt
                   FROM journal_entry
                            INNER JOIN journal_entry_line_item jeli
                                       on journal_entry.journal_entry_id = jeli.journal_entry_id
                            INNER JOIN account a on jeli.account_id = a.account_id
                   WHERE journal_entry.company_id = @comp_id
                     AND balance_sheet_section_id = 65
                     AND (journal_entry LIKE '%loan%' OR journal_entry LIKE '%debt%')
                     AND cancelled = 0
                     AND YEAR(entry_date) = varCalendarYear
                   GROUP BY account) AS longd) +
            -- calculating if they have issued stock
            (SELECT IFNULL(SUM(equity), 0)
             FROM (SELECT IF(SUM(credit) - SUM(debit) < 0, 0, SUM(credit) - SUM(debit)) AS equity
                   FROM journal_entry
                            INNER JOIN journal_entry_line_item jeli
                                       on journal_entry.journal_entry_id = jeli.journal_entry_id
                            INNER JOIN account a on jeli.account_id = a.account_id
                   WHERE journal_entry.company_id = @comp_id
                     AND balance_sheet_section_id = 67
                     AND (journal_entry LIKE '%issued%')
                     AND cancelled = 0
                     AND YEAR(entry_date) = varCalendarYear
                   GROUP BY account) AS equity));
    INSERT INTO final_CF_statement
    VALUES ('Cash Inflows from Issuing Debt or Equity', issued_debt_equity);
    -- get Dividends Paid
    SET dividends_paid = (SELECT IFNULL(SUM(debit), 0)
                          FROM journal_entry
                                   INNER JOIN journal_entry_line_item jeli
                                              on journal_entry.journal_entry_id = jeli.journal_entry_id
                                   INNER JOIN account a on jeli.account_id = a.account_id
                          WHERE journal_entry.company_id = @comp_id
                            AND balance_sheet_section_id = 64
                            AND journal_entry LIKE '%dividend%'
                            AND cancelled = 0
                            AND YEAR(entry_date) = varCalendarYear);
    INSERT INTO final_CF_statement
    VALUES ('Dividends Paid', dividends_paid);
    -- get Repurchase of Debt and Equity
    SET repurchase_debt_equity = ((SELECT IFNULL(SUM(debt), 0)
                                   FROM (SELECT IF(SUM(debit) - SUM(credit) < 0, 0, SUM(debit) - SUM(credit)) AS debt
                                         FROM journal_entry
                                                  INNER JOIN journal_entry_line_item jeli
                                                             on journal_entry.journal_entry_id = jeli.journal_entry_id
                                                  INNER JOIN account a on jeli.account_id = a.account_id
                                         WHERE journal_entry.company_id = @comp_id
                                           AND balance_sheet_section_id = 64
                                           AND (journal_entry LIKE '%loan%' OR journal_entry LIKE '%debt%')
                                           AND cancelled = 0
                                           AND YEAR(entry_date) = varCalendarYear
                                         GROUP BY account) AS shortd) +
        -- calculating if there is any long term debt
                                  (SELECT IFNULL(SUM(debt), 0)
                                   FROM (SELECT IF(SUM(debit) - SUM(credit) < 0, 0, SUM(debit) - SUM(credit)) AS debt
                                         FROM journal_entry
                                                  INNER JOIN journal_entry_line_item jeli
                                                             on journal_entry.journal_entry_id = jeli.journal_entry_id
                                                  INNER JOIN account a on jeli.account_id = a.account_id
                                         WHERE journal_entry.company_id = @comp_id
                                           AND balance_sheet_section_id = 65
                                           AND (journal_entry LIKE '%loan%' OR journal_entry LIKE '%debt%')
                                           AND cancelled = 0
                                           AND YEAR(entry_date) = varCalendarYear
                                         GROUP BY account) AS shortd) +
        -- calculating if they have issued stock
                                  (SELECT IFNULL(SUM(debt), 0)
                                   FROM (SELECT IF(SUM(debit) - SUM(credit) < 0, 0, SUM(debit) - SUM(credit)) AS debt
                                         FROM journal_entry
                                                  INNER JOIN journal_entry_line_item jeli
                                                             on journal_entry.journal_entry_id = jeli.journal_entry_id
                                                  INNER JOIN account a on jeli.account_id = a.account_id
                                         WHERE journal_entry.company_id = @comp_id
                                           AND balance_sheet_section_id = 67
                                           AND journal_entry LIKE '%issued%'
                                           AND cancelled = 0
                                           AND YEAR(entry_date) = varCalendarYear
                                         GROUP BY account) AS shortd));
    INSERT INTO final_CF_statement
    VALUES ('Cash Outflows from Repurchase of Debt or Equity', repurchase_debt_equity);
    SET CF_financing_activities = issued_debt_equity - dividends_paid - repurchase_debt_equity;
    INSERT INTO final_CF_statement
    VALUES ('CASH FLOW FROM FINANCING ACTIVITIES', CF_financing_activities);
    -- CALCULATING CASH FLOW FROM INVESTING ACTIVITIES
    -- get Purchase/Sale of Property and Equipment
    SET purchase_sale_ppe = (SELECT IFNULL(SUM(debit) - SUM(credit), 0)
                             FROM journal_entry
                                      INNER JOIN journal_entry_line_item jeli
                                                 on journal_entry.journal_entry_id = jeli.journal_entry_id
                                      INNER JOIN account a on jeli.account_id = a.account_id
                             WHERE journal_entry.company_id = @comp_id
                               AND balance_sheet_section_id = 62
                               AND ((journal_entry LIKE '%property%' OR journal_entry LIKE '%plant%' OR
                                     journal_entry LIKE '%equipment%' OR journal_entry LIKE '%ppe%')
                                 OR (description LIKE '%property%' OR description LIKE '%plant%' OR
                                     description LIKE '%equipment%' OR description LIKE '%ppe%'))
                               AND cancelled = 0
                               AND YEAR(entry_date) = varCalendarYear);
    INSERT INTO final_CF_statement
    VALUES ('Purchase/Sale of Property and Equipment', purchase_sale_ppe);
    -- get Purchase/Sale of Other Businesses
    SET purchase_sale_business = (SELECT IFNULL(SUM(debit) - SUM(credit), 0)
                                  FROM journal_entry
                                           INNER JOIN journal_entry_line_item jeli
                                                      on journal_entry.journal_entry_id = jeli.journal_entry_id
                                           INNER JOIN account a on jeli.account_id = a.account_id
                                  WHERE journal_entry.company_id = @comp_id
                                    AND balance_sheet_section_id = 62
                                    AND ((journal_entry LIKE '%equity%' OR journal_entry LIKE '%equity_investment%')
                                      OR (description LIKE '%equity%' OR description LIKE '%equity_investment%'))
                                    AND cancelled = 0
                                    AND YEAR(entry_date) = varCalendarYear);
    INSERT INTO final_CF_statement
    VALUES ('Purchase/Sale of Other Businesses', purchase_sale_business);
    -- get Purchase/Sale of Marketable Securities
    SET purchase_sale_marketable_securities = (SELECT IFNULL(SUM(debit) - SUM(credit), 0)
                                               FROM journal_entry
                                                        INNER JOIN journal_entry_line_item jeli
                                                                   on journal_entry.journal_entry_id = jeli.journal_entry_id
                                                        INNER JOIN account a on jeli.account_id = a.account_id
                                               WHERE journal_entry.company_id = @comp_id
                                                 AND balance_sheet_section_id = 61
                                                 AND ((journal_entry LIKE '%marketable_security%')
                                                   OR (description LIKE '%marketable_security%'))
                                                 AND cancelled = 0
                                                 AND YEAR(entry_date) = varCalendarYear);
    INSERT INTO final_CF_statement
    VALUES ('Purchase/Sale of Marketable Securities', purchase_sale_marketable_securities);
    -- CALCULATING TOTAL CASH FLOW
    SET CF_investing_activities = - purchase_sale_ppe - purchase_sale_business - purchase_sale_marketable_securities;
    INSERT INTO final_CF_statement
    VALUES ('CASH FLOW FROM INVESTING ACTIVITIES', CF_investing_activities);
    -- sum all three subsection of the CF statement
    SET total_CF = CF_operating_activities + CF_financing_activities + CF_investing_activities;
    INSERT INTO final_CF_statement
    VALUES ('TOTAL CASH FLOW', total_CF);

    SELECT Account, FORMAT(Current_Year, 2) AS USD
    FROM final_CF_statement;

END $$

CALL LL_CF_Statement(2017);