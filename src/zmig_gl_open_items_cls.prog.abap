*&---------------------------------------------------------------------*
*& Include          ZMIG_GL_OPEN_ITEMS_CLS
*&---------------------------------------------------------------------*
CLASS slg_log_process DEFINITION.

  PUBLIC SECTION.
    METHODS constructor.
    METHODS create_log_handle
      IMPORTING ext_number    TYPE balnrext
      RETURNING VALUE(result) TYPE balloghndl.

    METHODS add_message
      IMPORTING log_handle TYPE balloghndl
                message    TYPE bal_s_msg.

    DATA slg_log TYPE REF TO zmig_if_slg_log.

ENDCLASS.

CLASS slg_log_process IMPLEMENTATION.

  METHOD constructor.
    slg_log = COND #( WHEN slg_log IS BOUND THEN slg_log ELSE NEW zmig_cl_slg_log( ) ).
  ENDMETHOD.

  METHOD create_log_handle.

    result = slg_log->log_create( log = VALUE #( object    = zmig_cl_migration_constants=>slg_log-main_object
                                                 subobject = zmig_cl_migration_constants=>slg_log-gl
                                                 extnumber = ext_number
                                                 aluser    = sy-uname
                                                 alprog    = sy-repid
                                                 aldate    = sy-datum
                                                 altime    = sy-uzeit ) ).

  ENDMETHOD.

  METHOD add_message.

    slg_log->log_message_add( EXPORTING log_handle = log_handle
                                         message   = message ).

  ENDMETHOD.

ENDCLASS.

CLASS migration_dao DEFINITION.

  PUBLIC SECTION.
    METHODS get_migration_tables
      IMPORTING migration_project       TYPE zmig_project
      RETURNING VALUE(migration_tables) TYPE zmig_if_migration_types=>table_types-tt_staging_tables.

    METHODS get_fields_to_be_changed
      IMPORTING bukrs                       TYPE bukrs
      RETURNING VALUE(fields_to_be_changed) TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.

    METHODS get_gl_account_data
      IMPORTING bukrs              TYPE bukrs
                gjahr              TYPE zmig_if_migration_types=>ranges-gjahr_filter
                hkonts_filter      TYPE zmig_if_migration_types=>ranges-hkonts_filter
                documents          TYPE zmig_if_migration_types=>ranges-document_filter
                grp_indicator      TYPE char255
      RETURNING VALUE(gl_acc_data) TYPE zmig_if_migration_types=>table_types-tt_gl_open_items.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zmig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zmig_gl_acc_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_gl_account_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) ).

    CALL FUNCTION 'ZMIG_GL_OPEN_ITEMS_DATA'
      DESTINATION destination
      EXPORTING
        bukrs         = bukrs
        gjahr         = gjahr
        gl_accounts   = hkonts_filter
        documents     = documents
        grp_indicator = grp_indicator
      TABLES
        result        = gl_acc_data
      EXCEPTIONS
        OTHERS        = 1.

