*&---------------------------------------------------------------------*
*& Include          ZMIG_BALANCE_ACCOUNTS_CLS
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
                accounts      TYPE zmig_if_migration_types=>ranges-accounts_filter
                documents     TYPE zmig_if_migration_types=>ranges-document_filter
                grp_indicator TYPE char255
      RETURNING VALUE(result) TYPE zmig_if_migration_types=>table_types-tt_balance_accounts.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zmig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zmig_bal_acc_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) )..

    CALL FUNCTION 'ZMIG_BALANCE_ACCOUNTS_DATA'
      DESTINATION destination
      EXPORTING
        bukrs         = bukrs                 " Company Code
        gjahr         = gjahr                 " Fiscal Year
        accounts      = accounts              " Accounts Filter
        documents     = documents
        grp_indicator = grp_indicator
      TABLES
        result        = result                 " Balance Accounts Migration: Balance Accounts
      EXCEPTIONS
        OTHERS        = 1.

*    SELECT FROM bsis
*    INNER JOIN bkpf ON bsis~belnr = bkpf~belnr
*                    AND bsis~bukrs = bkpf~bukrs
*                    AND bsis~gjahr = bkpf~gjahr
*    INNER JOIN bseg ON bseg~belnr = bkpf~belnr
*                    AND bseg~bukrs = bkpf~bukrs
*                    AND bseg~gjahr = bkpf~gjahr
*                    AND bseg~koart = 'S'  " Balance Sheet Accounts
*    FIELDS bsis~bukrs,
*           bkpf~ldgrp,
*           bkpf~xblnr,
*           bseg~buzei AS docln,
*           bsis~hkont,
*           bsis~gkont,
*           bsis~blart,
*           bsis~bldat,
**           bseg~acc_principle,
*           bkpf~bktxt,
*           bsis~sgtxt,
*           bkpf~waers,
*           bsis~wrbtr,
*           bkpf~hwaer,
*           bseg~dmbtr,
*           bseg~h_hwae2 AS hwae2,
*           bseg~dmbe2,
*           bseg~h_hwae3 AS hwae3,
*           bseg~dmbe3,
*           bseg~mwskz,
*           bseg~txjcd,
**           bseg~rassc,
*           bsis~zuonr,
**           bseg~rmvct,
*           bseg~pernr,
*           bsis~valut,
*           bsis~hbkid,
*           bsis~hktid,
*           bseg~kostl,
*           bseg~prctr,
**           bseg~fb_segment,
**           bseg~pspnr,
*           bseg~aufnr,
**           bseg~material_long,
*           bseg~nplnr,
**           bseg~copa_kndnr,
**           bseg~copa_kdgrp,
**           bseg~copa_brsch,
**           bseg~copa_kmland,
**           bseg~copa_bzirk,
**           bseg~copa_artnr,
**           bseg~copa_kmmakl,
**           bseg~copa_vkorg,
**           bseg~copa_vtweg,
**           bseg~copa_spart,
**           bseg~copa_werks,
**           bseg~copa_kostl,
**           bseg~copa_prctr,
**           bseg~copa_fb_segment,
**           bseg~copa_pspnr,
**           bseg~copa_rkaufnr,
**           bseg~copa_kunre,
**           bseg~copa_kunwe,
*           bsis~budat AS pstng_date,
*           @grp_indicator AS /1lt/grp_indicator
*    WHERE bsis~bukrs =  @bukrs
*      AND bsis~gjahr =  @gjahr
*      AND bsis~hkont IN @accounts
*    INTO CORRESPONDING FIELDS OF TABLE @result.
*
*
*    DELETE ADJACENT DUPLICATES FROM result.

  ENDMETHOD.

ENDCLASS.

CLASS balance_accounts_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs.

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name TYPE char30     VALUE 'ZMIG_BALANCE_ACCOUNTS'.

    DATA dao                  TYPE REF TO migration_dao.
    DATA bukrs                TYPE bukrs.
    DATA fields_to_be_changed TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration            TYPE REF TO zmig_if_migration.

    METHODS update_migration_tables
      IMPORTING balance_accounts TYPE zmig_if_migration_types=>table_types-tt_balance_accounts
      RETURNING VALUE(result)    TYPE bapiret2_t.

    METHODS update_empty_xblnr
      CHANGING balance_accounts TYPE zmig_if_migration_types=>table_types-tt_balance_accounts.

