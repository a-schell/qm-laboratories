*&---------------------------------------------------------------------*
*& Report  ZQMPROBE_PRINT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 07.02.2017
*& DESCRIPTION: print program for transaction QPR2
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqmprobe_print.

* Dictionary
TABLES: qprs,                                               "#EC NEEDED
        qprn,                                               "#EC NEEDED
        qals,
        mara,
        makt.

TYPE-POOLS: qprp1.

DATA: gs_print_opt         TYPE print_co,
      gt_samples_tab       TYPE qprp1_sample_tab,
      gs_interface         TYPE zqmprobe_interface_s,
      gt_interface         TYPE TABLE OF zqmprobe_interface_s.

CONSTANTS:
      gc_form_name TYPE fpwbformname   VALUE 'ZQMPROBE_FORM'.

CLEAR:  qprs,
        qprn,
        qals,
        mara,
        makt,
        gs_print_opt,
        gt_samples_tab[],
        gs_interface,
        gt_interface.

PERFORM get_data.
PERFORM print_pdf.

*&---------------------------------------------------------------------*
*&      Form  IMPORT_DATA
*&---------------------------------------------------------------------*
FORM import_data .
  IMPORT g_qmem_print_order TO gs_print_opt
         g_qmem_samples_tab TO gt_samples_tab
         FROM MEMORY ID 'QM_SAMPLE_PRINT01'.
ENDFORM.                    " IMPORT_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data .
  DATA: ls_samples   TYPE qprp1_sample,
        ls_zqmprobes TYPE zqmprobes.

  "fetch data from memory
  PERFORM import_data.

  "print one label for every probe
  LOOP AT gt_samples_tab INTO ls_samples.
    CLEAR: gs_interface.

    "get prbty
    SELECT SINGLE * FROM zqmprobes INTO ls_zqmprobes WHERE phynr EQ ls_samples-phynr.
    IF sy-subrc EQ 0.
      SELECT SINGLE zzqmprbty FROM qmel INTO gs_interface-zzqmprbty WHERE qmnum EQ ls_zqmprobes-qmnum.
    ENDIF.

    gs_interface-phynr     = ls_samples-phynr.
    MOVE-CORRESPONDING ls_samples-qprs TO gs_interface.
*    gs_interface-ktext     = ls_samples-qprs-ktext.
*    gs_interface-entort    = ls_samples-qprs-entort.
*    gs_interface-entdatum  = ls_samples-qprs-entdatum.
*    gs_interface-entzeit   = ls_samples-qprs-entzeit.
    APPEND gs_interface TO gt_interface.
  ENDLOOP.
ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  PRINT_PDF
*&---------------------------------------------------------------------*
FORM print_pdf .
  DATA: lv_fm_name         TYPE funcname,
        lv_interface_type  TYPE fpinterfacetype,
        ls_fp_outputparams TYPE sfpoutputparams,
        ls_fp_docparams    TYPE sfpdocparams,
        ls_fp_result       TYPE fpformoutput,
        ls_result          TYPE sfpjoboutput.

  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name               = gc_form_name
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

  "map print options with ls_fp_outputparams
  ls_fp_outputparams-dest     = gs_print_opt-desti.
  ls_fp_outputparams-copies   = gs_print_opt-copys.
  ls_fp_outputparams-reqnew   = gs_print_opt-nlist.
  ls_fp_outputparams-reqimm   = gs_print_opt-primm.
  ls_fp_outputparams-reqdel   = gs_print_opt-pkeep.
  ls_fp_outputparams-covtitle = gs_print_opt-lname.

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

  ls_fp_outputparams-nodialog = 'X'.
  ls_fp_outputparams-preview  = 'X'.

  ls_fp_docparams-langu    = gs_print_opt-spras.
  ls_fp_docparams-fillable = space.

  "one label per entry
  LOOP AT gt_interface INTO gs_interface.
    CALL FUNCTION lv_fm_name
      EXPORTING
        /1bcdwb/docparams  = ls_fp_docparams
        interface          = gs_interface
      IMPORTING
        /1bcdwb/formoutput = ls_fp_result
      EXCEPTIONS
        usage_error        = 1
        system_error       = 2
        internal_error     = 3
        OTHERS             = 4.
  ENDLOOP.

  CALL FUNCTION 'FP_JOB_CLOSE'
    IMPORTING
      e_result       = ls_result
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
ENDFORM.                    " PRINT_PDF
