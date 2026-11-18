*&---------------------------------------------------------------------*
*& Report ZMIG_BANK_ACC_BALANCE
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmig_bank_acc_balance.

INCLUDE zmig_bank_acc_balance_sel."Selection Screen
INCLUDE zmig_bank_acc_balance_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW bab_migration( bukrs ).
  migration->process( ).
