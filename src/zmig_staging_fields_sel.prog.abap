*&---------------------------------------------------------------------*
*& Include          ZMIG_STAGING_FIELDS_SEL
*&---------------------------------------------------------------------*
TABLES: dd02l, tadir.

SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-h01.
  SELECT-OPTIONS stgtabs  FOR dd02l-tabname DEFAULT '/1LT/DS*' OPTION CP.
  SELECT-OPTIONS packages FOR tadir-devclass.
  PARAMETERS object TYPE zmig_object.
SELECTION-SCREEN END OF BLOCK main.
