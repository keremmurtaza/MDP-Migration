*&---------------------------------------------------------------------*
*& Include          ZMIG_BANK_ACC_BALANCE_CLS
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
                iban_numbers  TYPE zmig_if_migration_types=>ranges-iban_filter
                create_users  TYPE zmig_if_migration_types=>ranges-uname_filter
                grp_indicator TYPE char255
      RETURNING VALUE(result) TYPE zmig_if_migration_types=>table_types-tt_bank_account_balance.

ENDCLASS.

CLASS migration_dao IMPLEMENTATION.

  METHOD get_migration_tables.

    SELECT * FROM zmig_staging
            WHERE migration = @migration_project
       INTO TABLE @migration_tables.

  ENDMETHOD.

  METHOD get_fields_to_be_changed.

    SELECT * FROM zmig_bab_map
     WHERE bukrs = @bukrs
      INTO TABLE @fields_to_be_changed.

  ENDMETHOD.

  METHOD get_data.

    DATA(destination)  = CONV string( COND #( WHEN sy-sysid = 'PS4' THEN |NONE| ELSE |TS4CLNT050| ) ).

    CALL FUNCTION 'ZMIG_BANK_ACC_BALANCE_DATA'
      DESTINATION destination
      EXPORTING
        bukrs         = bukrs          " Company Code
        iban_numbers  = iban_numbers   " Range Table IBAN
        create_users  = create_users   " User Name Range Table
        grp_indicator = grp_indicator  " Group Indicator
      TABLES
        result        = result         " Bank Account Balance Migration: Bank Account Balance
      EXCEPTIONS
        OTHERS        = 1.

*    SELECT FROM fclm_bam_amd AS fclm
*     INNER JOIN t012k        AS t012  ON fclm~acc_num = t012~bankn
*                                     AND fclm~bukrs   = t012~bukrs
*     INNER JOIN fqm_flow     AS flow  ON t012~hkont   = flow~fi_account
*                                     AND t012~waers   = flow~currency
*         FIELDS t012~waers AS account_id,
*                fclm~iban,
*                t012~hkont AS glaccount,
*                SUM( flow~amount ) AS balance_amount,
*                t012~waers AS balance_currency,
*                @grp_indicator AS /1lt/grp_indicator
*          WHERE fclm~bukrs = @bukrs
*            AND fclm~iban IN @iban_numbers
*            AND flow~create_user IN @create_users
*       GROUP BY t012~waers, fclm~iban, t012~hkont, t012~waers
*           INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

ENDCLASS.

CLASS bab_migration DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING bukrs TYPE bukrs.

    METHODS process.

  PRIVATE SECTION.
    CONSTANTS program_name TYPE char30     VALUE 'ZMIG_BANK_ACC_BALANCE'.

    DATA dao                  TYPE REF TO migration_dao.
    DATA bukrs                TYPE bukrs.
    DATA fields_to_be_changed TYPE zmig_if_migration_types=>table_types-tt_fields_to_be_changed.
    DATA migration            TYPE REF TO zmig_if_migration.

    METHODS update_migration_tables
      IMPORTING customer_open_items TYPE zmig_if_migration_types=>table_types-tt_bank_account_balance
      RETURNING VALUE(result)       TYPE bapiret2_t.

ENDCLASS.

CLASS bab_migration IMPLEMENTATION.

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
    DATA(bank_account_balance) = dao->get_data( bukrs         = bukrs
                                                iban_numbers  = iban[]
                                                create_users  = user[]
                                                grp_indicator = grp_indicator ).

    "Update data
    DATA updated_bank_account_balance TYPE zmig_if_migration_types=>table_types-tt_bank_account_balance.
    migration->update_fields( EXPORTING table                = bank_account_balance
                                        fields_to_be_changed = fields_to_be_changed
                              IMPORTING updated_table        = updated_bank_account_balance ).

    "If it's a test run, do not update migration database tables
    IF test = abap_true.
      RETURN.
    ENDIF.

    "Update migration tables
    update_migration_tables( updated_bank_account_balance ).

  ENDMETHOD.

  METHOD update_migration_tables.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    "Get migration tables
    DATA(migration_tables) = dao->get_migration_tables( zmig_cl_migration_constants=>migration_projects-mig_44 ).

    LOOP AT migration_tables INTO DATA(migration_table).

      CASE migration_table-table_name.
        WHEN zmig_cl_migration_constants=>bab_staging_tables-bank_account_balance.
          ASSIGN customer_open_items TO <table>.
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

      TRY.
          MODIFY (migration_table-technical_id) FROM TABLE <table>.
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

ENDCLASS.
