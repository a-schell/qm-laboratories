FUNCTION z_qm_prueflos_anlegen.
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

  TYPES: BEGIN OF s_probes,
           plnnr TYPE plnnr,
           plnal TYPE plnal,
           phynr TYPE qphysprnr,
           prbnr TYPE zzqmprbnr,
         END OF s_probes.

  CONSTANTS: lc_mem_id TYPE char40 VALUE 'GT_PROBES_0503'.

  DATA: lt_probes        TYPE zqmprobes_t,
        ls_probes        TYPE zqmprobes,
        lt_probestab     TYPE zqmprobes_t,
        lt_probessort    TYPE TABLE OF s_probes,
        ls_probessort    TYPE s_probes,
        ls_probessort_prev TYPE s_probes,
        ls_probessort_next TYPE s_probes,
        lv_prbnr         TYPE zzqmprbnr,
        ls_wqmma         TYPE wqmma,
        lv_prueflos      TYPE qplos,
        lv_next          TYPE i,
        lt_status        TYPE TABLE OF bapi2045ss,
        ls_status        TYPE bapi2045ss.

  "get probes table from include ZXQQMI04
  IMPORT gt_probes_0503 TO lt_probes FROM MEMORY ID lc_mem_id.
  FREE MEMORY ID lc_mem_id.

  "if none is marked, all are selected
  READ TABLE lt_probes INTO ls_probes WITH KEY mark = 'X'.
  IF sy-subrc <> 0.
    LOOP AT lt_probes INTO ls_probes.
      IF zqm_cl_util=>get_probe_lock_status( iv_status = ls_probes-status
                                             iv_phynr  = ls_probes-phynr ) <> 'X'.
        ls_probes-mark = 'X'.
        MODIFY lt_probes FROM ls_probes.
      ENDIF.
    ENDLOOP.
  ENDIF.

  "all selected probes need a inspection plan
  READ TABLE lt_probes WITH KEY mark = 'X' plnnr = space TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 0.
    MESSAGE e030(zqm).
  ENDIF.

  "all selected probes need a physical sample
  READ TABLE lt_probes WITH KEY mark = 'X' phynr = space TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 0.
    MESSAGE e041(zqm).
  ENDIF.

  "check if probes already have an inspection lot; if status EQ 'LSTO' create a new one, otherwhise throw an error
  LOOP AT lt_probes INTO ls_probes WHERE prueflos IS NOT INITIAL and mark = 'X'.
    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number        = ls_probes-prueflos
      TABLES
        system_status = lt_status.

    READ TABLE lt_status WITH KEY sy_st_text = 'LSTO' TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      MESSAGE e042(zqm) WITH ls_probes-phynr.
    ENDIF.
  ENDLOOP.

  "write lt_probes to lt_probessort to make them sortable
  LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
    MOVE-CORRESPONDING ls_probes TO ls_probessort.
    APPEND ls_probessort TO lt_probessort.
  ENDLOOP.

  SORT lt_probessort BY plnnr ASCENDING plnal ASCENDING phynr ASCENDING.

  "aggregate probes per inspection plan for new inspection lot
  LOOP AT lt_probessort INTO ls_probessort.
    lv_next = sy-tabix + 1.

    READ TABLE lt_probes INTO ls_probes WITH KEY prbnr = ls_probessort-prbnr.
    IF sy-subrc EQ 0.
      APPEND ls_probes TO lt_probestab.
    ENDIF.

    "read next entry; if it does not exist or the plnnr is different create a new inspection lot
    READ TABLE lt_probessort INTO ls_probessort_next INDEX lv_next.
    IF sy-subrc <> 0 OR
       ls_probessort-plnnr <> ls_probessort_next-plnnr OR
       ls_probessort-plnal <> ls_probessort_next-plnal.

      PERFORM create_prueflos USING i_viqmel      "create inspection lot
                              CHANGING lt_probestab
                                       lv_prueflos.
      IF lv_prueflos IS NOT INITIAL.
        LOOP AT lt_probestab INTO ls_probes.
          ls_probes-prueflos = lv_prueflos.
          MODIFY lt_probes FROM ls_probes INDEX ls_probes-prbnr.
        ENDLOOP.

        IF e_qnqmama0-matxt IS INITIAL.
          e_qnqmama0-matxt = lv_prueflos.
        ELSE.
          CONCATENATE e_qnqmama0-matxt '/' lv_prueflos INTO e_qnqmama0-matxt.
        ENDIF.
      ENDIF.
      CLEAR: lt_probestab.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'QPL1_INSPECTION_LOTS_POSTING'.
  COMMIT WORK AND WAIT.

  "export
  EXPORT lt_probes TO MEMORY ID lc_mem_id.

  MESSAGE s025(zqm) WITH e_qnqmama0-matxt.
ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  create_prueflos
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_prueflos USING s_viqmel   TYPE viqmel
                     CHANGING
                           t_probes   TYPE zqmprobes_t
                           p_prueflos TYPE qplos.

  DATA: lt_return        TYPE bapiret2_t,
        ls_return        TYPE bapiret2,
        ls_rmqed         TYPE rmqed,
        ls_qals          TYPE qals,
        ls_qals_out      TYPE qals,
        ls_plko          TYPE plko,
        lv_subrc         TYPE sy-subrc,
        ls_probes        TYPE zqmprobes,
        ls_qprs          TYPE qprs,
        ls_zqm_lms_mdm   TYPE zqm_lms_mdm,
        ls_qmat          TYPE qmat.

  READ TABLE t_probes INTO ls_probes INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  SELECT SINGLE * FROM zqm_lms_mdm into ls_zqm_lms_mdm WHERE WERKS = s_viqmel-mawerk AND ART = 'ZLAG-00'.

  IF sy-subrc <> 0.
    MESSAGE e029(zqm).
    RETURN.
  ELSE.
    CALL FUNCTION 'QMAT_READ'
      EXPORTING
        i_art          = ls_zqm_lms_mdm-art
        i_matnr        = ls_zqm_lms_mdm-matnr
        i_werks        = ls_zqm_lms_mdm-werks
      IMPORTING
        E_QMAT         = ls_QMAT
      EXCEPTIONS
        NO_ENTRY       = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE e029(zqm).
      RETURN.
    ENDIF.
  ENDIF.

  ls_qals-werk       = s_viqmel-mawerk.
  ls_qals-ktextlos   = s_viqmel-qmtxt.
  ls_qals-matnr      = ls_QMAT-matnr.
  ls_qals-art        = ls_QMAT-ART.
  ls_qals-herkunft   = ls_zqm_lms_mdm-herkunft.
  ls_qals-losmenge   = 1.
  ls_qals-mengeneinh = 'KG'.
  ls_qals-stat13     = '3'.
  ls_qals-stat07     = 'X'.
  ls_qals-aufnr_co = ls_QMAT-aufnr_co.

  SELECT SINGLE * FROM plko INTO ls_plko WHERE plnnr EQ ls_probes-plnnr
                                           AND plnal EQ ls_probes-plnal.

  ls_qals-plnty      = ls_plko-plnty.
  ls_qals-plnnr      = ls_plko-plnnr.
  ls_qals-plnal      = ls_plko-plnal.
  ls_qals-pplverw    = ls_plko-verwe.
  ls_qals-zaehl      = ls_plko-zaehl.
  ls_qals-slwbez     = ls_plko-slwbez.

  ls_qals-gueltigab  = sy-datum.

  ls_rmqed-dbs_steuer  = '01'.
  ls_rmqed-dbs_flag    = 'X'.
  ls_rmqed-dbs_edunk   = 'X'.
  ls_rmqed-dbs_fdunk   = 'X'.
  ls_rmqed-dbs_noerr   = 'X'.
  ls_rmqed-dbs_nowrn   = 'X'.
  ls_rmqed-dbs_noauf   = 'X'.
  ls_rmqed-dbs_planzuo = 'X'.
  ls_rmqed-dbs_subrc   = 'X'.
*break: extjaw.
  CALL FUNCTION 'QPL1_INSPECTION_LOT_CREATE'
    EXPORTING
      qals_imp   = ls_qals
      rmqed_imp  = ls_rmqed
    IMPORTING
      e_prueflos = p_prueflos
      e_qals     = ls_qals_out
      subrc      = lv_subrc.
  IF lv_subrc <> 0.
    MESSAGE e029(zqm).
    ROLLBACK WORK.
    RAISE action_stopped.
  ELSE.
    CALL FUNCTION 'QPL1_UPDATE_MEMORY'
      EXPORTING
        i_qals  = ls_qals_out
        i_updkz = 'I'
        i_rmqed = ls_rmqed.

    LOOP AT t_probes INTO ls_probes.
      SELECT SINGLE * FROM qprs INTO ls_qprs WHERE phynr EQ ls_probes-phynr.
      CALL FUNCTION 'QPRS_QPRS_LOT_UPDATE'
        EXPORTING
          i_qprs           = ls_qprs
          i_prueflos       = p_prueflos
        EXCEPTIONS
          locking_error    = 1
          sample_not_found = 2
          OTHERS           = 3.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "create_prueflos
