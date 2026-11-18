*&---------------------------------------------------------------------*
*& Report ZMIG_CUSTOMER_OPEN_ITEMS
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zmig_customer_open_items.

include zmig_customer_open_items_sel. "Selection Screen
include zmig_customer_open_items_cls. "Classes

start-of-selection.

  data(migration) = new coi_migration( bukrs ).
  migration->process( ).
