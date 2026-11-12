*&---------------------------------------------------------------------*
*& Include          ZF01_GL_OPEN_ITEMS_SEL
*&---------------------------------------------------------------------*
TABLES bsis.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
  SELECT-OPTIONS docmnts FOR bsis-belnr.
  SELECT-OPTIONS gjahr   FOR bsis-gjahr.
  SELECT-OPTIONS hkonts  FOR bsis-hkont.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
