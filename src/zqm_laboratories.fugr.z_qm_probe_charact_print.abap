FUNCTION z_qm_probe_charact_print.
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
        lt_label    TYPE zqmprobe_char_interface_t,
        ls_label    TYPE zqmprobe_char_interface_s,

        lv_fm_name         TYPE funcname,
        lv_interface_type  TYPE fpinterfacetype,
        ls_fp_outputparams TYPE sfpoutputparams,
        ls_fp_docparams    TYPE sfpdocparams,
        ls_fp_result       TYPE fpformoutput,
        ls_result          TYPE sfpjoboutput.

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

  CALL FUNCTION 'MESSAGES_INITIALIZE'.

  LOOP AT lt_probes INTO ls_probes WHERE mark EQ 'X'.
    CLEAR: ls_label.

    IF ls_probes-prueflos IS INITIAL.
      CALL FUNCTION 'MESSAGE_STORE'
        EXPORTING
          arbgb                   = 'ZQM_LABORATORIES'
          exception_if_not_active = ' '
          msgty                   = 'E'
          msgv1                   = ls_probes-phynr
          txtnr                   = 005
          zeile                   = ls_probes-prbnr
        EXCEPTIONS
          message_type_not_valid  = 1
          not_active              = 2
          OTHERS                  = 3.
    ELSE.
      ls_label-phynr = ls_probes-phynr.
      SELECT * FROM qamv INTO TABLE ls_label-t_qamv WHERE prueflos EQ ls_probes-prueflos.
      APPEND ls_label TO lt_label.
    ENDIF.
  ENDLOOP.

* start printing
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name               = 'ZQMPROBE_CHAR_FORM'
    IMPORTING
      e_funcname           = lv_fm_name
      e_interface_type     = lv_interface_type "ABAP Dictionary based interface
    EXCEPTIONS
      cx_fp_api_repository = 1
      cx_fp_api_usage      = 2
      cx_fp_api_internal   = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = ls_fp_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ls_fp_docparams-langu    = sy-langu.
  ls_fp_docparams-fillable = space.

  LOOP AT lt_label INTO ls_label.
    READ TABLE lt_probes INTO ls_probes WITH KEY phynr = ls_label-phynr.

    CALL FUNCTION lv_fm_name
      EXPORTING
        /1bcdwb/docparams  = ls_fp_docparams
        interface          = ls_label
      IMPORTING
        /1bcdwb/formoutput = ls_fp_result
      EXCEPTIONS
        usage_error        = 1
        system_error       = 2
        internal_error     = 3
        OTHERS             = 4.
    IF sy-subrc <> 0.
      CALL FUNCTION 'MESSAGE_STORE'
        EXPORTING
          arbgb                   = 'ZQM_LABORATORIES'
          exception_if_not_active = ' '
          msgty                   = 'E'
          msgv1                   = ls_label-phynr
          txtnr                   = 005
          zeile                   = ls_probes-prbnr
        EXCEPTIONS
          message_type_not_valid  = 1
          not_active              = 2
          OTHERS                  = 3.
    ELSE.
      CALL FUNCTION 'MESSAGE_STORE'
        EXPORTING
          arbgb                   = 'ZQM_LABORATORIES'
          exception_if_not_active = ' '
          msgty                   = 'S'
          msgv1                   = ls_label-phynr
          txtnr                   = 004
          zeile                   = ls_probes-prbnr
        EXCEPTIONS
          message_type_not_valid  = 1
          not_active              = 2
          OTHERS                  = 3.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'FP_JOB_CLOSE'
    IMPORTING
      e_result       = ls_result
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.

  CALL FUNCTION 'MESSAGES_STOP'
    EXCEPTIONS
      a_message = 04
      e_message = 03
      i_message = 02
      w_message = 01.

  IF NOT sy-subrc IS INITIAL.
    CALL FUNCTION 'MESSAGES_SHOW'
      EXPORTING
        i_use_grid         = 'X'
        i_amodal_window    = 'X'
      EXCEPTIONS
        inconsistent_range = 1
        no_messages        = 2
        OTHERS             = 3.
  ENDIF.
ENDFUNCTION.
