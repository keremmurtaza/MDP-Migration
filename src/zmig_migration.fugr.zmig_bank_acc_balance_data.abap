FUNCTION zmig_bank_acc_balance_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(IBAN_NUMBERS) TYPE  FKK_RT_IBAN
*"     VALUE(CREATE_USERS) TYPE  FKK_RT_UNAME
*"     VALUE(GRP_INDICATOR) TYPE  CHAR255
*"  TABLES
*"      RESULT STRUCTURE  ZMIG_BANK_ACCOUNT_BALANCE
*"----------------------------------------------------------------------

  SELECT FROM fclm_bam_amd AS fclm
       INNER JOIN t012k        AS t012  ON fclm~acc_num = t012~bankn
                                       AND fclm~bukrs   = t012~bukrs
       INNER JOIN fqm_flow     AS flow  ON t012~hkont   = flow~fi_account
                                       AND t012~waers   = flow~currency
           FIELDS t012~waers AS account_id,
                  fclm~iban,
                  t012~hkont AS glaccount,
                  SUM( flow~amount ) AS balance_amount,
                  t012~waers AS balance_currency,
                  @grp_indicator AS /1lt/grp_indicator
            WHERE fclm~bukrs = @bukrs
              AND fclm~iban IN @iban_numbers
              AND flow~create_user IN @create_users
         GROUP BY t012~waers, fclm~iban, t012~hkont, t012~waers
             INTO CORRESPONDING FIELDS OF TABLE @result.

ENDFUNCTION.
