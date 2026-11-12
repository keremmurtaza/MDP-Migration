*&---------------------------------------------------------------------*
*& Report ZF01_BANK_ACC_BALANCE_MIG
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zf01_bank_acc_balance_mig.

INCLUDE zf01_bank_acc_balance_sel."Selection Screen
INCLUDE zf01_bank_acc_balance_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW bab_migration( bukrs ).
  migration->process( ).
