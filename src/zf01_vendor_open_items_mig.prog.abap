*&---------------------------------------------------------------------*
*& Report ZF01_VENDOR_OPEN_ITEMS_MIG
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zf01_vendor_open_items_mig.

INCLUDE zf01_vendor_open_items_sel."Selection Screen
INCLUDE zf01_vendor_open_items_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW voi_migration( bukrs ).
  migration->process( ).
