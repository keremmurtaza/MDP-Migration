*&---------------------------------------------------------------------*
*& Include          ZF01_CUSTOMER_OPEN_ITEMS_CLS
*&---------------------------------------------------------------------*

CLASS migration_dao DEFINITION.

  PUBLIC SECTION.
    METHODS get_migration_tables
      IMPORTING migration_project       TYPE zf01_migration_project
      RETURNING VALUE(migration_tables) TYPE zf01_if_migration_types=>table_types-tt_staging_tables.

    METHODS get_fields_to_be_changed
      IMPORTING bukrs                       TYPE bukrs
      RETURNING VALUE(fields_to_be_changed) TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed.

    METHODS get_data
      IMPORTING bukrs         TYPE bukrs
                gjahr         TYPE gjahr
                customers     TYPE zf01_if_migration_types=>ranges-customers_filter
                documents     TYPE zf01_if_migration_types=>ranges-document_filter
                grp_indicator TYPE char255
      RETURNING VALUE(result) TYPE zf01_if_migration_types=>table_types-tt_customer_open_items.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zf01_mig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zf01_coi_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) ).

    CALL FUNCTION 'ZF01_CUSTOMER_OPEN_ITEMS_DATA'
      DESTINATION destination
      EXPORTING
        bukrs         = bukrs           " Company Code
        gjahr         = gjahr           " Fiscal Year
        customers     = customers       " Range Table for KUNNR
        documents     = documents
        grp_indicator = grp_indicator   " Group Indicator
      TABLES
        result        = result          " Customer Open Items Migration: Customer Open Items
      EXCEPTIONS
        OTHERS        = 1.

*    SELECT FROM bsid
*     INNER JOIN bkpf ON  bsid~belnr = bkpf~belnr
*                     AND bsid~gjahr = bkpf~gjahr
*     INNER JOIN bseg ON  bseg~belnr = bkpf~belnr
*                     AND bseg~bukrs = bkpf~bukrs
*                     AND bseg~gjahr = bkpf~gjahr
*                     AND bseg~koart = 'D' "Customer
*         FIELDS bsid~bukrs,
*                bkpf~xblnr,
*                bsid~kunnr,
*                bseg~buzei AS docln,
**                bsid~gl_account,
*                bsid~gkont,
*                bsid~blart,
*                bsid~umskz,
*                bsid~bldat,
**                bsid~bktxt,
*                bsid~sgtxt,
*                bsid~waers,
**                bsid~hwaer,
*                bseg~dmbtr,
*                bseg~h_hwae2 AS hwae2,
*                bseg~dmbe2,
*                bseg~h_hwae3 AS hwae3,
*                bseg~dmbe3,
*                bseg~mwskz,
*                bsid~bupla,
**                bsid~vatdate,
**                bsid~tax_calc_date,
*                bsid~zterm,
*                bsid~zfbdt,
*                bsid~zlsch,
*                bsid~zlspr,
*                bsid~mschl,
*                bsid~kidno,
*                bsid~zbd1t,
*                bsid~zbd1p,
*                bsid~zbd2t,
*                bsid~zbd2p,
*                bsid~zbd3t,
*                bsid~skfbt,
**                bsid~acskt,
*                bsid~hbkid,
*                bsid~hktid,
*                bsid~bvtyp,
*                bsid~kkber,
*                bsid~lzbkz,
*                bsid~landl,
*                bsid~xref1,
*                bsid~xref2,
*                bsid~xref3,
**                bseg~posid,
*                bsid~prctr,
*                bsid~fkber,
*                bsid~zuonr,
*                bseg~h_budat AS pstng_date,
*                @grp_indicator AS /1lt/grp_indicator
*          WHERE bsid~bukrs = @bukrs
*            AND bsid~gjahr = @gjahr
*            AND bsid~kunnr IN @customers
*           INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

ENDCLASS.

CLASS coi_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs.

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name TYPE char30     VALUE 'ZF01_CUSTOMER_OPEN_ITEMS'.

    DATA dao                  TYPE REF TO migration_dao.
    DATA bukrs                TYPE bukrs.
    DATA fields_to_be_changed TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration            TYPE REF TO zf01_if_migration.

    METHODS update_migration_tables
      IMPORTING customer_open_items TYPE zf01_if_migration_types=>table_types-tt_customer_open_items
      RETURNING VALUE(result)       TYPE bapiret2_t.

    METHODS update_empty_xblnr
      CHANGING customer_open_items TYPE zf01_if_migration_types=>table_types-tt_customer_open_items.
ENDCLASS.

