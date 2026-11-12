*&---------------------------------------------------------------------*
*& Include          ZF01_ASSET_MIGRATION_CLS
*&---------------------------------------------------------------------*
CLASS migration_dao DEFINITION.

  PUBLIC SECTION.
    METHODS get_migration_tables
      IMPORTING migration_project       TYPE zf01_migration_project
      RETURNING VALUE(migration_tables) TYPE zf01_if_migration_types=>table_types-tt_staging_tables.

    METHODS get_fields_to_be_changed
      IMPORTING bukrs                       TYPE bukrs
      RETURNING VALUE(fields_to_be_changed) TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed.

    METHODS get_header_data
      IMPORTING bukrs                  TYPE bukrs
                assets_filter          TYPE zf01_if_migration_types=>ranges-assets_filter
                original_assets_filter TYPE zf01_if_migration_types=>ranges-original_assets_filter
                grp_indicator          TYPE char255
      RETURNING VALUE(header_data)     TYPE zf01_if_migration_types=>table_types-tt_header_fields.

    METHODS get_item_data
      IMPORTING bukrs                  TYPE bukrs
                gjahr                  TYPE gjahr
                assets_filter          TYPE zf01_if_migration_types=>ranges-assets_filter
                original_assets_filter TYPE zf01_if_migration_types=>ranges-original_assets_filter
                grp_indicator          TYPE char255
      RETURNING VALUE(item_data)       TYPE zf01_if_migration_types=>table_types-tt_item_fields.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zf01_mig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zf01_asset_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_header_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) ).

    DATA(options) = VALUE zf01_if_migration_types=>table_types-tt_rfc_db_options( ( |BUKRS = '{ bukrs }'| ) ).

    "Assets Filter
    IF assets_filter IS NOT INITIAL.
      options = zf01_cl_migration=>range_to_options( range_table     = assets_filter
                                                     field_name      = 'ANLN1'
                                                     current_options = options ).
    ENDIF.

    "Original Assets Filter
    DATA(anla_options) = options.
    IF original_assets_filter IS NOT INITIAL.
      anla_options = zf01_cl_migration=>range_to_options( range_table     = original_assets_filter
                                                          field_name      = 'AIBN1'
                                                          current_options = options ).
    ENDIF.

    "Exclude assets with both AKTIV date and original asset number is initial. Example asset on TS4-050 1002-32000034
    anla_options = VALUE #( BASE anla_options ( | AND ( AKTIV <> '00000000' OR AIBN1 <> '' ) | ) ).

    "Get ANLA Data
    DATA anla TYPE TABLE OF anla.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLA'
                                                 destination  = destination
                                                 options      = anla_options
                                       CHANGING  result_table = anla ).
    "Get ANLH Data
    DATA anlh TYPE TABLE OF anlh.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLH'
                                                 destination  = destination
                                                 options      = options
                                       CHANGING  result_table = anlh ).
    "Get ANLZ Data
    DATA anlz TYPE TABLE OF anlz.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLZ'
                                                 destination  = destination
                                                 options      = options
                                       CHANGING  result_table = anlz ).

    LOOP AT anla ASSIGNING FIELD-SYMBOL(<anla>).

      TRY.
          header_data = VALUE #( BASE header_data
                                 ( bukrs         = <anla>-bukrs
                                   anln1         = <anla>-anln1
                                   anln2         = <anla>-anln2
                                   anlkl         = <anla>-anlkl
                                   txt50         = <anla>-txt50
                                   txa50_more    = <anla>-txa50
                                   sernr         = <anla>-sernr
                                   invnr         = <anla>-invnr
                                   menge         = <anla>-menge
                                   meins         = <anla>-meins
                                   main_descript = anlh[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 ]-anlhtxt
                                   aktiv         = <anla>-aktiv
                                   deakt         = <anla>-deakt
                                   gplab         = <anla>-gplab
                                   bstdt         = <anla>-bstdt
                                   evalgroup1    = <anla>-ord41
                                   evalgroup2    = <anla>-ord42
                                   evalgroup3    = <anla>-ord43
                                   evalgroup4    = <anla>-ord44
                                   evalgroup5    = <anla>-gdlgrp
                                   inv_reason    = <anla>-izwek
                                   envir_invest  = <anla>-umwkz
                                   assetsupno    = <anla>-anlue
                                   vendor_no     = <anla>-lifnr
                                   type_name     = <anla>-typbz
                                   orig_acq_date = <anla>-aibdt
                                   gsber         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-gsber
                                   kostl         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-kostl
                                   kostlv        = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-kostlv
                                   lstar         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-lstar
                                   caufn         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-caufn
                                   iaufn         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-iaufn
                                   werks         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-werks
                                   stort         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-stort
                                   raumn         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-raumn
                                   kfzkz         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-kfzkz
                                   pernr         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-pernr
                                   xstil         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-xstil
                                   geber         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-geber
                                   grant_nbr     = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-grant_nbr
                                   fistl         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-fistl
                                   ps_psp_pnr2   = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-ps_psp_pnr2
                                   taxjurcode    = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-txjcd
                                   imkey         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-imkey
                                   budget_pd     = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-budget_pd
                                   segment       = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-segment
                                   prctr         = anlz[ bukrs = <anla>-bukrs anln1 = <anla>-anln1 anln2 = <anla>-anln2 ]-prctr
                                   /1lt/grp_indicator = grp_indicator ) ).
        CATCH cx_sy_itab_line_not_found.
          header_data = VALUE #( BASE header_data ( CORRESPONDING #( <anla> ) ) ).
      ENDTRY.

    ENDLOOP.


