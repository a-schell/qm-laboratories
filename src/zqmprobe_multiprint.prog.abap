*&---------------------------------------------------------------------*
*& Report  ZQMPROBE_PRINT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 07.02.2017
*& DESCRIPTION: print program for transaction QPR2
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqmprobe_multiprint.

* Dictionary
TABLES: qprs,                                               "#EC NEEDED
        qprn,                                               "#EC NEEDED
        qals,
        mara,
        makt,
        print_co.

TYPE-POOLS: qprp1.

CONSTANTS:
      gc_id_iprt_struct(16)   VALUE 'ID_IPRT_STRUCT',
      gc_id_iprt_options(16)  VALUE 'ID_IPRT_OPTIONS',
      gc_text_id              TYPE tdid           VALUE 'LTQM',
      gc_text_object          TYPE tdobject       VALUE 'QMEL',
      gc_form_name            TYPE fpwbformname   VALUE 'ZQMPROBE_MULTI_FORM',
      gc_preview              TYPE char8          VALUE 'PREVIEW',
      gc_bor_type             TYPE sibftypeid     VALUE 'BUS2078',
      gc_workpaper_results    TYPE workpaper      VALUE '5901'.


DATA: gs_print_opt         TYPE print_co,
      gs_interface         TYPE zqmprobe_interface_s,
      gt_interface         TYPE TABLE OF zqmprobe_interface_s,
      gs_viqmel            TYPE viqmel,

      gs_workpaper TYPE wworkpaper,
      gv_device    TYPE char8.

*&---------------------------------------------------------------------*
*&      Form  entry_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM entry_pdf.
  CLEAR:  qprs,
          qprn,
          qals,
          mara,
          makt,
          gs_print_opt,
          gs_interface,
          gt_interface.

  PERFORM get_data.
  IF gs_workpaper-workpaper = '5921'.
    PERFORM send_email.
  ELSE.
    PERFORM print_pdf.
  ENDIF.
ENDFORM.                    "entry_pdf


*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data.
  DATA: ls_samples   TYPE qprp1_sample,
        lt_zqmprobes TYPE TABLE OF zqmprobes,
        ls_zqmprobes TYPE zqmprobes,
        ls_qprs      TYPE qprs.

  "fetch memory data
  PERFORM import_data.

  SELECT * FROM zqmprobes INTO TABLE lt_zqmprobes WHERE qmnum  EQ gs_viqmel-qmnum
                                                    AND phynr  NE space
                                                    AND status NE '@11@'.

  "print one label for every probe
  LOOP AT lt_zqmprobes INTO ls_zqmprobes.
    CLEAR: gs_interface, ls_qprs.

    "get prbty
    SELECT SINGLE zzqmprbty FROM qmel INTO gs_interface-zzqmprbty WHERE qmnum EQ ls_zqmprobes-qmnum.

    "get qprs
    SELECT SINGLE * FROM qprs INTO ls_qprs WHERE phynr EQ ls_zqmprobes-phynr.


    gs_interface-phynr     = ls_zqmprobes-phynr.
    MOVE-CORRESPONDING ls_qprs TO gs_interface.
