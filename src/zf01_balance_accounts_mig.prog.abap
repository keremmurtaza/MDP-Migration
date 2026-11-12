*&---------------------------------------------------------------------*
*& Report ZF01_BALANCE_ACCOUNTS_MIG
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zf01_balance_accounts_mig.

INCLUDE zf01_balance_accounts_mig_sel."Selection Screen
INCLUDE zf01_balance_accounts_mig_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW balance_accounts_migration( bukrs ).
  migration->process( ).
