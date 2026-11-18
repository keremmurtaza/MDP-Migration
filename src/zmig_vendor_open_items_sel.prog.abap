*&---------------------------------------------------------------------*
*& Include          ZMIG_VENDOR_OPEN_ITEMS_SEL
*&---------------------------------------------------------------------*
TABLES bsik.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
  SELECT-OPTIONS docmnts FOR bsik-belnr.
  PARAMETERS gjahr TYPE gjahr OBLIGATORY.
  SELECT-OPTIONS vendors FOR bsik-lifnr.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
