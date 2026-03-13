*&---------------------------------------------------------------------*
*& Report  ZQMNOTIF_PRINT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 24.11.2016
*& DESCRIPTION: print program for transaction QM01
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqmnotif_print.

TABLES: print_co.

DATA: gs_interface TYPE zqmnotif_interface_s,
      gs_workpaper TYPE wworkpaper,
      gv_device    TYPE char8.

CONSTANTS:
      gc_id_iprt_struct(16)   VALUE 'ID_IPRT_STRUCT',
      gc_id_iprt_options(16)  VALUE 'ID_IPRT_OPTIONS',
      gc_text_id              TYPE tdid           VALUE 'LTQM',
      gc_text_object          TYPE tdobject       VALUE 'QMEL',
      gc_form_name            TYPE fpwbformname   VALUE 'ZQMNOTIF_FORM',
      gc_preview              TYPE char8          VALUE 'PREVIEW',
      gc_bor_type             TYPE sibftypeid     VALUE 'BUS2078',
      gc_workpaper_results    TYPE workpaper      VALUE '5901',
      gc_workpaper_results_mail    TYPE workpaper      VALUE '5911'.

*&---------------------------------------------------------------------*
*&      Form  entry_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM entry_pdf.
*  break: extjaw.

  PERFORM initialize_data.
  PERFORM get_data.
  IF gs_workpaper-workpaper = '5910' OR gs_workpaper-workpaper = '5911' OR gs_workpaper-workpaper = '5913'.
    PERFORM send_email.
  ELSE.
    PERFORM print_pdf.
  ENDIF.
