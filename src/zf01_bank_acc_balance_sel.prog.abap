*&---------------------------------------------------------------------*
*& Include          ZF01_BANK_ACC_BALANCE_SEL
*&---------------------------------------------------------------------*
TABLES: fclm_bam_amd, fqm_flow.
SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  PARAMETERS bukrs TYPE bukrs OBLIGATORY.
*  PARAMETERS gjahr TYPE gjahr OBLIGATORY.
  SELECT-OPTIONS iban FOR fclm_bam_amd-iban.
  SELECT-OPTIONS user FOR fqm_flow-create_user.
  PARAMETERS test  TYPE abap_boolean AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK main.