*    LOOP AT anla ASSIGNING FIELD-SYMBOL(<anla>).
*
*    TRY.
*      header_data = VALUE #( BASE header_data ( bukrs   = <anla>-bukrs
*                                                anlhtxt = anlh[ anln1 = <anla>-anln1 bukrs = <anla>-bukrs anln2 = <anla>-anln2 ]-main_descript ).
*    CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    ENDLOOP.

*    SELECT
*        anla~bukrs,
*        anla~anln1,
*        anla~anln2,
*        anla~anlkl,
*        anla~txt50,
*        anla~txa50 AS txa50_more,
*        anla~sernr,
*        anla~invnr,
*        anla~menge,
*        anla~meins,
*        anlh~anlhtxt AS main_descript,
*        anla~aktiv,
*        anla~deakt,
*        anla~gplab,
*        anla~bstdt,
*        anla~ord41 AS evalgroup1,
*        anla~ord42 AS evalgroup2,
*        anla~ord43 AS evalgroup3,
*        anla~ord44 AS evalgroup4,
*        anla~gdlgrp AS evalgroup5,
*        anla~izwek AS inv_reason,
*        anla~umwkz AS envir_invest,
*        anla~anlue AS assetsupno,
*        anla~lifnr AS vendor_no,
*        anla~typbz AS type_name,
*        anla~aibdt AS orig_acq_date,
*        anlz~gsber,
*        anlz~kostl,
*        anlz~kostlv,
*        anlz~lstar,
*        anlz~caufn,
*        anlz~iaufn,
*        anlz~werks,
*        anlz~stort,
*        anlz~raumn,
*        anlz~kfzkz,
*        anlz~pernr,
*        anlz~xstil,
*        anlz~geber,
*        anlz~grant_nbr,
*        anlz~fistl,
*        anlz~ps_psp_pnr2,
*        anlz~txjcd AS taxjurcode,
*        anlz~imkey,
*        anlz~budget_pd,
*        anlz~segment,
*        anlz~prctr,
*        @grp_indicator AS /1lt/grp_indicator   " veya grup göstergesi
*    FROM anla
*    LEFT OUTER JOIN anlh
*        ON anlh~bukrs = anla~bukrs AND anlh~anln1 = anla~anln1
*    LEFT OUTER JOIN anlz
*        ON anlz~bukrs = anla~bukrs AND anlz~anln1 = anla~anln1 AND anlz~anln2 = anla~anln2
*    WHERE anla~bukrs = @bukrs
*      AND ( anla~aktiv <> '00000000' OR anla~aibn1 <> '' )  " Aktiv veya Original Asset Filter
*      AND ( anla~anln1 IN @assets_filter )
*      AND ( anla~aibn1 IN @original_assets_filter )
*    INTO CORRESPONDING FIELDS OF TABLE @header_data.

  ENDMETHOD.

  METHOD get_item_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) ).

    SELECT SINGLE waers FROM t001
     WHERE bukrs = @bukrs
      INTO @DATA(company_code_currency).

    DATA(options) = VALUE zf01_if_migration_types=>table_types-tt_rfc_db_options( ( |BUKRS = '{ bukrs }'| ) ).

    "Assets Filter
    IF assets_filter IS NOT INITIAL.
      options = zf01_cl_migration=>range_to_options( range_table     = assets_filter
                                                     field_name      = 'ANLN1'
                                                     current_options = options ).
    ENDIF.

    "Original Assets Filter
    DATA(anla_options) = options.
    IF original_assets_filter IS NOT INITIAL.
      anla_options = zf01_cl_migration=>range_to_options( range_table     = original_assets_filter
                                                          field_name      = 'AIBN1'
                                                          current_options = options ).
    ENDIF.

    "Get ANLA Data
    DATA anla TYPE TABLE OF anla.
    DATA anla_structure TYPE anla.

    "Exclude assets with both AKTIV date and original asset number is initial. Example asset on TS4-050 1002-32000034
    anla_options = VALUE #( BASE anla_options ( | AND ( AKTIV <> '00000000' OR AIBN1 <> '' ) | ) ).

    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLA'
                                                 destination  = destination
                                                 options      = anla_options
                                       CHANGING  result_table = anla ).

    "Get ANLB Data
    DATA anlb TYPE TABLE OF anlb.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLB'
                                                 destination  = destination
                                                 options      = options
                                       CHANGING  result_table = anlb ).

    "Get ANLC Data
    DATA anlc TYPE TABLE OF anlc.
    DATA(anlc_options) = options.
    anlc_options = VALUE #( BASE anlc_options ( |AND GJAHR = '{ gjahr }'| ) ).
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANLC'
                                                 destination  = destination
                                                 options      = anlc_options
                                       CHANGING  result_table = anlc ).

    DATA anep TYPE TABLE OF anep.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'ANEP'
                                                 destination  = destination
                                                 options      = anlc_options
                                       CHANGING  result_table = anep ).

    "Get i_fixedassettp
    DATA i_fixedassettp TYPE TABLE OF i_fixedassettp.
    zf01_cl_migration=>get_table_data( EXPORTING query_table  = 'I_FIXEDASSETTP'
                                                 destination  = destination
                                                 options      = options
                                       CHANGING  result_table = i_fixedassettp ).

    DATA awkey_range TYPE RANGE OF bseg-awkey.
    LOOP AT anep ASSIGNING FIELD-SYMBOL(<anep>).

      DATA(belnr) = CONV belnr_d( |{ <anep>-belnr ALPHA = IN }| ).

      awkey_range = VALUE #( BASE awkey_range ( sign = 'I' option = 'EQ' low = |{ belnr }{ <anep>-bukrs }{ <anep>-gjahr }| ) ).

    ENDLOOP.
    UNASSIGN <anep>.

    DATA anep_bseg TYPE TABLE OF zf01_asset_migration_bseg.
    CALL FUNCTION 'ZF01_MIGRATION_ITEM'
      DESTINATION destination
      EXPORTING
        awkey_range = awkey_range                 " Range AWKEY
      TABLES
        anep_bseg   = anep_bseg.                  " BSEG Data for Asset Migration

    DATA item_data_row TYPE zf01_if_migration_types=>structures-item_fields.

    LOOP AT anep ASSIGNING <anep>.

      IF line_exists( anlc[ bukrs = <anep>-bukrs anln1 = <anep>-anln1 anln2 = <anep>-anln2 afabe = <anep>-afabe ] ).
        ASSIGN anlc[ bukrs = <anep>-bukrs anln1 = <anep>-anln1 anln2 = <anep>-anln2 afabe = <anep>-afabe ] TO FIELD-SYMBOL(<anlc>).
      ELSE.
        CONTINUE.
      ENDIF.

      IF line_exists( anla[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 ] ).

        item_data_row = CORRESPONDING #( <anlc> ).
        item_data_row = VALUE #( BASE item_data_row
                                     dzinsg = <anlc>-zinsg
                                     /1lt/grp_indicator = grp_indicator ).
        TRY.

            item_data_row = VALUE #( BASE item_data_row
                                     ndjar         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-ndjar
                                     ndper         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-ndper
                                     afasl         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-afasl
                                     umjar         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-umjar
                                     afabg         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-afabg
                                     safbg         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-safbg
                                     zinbg         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-zinbg
                                     inbda         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-inbda
                                     wbind         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-wbind
                                     alind         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-alind
                                     aprop         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-aprop
                                     schrw         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-schrw
                                     xnega         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-xnega
                                     anlgr         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-anlgr
                                     anlgr2        = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-anlgr2
                                     vyear         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-vyear
                                     vmnth         = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-vmnth
                                     schrw_proz    = anlb[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe ]-schrw_proz ).
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.

        TRY.
            item_data_row = VALUE #( BASE item_data_row
                                     assettrtyp    = anep[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe gjahr = <anlc>-gjahr ]-bwasl
                                     amount        = anep[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe gjahr = <anlc>-gjahr ]-anbtr
                                     valuedate     = anep[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 afabe = <anlc>-afabe gjahr = <anlc>-gjahr ]-bzdat
                                     current_no    = <anep>-lnran ).
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.

