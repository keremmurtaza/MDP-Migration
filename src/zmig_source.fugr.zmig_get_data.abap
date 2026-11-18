FUNCTION zmig_get_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCE_CLASS) TYPE  SEOCLSNAME
*"     VALUE(SELECTIONS) TYPE  RSPARAMS_TT
*"  TABLES
*"      VALUES STRUCTURE  ZMIG_DATA_VALUE
*"      MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA source TYPE REF TO zmig_cl_source.
  DATA text   TYPE bapi_msg.

  CLEAR: values[], messages[].

  TRY.
      CREATE OBJECT source TYPE (source_class)
        EXPORTING
          selections = selections.

      source->read_data( ).

      values[]   = source->get_values( ).
      messages[] = source->get_messages( ).

    CATCH cx_sy_create_object_error.
      MESSAGE ID zmig_cl_source=>message_class TYPE 'E' NUMBER '006' WITH source_class INTO text.
      APPEND VALUE #( type       = 'E'
                      id         = zmig_cl_source=>message_class
                      number     = '006'
                      message    = text
                      message_v1 = source_class ) TO messages.

    CATCH cx_root INTO DATA(error).
      text = error->get_text( ).
      APPEND VALUE #( type       = 'E'
                      id         = zmig_cl_source=>message_class
                      number     = '000'
                      message    = text
                      message_v1 = text(50)
                      message_v2 = text+50(50)
                      message_v3 = text+100(50)
                      message_v4 = text+150(50) ) TO messages.
  ENDTRY.

ENDFUNCTION.
