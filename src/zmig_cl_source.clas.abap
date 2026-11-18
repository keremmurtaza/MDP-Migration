"! Base class for reading migration data in the source system.
"! Subclasses implement READ_DATA with the object specific selects and pass every
"! result table to ADD_TABLE with the Migration Cockpit structure name.
"! Field names of the result tables have to match the staging table field names.
CLASS zmig_cl_source DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES tt_values TYPE STANDARD TABLE OF zmig_data_value WITH EMPTY KEY .

    CONSTANTS message_class TYPE symsgid VALUE 'ZMIG_BASE' ##NO_TEXT.

    METHODS constructor
      IMPORTING
        !selections TYPE rsparams_tt .
    "! Reads the source data, implemented per migration object
    METHODS read_data
      ABSTRACT .
    METHODS get_values
      RETURNING
        VALUE(result) TYPE tt_values .
    METHODS get_messages
      RETURNING
        VALUE(result) TYPE bapiret2_t .

  PROTECTED SECTION.

    DATA selections TYPE rsparams_tt .

    "! Returns the value of a selection screen parameter of the calling program
    METHODS get_parameter
      IMPORTING
        !name         TYPE rsscr_name
      RETURNING
        VALUE(result) TYPE rsparams-low .
    "! Fills a range table from a select-option of the calling program
    METHODS get_range
      IMPORTING
        !name        TYPE rsscr_name
      EXPORTING
        !range_table TYPE STANDARD TABLE .
    "! Adds a result table for a Migration Cockpit structure
    METHODS add_table
      IMPORTING
        !structure TYPE zmig_structure
        !rows      TYPE ANY TABLE .
    METHODS add_message
      IMPORTING
        !type   TYPE bapi_mtype
        !number TYPE symsgno
        !v1     TYPE symsgv OPTIONAL
        !v2     TYPE symsgv OPTIONAL
        !v3     TYPE symsgv OPTIONAL
        !v4     TYPE symsgv OPTIONAL .

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_counter,
        structure TYPE zmig_structure,
        record    TYPE i,
      END OF ty_counter .
    TYPES tt_counters TYPE HASHED TABLE OF ty_counter WITH UNIQUE KEY structure .

    CONSTANTS segment_length TYPE i VALUE 255.

    DATA values TYPE tt_values .
    DATA messages TYPE bapiret2_t .
    DATA counters TYPE tt_counters .
ENDCLASS.



CLASS ZMIG_CL_SOURCE IMPLEMENTATION.


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
                    message_v4 = v4 ) TO messages.
  ENDMETHOD.


  METHOD add_table.
    DATA value  TYPE string.
    DATA offset TYPE i.
    DATA length TYPE i.
    DATA segment TYPE i.
    FIELD-SYMBOLS <field> TYPE any.

    IF rows IS INITIAL.
      RETURN.
    ENDIF.

    "Record counter per structure, so that ADD_TABLE can be called more than once
    READ TABLE counters ASSIGNING FIELD-SYMBOL(<counter>) WITH TABLE KEY structure = structure.
    IF sy-subrc <> 0.
      INSERT VALUE #( structure = structure ) INTO TABLE counters ASSIGNING <counter>.
    ENDIF.

    DATA(table_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( rows ) ).
    DATA(line_descr)  = CAST cl_abap_structdescr( table_descr->get_table_line_type( ) ).

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      <counter>-record = <counter>-record + 1.

      LOOP AT line_descr->components INTO DATA(component).
        ASSIGN COMPONENT component-name OF STRUCTURE <row> TO <field>.
        IF sy-subrc <> 0 OR <field> IS INITIAL.
          CONTINUE.
        ENDIF.

        "Only filled fields are transferred, long values are split into segments
        value   = |{ <field> }|.
        length  = strlen( value ).
        offset  = 0.
        segment = 0.
        WHILE offset < length.
          segment = segment + 1.
          APPEND VALUE #( structure = structure
                          record    = <counter>-record
                          field     = component-name
                          segment   = segment
                          value     = substring( val = value
                                                 off = offset
                                                 len = nmin( val1 = segment_length val2 = length - offset ) ) )
                 TO values.
          offset = offset + segment_length.
        ENDWHILE.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD constructor.
    me->selections = selections.
  ENDMETHOD.


  METHOD get_messages.
    result = messages.
  ENDMETHOD.


  METHOD get_parameter.
    READ TABLE selections INTO DATA(selection) WITH KEY selname = name kind = 'P'.
    IF sy-subrc = 0.
      result = selection-low.
    ENDIF.
  ENDMETHOD.


  METHOD get_range.
    FIELD-SYMBOLS <line> TYPE any.

    CLEAR range_table.
    LOOP AT selections INTO DATA(selection) WHERE selname = name
                                              AND kind    = 'S'
                                              AND option IS NOT INITIAL.
      APPEND INITIAL LINE TO range_table ASSIGNING <line>.
      MOVE-CORRESPONDING selection TO <line>.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_values.
    result = values.
  ENDMETHOD.
ENDCLASS.
