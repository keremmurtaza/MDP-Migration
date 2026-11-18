*&---------------------------------------------------------------------*
*& Include          ZMIG_BALANCE_ACCOUNTS_SEL
*&---------------------------------------------------------------------*
TABLES bsis.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
  SELECT-OPTIONS docmnts FOR bsis-belnr.
  PARAMETERS gjahr TYPE gjahr OBLIGATORY.
  SELECT-OPTIONS accounts FOR bsis-hkont.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