*        TRY.
*            item_data_row = VALUE #( BASE item_data_row
*                                         currency      = anep_bseg[ bukrs = <anlc>-bukrs anln1 = <anlc>-anln1 anln2 = <anlc>-anln2 ]-pswsl ).
*          CATCH cx_sy_itab_line_not_found.
*        ENDTRY.

        item_data_row-currency = SWITCH #( item_data_row-afabe WHEN '01' OR '15' OR '32' THEN company_code_currency WHEN '31' OR '16' OR '33' THEN 'EUR' ).

        item_data = VALUE #( BASE item_data ( item_data_row ) ).

      ENDIF.
      UNASSIGN <anlc>.
    ENDLOOP.

*    SELECT FROM anlc AS c
*     INNER JOIN anla AS a ON a~bukrs = c~bukrs
*                         AND a~anln1 = c~anln1
*                         AND a~anln2 = c~anln2
*LEFT OUTER JOIN anlb AS b ON b~bukrs = c~bukrs
*                         AND b~anln1 = c~anln1
*                         AND b~anln2 = c~anln2
*                         AND b~afabe = c~afabe
*LEFT OUTER JOIN i_fixedassettp AS f ON a~bukrs = f~companycode
*                                   AND a~anln1 = f~masterfixedasset
*                                   AND a~anln2 = f~fixedasset
*         FIELDS c~bukrs,
*                c~anln1,
*                c~anln2,
*                c~afabe,
*                c~gjahr,
*                c~kansw, "Cumulative Values
*                c~kaufw, "Cumulative Values
*                c~kinvz, "Cumulative Values
*                c~knafa, "Cumulative Values
*                c~ksafa, "Cumulative Values
*                c~kaafa, "Cumulative Values
*                c~kmafa, "Cumulative Values
*                c~kzinw, "Cumulative Values
*                c~kaufn, "Cumulative Values
*                c~kanza, "Cumulative Values
*                c~aufwb, "Posted Values
*                c~nafag, "Posted Values
*                c~safag, "Posted Values
*                c~aafag, "Posted Values
*                c~zinsg AS dzinsg, "Posted Values
*                c~aufng, "Posted Values
*                f~currency,
*                @grp_indicator AS /1lt/grp_indicator
*          WHERE c~bukrs = @bukrs
*            AND c~gjahr = @gjahr
*            AND a~anln1 IN @assets_filter
*            AND a~aibn1 IN @original_assets_filter
*          INTO CORRESPONDING FIELDS OF TABLE @item_data.

  ENDMETHOD.

