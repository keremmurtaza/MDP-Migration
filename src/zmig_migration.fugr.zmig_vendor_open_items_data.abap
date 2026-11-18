FUNCTION zmig_vendor_open_items_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(GJAHR) TYPE  GJAHR
*"     VALUE(VENDORS) TYPE  /DSD/CA_LIFNR_TT
*"     VALUE(DOCUMENTS) TYPE  BKK_R_BELNR
*"     VALUE(GRP_INDICATOR) TYPE  CHAR255
*"  TABLES
*"      RESULT STRUCTURE  ZMIG_VENDOR_OPEN_ITEMS
*"----------------------------------------------------------------------

  SELECT FROM bsik
       LEFT JOIN t001  AS t01 ON bsik~bukrs = t01~bukrs
       LEFT OUTER JOIN bkpf ON bsik~belnr = bkpf~belnr
                           AND bsik~gjahr = bkpf~gjahr
                           AND bsik~bukrs = bkpf~bukrs
       LEFT OUTER JOIN bseg ON bseg~belnr = bsik~belnr
                           AND bseg~bukrs = bsik~bukrs
                           AND bseg~gjahr = bsik~gjahr
                           AND bseg~buzei = bsik~buzei
           FIELDS bsik~bukrs,
                  bsik~xblnr,
                  bsik~lifnr,
                  bsik~buzei AS docln,
*                bsik~gl_account,
                  bsik~gkont,
                  bsik~blart,
                  bsik~umskz,
                  bsik~bldat,
                  bkpf~bktxt,
                  bsik~sgtxt,
                  bsik~waers,
*                bsik~hwaer,
                 t01~waers AS hwaer,
                  CASE bsik~shkzg WHEN 'H' THEN -bsik~dmbtr ELSE bsik~dmbtr END AS dmbtr,
                  CASE bsik~shkzg WHEN 'H' THEN -bsik~wrbtr ELSE bsik~wrbtr END AS wrbtr,
                  bseg~h_hwae2 AS hwae2,
                  CASE bsik~shkzg WHEN 'H' THEN -bsik~dmbe2 ELSE bsik~dmbe2 END AS dmbe2,
                  bseg~h_hwae3 AS hwae3,
                  bsik~dmbe3,
*                  CASE bsik~shkzg WHEN 'H' THEN -bsik~dmbe3 ELSE bsik~dmbe3 END AS dmbe3,
                  bsik~mwskz,
                  bsik~bupla,
*                bsik~vatdate,
*                bsik~tax_calc_date,
                  bsik~zterm,
                  bsik~zfbdt,
                  bsik~zlsch,
                  bsik~zlspr,
*                bsik~mschl,
                  bsik~kidno,
                  bsik~zbd1t,
                  bsik~zbd1p,
                  bsik~zbd2t,
                  bsik~zbd2p,
                  bsik~zbd3t,
                  CASE bsik~shkzg WHEN 'H' THEN -bsik~skfbt ELSE bsik~skfbt END AS skfbt,
*                bsik~acskt,
                  bsik~hbkid,
                  bsik~hktid,
                  bsik~bvtyp,
*                bsik~kkber,
                  bsik~lzbkz,
                  bsik~landl,
                  bsik~xref1,
                  bsik~xref2,
                  bsik~xref3,
*                bseg~posid,
                  bsik~prctr,
                  bsik~fkber,
                  bsik~zuonr,
                  bsik~budat AS pstng_date,
                  bsik~belnr,
                  bsik~buzei,
                  @grp_indicator AS /1lt/grp_indicator,
                  "LSMW
                  bsik~budat,
                  bkpf~kursf,
                  bsik~umskz AS newum,
                  bsik~projk,
                  bsik~ebeln,
                  bsik~ebelp,
                  bsik~sknto
            WHERE bsik~bukrs = @bukrs
              AND bsik~gjahr = @gjahr
              AND bsik~lifnr IN @vendors
              AND bsik~belnr IN @documents
             INTO CORRESPONDING FIELDS OF TABLE @result.

  DATA(counter) = 1.
  LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

    <result>-docln = counter.
    counter += 1.

  ENDLOOP.

ENDFUNCTION.
