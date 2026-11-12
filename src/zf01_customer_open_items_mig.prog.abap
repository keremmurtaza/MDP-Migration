*&---------------------------------------------------------------------*
*& Report ZF01_CUSTOMER_OPEN_ITEMS_MIG
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zf01_customer_open_items_mig.

include zf01_customer_open_items_sel. "Selection Screen
include zf01_customer_open_items_cls. "Classes

start-of-selection.

  data(migration) = new coi_migration( bukrs ).
  migration->process( ).
