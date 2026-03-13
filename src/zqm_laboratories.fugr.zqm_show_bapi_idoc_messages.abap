FUNCTION ZQM_SHOW_BAPI_IDOC_MESSAGES.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_AMODAL_WINDOW) TYPE  CHAR1
*"     REFERENCE(IT_RETURN_BAPI) TYPE  BAPIRET2_T OPTIONAL
*"     REFERENCE(IT_RETURN_IDOC) TYPE  BDTIDOCSTA OPTIONAL
*"----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*& AUTHOR: wiesmayr, wiw@informatics.at
*& DATE: 06.12.2016
*& DESCRIPTION: Ausgabe von BAPI und IDOC-Meldungen
*& CHANGE:
*&---------------------------------------------------------------------*

DATA: ls_bapi TYPE bapiret2,
      ls_idoc TYPE bdidocstat.

*** INIT ***
  CALL FUNCTION 'MESSAGES_INITIALIZE'.

*** BAPI-MELDUNGEN ***
  LOOP AT it_return_bapi INTO ls_bapi.
    CALL FUNCTION 'MESSAGE_STORE'
      EXPORTING
        arbgb                   = ls_bapi-id
        exception_if_not_active = ' '
        msgty                   = ls_bapi-type
        msgv1                   = ls_bapi-message_v1
        msgv2                   = ls_bapi-message_v2
        msgv3                   = ls_bapi-message_v3
        msgv4                   = ls_bapi-message_v4
        txtnr                   = ls_bapi-number
        zeile                   = ' '
      EXCEPTIONS
        message_type_not_valid  = 1
        not_active              = 2
        OTHERS                  = 3.
  ENDLOOP.

*** IDOC-MELDUNGEN ***
  LOOP AT it_return_idoc INTO ls_idoc.
    CALL FUNCTION 'MESSAGE_STORE'
      EXPORTING
        arbgb                   = ls_idoc-msgid
        exception_if_not_active = ' '
        msgty                   = ls_idoc-msgty
        msgv1                   = ls_idoc-msgv1
        msgv2                   = ls_idoc-msgv2
        msgv3                   = ls_idoc-msgv3
        msgv4                   = ls_idoc-msgv4
        txtnr                   = ls_idoc-msgno
        zeile                   = ' '
      EXCEPTIONS
        message_type_not_valid  = 1
        not_active              = 2
        OTHERS                  = 3.
  ENDLOOP.

*** STOP um "Fehler in Message-Handling" zu vermeiden
  CALL FUNCTION 'MESSAGES_STOP'
    EXCEPTIONS
      a_message = 04
      e_message = 03
      i_message = 02
      w_message = 01.

  IF NOT sy-subrc IS INITIAL.
*** AUSGABE ***
    CALL FUNCTION 'MESSAGES_SHOW'
      EXPORTING
        i_use_grid         = 'X'
        i_amodal_window    = iv_amodal_window
      EXCEPTIONS
        inconsistent_range = 1
        no_messages        = 2
        OTHERS             = 3.
  ENDIF.

ENDFUNCTION.
