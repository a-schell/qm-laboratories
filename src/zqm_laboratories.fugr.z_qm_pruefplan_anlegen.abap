FUNCTION z_qm_pruefplan_anlegen.
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

  DATA: lo_obj      TYPE REF TO zqm_cl_notif_ref_create_report,
        lv_plnnr    TYPE plnnr,
        lv_plnal    TYPE plnal,
        lv_time     TYPE zzqmsollzeit_d,
        lv_timeunit TYPE zzqmsollzeiteinh_d,
        lt_probes   TYPE zqmprobes_t,
        ls_probes   TYPE zqmprobes,
        lv_prbnr    TYPE zzqmprbnr,
        lv_all      TYPE xfeld.

  "get probes table from include ZXQQMI04
  IMPORT gt_probes_0503 TO lt_probes FROM MEMORY ID lc_mem_id.
  FREE MEMORY ID lc_mem_id.

  "get number of probes selected (to multiply time)
  "if none is marked, all are selected
  READ TABLE lt_probes WITH KEY mark = 'X' TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    LOOP AT lt_probes INTO ls_probes.
      IF zqm_cl_util=>get_probe_lock_status( iv_status = ls_probes-status
                                             iv_phynr  = ls_probes-phynr ) <> 'X'.
        ls_probes-mark = 'X'.
        MODIFY lt_probes FROM ls_probes.
      ENDIF.
    ENDLOOP.
  ENDIF.

  LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
    lv_prbnr = lv_prbnr + 1.
  ENDLOOP.

  LOOP AT lt_probes INTO ls_probes WHERE plnnr IS NOT INITIAL AND mark EQ 'X'.
    MESSAGE e043(zqm) WITH ls_probes-phynr.
  ENDLOOP.

  CREATE OBJECT lo_obj
    EXPORTING
      iv_werks = i_viqmel-mawerk
      iv_prbnr = lv_prbnr.

  lo_obj->run( IMPORTING ev_plnnr    = lv_plnnr
                         ev_plnal    = lv_plnal
                         ev_time     = lv_time
                         ev_timeunit = lv_timeunit ).

  FREE lo_obj.

  IF lv_plnnr IS INITIAL AND lv_plnal IS INITIAL.
    RAISE action_stopped.
  ELSE.
    CONCATENATE lv_plnnr '/' lv_plnal INTO e_qnqmama0-matxt.

    "write plnnr/plnal back to zqmprobes and export
    LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
      ls_probes-plnnr            = lv_plnnr.
      ls_probes-plnal            = lv_plnal.
      ls_probes-zzqmsollzeit     = lv_time.
      ls_probes-zzqmsollzeiteinh = lv_timeunit.
      MODIFY lt_probes FROM ls_probes.
    ENDLOOP.

    EXPORT lt_probes TO MEMORY ID lc_mem_id.
  ENDIF.
ENDFUNCTION.
