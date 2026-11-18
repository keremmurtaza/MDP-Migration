*&---------------------------------------------------------------------*
*& Report ZMIG_VENDOR_OPEN_ITEMS
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmig_vendor_open_items.

INCLUDE zmig_vendor_open_items_sel."Selection Screen
INCLUDE zmig_vendor_open_items_cls."Classes

START-OF-SELECTION.

  DATA(migration) = NEW voi_migration( bukrs ).
  migration->process( ).
