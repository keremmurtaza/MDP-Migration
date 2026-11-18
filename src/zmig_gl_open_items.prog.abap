*&---------------------------------------------------------------------*
*& Report ZMIG_GL_OPEN_ITEMS
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zmig_gl_open_items.

include zmig_gl_open_items_sel. "Selection Screen
include zmig_gl_open_items_cls. "Classes

start-of-selection.

  data(migration) = new gl_open_items_migration( bukrs ).
  migration->process( ).
