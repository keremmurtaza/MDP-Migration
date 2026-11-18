*&---------------------------------------------------------------------*
*& Include          ZMIG_VENDOR_OPEN_ITEMS_CLS
*&---------------------------------------------------------------------*

CLASS migration_dao DEFINITION.

  PUBLIC SECTION.
    METHODS get_migration_tables
      IMPORTING migration_project       TYPE zmig_project
      RETURNING VALUE(migration_tables) TYPE zmig_if_migration_types=>table_types-tt_staging_tables.

    METHODS get_fields_to_be_changed
      IMPORTING bukrs                       TYPE bukrs
      RETURNING VALUE(fields_to_be_changed) TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.

    METHODS get_data
      IMPORTING bukrs         TYPE bukrs
                gjahr         TYPE gjahr
                vendors       TYPE zmig_if_migration_types=>ranges-vendors_filter
                documents     TYPE zmig_if_migration_types=>ranges-document_filter
                grp_indicator TYPE char255
      RETURNING VALUE(result) TYPE zmig_if_migration_types=>table_types-tt_vendor_open_items.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zmig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zmig_voi_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) )..

    CALL FUNCTION 'ZMIG_VENDOR_OPEN_ITEMS_DATA'
      DESTINATION destination
      EXPORTING
        bukrs         = bukrs          " Company Code
        gjahr         = gjahr          " Fiscal Year
        vendors       = vendors        " Range table for vendor number
        documents     = documents
        grp_indicator = grp_indicator  " Group Indicator
      TABLES
        result        = result         " Vendor Open Items Migration: Vendor Open Items
      EXCEPTIONS
        OTHERS        = 1.

*    SELECT FROM bsik
*     INNER JOIN bkpf ON  bsik~belnr = bkpf~belnr
*                     AND bsik~gjahr = bkpf~gjahr
*     INNER JOIN bseg ON  bseg~belnr = bkpf~belnr
*                     AND bseg~bukrs = bkpf~bukrs
*                     AND bseg~gjahr = bkpf~gjahr
*                     AND bseg~koart = 'K' "Vendor
*         FIELDS bsik~bukrs,
*                bkpf~xblnr,
*                bsik~lifnr,
*                bseg~buzei AS docln,
**                bsik~gl_account,
*                bsik~gkont,
*                bsik~blart,
*                bsik~umskz,
*                bsik~bldat,
**                bsik~bktxt,
*                bsik~sgtxt,
*                bsik~waers,
**                bsik~hwaer,
*                bseg~dmbtr,
*                bseg~h_hwae2 AS hwae2,
*                bseg~dmbe2,
*                bseg~h_hwae3 AS hwae3,
*                bseg~dmbe3,
*                bseg~mwskz,
*                bsik~bupla,
**                bsik~vatdate,
**                bsik~tax_calc_date,
*                bsik~zterm,
*                bsik~zfbdt,
*                bsik~zlsch,
*                bsik~zlspr,
**                bsik~mschl,
*                bsik~kidno,
*                bsik~zbd1t,
*                bsik~zbd1p,
*                bsik~zbd2t,
*                bsik~zbd2p,
*                bsik~zbd3t,
*                bsik~skfbt,
**                bsik~acskt,
*                bsik~hbkid,
*                bsik~hktid,
*                bsik~bvtyp,
**                bsik~kkber,
*                bsik~lzbkz,
*                bsik~landl,
*                bsik~xref1,
*                bsik~xref2,
*                bsik~xref3,
**                bseg~posid,
*                bsik~prctr,
*                bsik~fkber,
*                bsik~zuonr,
*                bseg~h_budat AS pstng_date,
*                @grp_indicator AS /1lt/grp_indicator
*          WHERE bsik~bukrs = @bukrs
*            AND bsik~gjahr = @gjahr
*            AND bsik~lifnr IN @vendors
*           INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

ENDCLASS.

CLASS voi_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs.

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name TYPE char30     VALUE 'ZMIG_VENDOR_OPEN_ITEMS'.

    DATA dao                  TYPE REF TO migration_dao.
    DATA bukrs                TYPE bukrs.
    DATA fields_to_be_changed TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration            TYPE REF TO zmig_if_migration.

    METHODS update_migration_tables
      IMPORTING vendor_open_items TYPE zmig_if_migration_types=>table_types-tt_vendor_open_items
      RETURNING VALUE(result)     TYPE bapiret2_t.

    METHODS update_empty_xblnr
      CHANGING vendor_open_items TYPE zmig_if_migration_types=>table_types-tt_vendor_open_items.

ENDCLASS.

CLASS voi_migration IMPLEMENTATION.

  METHOD constructor.
    dao = COND #( WHEN dao IS BOUND THEN dao ELSE NEW migration_dao(  ) ).
    migration = COND #( WHEN migration IS BOUND THEN migration ELSE NEW zmig_cl_migration(  ) ).
    me->bukrs = bukrs.
    fields_to_be_changed = dao->get_fields_to_be_changed( bukrs ).
  ENDMETHOD.

  METHOD process.

    "Set group indicator
    DATA(grp_indicator) = CONV char255( |{ bukrs }_{ cl_abap_context_info=>get_system_date( ) }:{ cl_abap_context_info=>get_system_time( ) }_{ program_name }| ).

    "Get data
    DATA(vendor_open_items) = dao->get_data( bukrs         = bukrs
                                             gjahr         = gjahr
                                             vendors       = vendors[]
                                             documents     = docmnts[]
                                             grp_indicator = grp_indicator ).

    "Update data
    DATA updated_vendor_open_items TYPE zmig_if_migration_types=>table_types-tt_vendor_open_items.
    migration->update_fields( EXPORTING table                = vendor_open_items
                                        fields_to_be_changed = fields_to_be_changed
                              IMPORTING updated_table        = updated_vendor_open_items ).

    "Update Empty XBLNR Fields
