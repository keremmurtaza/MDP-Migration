CLASS zf01_cl_migration DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    INTERFACES zf01_if_migration.
    CLASS-METHODS range_to_options
      IMPORTING range_table     TYPE STANDARD TABLE
                field_name      TYPE string
                current_options TYPE zf01_if_migration_types=>table_types-tt_rfc_db_options
      RETURNING VALUE(result)   TYPE zf01_if_migration_types=>table_types-tt_rfc_db_options.
    CLASS-METHODS string_to_options
      IMPORTING string        TYPE string
      RETURNING VALUE(result) TYPE zf01_if_migration_types=>table_types-tt_rfc_db_options.
    CLASS-METHODS get_table_data
      IMPORTING query_table  TYPE dd02l-tabname
                destination  TYPE string
                options      TYPE zf01_if_migration_types=>table_types-tt_rfc_db_options
      CHANGING  result_table TYPE ANY TABLE.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS get_iso_code_of_buom
      IMPORTING base_unit_of_measure TYPE msehi
      RETURNING VALUE(result)        TYPE isocd_unit.
    METHODS get_profit_center
      IMPORTING bukrs         TYPE bukrs
                kostl         TYPE kostl
      RETURNING VALUE(result) TYPE prctr.
    METHODS convert_wbs_element
      IMPORTING wbs_element   TYPE char80
      RETURNING VALUE(result) TYPE char80.
ENDCLASS.



CLASS ZF01_CL_MIGRATION IMPLEMENTATION.


  METHOD convert_wbs_element.
    CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
      EXPORTING
        input  = wbs_element
      IMPORTING
        output = result.
    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.


  METHOD get_iso_code_of_buom.
    SELECT SINGLE isocode FROM t006
     WHERE msehi = @base_unit_of_measure
      INTO @result.
    IF sy-subrc <> 0.
      result = base_unit_of_measure.
    ENDIF.
  ENDMETHOD.


  METHOD get_profit_center.
    SELECT SINGLE prctr FROM csks
      INNER JOIN tka02 ON tka02~kokrs = csks~kokrs
      WHERE tka02~bukrs = @bukrs
        AND csks~kostl  = @kostl
        AND csks~datbi >= @sy-datum
      INTO @result.
  ENDMETHOD.


  METHOD get_table_data.
    DATA data128     TYPE zf01_if_migration_types=>table_types-tt_/bods/tab128.
    DATA data512     TYPE zf01_if_migration_types=>table_types-tt_/bods/tab512.
    DATA data2048    TYPE zf01_if_migration_types=>table_types-tt_/bods/tab2048.
    DATA data8192    TYPE zf01_if_migration_types=>table_types-tt_/bods/tab8192.
    DATA data30k     TYPE zf01_if_migration_types=>table_types-tt_/bods/tab30k.
    DATA data        TYPE zf01_if_migration_types=>table_types-tt_/bods/tab30k.
    DATA fields TYPE zf01_if_migration_types=>table_types-tt_rfc_db_fields.
    CALL FUNCTION '/BODS/RFC_READ_TABLE2'
      DESTINATION destination
      EXPORTING
        query_table          = query_table
      TABLES
        options              = options
        fields               = fields
        tblout128            = data128
        tblout512            = data512
        tblout2048           = data2048
        tblout8192           = data8192
        tblout30000          = data30k
      EXCEPTIONS
        table_not_available  = 1
        table_without_data   = 2
        option_not_valid     = 3
        field_not_valid      = 4
        not_authorized       = 5
        data_buffer_exceeded = 6
        OTHERS               = 7.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
    IF data30k IS NOT INITIAL.
      data = VALUE #( FOR wa30k IN data30k   ( CONV string( wa30k-wa  ) ) ).
    ELSEIF data8192 IS NOT INITIAL.
      data = VALUE #( FOR wa8192 IN data8192 ( CONV string( wa8192-wa ) ) ).
    ELSEIF data2048 IS NOT INITIAL.
      data = VALUE #( FOR wa2048 IN data2048 ( CONV string( wa2048-wa ) ) ).
    ELSEIF data512 IS NOT INITIAL.
      data = VALUE #( FOR wa512 IN data512   ( CONV string( wa512-wa  ) ) ).
    ELSEIF data128 IS NOT INITIAL.
      data = VALUE #( FOR wa128 IN data128   ( CONV string( wa128-wa  ) ) ).
    ENDIF.
    IF data IS INITIAL.
      RETURN.
    ENDIF.
    "Dynamic data definitions
    DATA dynamic_table TYPE REF TO data.
    FIELD-SYMBOLS <dynamic_table> TYPE ANY TABLE.
    DATA dynamic_structure TYPE REF TO data.
    FIELD-SYMBOLS <dynamic_structure> TYPE any.
    TRY.
        DATA(structure_descr) = CAST cl_abap_structdescr( cl_abap_structdescr=>describe_by_name( query_table ) ).
        DATA(table_descr) = cl_abap_tabledescr=>create( p_line_type  = CAST cl_abap_datadescr( structure_descr ) ).
      CATCH cx_sy_struct_creation cx_sy_table_creation.
        RETURN.
    ENDTRY.
    CREATE DATA dynamic_structure TYPE HANDLE structure_descr.
    CREATE DATA dynamic_table TYPE HANDLE table_descr.
    ASSIGN dynamic_structure->* TO <dynamic_structure>.
    ASSIGN dynamic_table->* TO <dynamic_table>.
    IF <dynamic_structure> IS NOT ASSIGNED OR <dynamic_table> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    LOOP AT data ASSIGNING FIELD-SYMBOL(<data>).
      LOOP AT fields ASSIGNING FIELD-SYMBOL(<field>).
        DATA(field_name) =  |<dynamic_structure>-{ <field>-fieldname }|.
        ASSIGN (field_name) TO FIELD-SYMBOL(<value>).
        <value> = <data>-wa+<field>-offset(<field>-length).
      ENDLOOP.
      INSERT <dynamic_structure> INTO TABLE <dynamic_table>.
    ENDLOOP.
    result_table = <dynamic_table>.
  ENDMETHOD.


  METHOD range_to_options.
    FIELD-SYMBOLS: <row> TYPE any.
    DATA: line       TYPE string,
