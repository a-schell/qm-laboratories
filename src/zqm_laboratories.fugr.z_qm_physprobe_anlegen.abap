FUNCTION z_qm_physprobe_anlegen.
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

  DATA: lt_probes   TYPE zqmprobes_t,
        ls_probes   TYPE zqmprobes,
        lv_prbnr    TYPE zzqmprbnr,
        lv_all      TYPE xfeld,
        ls_qprs_in  TYPE qprs,
        ls_qprs_out TYPE qprs,
        lt_fields   TYPE ty_sval,
        ls_field    TYPE sval,
        lv_return   TYPE char1,
        ls_qals     TYPE qals,
        ls_qprs_addon_in TYPE qprs_addon.

  "get probes table from include ZXQQMI04
  IMPORT gt_probes_0503 TO lt_probes FROM MEMORY ID lc_mem_id.
  FREE MEMORY ID lc_mem_id.

  READ TABLE lt_probes WITH KEY mark = 'X' TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    LOOP AT lt_probes INTO ls_probes WHERE status <> zqm_cl_util=>c_icon_delete.
      ls_probes-mark = 'X'.
      MODIFY lt_probes FROM ls_probes.
    ENDLOOP.
  ENDIF.

  "check, if a selection already has a probe
  LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
    IF ls_probes-phynr IS NOT INITIAL.
      MESSAGE e036(zqm) WITH ls_probes-prbnr ls_probes-phynr.
    ENDIF.
  ENDLOOP.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'MENGE'.
  ls_field-field_obl  = 'X'.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'MEINH'.
  ls_field-field_obl  = 'X'.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'BEARBEITER'.
  ls_field-field_obl  = ' '.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'ENTDATUM'.
  ls_field-field_obl  = ' '.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'ENTZEIT'.
  ls_field-field_obl  = ' '.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'ZZBMS_BALLENNR'.
  ls_field-field_obl  = ' '.
  APPEND ls_field TO lt_fields.

  ls_field-tabname    = 'QPRS'.
  ls_field-fieldname  = 'ZZBMS_BALLENINFO'.
  ls_field-field_obl  = ' '.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'HANDLE_CL_USER_INPUT'
      programname       = 'ZQM_NOTIF_REF_CREATE_REPORT' "calls dummy form
      popup_title       = text-901
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
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'MENGE'.
  IF sy-subrc EQ 0.
    ls_qprs_in-menge = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'MEINH'.
  IF sy-subrc EQ 0.
    ls_qprs_in-meinh = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'BEARBEITER'.
  IF sy-subrc EQ 0.
    ls_qprs_in-bearbeiter = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ENTDATUM'.
  IF sy-subrc EQ 0.
    ls_qprs_in-entdatum = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ENTZEIT'.
  IF sy-subrc EQ 0.
    ls_qprs_in-entzeit = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ZZBMS_BALLENNR'.
  IF sy-subrc EQ 0.
    ls_qprs_addon_in-zzbms_ballennr = ls_field-value.
  ENDIF.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ZZBMS_BALLENINFO'.
  IF sy-subrc EQ 0.
    ls_qprs_addon_in-zzbms_balleninfo = ls_field-value.
  ENDIF.
  ls_qprs_in-prart = '08'.

  LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
    CALL FUNCTION 'QPRS_MASTER_SAMPLE_CREATE'
      EXPORTING
        i_prtyp      = ls_qprs_in-prtyp
        i_gbtyp      = ls_qprs_in-gbtyp
        i_menge      = ls_qprs_in-menge
        i_meinh      = ls_qprs_in-meinh
        i_prart      = ls_qprs_in-prart
        i_ktext      = ls_probes-prbdesc
        i_infeort    = ls_probes-prbexam
        i_entort     = ls_qprs_in-entort
        i_entdatum   = ls_qprs_in-entdatum
        i_entzeit    = ls_qprs_in-entzeit
        i_bearbeiter = ls_qprs_in-bearbeiter
        i_first      = 'X'
        i_last       = 'X'
        i_qprs_addon = ls_qprs_addon_in
      IMPORTING
        e_qprs       = ls_qprs_out.

    IF ls_qprs_out-phynr IS INITIAL.
      ROLLBACK WORK.
      RAISE action_stopped.
    ELSE.
      e_qnqmama0-matxt = ls_qprs_out-phynr.

      ls_probes-phynr = ls_qprs_out-phynr.
      ls_probes-menge = ls_qprs_out-menge.
      ls_probes-meinh = ls_qprs_out-meinh.
      MODIFY lt_probes FROM ls_probes.
    ENDIF.
  ENDLOOP.

  "write phynr back to zqmprobes and export
  EXPORT lt_probes TO MEMORY ID lc_mem_id.
  IF sy-tcode = 'QM02'.
    COMMIT WORK AND WAIT.
  ENDIF.
  MESSAGE s026(zqm) WITH ls_qprs_out-phynr.
ENDFUNCTION.
