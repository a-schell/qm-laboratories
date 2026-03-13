FUNCTION z_qm_probe_print.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_QPRS) LIKE  QPRS STRUCTURE  QPRS
*"     VALUE(I_QPRN) LIKE  QPRN STRUCTURE  QPRN OPTIONAL
*"     VALUE(I_QALS) LIKE  QALS STRUCTURE  QALS OPTIONAL
*"     VALUE(I_PRINT_ORIGINAL) LIKE  QM00-QKZ OPTIONAL
*"     VALUE(I_FIRST_SAMPLE) LIKE  QM00-QKZ OPTIONAL
*"     VALUE(I_LAST_SAMPLE) LIKE  QM00-QKZ OPTIONAL
*"  EXPORTING
*"     VALUE(E_PRINT_OK) LIKE  QM00-QKZ
*"----------------------------------------------------------------------
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 07.02.2017
*& DESCRIPTION: print program for transaction QPR2
*& CHANGE:
*&---------------------------------------------------------------------*

  DATA: ls_zqmprobes TYPE zqmprobes,
        ls_interface         TYPE zqmprobe_interface_s,

        lv_fm_name         TYPE funcname,
        lv_interface_type  TYPE fpinterfacetype,
        ls_fp_outputparams TYPE sfpoutputparams,
        ls_fp_docparams    TYPE sfpdocparams,
        ls_fp_result       TYPE fpformoutput,
        ls_result          TYPE sfpjoboutput.

* get data
  CLEAR: ls_interface.

  "get prbty
  SELECT SINGLE * FROM zqmprobes INTO ls_zqmprobes WHERE phynr EQ i_qprs-phynr.
  IF sy-subrc EQ 0.
    SELECT SINGLE zzqmprbty FROM qmel INTO ls_interface-zzqmprbty WHERE qmnum EQ ls_zqmprobes-qmnum.
  ENDIF.

  MOVE-CORRESPONDING i_qprs TO ls_interface.

* start printing
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name               = 'ZQMPROBE_FORM'
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

  CALL FUNCTION lv_fm_name
    EXPORTING
      /1bcdwb/docparams  = ls_fp_docparams
      interface          = ls_interface
    IMPORTING
      /1bcdwb/formoutput = ls_fp_result
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.

  CALL FUNCTION 'FP_JOB_CLOSE'
    IMPORTING
      e_result       = ls_result
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.

ENDFUNCTION.