*          conditions TYPE STANDARD TABLE OF string,
          where_line TYPE string.
    result = current_options.
    DATA(first_append_flag) = abap_true.
    LOOP AT range_table ASSIGNING <row>.
      ASSIGN COMPONENT 'SIGN'   OF STRUCTURE <row> TO FIELD-SYMBOL(<sign>).
      ASSIGN COMPONENT 'OPTION' OF STRUCTURE <row> TO FIELD-SYMBOL(<option>).
      ASSIGN COMPONENT 'LOW'    OF STRUCTURE <row> TO FIELD-SYMBOL(<low>).
      ASSIGN COMPONENT 'HIGH'   OF STRUCTURE <row> TO FIELD-SYMBOL(<high>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(low_val) =	'{ <low> }'	.
      DATA(high_val) =  '{ <high> }'  .
      CASE <option>.
        WHEN 'EQ'.
          line =  |{ field_name } = { low_val }|  .
        WHEN 'BT'.
          line =  |{ field_name } BETWEEN { low_val } AND { high_val }| .
        WHEN 'NE'.
          line =  |{ field_name } <> { low_val }| .
        WHEN 'GE'.
          line =  |{ field_name } >= { low_val }| .
        WHEN 'LE'.
          line =  |{ field_name } <= { low_val }| .
        WHEN 'LT'.
          line =  |{ field_name } < { low_val }|  .
        WHEN 'GT'.
          line =  |{ field_name } > { low_val }|  .
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
      IF <sign> = 'E'.
        line =  |NOT ( { line } )|  .
      ENDIF.
*      APPEND line TO conditions.
      line = COND #( WHEN first_append_flag = abap_true THEN  |AND ( { line } |
                     ELSE	|OR { line } | ).
      result = VALUE #( BASE result
                      ( |{ line }| ) ).
      first_append_flag = abap_false.
    ENDLOOP.
    result[ lines( result ) ]-text = |{ result[ lines( result ) ]-text } )|.