ENDCLASS.

CLASS asset_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs.

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name             TYPE char30     VALUE 'ZF01_ASSET_MIGRATION'.

    DATA dao TYPE REF TO migration_dao.
    DATA bukrs TYPE bukrs.
    DATA fields_to_be_changed TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration TYPE REF TO zf01_if_migration.

    METHODS update_migration_tables
      IMPORTING master_details      TYPE zf01_if_migration_types=>table_types-tt_master_details
                posting_information TYPE zf01_if_migration_types=>table_types-tt_posting_information
                time_dependent_data TYPE zf01_if_migration_types=>table_types-tt_time_dependent_data
                allocations         TYPE zf01_if_migration_types=>table_types-tt_allocations
                origin              TYPE zf01_if_migration_types=>table_types-tt_origin
                depreciation_areas  TYPE zf01_if_migration_types=>table_types-tt_depreciation_areas
                cumulative_values   TYPE zf01_if_migration_types=>table_types-tt_cumulative_values
                posted_values       TYPE zf01_if_migration_types=>table_types-tt_posted_values
                transactions        TYPE zf01_if_migration_types=>table_types-tt_transactions
      RETURNING VALUE(result)       TYPE bapiret2_t.

ENDCLASS.

CLASS asset_migration IMPLEMENTATION.

  METHOD constructor.
    dao = COND #( WHEN dao IS BOUND THEN dao ELSE NEW migration_dao(  ) ).
    migration = COND #( WHEN migration IS BOUND THEN migration ELSE NEW zf01_cl_migration(  ) ).
    me->bukrs = bukrs.
    fields_to_be_changed = dao->get_fields_to_be_changed( bukrs ).
  ENDMETHOD.

  METHOD process.

    "Set group indicator
    DATA(grp_indicator) = CONV char255( |{ bukrs }_{ cl_abap_context_info=>get_system_date( ) }:{ cl_abap_context_info=>get_system_time( ) }_{ program_name }| ).

    "Get header data
    DATA(header_data) = dao->get_header_data( bukrs                  = bukrs
                                              assets_filter          = assets[]
                                              original_assets_filter = orgast[]
                                              grp_indicator          = grp_indicator ).
    "Get item data
    DATA(item_data)   = dao->get_item_data( bukrs                  = bukrs
                                            gjahr                  = gjahr
                                            assets_filter          = assets[]
                                            original_assets_filter = orgast[]
                                            grp_indicator          = grp_indicator ).

    "Get unchanged data to internal tables to be compared with changed ones
    "Headers
    DATA(time_dependent_data) = CORRESPONDING zf01_if_migration_types=>table_types-tt_time_dependent_data( header_data ).
    DATA(posting_information) = CORRESPONDING zf01_if_migration_types=>table_types-tt_posting_information( header_data ).
    DATA(master_details)      = CORRESPONDING zf01_if_migration_types=>table_types-tt_master_details( header_data ).
    DATA(allocations)         = CORRESPONDING zf01_if_migration_types=>table_types-tt_allocations( header_data ).
    DATA(origin)              = CORRESPONDING zf01_if_migration_types=>table_types-tt_origin( header_data ).
    "Items
    DATA(depreciation_areas)  = CORRESPONDING zf01_if_migration_types=>table_types-tt_depreciation_areas( item_data ).
    DATA(cumulative_values)   = CORRESPONDING zf01_if_migration_types=>table_types-tt_cumulative_values( item_data ).
    DATA(posted_values)       = CORRESPONDING zf01_if_migration_types=>table_types-tt_posted_values( item_data ).
    DATA(transactions)        = CORRESPONDING zf01_if_migration_types=>table_types-tt_transactions( item_data ).

    "Headers
    DATA updated_time_dependent_data TYPE zf01_if_migration_types=>table_types-tt_time_dependent_data.
    migration->update_fields( EXPORTING table = time_dependent_data fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_time_dependent_data ).

    DATA updated_posting_information TYPE zf01_if_migration_types=>table_types-tt_posting_information.
    migration->update_fields( EXPORTING table = posting_information fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_posting_information ).

    DATA updated_master_details TYPE zf01_if_migration_types=>table_types-tt_master_details.
    migration->update_fields( EXPORTING table = master_details      fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_master_details ).

    DATA updated_allocations TYPE zf01_if_migration_types=>table_types-tt_allocations.
    migration->update_fields( EXPORTING table = allocations         fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_allocations ).

    DATA updated_origin TYPE zf01_if_migration_types=>table_types-tt_origin.
    migration->update_fields( EXPORTING table = origin              fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_origin ).

    "Items
    DATA updated_depreciation_areas TYPE zf01_if_migration_types=>table_types-tt_depreciation_areas.
    migration->update_fields( EXPORTING table = depreciation_areas  fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_depreciation_areas ).

    DATA updated_cumulative_values TYPE zf01_if_migration_types=>table_types-tt_cumulative_values.
    migration->update_fields( EXPORTING table = cumulative_values   fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_cumulative_values ).

    DATA updated_posted_values TYPE zf01_if_migration_types=>table_types-tt_posted_values.
    migration->update_fields( EXPORTING table = posted_values       fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_posted_values ).

    DATA updated_transactions TYPE zf01_if_migration_types=>table_types-tt_transactions.
    migration->update_fields( EXPORTING table = transactions        fields_to_be_changed = fields_to_be_changed IMPORTING updated_table = updated_transactions ).

