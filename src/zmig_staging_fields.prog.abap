*&---------------------------------------------------------------------*
*& Report ZMIG_STAGING_FIELDS
*& Migration: Field list of the Migration Cockpit staging tables
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zmig_staging_fields.

include zmig_staging_fields_sel. "Selection Screen
include zmig_staging_fields_cls. "Classes

start-of-selection.

  data(staging_fields) = new staging_fields( ).
  staging_fields->process( ).