*    IF conditions IS NOT INITIAL.
*      where_line = REDUCE string( INIT s TYPE string
*                                   FOR cond IN conditions
*                                   NEXT s = COND string( WHEN s IS INITIAL THEN cond
*                                                         ELSE   { s } OR { cond }   ) )."  s && ' OR ' && cond ) ).
*      result = ( { where_line } )  .
*    ENDIF.
*
*    IF where_clause IS NOT INITIAL.
*      result =	{ where_clause } AND { result }	.
*    ENDIF.
  ENDMETHOD.


  METHOD string_to_options.
    DATA position   TYPE int4 VALUE 0.
    DATA max_length TYPE int4 VALUE 72.
    DATA(remaining_length) = strlen( string ).
    WHILE remaining_length > 0.
      max_length = COND #( WHEN remaining_length >= 72 THEN max_length
                           ELSE remaining_length ).
      result = VALUE #( BASE result ( text = string+position(max_length) ) ).
      remaining_length = remaining_length - 72.
      position = position + max_length.
    ENDWHILE.
  ENDMETHOD.


  METHOD zf01_if_migration~get_table_description.
    DATA(fixed_values) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_name( zf01_cl_migration_constants=>migration_staging_tables ) )->get_ddic_fixed_values( p_langu = sy-langu ).
    TRY.
        description = fixed_values[ low = fixed_value ]-ddtext.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD zf01_if_migration~specific_fields_check.
