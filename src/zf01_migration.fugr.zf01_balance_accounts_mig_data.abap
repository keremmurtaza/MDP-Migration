FUNCTION zf01_balance_accounts_mig_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(GJAHR) TYPE  GJAHR
*"     VALUE(ACCOUNTS) TYPE  FKK_RT_HKONT
*"     VALUE(DOCUMENTS) TYPE  BKK_R_BELNR
*"     VALUE(GRP_INDICATOR) TYPE  CHAR255
*"  TABLES
*"      RESULT STRUCTURE  ZF01_BALANCE_ACCOUNTS
*"----------------------------------------------------------------------

  TRY.
      SELECT FROM acdoca
        INNER JOIN t001 ON acdoca~rbukrs = t001~bukrs
        FIELDS
        acdoca~rldnr  AS ldgrp,
        acdoca~rbukrs AS bukrs,
        acdoca~gjahr,
*        acdoca~poper,
        acdoca~rassc,
        acdoca~rmvct,
        acdoca~racct,
        acdoca~ps_psp_pnr AS pspnr,
        acdoca~rwcur AS waers,
        SUM( acdoca~wsl ) AS wrbtr,
        t001~waers AS hwaer,
        SUM( acdoca~hsl ) AS dmbtr,
        ( 'EUR' ) AS hwae2,
        SUM( acdoca~ksl ) AS dmbe2,
        @grp_indicator AS /1lt/grp_indicator
        WHERE rldnr = '0L'
          AND rrcty = '0'
          AND rbukrs = @bukrs
          AND gjahr  = @gjahr
          AND racct IN @accounts
          AND belnr IN @documents
        GROUP BY
          rldnr,
          rbukrs,
          gjahr,
*          poper,
          rassc,
          rmvct,
          racct,
          ps_psp_pnr,
          rwcur,
          waers
        INTO TABLE @DATA(acdoca).
    CATCH cx_sy_dynamic_osql_semantics INTO DATA(lx_sql).
  ENDTRY.

  result[] = CORRESPONDING #( acdoca ).

  DATA(counter) = 1.
  LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

    IF <result>-wrbtr IS INITIAL AND <result>-dmbtr IS INITIAL AND <result>-dmbe2 IS INITIAL.
      DELETE result.
      CONTINUE.
    ENDIF.

    <result>-ldgrp = ''.
    <result>-docln = counter.
    counter += 1.
    <result>-xblnr = |{ <result>-racct } Migration|.
    <result>-hkont = <result>-racct.
  ENDLOOP.

ENDFUNCTION.
