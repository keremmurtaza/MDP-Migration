*&---------------------------------------------------------------------*
*& Report ZMIG_ASSET
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmig_asset.

INCLUDE zmig_asset_sel. "Selection Screen
INCLUDE zmig_asset_cls. "Classes

START-OF-SELECTION.

  DATA(migration) = NEW asset_migration( bukrs ).
  migration->process( ).