*    DATA(options) = VALUE zmig_if_migration_types=>table_types-tt_rfc_db_options( ( |BUKRS = '{ bukrs }'| )
*                                                                                  ( |AND GJAHR = '{ gjahr }'| ) ).
*
*    "GL Account Number Filter
*    DATA(bsis_options) = options.
*    IF hkonts_filter IS NOT INITIAL.
*      bsis_options = zmig_cl_migration=>range_to_options( range_table     = hkonts_filter
*                                                          field_name      = 'HKONT'
*                                                          current_options = options ).
*    ENDIF.
*
*    DATA bsis  TYPE TABLE OF bsis.
*    zmig_cl_migration=>get_table_data( EXPORTING query_table  = 'BSIS'
*                                                 destination  = destination
*                                                 options      = bsis_options
*                                       CHANGING  result_table = bsis ).
*
*    DATA bkpf  TYPE TABLE OF bkpf.
*    zmig_cl_migration=>get_table_data( EXPORTING query_table  = 'BKPF'
*                                                 destination  = destination
*                                                 options      = options
*                                       CHANGING  result_table = bkpf ).
*
*    DATA bseg  TYPE TABLE OF bseg.
*    zmig_cl_migration=>get_table_data( EXPORTING query_table  = 'BSEG'
*                                                 destination  = destination
*                                                 options      = options
*                                       CHANGING  result_table = bseg ).
*
*    LOOP AT bsis ASSIGNING FIELD-SYMBOL(<bsis_line>).
*
*      TRY.  "Inner join control
*          ASSIGN bkpf[ bukrs = <bsis_line>-bukrs gjahr = <bsis_line>-gjahr belnr = <bsis_line>-belnr ] TO FIELD-SYMBOL(<bkpf_line>).
*          ASSIGN bseg[ bukrs = <bsis_line>-bukrs gjahr = <bsis_line>-gjahr belnr = <bsis_line>-belnr buzei = <bsis_line>-buzei hkont = <bsis_line>-hkont ] TO FIELD-SYMBOL(<bseg_line>).
*        CATCH cx_sy_itab_line_not_found.
*          CONTINUE.
*      ENDTRY.
*
*      IF <bseg_line> IS NOT ASSIGNED OR <bkpf_line> IS NOT ASSIGNED.
*        RETURN.
*      ENDIF.
*
*      APPEND VALUE #( bukrs      = <bsis_line>-bukrs
*                      ldgrp      = <bkpf_line>-ldgrp
*                      bktxt      = <bkpf_line>-bktxt
*                      xblnr      = <bsis_line>-xblnr
**                 docln      = <bseg_line>-docln
*                      hwaer      = <bseg_line>-h_hwaer
*                      hwae2      = <bseg_line>-h_hwae2
*                      hwae3      = <bseg_line>-h_hwae3
*                      rmvct      = <bseg_line>-bewar
*                      rassc      = <bseg_line>-vbund
*                      fb_segment = <bseg_line>-segment
*                      txjcd      = <bseg_line>-txjcd
*                      pernr      = <bseg_line>-pernr
*                      nplnr      = <bseg_line>-nplnr
*                      pspnr      = <bsis_line>-projk
**                 material_long = <bseg_line>-material_long
*                      hkont      = <bsis_line>-hkont
*                      gkont      = <bsis_line>-gkont
*                      blart      = <bsis_line>-blart
*                      bldat      = <bsis_line>-bldat
*                      sgtxt      = <bsis_line>-sgtxt
*                      waers      = <bsis_line>-waers
*                      wrbtr      = <bsis_line>-wrbtr
*                      dmbtr      = <bsis_line>-dmbtr
*                      dmbe2      = <bsis_line>-dmbe2
*                      dmbe3      = <bsis_line>-dmbe3
*                      mwskz      = <bsis_line>-mwskz
*                      zuonr      = <bsis_line>-zuonr
*                      valut      = <bsis_line>-valut
*                      hbkid      = <bsis_line>-hbkid
*                      hktid      = <bsis_line>-hktid
*                      kostl      = <bsis_line>-kostl
*                      prctr      = <bsis_line>-prctr
*                      aufnr      = <bsis_line>-aufnr
*                      pstng_date = <bsis_line>-budat
*                      /1lt/grp_indicator = grp_indicator )
*             TO gl_acc_data.
*    ENDLOOP.

*    SELECT
*    FROM bsis_view  AS bsis
*    INNER JOIN bkpf AS bkpf ON bkpf~bukrs = bsis~bukrs
*                           AND bkpf~gjahr = bsis~gjahr
*                           AND bkpf~belnr = bsis~belnr
*    INNER JOIN bseg AS bseg ON bseg~bukrs = bsis~bukrs
*                           AND bseg~belnr = bsis~belnr
*                           AND bseg~gjahr = bsis~gjahr
*                           AND bseg~buzei = bsis~buzei
*                           AND bseg~hkont = bsis~hkont
*    FIELDS bsis~bukrs,
*           bkpf~ldgrp,
*           bkpf~bktxt,
*           bsis~xblnr,
**           bseg~docln,
*           bseg~h_hwaer   AS hwaer,
*           bseg~h_hwae2   AS hwae2,
*           bseg~h_hwae3   AS hwae3,
*           bseg~bewar     AS rmvct,
*           bseg~vbund     AS rassc,
*           bseg~segment   AS fb_segment,
*           bseg~txjcd,
*           bseg~pernr,
*           bseg~nplnr,
*           bsis~projk     AS pspnr,
**           bseg~material_long,
*           bsis~hkont,
*           bsis~gkont,
*           bsis~blart,
*           bsis~bldat,
*           bsis~sgtxt,
*           bsis~waers,
*           bsis~wrbtr,
*           bsis~dmbtr,
*           bsis~dmbe2,
*           bsis~dmbe3,
*           bsis~mwskz,
*           bsis~zuonr,
*           bsis~valut,
*           bsis~hbkid,
*           bsis~hktid,
*           bsis~kostl,
*           bsis~prctr,
*           bsis~aufnr,
*           bsis~budat     AS pstng_date,
*           @grp_indicator AS /1lt/grp_indicator
*     WHERE bsis~bukrs = @bukrs
*       AND bsis~gjahr = @gjahr
*       AND bsis~hkont IN @hkonts_filter
*     INTO CORRESPONDING FIELDS OF TABLE @gl_acc_data .

  ENDMETHOD.