ENDFORM.                    "entry_pdf

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data.
  DATA: lv_text_name TYPE tdobname,
        ls_probes    TYPE zqmprobes,
        ls_insp_lot  TYPE zqmnotif_insp_lot_head_s.

  "get viqmel
  IMPORT iviqmel TO gs_interface-viqmel FROM MEMORY ID gc_id_iprt_struct.
  IF sy-subrc <> 0.
    MESSAGE a650(id). "import failed
  ENDIF.

  "get options
  IMPORT wworkpaper TO gs_workpaper FROM MEMORY ID gc_id_iprt_options.
  IMPORT device     TO gv_device    FROM MEMORY ID gc_id_iprt_options.

  "get additional header data
  PERFORM get_additional_header_data.

  "get probes table and update text name
  SELECT * FROM zqmprobes INTO TABLE gs_interface-t_probes WHERE qmnum EQ gs_interface-viqmel-qmnum.
  IF sy-subrc EQ 0.
    LOOP AT gs_interface-t_probes INTO ls_probes.
      CONCATENATE ls_probes-qmnum ls_probes-prbnr INTO ls_probes-tdname.
      MODIFY gs_interface-t_probes FROM ls_probes.
    ENDLOOP.
  ENDIF.

  "get inspection results
  IF gs_workpaper-workpaper EQ gc_workpaper_results OR gs_workpaper-workpaper EQ gc_workpaper_results_mail.
    LOOP AT gs_interface-t_probes INTO ls_probes WHERE status <> '@11@'.
      CLEAR: ls_insp_lot.
      PERFORM get_inspection_results_as_tab USING    ls_probes
                                            CHANGING ls_insp_lot.
      APPEND ls_insp_lot TO gs_interface-t_insp_result_tab.
    ENDLOOP.

    DELETE ADJACENT DUPLICATES FROM gs_interface-t_insp_result_tab COMPARING prueflos.
  ENDIF.

  "get hyperlinks from GOS
  PERFORM get_hyperlinks.

  "get long text
  WRITE gs_interface-viqmel-qmnum TO lv_text_name.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = gc_text_id
      language                = gs_workpaper-print_lang
      name                    = lv_text_name
      object                  = gc_text_object
    TABLES
      lines                   = gs_interface-t_text
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
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
      interface          = gs_interface
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
*&      Form  GET_ADDITIONAL_HEADER_DATA
*&---------------------------------------------------------------------*
FORM get_additional_header_data.
  DATA: ls_crhd TYPE crhd.

  "get contact name
  SELECT SINGLE ename FROM pa0001 INTO (gs_interface-s_header_helper-buname_txt) WHERE pernr EQ gs_interface-viqmel-buname.

  "get psp text
  SELECT SINGLE post1 FROM prps INTO (gs_interface-s_header_helper-zzpspel_txt) WHERE pspnr EQ gs_interface-viqmel-zzpspel.

  "get kostl text
  SELECT SINGLE ktext FROM cskt INTO (gs_interface-s_header_helper-zzqmkostl_txt) WHERE kostl EQ gs_interface-viqmel-zzqmkostl.

  "get aufnr text
  SELECT SINGLE ktext FROM aufk INTO (gs_interface-s_header_helper-aufnr_txt) WHERE aufnr EQ gs_interface-viqmel-zzaufnr.

  "get arbpl text
  SELECT SINGLE * FROM crhd INTO ls_crhd WHERE arbpl EQ gs_interface-viqmel-zzarbpl.
  IF sy-subrc EQ 0.
    SELECT SINGLE ktext FROM crtx INTO (gs_interface-s_header_helper-zzarbpl_txt) WHERE objty EQ ls_crhd-objty
                                                                                    AND objid EQ ls_crhd-objid
                                                                                    AND spras EQ gs_workpaper-print_lang.
  ENDIF.

  "get print language
  gs_interface-s_header_helper-langu = gs_workpaper-print_lang.

  "[20170407] get headline
  CASE gs_workpaper-workpaper.
    WHEN '5910'.
      gs_interface-s_header_helper-headline = text-001.
    WHEN '5911'.
      gs_interface-s_header_helper-headline = text-002.
    WHEN '5913'.
      gs_interface-s_header_helper-headline = text-003.
    WHEN OTHERS.
      gs_interface-s_header_helper-headline = text-004.
  ENDCASE.

  "get status
  CALL FUNCTION 'STATUS_TEXT_EDIT'
    EXPORTING
      objnr            = gs_interface-viqmel-objnr
      spras            = gs_interface-s_header_helper-langu
    IMPORTING
      line             = gs_interface-s_header_helper-status
    EXCEPTIONS
      object_not_found = 1
      OTHERS           = 2.
  IF sy-subrc EQ 0.
    gs_interface-s_header_helper-status = gs_interface-s_header_helper-status(4). "only first status

    "get status text
    SELECT SINGLE txt30 FROM tj02t INTO (gs_interface-s_header_helper-status_text) WHERE spras EQ gs_interface-s_header_helper-langu
                                                                                     AND txt04 EQ gs_interface-s_header_helper-status.
  ENDIF.
  CASE gs_interface-viqmel-phase.
    WHEN '1'.
      gs_interface-s_header_helper-status = 'MOFN'.
      gs_interface-s_header_helper-status_text = 'Meldung offen'.
    WHEN '2'.
      gs_interface-s_header_helper-status = 'MRST'.
      gs_interface-s_header_helper-status_text = 'Meldung zurückgestellt'.
    WHEN '3'.
      gs_interface-s_header_helper-status = 'MIAR'.
      gs_interface-s_header_helper-status_text = 'Meldung in Arbeit'.
    WHEN '4'.
      gs_interface-s_header_helper-status = 'MMAB'.
      gs_interface-s_header_helper-status_text = 'Meldung abgeschlossen'.
    WHEN '5'.
      gs_interface-s_header_helper-status = 'LOVM'.
      gs_interface-s_header_helper-status_text = 'Gelöscht'.
  ENDCASE.

  "get qm type text
  SELECT SINGLE qmartx FROM tq80_t INTO (gs_interface-s_header_helper-qmartx) WHERE qmart EQ gs_interface-viqmel-qmart
                                                                                AND spras EQ gs_interface-s_header_helper-langu.

  "get plant description
  SELECT SINGLE name1 FROM t001w INTO (gs_interface-s_header_helper-plant_descr) WHERE werks EQ gs_interface-viqmel-mawerk.
