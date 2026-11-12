*&---------------------------------------------------------------------*
*& Include          ZF01_ASSET_MIGRATION_SEL
*&---------------------------------------------------------------------*
TABLES anla.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
  PARAMETERS gjahr TYPE gjahr OBLIGATORY.
  SELECT-OPTIONS assets FOR anla-anln1.
  SELECT-OPTIONS orgast FOR anla-aibn1.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