ENDCLASS.

CLASS gl_open_items_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs .

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name TYPE char30 VALUE 'ZMIG_GL_OPEN_ITEMS'.

    DATA dao TYPE REF TO migration_dao.
    DATA bukrs TYPE bukrs.
    DATA fields_to_be_changed TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration TYPE REF TO zmig_if_migration.

    METHODS update_migration_tables
      IMPORTING gl_data       TYPE zmig_if_migration_types=>table_types-tt_gl_open_items
      RETURNING VALUE(result) TYPE bapiret2_t.

    METHODS update_empty_xblnr
      CHANGING gl_open_items TYPE zmig_if_migration_types=>table_types-tt_gl_open_items.

ENDCLASS.

CLASS gl_open_items_migration IMPLEMENTATION.

  METHOD constructor.
    dao = COND #( WHEN dao IS BOUND THEN dao ELSE NEW migration_dao(  ) ).
    migration = COND #( WHEN migration IS BOUND THEN migration ELSE NEW zmig_cl_migration(  ) ).
    me->bukrs = bukrs.
    fields_to_be_changed = dao->get_fields_to_be_changed( bukrs ).
  ENDMETHOD.

  METHOD process.

    DATA updated_gl_data TYPE zmig_if_migration_types=>table_types-tt_gl_open_items.
    "Set group indicator
    DATA(grp_indicator) = CONV char255( |{ bukrs }_{ cl_abap_context_info=>get_system_date( ) }:{ cl_abap_context_info=>get_system_time( ) }_{ program_name }| ).

    "Get GL Data
    DATA(gl_data) = dao->get_gl_account_data( bukrs         = bukrs
                                              gjahr         = gjahr[]
                                              hkonts_filter = hkonts[]
                                              documents     = docmnts[]
                                              grp_indicator = grp_indicator ).

    "Update GL data
    migration->update_fields( EXPORTING table                = gl_data
                                        fields_to_be_changed = fields_to_be_changed
                              IMPORTING updated_table        = updated_gl_data ).

    "Update Empty XBLNR Fields
