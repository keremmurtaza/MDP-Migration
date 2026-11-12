*&---------------------------------------------------------------------*
*& Include          ZF01_CUSTOMER_OPEN_ITEMS_SEL
*&---------------------------------------------------------------------*
TABLES bsid.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
  SELECT-OPTIONS docmnts FOR bsid-belnr.
  PARAMETERS gjahr TYPE gjahr OBLIGATORY.
  SELECT-OPTIONS custmrs FOR bsid-kunnr.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