ENDCLASS.

CLASS balance_accounts_migration IMPLEMENTATION.

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
    DATA(balance_accounts) = dao->get_data( bukrs         = bukrs
                                            gjahr         = gjahr
                                            accounts      = accounts[]
                                            documents     = docmnts[]
                                            grp_indicator = grp_indicator ).
*
*    "Update data
    DATA updated_balance_accounts TYPE zmig_if_migration_types=>table_types-tt_balance_accounts.
    migration->update_fields( EXPORTING table                = balance_accounts
                                        fields_to_be_changed = fields_to_be_changed
                              IMPORTING updated_table        = updated_balance_accounts ).

    "Update Empty XBLNR Fields
*    update_empty_xblnr( CHANGING balance_accounts = updated_balance_accounts ).

    "If it's a test run, do not update migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    update_migration_tables( updated_balance_accounts ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zmig_cl_migration_constants=>migration_projects-mig_32 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zmig_cl_migration_constants=>balance_accounts-gl_balance.
          ASSIGN balance_accounts TO <table>.
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
      DATA gl_balances_staging  TYPE TABLE OF zmig_balance_accounts_stg.
      DATA gl_balances_lsmw     TYPE TABLE OF zmig_blnc_lsmw.

      LOOP AT balance_accounts INTO DATA(balance_account).

        "If not any of amount fields is empty
        IF balance_account-wrbtr IS NOT INITIAL AND balance_account-dmbtr IS NOT INITIAL AND balance_account-dmbe2 IS NOT INITIAL.
          gl_balances_staging = VALUE #( BASE gl_balances_staging ( CORRESPONDING #( balance_account ) ) ).
        ENDIF.

        "If one of the amount fields is empty
        IF balance_account-wrbtr IS INITIAL OR balance_account-dmbtr IS INITIAL OR balance_account-dmbe2 IS INITIAL.
          DATA(gl_balance_lsmw) = CORRESPONDING zmig_blnc_lsmw( balance_account MAPPING newko_saknr = hkont waersl = hwaer waers2l = hwae2 ).

          gl_balance_lsmw = VALUE #( BASE gl_balance_lsmw
                                     newbs_mig_saknr = COND #( WHEN gl_balance_lsmw-newbs_saknr = '40' THEN '50'
                                                               WHEN gl_balance_lsmw-newbs_saknr = '50' THEN '40'
                                                               WHEN gl_balance_lsmw-newbs_saknr = '81' THEN '91'
                                                               WHEN gl_balance_lsmw-newbs_saknr = '91' THEN '81'
                                                               WHEN gl_balance_lsmw-newbs_saknr = '96' THEN '86'
                                                               WHEN gl_balance_lsmw-newbs_saknr = '86' THEN '96' )
                                     newko_mig_saknr = '89000000' ).

          DATA(date) = CONV dats( gl_balance_lsmw-budat ).
          gl_balance_lsmw-budat = |{ date DATE = ENVIRONMENT }|.
          date = CONV dats( gl_balance_lsmw-bldat ).
          gl_balance_lsmw-bldat = |{ date DATE = ENVIRONMENT }|.

          gl_balances_lsmw = VALUE #( BASE gl_balances_lsmw ( gl_balance_lsmw ) ).
        ENDIF.

      ENDLOOP.

      "Modify Database Table
      TRY.
          MODIFY (migration_table-technical_id) FROM TABLE gl_balances_staging.
          MODIFY zmig_blnc_lsmw                 FROM TABLE gl_balances_lsmw.
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

    LOOP AT balance_accounts ASSIGNING FIELD-SYMBOL(<balance_account>) WHERE xblnr IS INITIAL.

      <balance_account>-xblnr = |BRANCH UAT { counter }|.
      counter += 1.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
