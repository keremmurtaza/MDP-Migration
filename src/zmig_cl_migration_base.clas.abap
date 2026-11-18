"! Base class of the migration programs.
"! Flow: read settings (ZMIG_OBJECT, ZMIG_OBJ_STG) - read source data via RFC (ZMIG_GET_DATA)
"! - fill staging tables by field name - apply mapping table - ADJUST_DATA (object specific)
"! - display result - write staging tables after confirmation.
CLASS zmig_cl_migration_base DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS message_class TYPE symsgid VALUE 'ZMIG_BASE' ##NO_TEXT.

    METHODS constructor
      IMPORTING
        !object TYPE zmig_object .
    METHODS process .

  PROTECTED SECTION.

    TYPES:
      BEGIN OF ty_staging_table,
        structure    TYPE zmig_structure,
        description  TYPE zmig_object_text,
        technical_id TYPE zmig_staging_tech_id,
        data         TYPE REF TO data,
      END OF ty_staging_table .
    TYPES tt_staging_tables TYPE STANDARD TABLE OF ty_staging_table WITH KEY structure .

    DATA object TYPE zmig_object .
    DATA settings TYPE zmig_object .
    DATA staging_tables TYPE tt_staging_tables .
    DATA messages TYPE bapiret2_t .

    "! Object specific adjustments on the staging data, called after the mapping.
    "! Use GET_STAGING_DATA to access the data of a structure.
    METHODS adjust_data .
    "! Selections passed to the source system. Default: selection screen of the program.
    METHODS get_selections
      RETURNING
        VALUE(result) TYPE rsparams_tt .
    "! Returns the data of a structure (standard table typed as the staging table)
    METHODS get_staging_data
      IMPORTING
        !structure    TYPE zmig_structure
      RETURNING
        VALUE(result) TYPE REF TO data .
    METHODS add_message
      IMPORTING
        !type      TYPE bapi_mtype
        !number    TYPE symsgno
        !structure TYPE zmig_structure OPTIONAL
        !v1        TYPE symsgv OPTIONAL
        !v2        TYPE symsgv OPTIONAL
        !v3        TYPE symsgv OPTIONAL
        !v4        TYPE symsgv OPTIONAL .

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_mapping,
        bukrs     TYPE bukrs,
        field     TYPE zmig_mapping_fields,
        old_value TYPE zmig_old_value,
        new_value TYPE zmig_new_value,
      END OF ty_mapping .
    TYPES tt_mappings TYPE HASHED TABLE OF ty_mapping WITH UNIQUE KEY bukrs field old_value .
    TYPES:
      BEGIN OF ty_summary,
        status       TYPE icon_d,
        structure    TYPE zmig_structure,
        description  TYPE zmig_object_text,
        technical_id TYPE zmig_staging_tech_id,
        records      TYPE i,
        warnings     TYPE i,
        errors       TYPE i,
      END OF ty_summary .
    TYPES tt_summary TYPE STANDARD TABLE OF ty_summary WITH EMPTY KEY .
    TYPES:
      BEGIN OF ty_message_output,
        status    TYPE icon_d,
        structure TYPE zmig_structure,
        message   TYPE bapi_msg,
      END OF ty_message_output .
    TYPES tt_message_output TYPE STANDARD TABLE OF ty_message_output WITH EMPTY KEY .

    CONSTANTS:
      BEGIN OF message_type,
        error   TYPE bapi_mtype VALUE 'E',
        warning TYPE bapi_mtype VALUE 'W',
        success TYPE bapi_mtype VALUE 'S',
        info    TYPE bapi_mtype VALUE 'I',
      END OF message_type .
    CONSTANTS group_indicator_field TYPE fieldname VALUE '/1LT/GRP_INDICATOR' ##NO_TEXT.

    DATA summary TYPE tt_summary .

    METHODS read_settings
      RETURNING
        VALUE(result) TYPE abap_bool .
    METHODS read_source_data
      RETURNING
        VALUE(result) TYPE abap_bool .
    METHODS fill_staging_tables
      IMPORTING
        !values TYPE zmig_cl_source=>tt_values .
    METHODS apply_mapping .
    METHODS build_summary .
    METHODS display_summary .
    METHODS confirm_write
      RETURNING
        VALUE(result) TYPE abap_bool .
    METHODS write_staging_tables .
    METHODS display_messages
      IMPORTING
        !structure TYPE zmig_structure OPTIONAL .
    METHODS display_popup
      IMPORTING
        !title TYPE lvc_title
      CHANGING
        !rows  TYPE STANDARD TABLE .
    METHODS has_errors
      RETURNING
        VALUE(result) TYPE abap_bool .
    METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING
        !row
        !column .
