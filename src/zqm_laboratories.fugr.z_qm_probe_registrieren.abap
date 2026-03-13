FUNCTION Z_QM_PROBE_REGISTRIEREN.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"     VALUE(I_CUSTOMIZING) LIKE  V_TQ85 STRUCTURE  V_TQ85
*"  EXPORTING
*"     VALUE(E_QNQMAMA0) LIKE  QNQMAMA0 STRUCTURE  QNQMAMA0
*"  TABLES
*"      TI_IVIQMFE STRUCTURE  WQMFE
*"      TI_IVIQMUR STRUCTURE  WQMUR
*"      TI_IVIQMSM STRUCTURE  WQMSM
*"      TI_IVIQMMA STRUCTURE  WQMMA
*"      TI_IHPA STRUCTURE  IHPA
*"      TE_LINES STRUCTURE  TLINE OPTIONAL
*"  EXCEPTIONS
*"      ACTION_STOPPED
*"----------------------------------------------------------------------
CONSTANTS: lc_mem_id TYPE char40 VALUE 'GT_PROBES_0503'.

  DATA: lt_probes      TYPE zqmprobes_t,
        ls_probes      TYPE zqmprobes,
        lt_fields      TYPE ty_sval,
        ls_field       TYPE sval,
        lv_return      TYPE char1,
        lv_tabix       TYPE sytabix,
        ls_qprs        TYPE qprs,
        lv_i           TYPE i.

  "get probes table from include ZXQQMI04
  IMPORT gt_probes_0503 TO lt_probes FROM MEMORY ID lc_mem_id.
  FREE MEMORY ID lc_mem_id.

  "one has to be marked, only one can be marked
  READ TABLE lt_probes INTO ls_probes WITH KEY mark = 'X'.
  IF sy-subrc <> 0.
    MESSAGE e037(zqm).
  ENDIF.

  lv_tabix = sy-tabix.

  IF ls_probes-phynr IS NOT INITIAL.
    MESSAGE e038(zqm).
  ENDIF.

  LOOP AT lt_probes INTO ls_probes WHERE mark = 'X'.
    lv_i = lv_i + 1.
  ENDLOOP.

  IF lv_i > 1.
    MESSAGE e039(zqm).
  ENDIF.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'PHYNR'.
  ls_field-field_obl  = 'X'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'HANDLE_CL_USER_INPUT'
      programname       = 'ZQM_NOTIF_REF_CREATE_REPORT' "calls dummy form
      popup_title       = text-903
      ok_pushbuttontext = text-904
      icon_ok_push      = '@0Y@'
    IMPORTING
      returncode        = lv_return
    TABLES
      fields            = lt_fields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.
  IF sy-subrc <> 0.
    MESSAGE e020(zqm).
  ELSEIF lv_return EQ 'A'.
    RETURN.
  ENDIF.

  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'PHYNR'.
  IF sy-subrc <> 0.
    MESSAGE e020(zqm).
  ENDIF.

  SELECT SINGLE * FROM qprs INTO ls_qprs WHERE phynr EQ ls_field-value.
  IF sy-subrc <> 0.
    MESSAGE e028(zqm) WITH ls_field-value.
    RAISE action_stopped.
  ENDIF.

  ls_probes-phynr = ls_qprs-phynr.
  e_qnqmama0-matxt = ls_probes-phynr.
  MODIFY lt_probes FROM ls_probes INDEX lv_tabix.

  "export
  EXPORT lt_probes TO MEMORY ID lc_mem_id.

  MESSAGE s027(zqm) WITH ls_probes-phynr.
ENDFUNCTION.
