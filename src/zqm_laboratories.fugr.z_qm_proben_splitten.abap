FUNCTION z_qm_proben_splitten.
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
        ls_probes_last TYPE zqmprobes,
        ls_probes_main TYPE zqmprobes,
        ls_wqmma       TYPE wqmma,
        lv_i           TYPE i,
        lt_fields      TYPE ty_sval,
        ls_field       TYPE sval,
        lv_return      TYPE char1,
        lv_splitcount  TYPE i,
        ls_qprs_in     TYPE qprs,
        ls_qprs_out    TYPE qprs,
        ls_qprs        TYPE qprs,
        ls_qals        TYPE qals,
        lv_locked      TYPE xfeld,
        lv_phynr      type qprs-phynr.

  "get probes table from include ZXQQMI04
  IMPORT gt_probes_0503 TO lt_probes FROM MEMORY ID lc_mem_id.
  FREE MEMORY ID lc_mem_id.

  "one has to be marked, only one can be marked
  READ TABLE lt_probes INTO ls_probes WITH KEY mark = 'X'.
  IF sy-subrc <> 0.
    MESSAGE e032(zqm).
  ELSE.
    ls_probes_main = ls_probes.
    IF zqm_cl_util=>get_physical_probe_lock_status( ls_probes-phynr ) EQ 'X'.
      MESSAGE e035(zqm).
    ENDIF.
  ENDIF.

  LOOP AT lt_probes INTO ls_probes WHERE mark = 'X'.
    lv_i = lv_i + 1.
  ENDLOOP.

  IF lv_i > 1.
    MESSAGE e032(zqm).
  ENDIF.

  IF ls_probes_main-plnal IS NOT INITIAL OR ls_probes_main-prueflos IS NOT INITIAL.
    MESSAGE e040(zqm) WITH ls_probes-phynr.
  ENDIF.

  IF ls_probes_main-phynr IS INITIAL.
    MESSAGE e041(zqm).
  ENDIF.

  ls_field-tabname    = 'QMEL'.
  ls_field-fieldname  = 'ZZQMPRBNR'.
  ls_field-field_obl  = 'X'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'HANDLE_CL_USER_INPUT'
      programname       = 'ZQM_NOTIF_REF_CREATE_REPORT' "calls dummy form
      popup_title       = text-905
      ok_pushbuttontext = text-902
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

  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ZZQMPRBNR'.
  IF sy-subrc <> 0.
    MESSAGE e020(zqm).
  ENDIF.

  lv_splitcount = ls_field-value.

  ls_qals-art = 'ZLAG-00'.
  ls_qals-werkvorg = i_viqmel-mawerk. "Werkzuordnung

  CALL FUNCTION 'QPRS_SAMPLE_DRAW_CREATE'
    EXPORTING
      i_qals         = ls_qals
    EXCEPTIONS
      no_sample_type = 1
      OTHERS         = 2.

  ls_qprs_in-prtyp = space.
  ls_qprs_in-gbtyp = space.
  ls_qprs_in-menge = ls_probes_main-menge / lv_splitcount.
  ls_qprs_in-meinh = ls_probes_main-meinh.
  ls_qprs_in-prart = '08'.
*  break: extjaw.
  lv_phynr = ls_probes_main-prbnr.
  SHIFT lv_phynr LEFT DELETING LEADING '0'.
  CONCATENATE 'SPLIT VON:' lv_phynr ':' ls_probes_main-PRBDESC
  into ls_qprs_in-ktext.


  DO lv_splitcount TIMES.
    CLEAR: ls_qprs_out.

    READ TABLE lt_probes INTO ls_probes WITH KEY prbnr = ls_probes_main-prbnr.

    CALL FUNCTION 'QPRS_MASTER_SAMPLE_CREATE'
      EXPORTING
        i_prtyp = ls_qprs_in-prtyp
        i_gbtyp = ls_qprs_in-gbtyp
        i_menge = ls_qprs_in-menge
        i_meinh = ls_qprs_in-meinh
        i_prart = ls_qprs_in-prart
        i_ktext = ls_qprs_in-ktext
        i_infeort = ls_qprs_in-infeort
        i_first = 'X'
        i_last  = 'X'
      IMPORTING
        e_qprs  = ls_qprs_out.
    IF ls_qprs_out-phynr IS NOT INITIAL.
      READ TABLE lt_probes INTO ls_probes_last INDEX lines( lt_probes ).
      ls_probes-prbnr    = ls_probes_last-prbnr + 1.
      ls_probes-phynr    = ls_qprs_out-phynr.
      ls_probes-menge    = ls_qprs_out-menge.
      ls_probes-prbdesc    = ls_qprs_out-ktext.
      ls_probes-prbexam = ls_probes_main-prbexam.
      APPEND ls_probes TO lt_probes.

      "lock the old/main probe
      READ TABLE lt_probes INTO ls_probes WITH KEY prbnr = ls_probes_main-prbnr.
      IF sy-subrc EQ 0.
        CALL FUNCTION 'Z_QM_PHYSPROBE_SPERREN'
          EXPORTING
            iv_phynr  = ls_probes-phynr
            iv_commit = ' '
          EXCEPTIONS
            error     = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
          MESSAGE e034(zqm) WITH ls_qprs-phynr.
        ENDIF.
      ENDIF.
      MESSAGE s033(zqm) WITH ls_probes_main-phynr lv_splitcount.
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDDO.
       loop at lt_probes into ls_probes where prbnr = ls_probes_main-prbnr.
          ls_probes-status = '@IA@'.
        MODIFY lt_probes from ls_probes.
        endloop.
  "export
  EXPORT lt_probes TO MEMORY ID lc_mem_id.
ENDFUNCTION.
