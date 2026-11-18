*&---------------------------------------------------------------------*
*& Include          ZMIG_STAGING_FIELDS_CLS
*&---------------------------------------------------------------------*
CLASS staging_fields DEFINITION.

  PUBLIC SECTION.
    METHODS process.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_output,
             technical_id TYPE zmig_staging_tech_id,
             table_text   TYPE as4text,
             object       TYPE zmig_object,
             structure    TYPE zmig_structure,
             position     TYPE tabfdpos,
             fieldname    TYPE fieldname,
             keyflag      TYPE keyflag,
             datatype     TYPE datatype_d,
             leng         TYPE ddleng,
             decimals     TYPE decimals,
             rollname     TYPE rollname,
             field_text   TYPE as4text,
           END OF ty_output,
           tt_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

    TYPES tt_table_names TYPE SORTED TABLE OF tabname WITH UNIQUE KEY table_line.

    DATA output TYPE tt_output.

    METHODS get_tables
      RETURNING VALUE(result) TYPE tt_table_names.

    METHODS get_fields
      IMPORTING table_names TYPE tt_table_names.

    METHODS display.

ENDCLASS.

CLASS staging_fields IMPLEMENTATION.

  METHOD process.

    DATA(table_names) = get_tables( ).

    IF table_names IS INITIAL.
      MESSAGE s017(zmig_base) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    get_fields( table_names ).
    display( ).

  ENDMETHOD.

  METHOD get_tables.

    "Active transparent tables with the given name
    SELECT tabname FROM dd02l
     WHERE tabname  IN @stgtabs
       AND as4local =  'A'
       AND tabclass =  'TRANSP'
      INTO TABLE @result.

    "Restrict to package
    IF packages[] IS NOT INITIAL AND result IS NOT INITIAL.
      SELECT obj_name FROM tadir
       WHERE pgmid    =  'R3TR'
         AND object   =  'TABL'
         AND devclass IN @packages
         AND obj_name IN @stgtabs
        INTO TABLE @DATA(package_tables).
      LOOP AT result INTO DATA(table_name).
        IF NOT line_exists( package_tables[ obj_name = table_name ] ).
          DELETE result.
        ENDIF.
      ENDLOOP.
    ENDIF.

    "Restrict to staging tables maintained for the migration object
    IF object IS NOT INITIAL AND result IS NOT INITIAL.
      SELECT technical_id FROM zmig_obj_stg
       WHERE object = @object
        INTO TABLE @DATA(object_tables).
      LOOP AT result INTO DATA(object_table_name).
        IF NOT line_exists( object_tables[ technical_id = object_table_name ] ).
          DELETE result.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD get_fields.

    SELECT tabname, position, fieldname, keyflag, rollname, datatype, leng, decimals
      FROM dd03l
       FOR ALL ENTRIES IN @table_names
     WHERE tabname   =  @table_names-table_line
       AND as4local  =  'A'
       AND fieldname NOT LIKE '.%'
      INTO TABLE @DATA(fields).

    SORT fields BY tabname position.

    IF fields IS INITIAL.
      RETURN.
    ENDIF.

    "Table texts
    SELECT tabname, ddlanguage, ddtext FROM dd02t
       FOR ALL ENTRIES IN @table_names
     WHERE tabname    = @table_names-table_line
       AND as4local   = 'A'
       AND ( ddlanguage = @sy-langu OR ddlanguage = 'E' )
      INTO TABLE @DATA(table_texts).
    SORT table_texts BY tabname ddlanguage.

    "Data element texts
    SELECT rollname, ddlanguage, ddtext FROM dd04t
       FOR ALL ENTRIES IN @fields
     WHERE rollname   = @fields-rollname
       AND as4local   = 'A'
       AND ( ddlanguage = @sy-langu OR ddlanguage = 'E' )
      INTO TABLE @DATA(element_texts).
    SORT element_texts BY rollname ddlanguage.

    "Field texts of fields without data element
    SELECT tabname, fieldname, ddlanguage, ddtext FROM dd03t
       FOR ALL ENTRIES IN @table_names
     WHERE tabname    = @table_names-table_line
       AND as4local   = 'A'
       AND ( ddlanguage = @sy-langu OR ddlanguage = 'E' )
      INTO TABLE @DATA(field_texts).
    SORT field_texts BY tabname fieldname ddlanguage.

    "Migration objects
    SELECT object, structure, technical_id FROM zmig_obj_stg
      INTO TABLE @DATA(object_structures).

    LOOP AT fields INTO DATA(field).

      DATA(line) = CORRESPONDING ty_output( field ).
      line-technical_id = field-tabname.

      "Logon language first, English as fallback
      line-table_text = VALUE #( table_texts[ tabname = field-tabname ddlanguage = sy-langu ]-ddtext
                                 DEFAULT VALUE #( table_texts[ tabname = field-tabname ddlanguage = 'E' ]-ddtext OPTIONAL ) ).

      IF field-rollname IS NOT INITIAL.
        line-field_text = VALUE #( element_texts[ rollname = field-rollname ddlanguage = sy-langu ]-ddtext
                                   DEFAULT VALUE #( element_texts[ rollname = field-rollname ddlanguage = 'E' ]-ddtext OPTIONAL ) ).
      ELSE.
        line-field_text = VALUE #( field_texts[ tabname = field-tabname fieldname = field-fieldname ddlanguage = sy-langu ]-ddtext
                                   DEFAULT VALUE #( field_texts[ tabname = field-tabname fieldname = field-fieldname ddlanguage = 'E' ]-ddtext OPTIONAL ) ).
      ENDIF.

      DATA(object_structure) = VALUE #( object_structures[ technical_id = field-tabname ] OPTIONAL ).
      line-object    = object_structure-object.
      line-structure = object_structure-structure.

      APPEND line TO output.

    ENDLOOP.

  ENDMETHOD.

  METHOD display.

    DATA alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = alv
                                CHANGING  t_table      = output ).

        alv->get_functions( )->set_all( abap_true ).
        alv->get_display_settings( )->set_striped_pattern( abap_true ).

        DATA(columns) = alv->get_columns( ).
        columns->set_optimize( abap_true ).
        columns->get_column( 'TABLE_TEXT' )->set_short_text( CONV #( TEXT-c01 ) ).
        columns->get_column( 'TABLE_TEXT' )->set_medium_text( CONV #( TEXT-c02 ) ).
        columns->get_column( 'TABLE_TEXT' )->set_long_text( CONV #( TEXT-c02 ) ).
        columns->get_column( 'FIELD_TEXT' )->set_short_text( CONV #( TEXT-c03 ) ).
        columns->get_column( 'FIELD_TEXT' )->set_medium_text( CONV #( TEXT-c04 ) ).
        columns->get_column( 'FIELD_TEXT' )->set_long_text( CONV #( TEXT-c04 ) ).

        DATA(sorts) = alv->get_sorts( ).
        sorts->add_sort( columnname = 'TECHNICAL_ID' subtotal = abap_false ).

        alv->display( ).
      CATCH cx_salv_msg cx_salv_not_found cx_salv_existing cx_salv_data_error.
        MESSAGE s015(zmig_base) DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
