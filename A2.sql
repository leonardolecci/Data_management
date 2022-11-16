USE H_Accounting;
DELIMITER $$

DROP PROCEDURE if EXISTS LL_PL_Statement;

CREATE PROCEDURE LL_PL_Statement()
BEGIN

DECLARE revenue INT;
DECLARE ret_ref_disc INT;
DECLARE cogs INT;

SET revenue = (SELECT SUM(jeli.credit) AS revenue
FROM account
         INNER JOIN journal_entry_line_item AS jeli
                    ON account.account_id = jeli.account_id
         INNER JOIN journal_entry AS je
                    ON jeli.journal_entry_id = je.journal_entry_id
WHERE profit_loss_section_id = 68
  AND je.entry_date >= '2017'
  AND je.entry_date < '2018'
  AND je.company_id = 1);

SET ret_ref_disc = (SELECT  SUM(jeli.credit) AS ret_ref_disc
FROM account
         INNER JOIN journal_entry_line_item AS jeli
                    ON account.account_id = jeli.account_id
         INNER JOIN journal_entry AS je
                    ON jeli.journal_entry_id = je.journal_entry_id
WHERE profit_loss_section_id = 69
  AND je.entry_date >= '2017'
  AND je.entry_date < '2018'
   AND je.company_id = 1);
SET cogs = (SELECT  SUM(jeli.credit) AS cogs
FROM account
         INNER JOIN journal_entry_line_item AS jeli
                    ON account.account_id = jeli.account_id
         INNER JOIN journal_entry AS je
                    ON jeli.journal_entry_id = je.journal_entry_id
WHERE profit_loss_section_id = 74
  AND je.entry_date >= '2017'
  AND je.entry_date < '2018'
   AND je.company_id = 1);

SELECT revenue, ret_ref_disc, cogs;

END $$

CALL LL_PL_Statement();