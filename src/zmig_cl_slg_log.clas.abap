CLASS zmig_cl_slg_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zmig_if_slg_log.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZMIG_CL_SLG_LOG IMPLEMENTATION.


METHOD zmig_if_slg_log~log_create.

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log                 = log
    IMPORTING
      e_log_handle            = result                 " Log handle
    EXCEPTIONS
      log_header_inconsistent = 1                " Log header is inconsistent
      OTHERS                  = 2.

ENDMETHOD.


METHOD zmig_if_slg_log~log_message_add.

  CALL FUNCTION 'BAL_LOG_MSG_ADD'
    EXPORTING
      i_log_handle        = log_handle
      i_s_msg             = message
    IMPORTING
      e_s_msg_handle      = message_handle
      e_msg_was_logged    = message_logged
      e_msg_was_displayed = message_displayed
    EXCEPTIONS
      log_not_found       = 1
      msg_inconsistent    = 2
      log_is_full         = 3
      OTHERS              = 4.

    CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING
      i_save_all       = abap_true
    EXCEPTIONS
      log_not_found    = 1
      save_not_allowed = 2
      numbering_error  = 3
      OTHERS           = 4.

ENDMETHOD.
ENDCLASS.