ENDCLASS.



CLASS ZMIG_CL_MIGRATION_BASE IMPLEMENTATION.


  METHOD add_message.
    DATA text TYPE bapi_msg.

    MESSAGE ID message_class TYPE type NUMBER number WITH v1 v2 v3 v4 INTO text.

    APPEND VALUE #( type       = type
                    id         = message_class
                    number     = number
                    message    = text
                    message_v1 = v1
                    message_v2 = v2
                    message_v3 = v3
                    message_v4 = v4
                    parameter  = structure ) TO messages.
  ENDMETHOD.


  METHOD adjust_data.
    "Redefine in the program for object specific rules
  ENDMETHOD.


  METHOD apply_mapping.
    DATA mappings TYPE tt_mappings.
    DATA mapping_fields TYPE SORTED TABLE OF zmig_mapping_fields WITH UNIQUE KEY table_line.
    FIELD-SYMBOLS <rows>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <field> TYPE any.
    FIELD-SYMBOLS <bukrs> TYPE any.

    IF settings-map_table IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        SELECT bukrs, field, old_value, new_value
          FROM (settings-map_table)
          INTO CORRESPONDING FIELDS OF TABLE @mappings.
      CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_db.
        add_message( type   = message_type-error
                     number = '014'
                     v1     = CONV #( settings-map_table ) ).
        RETURN.
    ENDTRY.

    IF mappings IS INITIAL.
      RETURN.
    ENDIF.

    mapping_fields = VALUE #( FOR GROUPS field_group OF map_line IN mappings GROUP BY map_line-field ( field_group ) ).

    "Company code of the selection screen is used for rows without company code
    DATA(selections) = get_selections( ).
    DATA(selection_bukrs) = CONV bukrs( VALUE #( selections[ selname = 'BUKRS' kind = 'P' ]-low OPTIONAL ) ).

    LOOP AT staging_tables INTO DATA(staging_table).
      ASSIGN staging_table-data->* TO <rows>.

      LOOP AT <rows> ASSIGNING FIELD-SYMBOL(<row>).
        UNASSIGN <bukrs>.
        ASSIGN COMPONENT 'BUKRS' OF STRUCTURE <row> TO <bukrs>.
        DATA(row_bukrs) = COND bukrs( WHEN <bukrs> IS ASSIGNED THEN <bukrs> ELSE selection_bukrs ).

        LOOP AT mapping_fields INTO DATA(mapping_field).
          ASSIGN COMPONENT mapping_field OF STRUCTURE <row> TO <field>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          "Order: company code + value, company code + '*', without company code + value, without company code + '*'
          DATA(old_value) = CONV zmig_old_value( <field> ).
          READ TABLE mappings INTO DATA(mapping) WITH TABLE KEY bukrs = row_bukrs field = mapping_field old_value = old_value.
          IF sy-subrc <> 0.
            READ TABLE mappings INTO mapping WITH TABLE KEY bukrs = row_bukrs field = mapping_field old_value = '*'.
          ENDIF.
          IF sy-subrc <> 0.
            READ TABLE mappings INTO mapping WITH TABLE KEY bukrs = space field = mapping_field old_value = old_value.
          ENDIF.
          IF sy-subrc <> 0.
            READ TABLE mappings INTO mapping WITH TABLE KEY bukrs = space field = mapping_field old_value = '*'.
          ENDIF.
          IF sy-subrc = 0.
            <field> = mapping-new_value.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_summary.
    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.

    CLEAR summary.
    LOOP AT staging_tables INTO DATA(staging_table).
      ASSIGN staging_table-data->* TO <rows>.

      DATA(line) = VALUE ty_summary( structure    = staging_table-structure
                                     description  = staging_table-description
                                     technical_id = staging_table-technical_id
                                     records      = lines( <rows> ) ).

      LOOP AT messages INTO DATA(message) WHERE parameter = staging_table-structure.
        CASE message-type.
          WHEN message_type-error OR 'A' OR 'X'.
            line-errors = line-errors + 1.
          WHEN message_type-warning.
            line-warnings = line-warnings + 1.
        ENDCASE.
      ENDLOOP.

      line-status = COND #( WHEN line-errors > 0   THEN icon_led_red
                            WHEN line-warnings > 0 THEN icon_led_yellow
                            WHEN line-records = 0  THEN icon_led_inactive
                            ELSE icon_led_green ).
      APPEND line TO summary.
    ENDLOOP.
  ENDMETHOD.


  METHOD confirm_write.
    DATA answer TYPE c LENGTH 1.

    IF has_errors( ) = abap_true.
      MESSAGE ID message_class TYPE 'I' NUMBER '016' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF REDUCE i( INIT total = 0 FOR line IN summary NEXT total = total + line-records ) = 0.
      MESSAGE ID message_class TYPE 'S' NUMBER '011'.
      RETURN.
    ENDIF.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = TEXT-t01
        text_question         = TEXT-q01
        text_button_1         = TEXT-b01
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = TEXT-b02
        icon_button_2         = 'ICON_CANCEL'
        default_button        = '2'
        display_cancel_button = abap_false
      IMPORTING
        answer                = answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.

    result = xsdbool( sy-subrc = 0 AND answer = '1' ).

    IF result = abap_false.
      MESSAGE ID message_class TYPE 'S' NUMBER '011'.
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    me->object = object.
  ENDMETHOD.


  METHOD display_messages.
    DATA output TYPE tt_message_output.

    "Without structure: all messages, with structure: messages of the structure
    LOOP AT messages INTO DATA(message).
      IF structure IS NOT INITIAL AND message-parameter <> structure.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( status    = SWITCH #( message-type WHEN message_type-error OR 'A' OR 'X' THEN icon_led_red
                                                         WHEN message_type-warning THEN icon_led_yellow
                                                         ELSE icon_led_green )
                      structure = message-parameter
                      message   = message-message ) TO output.
    ENDLOOP.

    IF output IS INITIAL.
      RETURN.
    ENDIF.

    display_popup( EXPORTING title = CONV #( TEXT-t02 )
                   CHANGING  rows  = output ).
  ENDMETHOD.


  METHOD display_popup.
    DATA alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = alv
                                CHANGING  t_table      = rows ).

        alv->get_functions( )->set_all( abap_true ).
        alv->get_columns( )->set_optimize( abap_true ).
        alv->get_display_settings( )->set_list_header( title ).

        TRY.
            CAST cl_salv_column_table( alv->get_columns( )->get_column( 'STATUS' ) )->set_icon( abap_true ).
            alv->get_columns( )->get_column( 'STATUS' )->set_short_text( CONV #( TEXT-c01 ) ).
            alv->get_columns( )->get_column( 'STATUS' )->set_medium_text( CONV #( TEXT-c01 ) ).
            alv->get_columns( )->get_column( 'STATUS' )->set_long_text( CONV #( TEXT-c01 ) ).
          CATCH cx_salv_not_found.
            "Data popup, no status column
        ENDTRY.

        alv->set_screen_popup( start_column = 5
                               end_column   = 160
                               start_line   = 3
                               end_line     = 25 ).
        alv->display( ).
      CATCH cx_salv_msg.
        MESSAGE ID message_class TYPE 'S' NUMBER '015' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD display_summary.
    DATA alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = alv
                                CHANGING  t_table      = summary ).

        alv->get_functions( )->set_all( abap_true ).
        alv->get_display_settings( )->set_list_header( CONV #( |{ TEXT-t03 } { object }| ) ).
        alv->get_display_settings( )->set_striped_pattern( abap_true ).

        DATA(columns) = alv->get_columns( ).
        columns->set_optimize( abap_true ).

        CAST cl_salv_column_table( columns->get_column( 'STATUS' ) )->set_icon( abap_true ).
        columns->get_column( 'STATUS' )->set_short_text( CONV #( TEXT-c01 ) ).
        columns->get_column( 'STATUS' )->set_medium_text( CONV #( TEXT-c01 ) ).
        columns->get_column( 'STATUS' )->set_long_text( CONV #( TEXT-c01 ) ).
        columns->get_column( 'RECORDS' )->set_short_text( CONV #( TEXT-c02 ) ).
        columns->get_column( 'RECORDS' )->set_medium_text( CONV #( TEXT-c02 ) ).
        columns->get_column( 'RECORDS' )->set_long_text( CONV #( TEXT-c02 ) ).
        columns->get_column( 'WARNINGS' )->set_short_text( CONV #( TEXT-c03 ) ).
        columns->get_column( 'WARNINGS' )->set_medium_text( CONV #( TEXT-c03 ) ).
        columns->get_column( 'WARNINGS' )->set_long_text( CONV #( TEXT-c03 ) ).
        columns->get_column( 'ERRORS' )->set_short_text( CONV #( TEXT-c04 ) ).
        columns->get_column( 'ERRORS' )->set_medium_text( CONV #( TEXT-c04 ) ).
        columns->get_column( 'ERRORS' )->set_long_text( CONV #( TEXT-c04 ) ).

        DATA(events) = alv->get_event( ).
        SET HANDLER on_double_click FOR events.

        "Messages without structure (e.g. source system) are shown first
        IF line_exists( messages[ parameter = space ] ).
          display_messages( ).
        ENDIF.

        alv->display( ).
      CATCH cx_salv_msg cx_salv_not_found.
        MESSAGE ID message_class TYPE 'S' NUMBER '015' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD fill_staging_tables.
    DATA text TYPE string.
    DATA missing_fields TYPE SORTED TABLE OF fieldname WITH UNIQUE KEY table_line.
    FIELD-SYMBOLS <rows>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <field> TYPE any.

    DATA(group_indicator) = |{ object }_{ sy-datum }:{ sy-uzeit }|.

    LOOP AT values INTO DATA(value)
         GROUP BY value-structure INTO DATA(structure_group).

      READ TABLE staging_tables INTO DATA(staging_table) WITH KEY structure = structure_group.
      IF sy-subrc <> 0.
        add_message( type   = message_type-warning
                     number = '008'
                     v1     = CONV #( structure_group ) ).
        CONTINUE.
      ENDIF.

      ASSIGN staging_table-data->* TO <rows>.
      CLEAR missing_fields.

      LOOP AT GROUP structure_group INTO DATA(structure_value)
           GROUP BY structure_value-record INTO DATA(record_group).

        APPEND INITIAL LINE TO <rows> ASSIGNING FIELD-SYMBOL(<row>).

        LOOP AT GROUP record_group INTO DATA(record_value)
             GROUP BY record_value-field INTO DATA(field_group).

          "Long values are delivered in segments of 255 characters
          CLEAR text.
          LOOP AT GROUP field_group INTO DATA(segment_value).
            CONCATENATE text segment_value-value INTO text RESPECTING BLANKS.
          ENDLOOP.

          ASSIGN COMPONENT field_group OF STRUCTURE <row> TO <field>.
          IF sy-subrc <> 0.
            INSERT CONV fieldname( field_group ) INTO TABLE missing_fields.
            CONTINUE.
          ENDIF.

          TRY.
              <field> = text.
            CATCH cx_sy_conversion_error.
              add_message( type      = message_type-error
                           number    = '007'
                           structure = staging_table-structure
                           v1        = CONV #( staging_table-structure )
                           v2        = CONV #( field_group )
                           v3        = CONV #( record_group ) ).
          ENDTRY.
        ENDLOOP.

        "Group indicator of the run, if the staging table has the field
        ASSIGN COMPONENT group_indicator_field OF STRUCTURE <row> TO <field>.
        IF sy-subrc = 0.
          <field> = group_indicator.
        ENDIF.
      ENDLOOP.

      LOOP AT missing_fields INTO DATA(missing_field).
        add_message( type      = message_type-warning
                     number    = '004'
                     structure = staging_table-structure
                     v1        = CONV #( staging_table-structure )
                     v2        = CONV #( missing_field )
                     v3        = CONV #( staging_table-technical_id ) ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_selections.
    CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
      EXPORTING
        curr_report     = sy-cprog
      TABLES
        selection_table = result
      EXCEPTIONS
        not_found       = 1
        no_report       = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.


  METHOD get_staging_data.
    READ TABLE staging_tables INTO DATA(staging_table) WITH KEY structure = structure.
    IF sy-subrc = 0.
      result = staging_table-data.
    ENDIF.
  ENDMETHOD.


  METHOD has_errors.
    result = xsdbool( line_exists( messages[ type = message_type-error ] )
                   OR line_exists( messages[ type = 'A' ] )
                   OR line_exists( messages[ type = 'X' ] ) ).
  ENDMETHOD.


  METHOD on_double_click.
    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.

    READ TABLE summary INTO DATA(line) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    "Warnings / errors column: messages of the structure, other columns: data
    IF column = 'WARNINGS' OR column = 'ERRORS' OR column = 'STATUS'.
      display_messages( line-structure ).
      RETURN.
    ENDIF.

    DATA(staging_data) = get_staging_data( line-structure ).
    IF staging_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN staging_data->* TO <rows>.
    IF <rows> IS INITIAL.
      RETURN.
    ENDIF.

    display_popup( EXPORTING title = CONV #( |{ line-structure } - { line-description }| )
                   CHANGING  rows  = <rows> ).
  ENDMETHOD.


  METHOD process.
    IF read_settings( ) = abap_false.
      display_messages( ).
      RETURN.
    ENDIF.

    IF read_source_data( ) = abap_false.
      display_messages( ).
      RETURN.
    ENDIF.

    apply_mapping( ).
    adjust_data( ).

    build_summary( ).
    display_summary( ).

    IF confirm_write( ) = abap_true.
      write_staging_tables( ).
      display_messages( ).
    ENDIF.
  ENDMETHOD.


  METHOD read_settings.
    DATA table_descr TYPE REF TO cl_abap_typedescr.
    DATA staging_data TYPE REF TO data.

    SELECT SINGLE * FROM zmig_object
     WHERE object = @object
      INTO @settings.
    IF sy-subrc <> 0.
      add_message( type   = message_type-error
                   number = '001'
                   v1     = CONV #( object ) ).
      RETURN.
    ENDIF.

    SELECT stg~structure, stg~technical_id, txt~description
      FROM zmig_obj_stg AS stg
      LEFT OUTER JOIN zmig_obj_stgt AS txt ON  txt~object    = stg~object
                                           AND txt~structure = stg~structure
                                           AND txt~spras     = @sy-langu
     WHERE stg~object = @object
       AND stg~active = @abap_true
     ORDER BY stg~structure
      INTO TABLE @DATA(structure_lines).
    IF structure_lines IS INITIAL.
      add_message( type   = message_type-error
                   number = '002'
                   v1     = CONV #( object ) ).
      RETURN.
    ENDIF.

    LOOP AT structure_lines INTO DATA(structure_line).
      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = structure_line-technical_id
                                           RECEIVING  p_descr_ref    = table_descr
                                           EXCEPTIONS type_not_found = 1
                                                      OTHERS         = 2 ).
      IF sy-subrc <> 0 OR structure_line-technical_id IS INITIAL OR table_descr->kind <> cl_abap_typedescr=>kind_struct.
        add_message( type      = message_type-error
                     number    = '003'
                     structure = structure_line-structure
                     v1        = CONV #( structure_line-structure )
                     v2        = CONV #( structure_line-technical_id ) ).
        CONTINUE.
      ENDIF.

      CREATE DATA staging_data TYPE STANDARD TABLE OF (structure_line-technical_id).
      APPEND VALUE #( structure    = structure_line-structure
                      description  = structure_line-description
                      technical_id = structure_line-technical_id
                      data         = staging_data ) TO staging_tables.
    ENDLOOP.

    result = xsdbool( has_errors( ) = abap_false ).
  ENDMETHOD.


  METHOD read_source_data.
    DATA values          TYPE zmig_cl_source=>tt_values.
    DATA source_messages TYPE bapiret2_t.
    DATA error_message   TYPE c LENGTH 200.

    DATA(destination) = COND rfcdest( WHEN settings-rfc_dest IS INITIAL THEN 'NONE' ELSE settings-rfc_dest ).
    DATA(selections)  = get_selections( ).

    CALL FUNCTION 'ZMIG_GET_DATA'
      DESTINATION destination
      EXPORTING
        source_class          = settings-source_class
        selections            = selections
      TABLES
        values                = values
        messages              = source_messages
      EXCEPTIONS
        system_failure        = 1 MESSAGE error_message
        communication_failure = 2 MESSAGE error_message
        OTHERS                = 3.

    IF sy-subrc <> 0.
      add_message( type   = message_type-error
                   number = '005'
                   v1     = CONV #( destination )
                   v2     = CONV #( error_message(50) )
                   v3     = CONV #( error_message+50(50) )
                   v4     = CONV #( error_message+100(50) ) ).
      RETURN.
    ENDIF.

    APPEND LINES OF source_messages TO messages.

    IF has_errors( ) = abap_true.
      RETURN.
    ENDIF.

    IF values IS INITIAL.
      add_message( type   = message_type-error
                   number = '012' ).
      RETURN.
    ENDIF.

    fill_staging_tables( values ).

    result = abap_true.
  ENDMETHOD.


  METHOD write_staging_tables.
    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.

    DATA(error) = abap_false.

    LOOP AT staging_tables INTO DATA(staging_table).
      ASSIGN staging_table-data->* TO <rows>.
      IF <rows> IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          MODIFY (staging_table-technical_id) FROM TABLE <rows>.
          add_message( type      = message_type-success
                       number    = '009'
                       structure = staging_table-structure
                       v1        = CONV #( staging_table-structure )
                       v2        = CONV #( lines( <rows> ) )
                       v3        = CONV #( staging_table-technical_id ) ).
        CATCH cx_sy_open_sql_db cx_sy_dynamic_osql_error INTO DATA(sql_error).
          error = abap_true.
          DATA(sql_text) = CONV bapi_msg( sql_error->get_text( ) ).
          add_message( type      = message_type-error
                       number    = '010'
                       structure = staging_table-structure
                       v1        = CONV #( staging_table-structure )
                       v2        = CONV #( staging_table-technical_id )
                       v3        = CONV #( sql_text(50) )
                       v4        = CONV #( sql_text+50(50) ) ).
      ENDTRY.
    ENDLOOP.

    "All or nothing
    IF error = abap_true.
      ROLLBACK WORK.
      add_message( type   = message_type-error
                   number = '013' ).
    ELSE.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