*    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
*    FIELD-SYMBOLS <line>  TYPE any.
*
*    ASSIGN !table TO <table>.
*
*    IF <table> IS NOT ASSIGNED.
*      RETURN.
*    ENDIF.
*
*    IF NOT line_exists( <table>[ 1 ] ).
*      RETURN.
*    ENDIF.
*
*    DATA(counter) = 1.
*
*    LOOP AT <table> ASSIGNING <line>.
*
*      "Check if BELNR is initial
*      ASSIGN COMPONENT zf01_cl_migration_constants=>fields-xblnr OF STRUCTURE <line> TO FIELD-SYMBOL(<xblnr>).
*      IF <xblnr> IS ASSIGNED.
*        <xblnr> = COND #( WHEN <blnr> IS NOT INITIAL THEN <xblnr> ELSE BRANCH UAT { counter }   ).
*        counter += 1.
*      ENDIF.
*
*
*
*    ENDLOOP.
  ENDMETHOD.


  METHOD zf01_if_migration~update_fields.
    DATA field_filter TYPE RANGE OF zf01_asset_map-field.
    DATA struct_descr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS <table_to_be_changed> TYPE ANY TABLE.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <field> TYPE any.
    "Create log object
    DATA(slg_log) = CAST zf01_if_slg_log( NEW zf01_cl_slg_log( ) ).
    ASSIGN updated_table TO <table_to_be_changed>.
    <table_to_be_changed> = table.
    ASSIGN <table_to_be_changed> TO <table>.
    CHECK sy-subrc = 0.
    "Get table line to define the type of structure
    ASSIGN <table>[ 1 ] TO <line>.
    CHECK sy-subrc = 0.
    "Get structure details
    struct_descr ?= cl_abap_typedescr=>describe_by_data( <line> ).
    CHECK struct_descr IS BOUND.
    "Get components of structure
    DATA(components) = struct_descr->get_components(  ).
    "Filter the components according to maintenance table
    field_filter = VALUE #( FOR wa IN fields_to_be_changed ( sign = 'I' option = 'EQ' low = wa-field ) ).
    "Add special fields
    field_filter = VALUE #( BASE field_filter sign = 'I' option = 'EQ'
                            ( low = zf01_cl_migration_constants=>fields-meins )
                            ( low = zf01_cl_migration_constants=>fields-gjahr )
                            ( low = zf01_cl_migration_constants=>fields-deakt )
                            ( low = zf01_cl_migration_constants=>fields-xblnr )
                            ( low = zf01_cl_migration_constants=>fields-xref2 )
                            ( low = zf01_cl_migration_constants=>fields-xref3 )
                            ( low = zf01_cl_migration_constants=>fields-pernr )
                            ( low = zf01_cl_migration_constants=>fields-kostl )
                            ( low = zf01_cl_migration_constants=>fields-pspnr )
                            ( low = zf01_cl_migration_constants=>fields-projk )
                            ( low = zf01_cl_migration_constants=>fields-ps_psp_pnr2 ) ).
    "Delete fields which will not be changed, to prevent unneccesary loops
    DELETE components WHERE name NOT IN field_filter.
    "Copy PROJK mappings for PSPNR and XREF3
    DATA(mapping_fields) = fields_to_be_changed.
    mapping_fields = VALUE #( BASE mapping_fields FOR wa IN mapping_fields WHERE ( field = zf01_cl_migration_constants=>fields-projk ) bukrs = wa-bukrs old_value = wa-old_value new_value = wa-new_value
                            ( field = zf01_cl_migration_constants=>fields-pspnr )
                            ( field = zf01_cl_migration_constants=>fields-xref3 ) ).
    "Get current date
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    "Get company code
    TRY.
        ASSIGN COMPONENT zf01_cl_migration_constants=>fields-bukrs OF STRUCTURE <table>[ 1 ] TO FIELD-SYMBOL(<bukrs>).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    "Counter variable to numbering empty XBLNR fields.
    DATA(xblnr_counter)  = 0.
    "Loop through the data table to update fields
    LOOP AT <table> ASSIGNING <line>.
      DATA(is_xblnr_empty) = abap_false.
      "Check each component
      LOOP AT components INTO DATA(component).
        "Assign the field
        ASSIGN COMPONENT component-name OF STRUCTURE <line> TO <field>.
        CHECK sy-subrc = 0.
        "Convert WBS Element Before Mapping
        IF ( component-name = zf01_cl_migration_constants=>fields-pspnr OR component-name = zf01_cl_migration_constants=>fields-projk OR component-name = zf01_cl_migration_constants=>fields-xref3 ) AND <field> = '00000000'.
          CLEAR <field>.
        ENDIF.
        IF ( component-name = zf01_cl_migration_constants=>fields-pspnr OR component-name = zf01_cl_migration_constants=>fields-projk OR component-name = zf01_cl_migration_constants=>fields-xref3 ) AND <field> IS NOT INITIAL.
          DATA(old_value) = CONV char30( <field> ).
          <field> = convert_wbs_element( CONV char80( <field> ) ).
          IF <field> IS INITIAL.
            <field> = old_value.
          ENDIF.
        ENDIF.
        "Check if XBLNR is empty
        IF component-name = zf01_cl_migration_constants=>fields-xblnr AND <field> IS INITIAL.
          xblnr_counter += 1.
          is_xblnr_empty = abap_true.
        ENDIF.
        "MAPPING
        "Change field value
        TRY.
            <field> = mapping_fields[ field = component-name old_value = <field> ]-new_value.
          CATCH cx_sy_itab_line_not_found.
            "If can not find with specific old value, try with *
            TRY.
                <field> = mapping_fields[ field = component-name old_value = '*' ]-new_value.
              CATCH cx_sy_itab_line_not_found.
            ENDTRY.
        ENDTRY.
        "Special fields
        CASE component-name.
            "If it's base unit of measure, get iso code of unit
          WHEN zf01_cl_migration_constants=>fields-meins.
            <field> = get_iso_code_of_buom( CONV msehi( <field> ) ).
            "If it's fiscal year, set it to current year
          WHEN zf01_cl_migration_constants=>fields-gjahr.
            <field> = current_date(4).
          WHEN zf01_cl_migration_constants=>fields-xref2.
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-belnr OF STRUCTURE <line> TO FIELD-SYMBOL(<belnr>).
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-buzei OF STRUCTURE <line> TO FIELD-SYMBOL(<buzei>).
            IF <belnr> IS ASSIGNED AND <buzei> IS ASSIGNED.
              <field> =	|{ CONV string( <belnr> ) ALPHA = OUT }/{ CONV string( <buzei> ) ALPHA = OUT }|.
              CONDENSE <field> NO-GAPS.
              UNASSIGN: <belnr>, <buzei>.
            ENDIF.
          WHEN zf01_cl_migration_constants=>fields-xblnr.
            IF is_xblnr_empty = abap_true.
              <field> =	|{ <field> } { xblnr_counter }|	.
            ENDIF.
            "Commented on 28.05.2025 as requested
