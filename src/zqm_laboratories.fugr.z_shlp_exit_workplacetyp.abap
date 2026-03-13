FUNCTION z_shlp_exit_workplacetyp .
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     REFERENCE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: ls_record LIKE seahlpres.
  DATA: lv_workplace   TYPE string.
  DATA: lv_werk   TYPE string.
  DATA: lv_art   TYPE string.
  DATA: ls_crhd TYPE crhd.
  DATA: lt_fields TYPE TABLE OF dynpread.
  DATA: ls_field TYPE dynpread.
  DATA: lv_lines TYPE i. "declare variable
  DATA: ls_werk TYPE t001w.


  ls_field-fieldname = 'VIQMEL-MAWERK'.
  APPEND ls_field TO lt_fields.


  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname                         = 'SAPLXQQM'
      dynumb                         = '0503'
*     TRANSLATE_TO_UPPER             = ' '
*     REQUEST                        = ' '
*     PERFORM_CONVERSION_EXITS       = ' '
*     PERFORM_INPUT_CONVERSION       = ' '
*     DETERMINE_LOOP_INDEX           = ' '
*     START_SEARCH_IN_CURRENT_SCREEN = ' '
*     START_SEARCH_IN_MAIN_SCREEN    = ' '
*     START_SEARCH_IN_STACKED_SCREEN = ' '
*     START_SEARCH_ON_SCR_STACKPOS   = ' '
*     SEARCH_OWN_SUBSCREENS_FIRST    = ' '
*     SEARCHPATH_OF_SUBSCREEN_AREAS  = ' '
    TABLES
      dynpfields                     = lt_fields.
*     EXCEPTIONS
*       INVALID_ABAPWORKAREA                 = 1
*       INVALID_DYNPROFIELD                  = 2
*       INVALID_DYNPRONAME                   = 3
*       INVALID_DYNPRONUMMER                 = 4
*       INVALID_REQUEST                      = 5
*       NO_FIELDDESCRIPTION                  = 6
*       INVALID_PARAMETER                    = 7
*       UNDEFIND_ERROR                       = 8
*       DOUBLE_CONVERSION                    = 9
*       STEPL_NOT_FOUND                      = 10
*       OTHERS                               = 11
  .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.




  READ TABLE lt_fields INDEX 1 INTO ls_field.

  DESCRIBE TABLE record_tab LINES lv_lines.


  LOOP AT record_tab INTO ls_record.

    lv_art = ls_record-string+3(4).
    lv_werk = ls_record-string+7(4).

    IF lv_werk NE ls_field-fieldvalue AND ls_field-fieldvalue IS NOT INITIAL.
      IF lv_lines = 1.
        SELECT SINGLE * FROM t001w INTO ls_werk WHERE werks = lv_werk.
        IF sy-subrc = 0.
          DELETE record_tab INDEX sy-tabix.
        ENDIF.
      ELSE.
        DELETE record_tab INDEX sy-tabix.
      ENDIF.
    ENDIF.
    CLEAR lv_werk.
    CLEAR lv_art.


  ENDLOOP.




ENDFUNCTION.
