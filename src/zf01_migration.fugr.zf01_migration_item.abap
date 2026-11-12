FUNCTION zf01_migration_item.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(AWKEY_RANGE) TYPE  TRGR_AWKEY
*"  TABLES
*"      ANEP_BSEG STRUCTURE  ZF01_ASSET_MIGRATION_BSEG
*"----------------------------------------------------------------------

  SELECT bukrs, anln1, anln2, gjahr, awkey, pswsl FROM bseg
   WHERE awkey IN @awkey_range
    INTO TABLE @anep_bseg.

ENDFUNCTION.