*            "Add company code to SGTXT Field
*          WHEN zf01_cl_migration_constants=>fields-sgtxt.
*            <field> =  { <bukrs> } { <field> } .
            "If PERNR or WBS Element is 0, clear it
          WHEN zf01_cl_migration_constants=>fields-pernr OR zf01_cl_migration_constants=>fields-ps_psp_pnr2.
            IF <field> = '00000000'.
              CLEAR <field>.
            ENDIF.
            "Change Profit Center according to Cost Center
          WHEN zf01_cl_migration_constants=>fields-kostl.
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-anln1 OF STRUCTURE <line> TO FIELD-SYMBOL(<anln1>).
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-anln2 OF STRUCTURE <line> TO FIELD-SYMBOL(<anln2>).
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-prctr OF STRUCTURE <line> TO FIELD-SYMBOL(<prctr>).
            IF <anln1> IS ASSIGNED AND <anln2> IS ASSIGNED AND <prctr> IS ASSIGNED.
              "Check profit center with new company code and new cost center (if changed)
              <prctr> = get_profit_center( bukrs = CONV bukrs( <bukrs> ) kostl = CONV kostl( <field> ) ).
              UNASSIGN: <anln1>, <anln2>, <prctr>.
            ENDIF.
            "If deakt date is not inital, clear and log it
          WHEN zf01_cl_migration_constants=>fields-deakt.
            IF <field> IS INITIAL.
              CONTINUE.
            ENDIF.
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-anln1 OF STRUCTURE <line> TO <anln1>.
            ASSIGN COMPONENT zf01_cl_migration_constants=>fields-anln2 OF STRUCTURE <line> TO <anln2>.
            IF <bukrs> IS NOT ASSIGNED OR <anln1> IS NOT ASSIGNED OR <anln2> IS NOT ASSIGNED.
              CONTINUE.
            ENDIF.
            DATA(log_handle) = slg_log->log_create( log = VALUE #( object    = zf01_cl_migration_constants=>slg_log-main_object
                                                                   subobject = zf01_cl_migration_constants=>slg_log-asset
                                                                   extnumber = |{ <bukrs> }/{ <anln1> }/{ <anln2> }|
                                                                   aluser    = sy-uname
                                                                   alprog    = sy-repid
                                                                   aldate    = sy-datum
                                                                   altime    = sy-uzeit ) ).
            slg_log->log_message_add( EXPORTING log_handle = log_handle
                                                message    = VALUE #( msgty = zf01_cl_migration_constants=>message_class-warning
                                                                      msgid = zf01_cl_migration_constants=>message_class-name
                                                                      msgno = zf01_cl_migration_constants=>message_class-deakt_msg_number
                                                                      msgv1 = <field>
                                                                      msgv2 = <bukrs>
                                                                      msgv3 = <anln1>
                                                                      msgv4 = <anln2> ) ).
            CLEAR <field>.
            UNASSIGN: <anln1>, <anln2>.
        ENDCASE.
      ENDLOOP.
      "XREF3 should get PROJK (WBS Element) value if it's filled
      ASSIGN COMPONENT zf01_cl_migration_constants=>fields-projk OF STRUCTURE <line> TO FIELD-SYMBOL(<projk>).
      ASSIGN COMPONENT zf01_cl_migration_constants=>fields-xref3 OF STRUCTURE <line> TO FIELD-SYMBOL(<xref3>).
      IF <projk> IS ASSIGNED AND <xref3> IS ASSIGNED.
        IF <projk> IS NOT INITIAL.
          <xref3> = <projk>.
        ENDIF.
        UNASSIGN: <xref3>, <projk>.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zf01_if_migration~update_messages.
    result = VALUE #( BASE messages
                    ( type       = message_type
                      id         = zf01_cl_migration_constants=>message_class
                      number     = message_no
                      message_v1 = message_v1
                      message_v2 = message_v2 ) ).
  ENDMETHOD.
ENDCLASS.