*    update_empty_xblnr( CHANGING vendor_open_items = updated_vendor_open_items ).


    "If it's a test run, do not update migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    update_migration_tables( updated_vendor_open_items ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zmig_cl_migration_constants=>migration_projects-mig_30 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zmig_cl_migration_constants=>voi_staging_tables-vendor_open_items.
          ASSIGN vendor_open_items TO <table>.
      ENDCASE.

      "If assigning is not successfull, log it and continue with next table
      IF <table> IS NOT ASSIGNED.
        result = migration->update_messages( messages     = result
                                             message_type = zmig_cl_migration_constants=>message_class-error
                                             message_no   = zmig_cl_migration_constants=>message_class-error_msg_number
                                             message_v1   = CONV symsgv( migration_table-technical_id )
                                             message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
        CONTINUE.
      ENDIF.

      "Update Migration Table
      IF NOT line_exists( <table>[ 1 ] ).
        result = migration->update_messages( messages     = result
                                             message_type = zmig_cl_migration_constants=>message_class-warning
                                             message_no   = zmig_cl_migration_constants=>message_class-no_data_msg_number
                                             message_v1   = CONV symsgv( migration_table-technical_id )
                                             message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
        CONTINUE.
      ENDIF.

      "11.05.2025 - LSMW Part
      "Do not insert rows where UMSKZ is not initial to migration staging table
      "Insert rows with UMSKZ filled to custom LSMW table
      DATA vendor_open_items_staging  TYPE TABLE OF zmig_vendor_open_items_stg.
      DATA vendor_open_items_lsmw     TYPE TABLE OF zmig_voi_lsmw.

      LOOP AT vendor_open_items INTO DATA(vendor_open_item).

        "If GL Special Indicator is initial, insert data to staging table
        IF vendor_open_item-umskz IS INITIAL.
          vendor_open_items_staging = VALUE #( BASE vendor_open_items_staging ( CORRESPONDING #( vendor_open_item ) ) ).
        ENDIF.

        "If GL Special Indicator is initial, insert data to lsmw table
        IF vendor_open_item-umskz IS NOT INITIAL.
          DATA(vendor_open_item_lsmw) = CORRESPONDING zmig_voi_lsmw( vendor_open_item MAPPING newko_lifnr = lifnr ).

          vendor_open_item_lsmw = VALUE #( BASE vendor_open_item_lsmw
                                             newbs_lifnr = COND #( WHEN vendor_open_item_lsmw-wrbtr < 0 THEN '39' ELSE '29' )
                                             newbs_saknr = COND #( WHEN vendor_open_item_lsmw-wrbtr < 0 THEN '40' ELSE '50' )
                                             newko_saknr = '89000000' ).

          "Update Date Fields
          DATA(date) = CONV dats( vendor_open_item_lsmw-budat ).
          vendor_open_item_lsmw-budat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( vendor_open_item_lsmw-bldat ).
          vendor_open_item_lsmw-bldat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( vendor_open_item_lsmw-zfbdt ).
          vendor_open_item_lsmw-zfbdt = |{ date DATE = ENVIRONMENT }|.

          "Update KURSF Field
          DATA(kursf) = CONV kursf( vendor_open_item_lsmw-kursf ).
          vendor_open_item_lsmw-kursf = COND #( WHEN kursf < 0 THEN |/{ kursf * -1 }| ELSE kursf ).

          vendor_open_items_lsmw = VALUE #( BASE vendor_open_items_lsmw ( vendor_open_item_lsmw ) ).
        ENDIF.

      ENDLOOP.

      TRY.
          MODIFY (migration_table-technical_id) FROM TABLE vendor_open_items_staging.
          MODIFY zmig_voi_lsmw                  FROM TABLE vendor_open_items_lsmw.
        CATCH cx_sy_open_sql_db INTO DATA(open_sql_db_ex) .
      ENDTRY .

      "Set Message Type and Message No
      DATA(message_type) = COND bapi_mtype( WHEN open_sql_db_ex IS BOUND THEN zmig_cl_migration_constants=>message_class-error ELSE zmig_cl_migration_constants=>message_class-succsess ).
      DATA(message_no)   = SWITCH symsgno( message_type WHEN zmig_cl_migration_constants=>message_class-succsess THEN zmig_cl_migration_constants=>message_class-succsess_msg_number ELSE zmig_cl_migration_constants=>message_class-error_msg_number ).

      result = migration->update_messages( messages     = result
                                           message_type = message_type
                                           message_no   = message_no
                                           message_v1   = CONV symsgv( migration_table-technical_id )
                                           message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).

    ENDLOOP.

  ENDMETHOD.

  METHOD update_empty_xblnr.

    DATA(counter) = 1.

    LOOP AT vendor_open_items ASSIGNING FIELD-SYMBOL(<vendor_open_item>) WHERE xblnr IS INITIAL.

      <vendor_open_item>-xblnr = |BRANCH UAT { counter }|.
      counter += 1.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