CLASS coi_migration IMPLEMENTATION.

  METHOD constructor.
    dao = COND #( WHEN dao IS BOUND THEN dao ELSE NEW migration_dao(  ) ).
    migration = COND #( WHEN migration IS BOUND THEN migration ELSE NEW zf01_cl_migration(  ) ).
    me->bukrs = bukrs.
    fields_to_be_changed = dao->get_fields_to_be_changed( bukrs ).
  ENDMETHOD.

  METHOD process.

    "Set group indicator
    DATA(grp_indicator) = CONV char255( |{ bukrs }_{ cl_abap_context_info=>get_system_date( ) }:{ cl_abap_context_info=>get_system_time( ) }_{ program_name }| ).

    "Get data
    DATA(customer_open_items) = dao->get_data( bukrs         = bukrs
                                               gjahr         = gjahr
                                               customers     = custmrs[]
                                               documents     = docmnts[]
                                               grp_indicator = grp_indicator ).

    "Update data
    DATA updated_customer_open_items TYPE zf01_if_migration_types=>table_types-tt_customer_open_items.
    migration->update_fields( EXPORTING table                = customer_open_items
                                        fields_to_be_changed = fields_to_be_changed
                              IMPORTING updated_table        = updated_customer_open_items ).

    "Update Empty XBLNR Fields
*    update_empty_xblnr( CHANGING customer_open_items = updated_customer_open_items ).

    "If it's a test run, do not update migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    update_migration_tables( updated_customer_open_items ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zf01_cl_migration_constants=>migration_projects-mig_29 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zf01_cl_migration_constants=>coi_staging_tables-customer_open_items.
          ASSIGN customer_open_items TO <table>.
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

      "Update Migration Table
      IF NOT line_exists( <table>[ 1 ] ).
        result = migration->update_messages( messages     = result
                                             message_type = zf01_cl_migration_constants=>message_class-warning
                                             message_no   = zf01_cl_migration_constants=>message_class-no_data_msg_number
                                             message_v1   = CONV symsgv( migration_table-technical_id )
                                             message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).
        CONTINUE.
      ENDIF.

      "11.05.2025 - LSMW Part
      "Do not insert rows where UMSKZ is not initial to migration staging table
      "Insert rows with UMSKZ filled to custom LSMW table
      DATA customer_open_items_staging  TYPE TABLE OF zf01_customer_open_items_stg.
      DATA customer_open_items_lsmw     TYPE TABLE OF zf01_coi_lsmw.

      LOOP AT customer_open_items INTO DATA(customer_open_item).

        "If GL Special Indicator is initial, insert data to staging table
        IF customer_open_item-umskz IS INITIAL.
          customer_open_items_staging = VALUE #( BASE customer_open_items_staging ( CORRESPONDING #( customer_open_item ) ) ).
        ENDIF.

        "If GL Special Indicator is initial, insert data to lsmw table
        IF customer_open_item-umskz IS NOT INITIAL.
          DATA(customer_open_item_lsmw) = CORRESPONDING zf01_coi_lsmw( customer_open_item MAPPING newko_kunnr = kunnr ).

          customer_open_item_lsmw = VALUE #( BASE customer_open_item_lsmw
                                             newbs_kunnr = COND #( WHEN customer_open_item_lsmw-wrbtr < 0 THEN '19' ELSE '09' )
                                             newbs_saknr = COND #( WHEN customer_open_item_lsmw-wrbtr < 0 THEN '40' ELSE '50' )
                                             newko_saknr = '89000000' ).

          "Update Date Fields
          DATA(date) = CONV dats( customer_open_item_lsmw-budat ).
          customer_open_item_lsmw-budat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( customer_open_item_lsmw-bldat ).
          customer_open_item_lsmw-bldat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( customer_open_item_lsmw-zfbdt ).
          customer_open_item_lsmw-zfbdt = |{ date DATE = ENVIRONMENT }|.

          "Update KURSF Field
          DATA(kursf) = CONV kursf( customer_open_item_lsmw-kursf ).
          customer_open_item_lsmw-kursf = COND #( WHEN kursf < 0 THEN |/{ kursf * -1 }| ELSE kursf ).

          customer_open_items_lsmw = VALUE #( BASE customer_open_items_lsmw ( customer_open_item_lsmw ) ).
        ENDIF.

      ENDLOOP.

      TRY.
          MODIFY (migration_table-technical_id) FROM TABLE customer_open_items_staging.
          MODIFY zf01_coi_lsmw                  FROM TABLE customer_open_items_lsmw.
        CATCH cx_sy_open_sql_db INTO DATA(open_sql_db_ex) .
      ENDTRY .

      "Set Message Type and Message No
      DATA(message_type) = COND bapi_mtype( WHEN open_sql_db_ex IS BOUND THEN zf01_cl_migration_constants=>message_class-error ELSE zf01_cl_migration_constants=>message_class-succsess ).
      DATA(message_no)   = SWITCH symsgno( message_type WHEN zf01_cl_migration_constants=>message_class-succsess THEN zf01_cl_migration_constants=>message_class-succsess_msg_number ELSE zf01_cl_migration_constants=>message_class-error_msg_number ).

      result = migration->update_messages( messages     = result
                                           message_type = message_type
                                           message_no   = message_no
                                           message_v1   = CONV symsgv( migration_table-technical_id )
                                           message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).

    ENDLOOP.

  ENDMETHOD.

  METHOD update_empty_xblnr.

    DATA(counter) = 1.

    LOOP AT customer_open_items ASSIGNING FIELD-SYMBOL(<customer_open_item>) WHERE xblnr IS INITIAL.

      <customer_open_item>-xblnr = |BRANCH UAT { counter }|.
      counter += 1.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