ENDFORM.                    " GET_ADDITIONAL_HEADER_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_INSPECTION_RESULTS
*&---------------------------------------------------------------------*
FORM get_inspection_results  USING    s_probes TYPE zqmprobes
                             CHANGING s_lot    TYPE zqmnotif_insp_lot_s.
  DATA: ls_qals       TYPE qals,
        ls_act        TYPE zqmnotif_activities_s,
        lt_operations TYPE TABLE OF bapi2045l2,
        ls_operations TYPE bapi2045l2,
        ls_point      TYPE zqmnotif_insp_point_s,
        ls_char       TYPE zqmnotif_insp_char_s,
        lt_char_req   TYPE TABLE OF bapi2045d1,
        ls_char_req   TYPE bapi2045d1.

  "get inspection lot
  SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos EQ s_probes-prueflos.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING ls_qals TO s_lot.

  "get operations (Vorgänge)
  CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
    EXPORTING
      number        = s_probes-prueflos
    TABLES
      inspoper_list = lt_operations.

  LOOP AT lt_operations INTO ls_operations.
    CLEAR: ls_act.
    ls_act-vornr = ls_operations-inspoper.
    SELECT SINGLE plnkn FROM plpo INTO (ls_act-plnkn) WHERE plnty EQ ls_qals-plnty
                                                        AND plnnr EQ ls_qals-plnnr
                                                        AND zaehl EQ ls_qals-zaehl
                                                        AND vornr EQ ls_act-vornr.
    ls_act-ltxa1 = ls_operations-txt_oper.
    APPEND ls_act TO s_lot-t_insp_act.
  ENDLOOP.


  "get inspection points (Prüfpunkte)
  LOOP AT s_lot-t_insp_act INTO ls_act.
    SELECT * FROM qapp INTO CORRESPONDING FIELDS OF TABLE ls_act-t_insp_point WHERE prueflos EQ ls_qals-prueflos
                                                                                AND vorglfnr EQ ls_act-plnkn.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    LOOP AT ls_act-t_insp_point INTO ls_point.
      SELECT * FROM qasr INTO CORRESPONDING FIELDS OF TABLE ls_point-t_insp_char WHERE prueflos EQ ls_qals-prueflos
                                                                                   AND vorglfnr EQ ls_act-plnkn
                                                                                   AND probenr  EQ ls_point-probenr.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "get short text for all characteristics
      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                = ls_qals-prueflos
          inspoper               = ls_act-vornr
          read_char_requirements = 'X'
        TABLES
          char_requirements      = lt_char_req.

      LOOP AT ls_point-t_insp_char INTO ls_char.
        READ TABLE lt_char_req INTO ls_char_req WITH KEY inspchar = ls_char-merknr.
        IF sy-subrc EQ 0.

          SELECT SINGLE kurztext FROM qpmt INTO (ls_char-kurztext) WHERE mkmnr   EQ ls_char_req-mstr_char
                                                                     AND sprache EQ sy-langu.
          MODIFY ls_point-t_insp_char FROM ls_char.
        ENDIF.
      ENDLOOP.

      MODIFY ls_act-t_insp_point FROM ls_point.
    ENDLOOP.

    MODIFY s_lot-t_insp_act FROM ls_act.
  ENDLOOP.
ENDFORM.                    " GET_INSPECTION_RESULTS

*&---------------------------------------------------------------------*
*&      Form  GET_INSPECTION_RESULTS_AS_TAB
*&---------------------------------------------------------------------*
FORM get_inspection_results_as_tab  USING    s_probes TYPE zqmprobes
                                    CHANGING s_head   TYPE zqmnotif_insp_lot_head_s.
  DATA: ls_qals       TYPE qals,
        lt_operations TYPE TABLE OF bapi2045l2,
        ls_operations TYPE bapi2045l2,
        lt_qapp       TYPE TABLE OF qapp,
        ls_qapp       TYPE qapp,
        lt_qasr       TYPE TABLE OF qasr,
        ls_qasr       TYPE qasr,
        lt_char_req   TYPE TABLE OF bapi2045d1,
        ls_char_req   TYPE bapi2045d1,
        lt_pos        TYPE zqmnotif_insp_lot_pos_t,
        ls_pos        TYPE zqmnotif_insp_lot_pos_s,
        lv_plnkn      TYPE plnkn.

  "get inspection lot
  SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos EQ s_probes-prueflos.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  s_head-prueflos = s_probes-prueflos.
  s_head-plnnr    = s_probes-plnnr.
  s_head-plnal    = s_probes-plnal.

  "get operations (Vorgänge)
  CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
    EXPORTING
      number        = s_head-prueflos
    TABLES
      inspoper_list = lt_operations.

  LOOP AT lt_operations INTO ls_operations.
    CLEAR: ls_pos, lv_plnkn.

    ls_pos-vornr = ls_operations-inspoper.
    ls_pos-ltxa1 = ls_operations-txt_oper.

    "get plnkn
    SELECT SINGLE plnkn FROM plpo INTO (lv_plnkn) WHERE plnty EQ ls_qals-plnty
                                                    AND plnnr EQ ls_qals-plnnr
                                                    AND zaehl EQ ls_qals-zaehl
                                                    AND vornr EQ ls_pos-vornr.

    "get inspection points
    SELECT * FROM qapp INTO CORRESPONDING FIELDS OF TABLE lt_qapp WHERE prueflos EQ s_head-prueflos
                                                                    AND vorglfnr EQ lv_plnkn.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    LOOP AT lt_qapp INTO ls_qapp.
      ls_pos-probenr    = ls_qapp-probenr.

      SELECT * FROM qasr INTO CORRESPONDING FIELDS OF TABLE lt_qasr WHERE prueflos EQ s_head-prueflos
                                                                      AND vorglfnr EQ lv_plnkn
                                                                      AND probenr  EQ ls_pos-probenr.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "get short text for all characteristics
      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                = s_head-prueflos
          inspoper               = ls_pos-vornr
          read_char_requirements = 'X'
        TABLES
          char_requirements      = lt_char_req.

      LOOP AT lt_qasr INTO ls_qasr.
        ls_pos-merknr         = ls_qasr-merknr.
        ls_pos-original_input = ls_qasr-original_input.
        ls_pos-pruefbemkt     = ls_qasr-pruefbemkt.

        READ TABLE lt_char_req INTO ls_char_req WITH KEY inspchar = ls_qasr-merknr.
        IF sy-subrc EQ 0.
          SELECT SINGLE kurztext FROM qpmt INTO (ls_pos-kurztext) WHERE mkmnr   EQ ls_char_req-mstr_char
                                                                    AND sprache EQ sy-langu.
        ENDIF.

        APPEND ls_pos TO s_head-t_pos.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " GET_INSPECTION_RESULTS_AS_TAB

