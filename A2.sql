USE H_Accounting;

DELIMITER $$

DROP PROCEDURE if EXISTS LL_PL_Statement;

CREATE PROCEDURE LL_PL_Statement(varCalendarYear SMALLINT)
BEGIN

    -- Declaring variables where I'll store my PL accounts
    DECLARE revenue FLOAT;
    DECLARE ret_ref_disc FLOAT;
    DECLARE cogs FLOAT;
    DECLARE adm_exp FLOAT;
    DECLARE sell_exp FLOAT;
    DECLARE other_exp FLOAT;
    DECLARE other_inc FLOAT;
    DECLARE income_tax FLOAT;
    DECLARE other_tax FLOAT;

-- CALCULATE revenue
    SET revenue = (SELECT SUM(jeli.credit) AS revenue
                   FROM account
                            INNER JOIN journal_entry_line_item AS jeli
                                       ON account.account_id = jeli.account_id
                            INNER JOIN journal_entry AS je
                                       ON jeli.journal_entry_id = je.journal_entry_id
                   WHERE profit_loss_section_id = 68
                     AND YEAR(je.entry_date) = varCalendarYear
                     AND je.company_id = 1);


-- CALCULATE RETURNS, REFUNDS, DISCOUNTS

    SET ret_ref_disc = (SELECT SUM(jeli.credit) AS ret_ref_disc
                        FROM account
                                 INNER JOIN journal_entry_line_item AS jeli
                                            ON account.account_id = jeli.account_id
                                 INNER JOIN journal_entry AS je
                                            ON jeli.journal_entry_id = je.journal_entry_id
                        WHERE profit_loss_section_id = 69
                          AND YEAR(je.entry_date) = varCalendarYear
                          AND je.company_id = 1);

-- CALCULATE COST OF GOOD SOLD

    SET cogs = (SELECT SUM(jeli.credit) AS cogs
                FROM account
                         INNER JOIN journal_entry_line_item AS jeli
                                    ON account.account_id = jeli.account_id
                         INNER JOIN journal_entry AS je
                                    ON jeli.journal_entry_id = je.journal_entry_id
                WHERE profit_loss_section_id = 74
                  AND YEAR(je.entry_date) = varCalendarYear
                  AND je.company_id = 1);

-- CALCULATE ADMINISTRATIVE EXPENSES

    SET adm_exp = (SELECT SUM(jeli.credit) AS adm_exp
                   FROM account
                            INNER JOIN journal_entry_line_item AS jeli
                                       ON account.account_id = jeli.account_id
                            INNER JOIN journal_entry AS je
                                       ON jeli.journal_entry_id = je.journal_entry_id
                   WHERE profit_loss_section_id = 75
                     AND YEAR(je.entry_date) = varCalendarYear
                     AND je.company_id = 1);

-- CALCULATE SELLING EXPENSES

    SET sell_exp = (SELECT SUM(jeli.credit) AS sell_exp
                    FROM account
                             INNER JOIN journal_entry_line_item AS jeli
                                        ON account.account_id = jeli.account_id
                             INNER JOIN journal_entry AS je
                                        ON jeli.journal_entry_id = je.journal_entry_id
                    WHERE profit_loss_section_id = 76
                      AND YEAR(je.entry_date) = varCalendarYear
                      AND je.company_id = 1);

-- CALCULATE OTHER EXPENSES

    SET other_exp = (SELECT SUM(jeli.credit) AS other_exp
                     FROM account
                              INNER JOIN journal_entry_line_item AS jeli
                                         ON account.account_id = jeli.account_id
                              INNER JOIN journal_entry AS je
                                         ON jeli.journal_entry_id = je.journal_entry_id
                     WHERE profit_loss_section_id = 77
                       AND YEAR(je.entry_date) = varCalendarYear
                       AND je.company_id = 1);

-- CALCULATE OTHER INCOME

    SET other_inc = (SELECT SUM(jeli.credit) AS other_inc
                     FROM account
                              INNER JOIN journal_entry_line_item AS jeli
                                         ON account.account_id = jeli.account_id
                              INNER JOIN journal_entry AS je
                                         ON jeli.journal_entry_id = je.journal_entry_id
                     WHERE profit_loss_section_id = 78
                       AND YEAR(je.entry_date) = varCalendarYear
                       AND je.company_id = 1);

-- CALCULATE INCOME TAX

    SET income_tax = (SELECT SUM(jeli.credit) AS income_tax
                      FROM account
                               INNER JOIN journal_entry_line_item AS jeli
                                          ON account.account_id = jeli.account_id
                               INNER JOIN journal_entry AS je
                                          ON jeli.journal_entry_id = je.journal_entry_id
                      WHERE profit_loss_section_id = 79
                        AND YEAR(je.entry_date) = varCalendarYear
                        AND je.company_id = 1);


-- CALCULATE OTHER TAX

    SET other_tax = (SELECT SUM(jeli.credit) AS other_tax
                     FROM account
                              INNER JOIN journal_entry_line_item AS jeli
                                         ON account.account_id = jeli.account_id
                              INNER JOIN journal_entry AS je
                                         ON jeli.journal_entry_id = je.journal_entry_id
                     WHERE profit_loss_section_id = 80
                       AND YEAR(je.entry_date) = varCalendarYear
                       AND je.company_id = 1);


    SELECT IFNULL(revenue, 0),
           IFNULL(ret_ref_disc, 0),
           IFNULL(cogs, 0),
           IFNULL(adm_exp, 0),
           IFNULL(sell_exp, 0),
           IFNULL(other_exp, 0),
           IFNULL(other_inc, 0),
           IFNULL(income_tax, 0),
           IFNULL(other_tax, 0),
           (IFNULL(revenue, 0) - IFNULL(ret_ref_disc, 0) - IFNULL(cogs, 0) - IFNULL(adm_exp, 0) - IFNULL(sell_exp, 0) -
            IFNULL(other_exp, 0)
               - IFNULL(other_inc, 0) - IFNULL(income_tax, 0) - IFNULL(other_tax, 0)) AS Net_Profit_Loss;


END $$

CALL LL_PL_Statement(2017);