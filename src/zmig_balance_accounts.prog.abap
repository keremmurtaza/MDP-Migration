*&---------------------------------------------------------------------*
*& Report ZMIG_BALANCE_ACCOUNTS
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmig_balance_accounts.

INCLUDE zmig_balance_accounts_sel."Selection Screen
INCLUDE zmig_balance_accounts_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW balance_accounts_migration( bukrs ).
  migration->process( ).