*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_DATA
*&---------------------------------------------------------------------*
FORM initialize_data .
  CLEAR: gs_interface, gs_workpaper, gv_device.
ENDFORM.                    " INITIALIZE_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_HYPERLINKS
*&---------------------------------------------------------------------*
FORM get_hyperlinks.
  DATA: ls_object   TYPE sibflporb,
        lt_relopt   TYPE obl_t_relt,
        ls_relopt   TYPE obl_s_relt,
        lt_links    TYPE obl_t_link,
        ls_links    TYPE obl_s_link,
        lv_doc_id   TYPE so_entryid,
        ls_doc_data TYPE sofolenti1,
        lt_cont     TYPE soli_tab,
        ls_cont     TYPE soli,
        ls_new_link TYPE zqmnotif_links_s.

  "define object
  ls_object-instid = gs_interface-viqmel-qmnum.
  ls_object-typeid = gc_bor_type.
  ls_object-catid  = 'BO'.

  "define filter parameters
  ls_relopt-sign   = 'I'.
  ls_relopt-option = 'EQ'.
  ls_relopt-low    = 'URL'.
  APPEND ls_relopt TO lt_relopt.

  TRY.
      "get objects
      cl_binary_relation=>read_links_of_binrels(
           EXPORTING
             is_object           = ls_object
             it_relation_options = lt_relopt
             ip_role             = 'GOSAPPLOBJ'
           IMPORTING
             et_links            = lt_links ).

      LOOP AT lt_links INTO ls_links WHERE typeid_b = 'MESSAGE'.
        CLEAR: ls_new_link.

        lv_doc_id = ls_links-instid_b.

        CALL FUNCTION 'SO_DOCUMENT_READ_API1'
          EXPORTING
            document_id                = lv_doc_id
          IMPORTING
            document_data              = ls_doc_data
          TABLES
            object_content             = lt_cont
          EXCEPTIONS
            document_id_not_exist      = 1
            operation_no_authorization = 2
            x_error                    = 3
            OTHERS                     = 4.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        ls_new_link-obj_descr = ls_doc_data-obj_descr.
        READ TABLE lt_cont INTO ls_cont INDEX 1.
        ls_new_link-value = ls_cont-line+5.
        APPEND ls_new_link TO gs_interface-t_links.
      ENDLOOP.
    CATCH cx_obl_parameter_error cx_obl_internal_error cx_obl_model_error.
  ENDTRY.
ENDFORM.                    " GET_HYPERLINKS

DATA:

*  t_venbank  type table of ZVNDBK,
  l_fm_name         TYPE rs38l_fnam,
  l_formname        TYPE fpname VALUE 'ZPERSONNEL_FORM',
  fp_docparams      TYPE sfpdocparams,
  fp_formoutput     TYPE fpformoutput,
  fp_outputparams   TYPE sfpoutputparams.
DATA:
  t_att_content_hex TYPE solix_tab.

*&---------------------------------------------------------------------*
*&      Form  SEND_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM send_email.
  DATA: ls_fp_result       TYPE fpformoutput.
