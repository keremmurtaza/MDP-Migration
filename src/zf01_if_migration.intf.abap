INTERFACE zf01_if_migration
  PUBLIC .


  METHODS update_fields
    IMPORTING
      !table                TYPE ANY TABLE
      !fields_to_be_changed TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed
    EXPORTING
      !updated_table        TYPE ANY TABLE .
  METHODS update_messages
    IMPORTING
      !messages     TYPE bapiret2_t
      !message_type TYPE bapi_mtype
      !message_no   TYPE symsgno
      !message_v1   TYPE symsgv
      !message_v2   TYPE symsgv
    RETURNING
      VALUE(result) TYPE bapiret2_t .
  METHODS get_table_description
    IMPORTING
      !fixed_value          TYPE char4
      !fields_to_be_changed TYPE zf01_if_migration_types=>table_types-tt_fields_to_be_changed
    RETURNING
      VALUE(description)    TYPE char60 .
  METHODS specific_fields_check
    IMPORTING !table         TYPE ANY TABLE
    EXPORTING !updated_table TYPE ANY TABLE.
ENDINTERFACE.