*    "Update header data
*    DATA updated_header_data TYPE zf01_if_migration_types=>table_types-tt_header_fields.
*    migration->update_fields( EXPORTING table                = header_data
*                                        fields_to_be_changed = fields_to_be_changed
*                              IMPORTING updated_table        = updated_header_data ).
*
*    "Update item data
*    DATA updated_item_data TYPE zf01_if_migration_types=>table_types-tt_item_fields.
*    migration->update_fields( EXPORTING table                = item_data
*                                        fields_to_be_changed = fields_to_be_changed
*                              IMPORTING updated_table        = updated_item_data ).
*
*    "Headers
*    DATA(updated_time_dependent_data) = CORRESPONDING zf01_if_migration_types=>table_types-tt_time_dependent_data( updated_header_data ).
*    DATA(updated_posting_information) = CORRESPONDING zf01_if_migration_types=>table_types-tt_posting_information( updated_header_data ).
*    DATA(updated_master_details)      = CORRESPONDING zf01_if_migration_types=>table_types-tt_master_details( updated_header_data ).
*    DATA(updated_allocations)         = CORRESPONDING zf01_if_migration_types=>table_types-tt_allocations( updated_header_data ).
*    DATA(updated_origin)              = CORRESPONDING zf01_if_migration_types=>table_types-tt_origin( updated_header_data ).
*    "Items
*    DATA(updated_depreciation_areas)  = CORRESPONDING zf01_if_migration_types=>table_types-tt_depreciation_areas( updated_item_data ).
*    DATA(updated_cumulative_values)   = CORRESPONDING zf01_if_migration_types=>table_types-tt_cumulative_values( updated_item_data ).
*    DATA(updated_posted_values)       = CORRESPONDING zf01_if_migration_types=>table_types-tt_posted_values( updated_item_data ).
*    DATA(updated_transactions)        = CORRESPONDING zf01_if_migration_types=>table_types-tt_transactions( item_data ).

    "If it's a test run, do not update asset_migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    DATA(result) = update_migration_tables( master_details      = updated_master_details
                                            posting_information = updated_posting_information
                                            time_dependent_data = updated_time_dependent_data
                                            allocations         = updated_allocations
                                            origin              = updated_origin
                                            depreciation_areas  = updated_depreciation_areas
                                            cumulative_values   = updated_cumulative_values
                                            posted_values       = updated_posted_values
                                            transactions        = updated_transactions ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zf01_cl_migration_constants=>migration_projects-mig_27 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-master_details.
          ASSIGN master_details      TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-posting_information.
          ASSIGN posting_information TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-time_dependent_data.
          ASSIGN time_dependent_data TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-allocations        .
          ASSIGN allocations         TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-origin             .
          ASSIGN origin              TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-depreciation_areas .
          ASSIGN depreciation_areas  TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-cumulative_values  .
          ASSIGN cumulative_values   TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-posted_values      .
          ASSIGN posted_values       TO <table>.
        WHEN zf01_cl_migration_constants=>asset_staging_tables-transactions       .
          ASSIGN transactions        TO <table>.
          LOOP AT transactions INTO DATA(transaction).
            "Date Conversion
            DATA(date) = CONV dats( transaction-valuedate ).
            transaction-valuedate = |{ date DATE = ENVIRONMENT }|.
          ENDLOOP.
      ENDCASE.

      "If assigning is not successfull, log it and continue with next table
      IF <table> IS NOT ASSIGNED.
        result = migration->update_messages( messages     = result
                                             message_type = zf01_cl_migration_constants=>message_class-error
                                             message_no   = zf01_cl_migration_constants=>message_class-error_msg_number
                                             message_v1   = CONV symsgv( migration_table-technical_id )
                                             message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
        CONTINUE.
      ENDIF.

      "Check if data exists
      IF NOT line_exists( <table>[ 1 ] ).
        "Update result table as no data exists
        result = migration->update_messages( messages     = result
                                             message_type = zf01_cl_migration_constants=>message_class-warning
                                             message_no   = zf01_cl_migration_constants=>message_class-no_data_msg_number
                                             message_v1   = CONV symsgv( migration_table-technical_id )
                                             message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
        CONTINUE.
      ENDIF.

      "Update Migration Table
      TRY.
          MODIFY (migration_table-technical_id) FROM TABLE <table>.
        CATCH cx_sy_open_sql_db INTO DATA(open_sql_db_ex) .
      ENDTRY.

      "Set Message Type and Message No
      DATA(message_type) = COND bapi_mtype( WHEN open_sql_db_ex IS BOUND THEN zf01_cl_migration_constants=>message_class-error ELSE zf01_cl_migration_constants=>message_class-succsess ).
      DATA(message_no)   = SWITCH symsgno( message_type WHEN zf01_cl_migration_constants=>message_class-succsess THEN zf01_cl_migration_constants=>message_class-succsess_msg_number ELSE zf01_cl_migration_constants=>message_class-error_msg_number ).

      "Update result table
      result = migration->update_messages( messages     = result
                                           message_type = message_type
                                           message_no   = message_no
                                           message_v1   = CONV symsgv( migration_table-technical_id )
                                           message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
      CLEAR open_sql_db_ex.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
