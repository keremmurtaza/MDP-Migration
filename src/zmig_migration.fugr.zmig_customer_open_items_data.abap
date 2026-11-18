FUNCTION zmig_customer_open_items_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(GJAHR) TYPE  GJAHR
*"     VALUE(CUSTOMERS) TYPE  FKK_RT_KUNNR
*"     VALUE(DOCUMENTS) TYPE  BKK_R_BELNR
*"     VALUE(GRP_INDICATOR) TYPE  CHAR255
*"  TABLES
*"      RESULT STRUCTURE  ZMIG_CUSTOMER_OPEN_ITEMS
*"----------------------------------------------------------------------

  SELECT FROM bsid
    LEFT JOIN t001  AS t01 ON bsid~bukrs = t01~bukrs
    LEFT OUTER JOIN bkpf ON bsid~belnr = bkpf~belnr
                        AND bsid~gjahr = bkpf~gjahr
                        AND bsid~bukrs = bkpf~bukrs
    LEFT OUTER JOIN bseg ON bseg~belnr = bsid~belnr
                        AND bseg~bukrs = bsid~bukrs
                        AND bseg~gjahr = bsid~gjahr
                        AND bseg~buzei = bsid~buzei
           FIELDS bsid~bukrs,
                  bsid~xblnr,
                  bsid~kunnr,
                  bsid~buzei AS docln,
*                bsid~gl_account,
                  bsid~gkont,
                  bsid~blart,
                  bsid~umskz,
                  bsid~bldat,
                  bkpf~bktxt,
                  bsid~sgtxt,
                  bsid~waers,
                  t01~waers AS hwaer,
*                bsid~hwaer,
                  CASE bsid~shkzg WHEN 'H' THEN -bsid~dmbtr ELSE bsid~dmbtr END AS dmbtr,
                  CASE bsid~shkzg WHEN 'H' THEN -bsid~wrbtr ELSE bsid~wrbtr END AS wrbtr,
                  bseg~h_hwae2 AS hwae2,
                  CASE bsid~shkzg WHEN 'H' THEN -bsid~dmbe2 ELSE bsid~dmbe2 END AS dmbe2,
                  bseg~h_hwae3 AS hwae3,
                  bsid~dmbe3,
*                  CASE bsid~shkzg WHEN 'H' THEN -bsid~dmbe3 ELSE bsid~dmbe3 END AS dmbe3,
                  bsid~mwskz,
                  bsid~bupla,
*                bsid~vatdate,
*                bsid~tax_calc_date,
                  bsid~zterm,
                  bsid~zfbdt,
                  bsid~zlsch,
                  bsid~zlspr,
                  bsid~mschl,
                  bsid~kidno,
                  bsid~zbd1t,
                  bsid~zbd1p,
                  bsid~zbd2t,
                  bsid~zbd2p,
                  bsid~zbd3t,
                  CASE bsid~shkzg WHEN 'H' THEN -bsid~skfbt ELSE bsid~skfbt END AS skfbt,
*                bsid~acskt,
                  bsid~hbkid,
                  bsid~hktid,
                  bsid~bvtyp,
*                  bsid~kkber,
                  bsid~lzbkz,
                  bsid~landl,
                  bsid~xref1,
                  bsid~xref2,
                  bsid~xref3,
*                bseg~posid,
                  bsid~prctr,
                  bsid~fkber,
                  bsid~zuonr,
                  bsid~budat AS pstng_date,
                  @grp_indicator AS /1lt/grp_indicator,
                  "LSMW
                  bsid~budat,
                  bkpf~kursf,
                  bsid~umskz AS newum,
                  bsid~projk,
*                  bsid~ebeln,
*                  bsid~ebelp,
                  bsid~sknto,
                  bsid~belnr,
                  bsid~buzei
*                  bsid~zbdxt
            WHERE bsid~bukrs = @bukrs
              AND bsid~gjahr = @gjahr
              AND bsid~kunnr IN @customers
              AND bsid~belnr IN @documents
             INTO CORRESPONDING FIELDS OF TABLE @result.

  DATA(counter) = 1.
  LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

    <result>-docln = counter.
    counter += 1.

  ENDLOOP.

ENDFUNCTION.