*  BREAK: EXTJAW.
  PERFORM send_pdf.
ENDFORM.                    "SEND_EMAIL
*&---------------------------------------------------------------------*
*&      Form  GET_FUNCTION_MODULE
*&---------------------------------------------------------------------
FORM get_function_module .
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = l_formname
    IMPORTING
      e_funcname = l_fm_name.
*   E_INTERFACE_TYPE           =
  fp_outputparams-nodialog = 'X'.
  fp_outputparams-getpdf   = 'X'.
  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = fp_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN OTHERS.
    ENDCASE.                           " CASE sy-subrc
  ENDIF.
  fp_docparams-langu = 'X'.
  fp_docparams-country = 'AT'.
  fp_docparams-fillable = 'X'.
  CALL FUNCTION l_fm_name
    EXPORTING
      /1bcdwb/docparams  = fp_docparams
*     emp_info           = fs_per_info
    IMPORTING
      /1bcdwb/formoutput = fp_formoutput
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN OTHERS.
    ENDCASE.                           " CASE sy-subrc
  ENDIF.                               " IF sy-subrc <> 0
  CALL FUNCTION 'FP_JOB_CLOSE'
*   IMPORTING
*     E_RESULT             = result
   EXCEPTIONS
     usage_error          = 1
     system_error         = 2
     internal_error       = 3
     OTHERS               = 4
             .
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN OTHERS.
    ENDCASE.                           " CASE sy-subrc
  ENDIF.                               " IF sy-subrc <> 0.
ENDFORM.                    " GET_FUNCTION_MODULE
*&---------------------------------------------------------------------*
*&      Form  CONVERT_PDF_BINARY
*&---------------------------------------------------------------------
FORM convert_pdf_binary .
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer                = fp_formoutput-pdf
*   APPEND_TO_TABLE       = ' '
* IMPORTING
*   OUTPUT_LENGTH         =
    TABLES
      binary_tab            = t_att_content_hex .
ENDFORM.                    " CONVERT_PDF_BINARY
*&---------------------------------------------------------------------*
*&      Form  send_PDF
*&---------------------------------------------------------------------*
FORM send_pdf.
  DATA: lv_fm_name         TYPE funcname,
        lv_interface_type  TYPE fpinterfacetype,
        ls_fp_outputparams TYPE sfpoutputparams,
        ls_fp_docparams    TYPE sfpdocparams,
        ls_fp_result       TYPE fpformoutput,
        ls_subject         TYPE so_obj_des,
        ls_result          TYPE sfpjoboutput,
        lv_filename        TYPE so_obj_des.

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
      interface          = gs_interface
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
        ls_message LIKE LINE OF lt_message,
        lt_mail_addresses TYPE somlreci1_t,
         ls_mail_addresses TYPE somlreci1,
        lv_returncode     TYPE sy-subrc,
        lt_lines TYPE TABLE OF tline,
        ls_lines LIKE tline,
        lt_lines2 TYPE TABLE OF tline,
        ls_lines2 LIKE tline,
        lv_tdname LIKE thead-tdname,
        lv_datum(10) TYPE c,
        lv_qmauftraggeber(40) TYPE c,
        lv_arbpl(40) TYPE c,
        ls_crhd TYPE crhd.
*  BREAK: EXTJAW.
  SELECT SINGLE usrid_long FROM pa0105 INTO
  ls_mail_addresses-receiver
    WHERE pernr = gs_interface-viqmel-buname
    AND subty = '0010'.

  ls_mail_addresses-blind_copy = 'X'.
  APPEND ls_mail_addresses TO lt_mail_addresses.


  CASE gs_workpaper-workpaper.
    WHEN '5910'.
      CONCATENATE 'LMS-Auftrag erstellt -' gs_interface-viqmel-qmnum gs_interface-viqmel-qmtxt INTO ls_subject SEPARATED BY space.
      lv_tdname = 'Z_QM_LMS_MAIL_RECEIVE'.
    WHEN '5913'.
      CONCATENATE 'LMS-Auftragsbestätigung -' gs_interface-viqmel-qmnum gs_interface-viqmel-qmtxt INTO ls_subject SEPARATED BY space.
      lv_tdname = 'Z_QM_LMS_MAIL_CONFIRM'.
    WHEN '5911'.
      CONCATENATE 'LMS-Prüfbericht -' gs_interface-viqmel-qmnum gs_interface-viqmel-qmtxt INTO ls_subject SEPARATED BY space.
      lv_tdname = 'Z_QM_LMS_MAIL_COMPLETE'.
  ENDCASE.
  CONCATENATE 'LMS' gs_interface-viqmel-qmnum INTO lv_filename SEPARATED BY space.
