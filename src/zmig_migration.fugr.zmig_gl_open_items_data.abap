FUNCTION zmig_gl_open_items_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(GJAHR) TYPE  FKK_RT_GJAHR
*"     VALUE(GL_ACCOUNTS) TYPE  FKK_RT_HKONT
*"     VALUE(DOCUMENTS) TYPE  BKK_R_BELNR
*"     VALUE(GRP_INDICATOR) TYPE  CHAR255
*"  TABLES
*"      RESULT STRUCTURE  ZMIG_GL_BALANCE
*"----------------------------------------------------------------------

  TRY.
      SELECT FROM acdoca
        INNER JOIN t001 ON acdoca~rbukrs = t001~bukrs
        LEFT OUTER JOIN bset ON acdoca~rbukrs = bset~bukrs
                            AND acdoca~gjahr  = bset~gjahr
                            AND acdoca~belnr  = bset~belnr
                            AND acdoca~buzei  = bset~buzei
        LEFT OUTER JOIN bkpf ON acdoca~rbukrs = bkpf~bukrs
                            AND acdoca~gjahr  = bkpf~gjahr
                            AND acdoca~belnr  = bkpf~belnr
        LEFT OUTER JOIN bseg ON acdoca~rbukrs = bseg~bukrs
                            AND acdoca~gjahr  = bseg~gjahr
                            AND acdoca~belnr  = bseg~belnr
                            AND acdoca~buzei  = bseg~buzei
        FIELDS
        acdoca~rldnr  AS ldgrp,
        acdoca~rbukrs AS bukrs,
        acdoca~gjahr,
*        acdoca~poper,
        bkpf~bktxt,
        bseg~sgtxt,
        acdoca~rassc,
        acdoca~rmvct,
        acdoca~racct AS hkont,
        acdoca~ps_psp_pnr AS pspnr,
        acdoca~rwcur AS waers,
        acdoca~wsl   AS wrbtr,
        t001~waers   AS hwaer,
        acdoca~hsl   AS dmbtr,
        ( 'EUR' )    AS hwae2,
        acdoca~ksl   AS dmbe2,
        acdoca~segment AS fb_segment,
        bset~txjcd,
        acdoca~pernr,
        acdoca~nplnr,
        acdoca~gkont,
        acdoca~blart,
        acdoca~bldat,
        bkpf~acc_principle,
        acdoca~mwskz,
        acdoca~zuonr,
        acdoca~valut,
        acdoca~hbkid,
        acdoca~hktid,
        bseg~kostl,
        acdoca~prctr,
        acdoca~aufnr,
        acdoca~budat     AS pstng_date,
        @grp_indicator AS /1lt/grp_indicator,
        acdoca~bschl AS newbs_saknr
        WHERE acdoca~rldnr   = '0L'
*          AND acdoca~rrcty   = '0'
          AND acdoca~bttype <> 'RFBC'
          AND acdoca~augbl = ''
          AND acdoca~rbukrs = @bukrs
          AND acdoca~gjahr IN @gjahr
          AND acdoca~racct IN @gl_accounts
          AND acdoca~belnr IN @documents
        INTO TABLE @DATA(acdoca).
    CATCH cx_sy_dynamic_osql_semantics INTO DATA(lx_sql).
  ENDTRY.

  result[] = CORRESPONDING #( acdoca ).

  DATA(counter) = 1.
  LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
    <result>-ldgrp = ''.
    <result>-docln = counter.
    counter += 1.
    <result>-xblnr = |{ <result>-hkont } Migration|.
*    <result>-bktxt = <result>-sgtxt = branch_gl_migration.

*    IF <result>-wrbtr IS INITIAL OR <result>-dmbtr IS INITIAL OR <result>-dmbe2 IS INITIAL.
*      DELETE result.
*    ENDIF.
  ENDLOOP.

ENDFUNCTION.
