FUNCTION z_qm_physprobe_sperren.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_PHYNR) TYPE  QPHYSPRNR
*"     REFERENCE(IV_COMMIT) TYPE  XFLAG
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
  DATA: ls_qprs TYPE qprs.

  SELECT SINGLE * FROM qprs INTO ls_qprs WHERE phynr EQ iv_phynr.
  CALL FUNCTION 'QPRS_MASTER_SAMPLE_UPDATE'
    EXPORTING
      i_phynr            = ls_qprs-phynr
      i_qprs_upd         = ls_qprs
      i_dialog           = space
      i_sperx            = 'X'
    EXCEPTIONS
      locking_error      = 1
      no_entry_found     = 2
      wrong_import_param = 3
      wrong_modus        = 4
      status_error       = 5
      no_data_changed    = 6
      action_canceled    = 7
      OTHERS             = 8.
  IF sy-subrc <> 0.
    RAISE error.
  ENDIF.

  IF iv_commit EQ 'X'.
    COMMIT WORK AND WAIT.
  ENDIF.
ENDFUNCTION.
