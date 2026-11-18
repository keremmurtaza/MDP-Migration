INTERFACE zmig_if_slg_log
  PUBLIC .

  METHODS log_create
    IMPORTING log           TYPE bal_s_log
    RETURNING VALUE(result) TYPE balloghndl.

  METHODS log_message_add
    IMPORTING log_handle        TYPE balloghndl OPTIONAL
              message           TYPE bal_s_msg
    EXPORTING message_handle    TYPE balmsghndl
              message_logged    TYPE abap_boolean
              message_displayed TYPE abap_boolean.

  METHODS log_save
    IMPORTING
      VALUE(client)            TYPE  sy-mandt   DEFAULT sy-mandt
      VALUE(in_update_task)    TYPE  boolean    DEFAULT space
      VALUE(save_all)          TYPE  boolean    DEFAULT space
      VALUE(t_log_handle)      TYPE  bal_t_logh OPTIONAL
      VALUE(connection)        TYPE  boolean    DEFAULT space
      VALUE(connect_commit)    TYPE  boolean    DEFAULT space
      VALUE(link2job)          TYPE  boolean    DEFAULT 'X'
    EXPORTING
      VALUE(new_lognumbers)    TYPE  bal_t_lgnm
      VALUE(second_connection) TYPE  dbcon_name.

ENDINTERFACE.