*  BREAK: EXTJAW.
  CALL FUNCTION 'READ_TEXT'
 EXPORTING
  client                        = sy-mandt
   id                            = 'QMQN'
   language                      = sy-langu
   name                          = lv_tdname
   object                        = 'TEXT'
*       ARCHIVE_HANDLE                = 0
*       LOCAL_CAT                     = ' '
*     IMPORTING
*       HEADER                        =
*       OLD_LINE_COUNTER              =
 TABLES
   lines                         = lt_lines
EXCEPTIONS
  id                            = 1
  language                      = 2
  name                          = 3
  not_found                     = 4
  object                        = 5
  reference_check               = 6
  wrong_access_to_archive       = 7
  OTHERS                        = 8
         .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


  APPEND '<html><body>' TO lt_message.
  LOOP AT lt_lines INTO ls_lines.
    SELECT SINGLE sname FROM pa0001 INTO lv_qmauftraggeber WHERE
       pernr = gs_interface-viqmel-buname.
    REPLACE ALL OCCURRENCES OF '<QMAuftraggeber>' IN ls_lines-tdline WITH lv_qmauftraggeber.
    IF sy-subrc = 0.
      CONCATENATE ls_lines-tdline '<br>' INTO ls_message.
      APPEND ls_message TO lt_message.
      CONTINUE.
    ENDIF.
    WRITE gs_interface-viqmel-qmdat TO lv_datum.
    REPLACE ALL OCCURRENCES OF '<CreateDate>' IN ls_lines-tdline WITH lv_datum.
    IF sy-subrc = 0.
      CONCATENATE ls_lines-tdline '<br>' INTO ls_message.
      APPEND ls_message TO lt_message.
      CONTINUE.
    ENDIF.
    REPLACE ALL OCCURRENCES OF '<Zusatztext>' IN ls_lines-tdline WITH ''.
    IF sy-subrc = 0.

      lv_tdname = gs_interface-viqmel-qmnum.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
         client                        = sy-mandt
          id                            = 'LTQM'
          language                      = sy-langu
          name                          = lv_tdname
          object                        = 'QMEL'
*           ARCHIVE_HANDLE                = 0
*           LOCAL_CAT                     = ' '
*         IMPORTING
*           HEADER                        =
*           OLD_LINE_COUNTER              =
        TABLES
          lines                         = lt_lines2
       EXCEPTIONS
         id                            = 1
         language                      = 2
         name                          = 3
         not_found                     = 4
         object                        = 5
         reference_check               = 6
         wrong_access_to_archive       = 7
         OTHERS                        = 8
                .
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CONCATENATE ls_lines-tdline '<br>' INTO ls_message.
      APPEND ls_message TO lt_message.
      LOOP AT lt_lines2 INTO ls_lines2.
        CONCATENATE ls_lines2-tdline '<br>' INTO ls_message.
        APPEND ls_message TO lt_message.
      ENDLOOP.


      CONTINUE.
    ENDIF.

    SELECT SINGLE * FROM crhd INTO ls_crhd WHERE arbpl EQ gs_interface-viqmel-zzarbpl.
    IF sy-subrc EQ 0.
      SELECT SINGLE ktext FROM crtx INTO lv_arbpl WHERE objty EQ ls_crhd-objty
                                                   AND objid EQ ls_crhd-objid
                                                   AND spras EQ sy-langu.
    ENDIF.
    REPLACE ALL OCCURRENCES OF '<Arbeitsplatz>' IN ls_lines-tdline WITH lv_arbpl.
    IF sy-subrc = 0.
      CONCATENATE ls_lines-tdline '<br>' INTO ls_message.
      APPEND ls_message TO lt_message.
      CONTINUE.
    ENDIF.
    CONCATENATE ls_lines-tdline '<br>' INTO ls_message.
    APPEND ls_message TO lt_message.
  ENDLOOP.




  CALL FUNCTION 'Z_QM_SEND_PAPER_MAIL'
    EXPORTING
      it_mail_addresses = lt_mail_addresses
      it_message        = lt_message
      iv_subject        = ls_subject
      is_formoutput     = ls_fp_result
      iv_filename       = lv_filename
    IMPORTING
      ev_returncode     = lv_returncode.
ENDFORM.                    " PRINT_PDF
