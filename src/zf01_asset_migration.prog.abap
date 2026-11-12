*&---------------------------------------------------------------------*
*& Report ZF01_ASSET_MIGRATION
*& SUP_KMURTAZA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zf01_asset_migration.

INCLUDE zf01_asset_migration_sel. "Selection Screen
INCLUDE zf01_asset_migration_cls. "Classes

START-OF-SELECTION.

  DATA(migration) = NEW asset_migration( bukrs ).
  migration->process( ).