*    gs_interface-ktext     = ls_qprs-ktext.
*    gs_interface-entort    = ls_qprs-entort.
*    gs_interface-entdatum  = ls_qprs-entdatum.
*    gs_interface-entzeit   = ls_qprs-entzeit.
    APPEND gs_interface TO gt_interface.
  ENDLOOP.
ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  PRINT_PDF
*&---------------------------------------------------------------------*
FORM print_pdf.
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

  "map workpaper options with ls_fp_outputparams
  ls_fp_outputparams-dest     = gs_workpaper-tddest.
  ls_fp_outputparams-copies   = gs_workpaper-tdcopies.
  ls_fp_outputparams-reqnew   = gs_workpaper-tdnewid.
  ls_fp_outputparams-reqimm   = gs_workpaper-tdimmed.
  ls_fp_outputparams-reqdel   = gs_workpaper-tddelete.
  ls_fp_outputparams-covtitle = gs_workpaper-tdcovtitle.
  ls_fp_outputparams-receiver = gs_workpaper-tdreceiver.
  ls_fp_outputparams-cover    = gs_workpaper-tdcover.
  ls_fp_outputparams-arcmode  = gs_workpaper-tdarmod.
  ls_fp_outputparams-getpdf   = gs_workpaper-pdf_data.

  IF gv_device EQ gc_preview.
    ls_fp_outputparams-preview = 'X'.
  ENDIF.

  ls_fp_outputparams-nodialog = 'X'.

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

  ls_fp_docparams-langu    = gs_workpaper-print_lang.
  ls_fp_docparams-fillable = space.

  CALL FUNCTION lv_fm_name
    EXPORTING
      /1bcdwb/docparams  = ls_fp_docparams
      t_interface        = gt_interface
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
ENDFORM.                    " PRINT_PDF
*&---------------------------------------------------------------------*
*&      Form  IMPORT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM import_data .
  "get viqmel
  IMPORT iviqmel TO gs_viqmel FROM MEMORY ID gc_id_iprt_struct.
  IF sy-subrc <> 0.
    MESSAGE a650(id). "import failed
  ENDIF.

  "get options
  IMPORT wworkpaper TO gs_workpaper FROM MEMORY ID gc_id_iprt_options.
  IMPORT device     TO gv_device    FROM MEMORY ID gc_id_iprt_options.
ENDFORM.                    " IMPORT_DATA
*&---------------------------------------------------------------------*
*&      Form  SEND_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM send_email .
  DATA: ls_fp_result       TYPE fpformoutput.
*  break: extjaw.
  PERFORM send_pdf.
ENDFORM.                    " SEND_EMAIL
*&---------------------------------------------------------------------*
*&      Form  SEND_PDF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM send_pdf .
  DATA: lv_fm_name         TYPE funcname,
        lv_interface_type  TYPE fpinterfacetype,
        ls_fp_outputparams TYPE sfpoutputparams,
        ls_fp_docparams    TYPE sfpdocparams,
        ls_fp_result       TYPE fpformoutput,
        lv_subject         TYPE so_obj_des,
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

  "map workpaper options with ls_fp_outputparams
  ls_fp_outputparams-dest     = gs_workpaper-tddest.
  ls_fp_outputparams-copies   = gs_workpaper-tdcopies.
  ls_fp_outputparams-reqnew   = gs_workpaper-tdnewid.
  ls_fp_outputparams-reqimm   = gs_workpaper-tdimmed.
  ls_fp_outputparams-reqdel   = gs_workpaper-tddelete.
  ls_fp_outputparams-covtitle = gs_workpaper-tdcovtitle.
  ls_fp_outputparams-receiver = gs_workpaper-tdreceiver.
  ls_fp_outputparams-cover    = gs_workpaper-tdcover.
  ls_fp_outputparams-arcmode  = gs_workpaper-tdarmod.
  ls_fp_outputparams-getpdf   = 'X'.

  ls_fp_outputparams-nodialog = 'X'.

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

  ls_fp_docparams-langu    = gs_workpaper-print_lang.
  ls_fp_docparams-fillable = space.

  CALL FUNCTION lv_fm_name
    EXPORTING
      /1bcdwb/docparams  = ls_fp_docparams
      t_interface        = gt_interface
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

  DATA: lt_message        TYPE swftlisti1,
        lt_mail_addresses TYPE somlreci1_t,
         ls_mail_addresses TYPE somlreci1,
        lv_returncode     TYPE sy-subrc.
*  break: extjaw.
  SELECT SINGLE usrid_long FROM pa0105 INTO
  ls_mail_addresses-receiver
    WHERE pernr = gs_viqmel-buname
    AND subty = '0010'.

  ls_mail_addresses-blind_copy = 'X'.
  APPEND ls_mail_addresses TO lt_mail_addresses.

  lv_subject = gs_workpaper-tdcovtitle.

  CALL FUNCTION 'Z_QM_SEND_PAPER_MAIL'
    EXPORTING
      it_mail_addresses = lt_mail_addresses
      it_message        = lt_message
      iv_subject        = lv_subject
      is_formoutput     = ls_fp_result
      iv_filename       = lv_subject
    IMPORTING
      ev_returncode     = lv_returncode.
ENDFORM.                    " SEND_PDF