*    update_empty_xblnr( CHANGING gl_open_items = updated_gl_data ).

    "If it's a test run, do not update gl open items migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    DATA(result) = update_migration_tables( updated_gl_data ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zmig_cl_migration_constants=>migration_projects-mig_31 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zmig_cl_migration_constants=>gl_open_items_tables-gl_open_items.
          ASSIGN gl_data TO <table>.
      ENDCASE.

      "If assigning is not successfull, log it and continue with next table
      IF <table> IS NOT ASSIGNED .
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
        CONTINUE .
      ENDIF.

      "11.05.2025 - LSMW Part
      "Do not insert rows where UMSKZ is not initial to migration staging table
      "Insert rows with UMSKZ filled to custom LSMW table
      DATA gl_open_items_staging  TYPE TABLE OF zmig_gl_balance_stg.
      DATA gl_open_items_lsmw     TYPE TABLE OF zmig_gl_lsmw.

      LOOP AT gl_data INTO DATA(gl_open_item).

        "If MWSKZ is initial, insert data to staging table
        IF gl_open_item-mwskz IS INITIAL AND ( gl_open_item-wrbtr IS NOT INITIAL AND gl_open_item-dmbtr IS NOT INITIAL ) .
          gl_open_items_staging = VALUE #( BASE gl_open_items_staging ( CORRESPONDING #( gl_open_item ) ) ).
        ENDIF.

        "If MWSKZ is initial, insert data to lsmw table
        IF gl_open_item-mwskz IS NOT INITIAL OR ( gl_open_item-wrbtr IS INITIAL OR gl_open_item-dmbtr IS INITIAL ).
          DATA(gl_open_item_lsmw) = CORRESPONDING zmig_gl_lsmw( gl_open_item MAPPING newko_saknr = hkont waersl = hwaer waers2l = hwae2 ).

          gl_open_item_lsmw = VALUE #( BASE gl_open_item_lsmw
                                       newbs_mig_saknr = COND #( WHEN gl_open_item_lsmw-newbs_saknr = '40' THEN '50'
                                                                 WHEN gl_open_item_lsmw-newbs_saknr = '50' THEN '40'
                                                                 WHEN gl_open_item_lsmw-newbs_saknr = '81' THEN '91'
                                                                 WHEN gl_open_item_lsmw-newbs_saknr = '91' THEN '81'
                                                                 WHEN gl_open_item_lsmw-newbs_saknr = '96' THEN '86'
                                                                 WHEN gl_open_item_lsmw-newbs_saknr = '86' THEN '96' )
                                       newko_mig_saknr = '89000000' ).

          DATA(date) = CONV dats( gl_open_item_lsmw-budat ).
          gl_open_item_lsmw-budat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( gl_open_item_lsmw-bldat ).
          gl_open_item_lsmw-bldat = |{ date DATE = ENVIRONMENT }|.

          gl_open_items_lsmw = VALUE #( BASE gl_open_items_lsmw ( gl_open_item_lsmw ) ).
        ENDIF.

      ENDLOOP.

      "Modify Database Table
      TRY .
          MODIFY (migration_table-technical_id) FROM TABLE gl_open_items_staging.
          MODIFY zmig_gl_lsmw                   FROM TABLE gl_open_items_lsmw.
        CATCH cx_sy_open_sql_db INTO DATA(open_sql_db_ex) .
      ENDTRY .

      "Set Message Type and Message No
      DATA(message_type) = COND bapi_mtype( WHEN open_sql_db_ex IS BOUND THEN zmig_cl_migration_constants=>message_class-error ELSE zmig_cl_migration_constants=>message_class-succsess ).
      DATA(message_no)   = SWITCH  symsgno( message_type WHEN zmig_cl_migration_constants=>message_class-succsess THEN zmig_cl_migration_constants=>message_class-succsess_msg_number ELSE zmig_cl_migration_constants=>message_class-error_msg_number ).

      "Fill result table
      result = migration->update_messages( messages     = result
                                           message_type = message_type
                                           message_no   = message_no
                                           message_v1   = CONV symsgv( migration_table-technical_id )
                                           message_v2   = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ).

      "Log error message
      IF message_type = zmig_cl_migration_constants=>message_class-error.

        TRY.
            ASSIGN COMPONENT zmig_cl_migration_constants=>fields-/1lt/grp_indicator OF STRUCTURE <table>[ 1 ] TO FIELD-SYMBOL(<group_indicator>).
          CATCH cx_sy_itab_line_not_found.
            CONTINUE.
        ENDTRY.

        DATA(slg_log_process) = NEW slg_log_process( ).
        DATA(log_handle) = slg_log_process->create_log_handle( CONV balnrext( <group_indicator> ) ).

        slg_log_process->add_message( EXPORTING log_handle = log_handle
                                                message    = VALUE #( msgty = zmig_cl_migration_constants=>message_class-error
                                                                      msgid = zmig_cl_migration_constants=>message_class-name
                                                                      msgno = zmig_cl_migration_constants=>message_class-error_msg_number
                                                                      msgv1 = CONV symsgv( migration_table-technical_id )
                                                                      msgv2 = CONV symsgv( migration->get_table_description( fixed_value = migration_table-table_name fields_to_be_changed = fields_to_be_changed ) ) ) ).

        slg_log_process->add_message( EXPORTING log_handle = log_handle
                                                message    = VALUE #( msgty = zmig_cl_migration_constants=>message_class-error
                                                                      msgid = zmig_cl_migration_constants=>message_class-name
                                                                      msgno = zmig_cl_migration_constants=>message_class-free_text_msg_number
                                                                      msgv1 = CONV symsgv( open_sql_db_ex->sqlmsg ) ) ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update_empty_xblnr.

    DATA(counter) = 1.

    LOOP AT gl_open_items ASSIGNING FIELD-SYMBOL(<gl_open_item>) WHERE xblnr IS INITIAL.

      <gl_open_item>-xblnr = |BRANCH UAT { counter }|.
      counter += 1.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
