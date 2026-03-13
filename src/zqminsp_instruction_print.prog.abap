*&---------------------------------------------------------------------*
*& Report  ZQMINSP_INSTRUCTION_PRINT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 07.02.2017
*& DESCRIPTION: print program for transaction QA02
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqminsp_instruction_print.

TABLES: thead,
        stxh,
        print_co,
        affhd,
        qals,
        qamv,
        qapo,
        qasv,
        qmtb,
        qmtt,
        qkat,
        qpac,
        qmkst,
        qdfm,
        qdfmt,
        plfhd,
        qpml,
        tq17u.

INCLUDE fp_utilities.                                      "#EC INCL_OK

* global constant
DATA:
  c_rc_0       LIKE sy-subrc    VALUE 0,
  c_ok(1)      VALUE '0',
  c_failure(1) VALUE '1',

* Herkünfte
  c_hk_pm      LIKE qals-herkunft VALUE '14'.

*-- Ausgabe des Merkmalsprüfintervalls
DATA: g_insp_interval    LIKE qapo-qrastmeng .

* data for print-options
DATA: BEGIN OF g_pr_options.
        INCLUDE STRUCTURE itcpo.
      DATA: END OF g_pr_options.

DATA: BEGIN OF g_pr_result.
        INCLUDE STRUCTURE itcpp.
      DATA: END OF g_pr_result.


* stored QM-data for printing
* features
DATA: BEGIN OF g_qamvtab OCCURS 10.
        INCLUDE STRUCTURE qamv.
      DATA: END OF g_qamvtab.
* operations
DATA: BEGIN OF g_qapotab OCCURS 10.
        INCLUDE STRUCTURE qapo.
      DATA: END OF g_qapotab.
* samples
DATA: BEGIN OF g_qasvtab OCCURS 10.
        INCLUDE STRUCTURE qasv.
      DATA: END OF g_qasvtab.
* codes of a characteristic   (2 internal tables)
DATA: BEGIN OF g_qkattab OCCURS 10.
        INCLUDE STRUCTURE qkat.
      DATA: END OF g_qkattab.
DATA: BEGIN OF g_qpactab OCCURS 10.
        INCLUDE STRUCTURE qpac.
      DATA: END OF g_qpactab.
* production facilities
DATA: BEGIN OF g_prttab OCCURS 10.
        INCLUDE STRUCTURE affhd.
      DATA: END OF g_prttab.
* PM objects
DATA: g_qpmltab LIKE qpml OCCURS 0.
* special indicators
*     first printout of the lot
DATA: g_first_print,
*     print a message at the end
      g_print_message  LIKE tq30-kzmessage.


DATA: BEGIN OF g_linestab OCCURS 10.
        INCLUDE STRUCTURE tline.
      DATA: END OF g_linestab.

DATA: gs_interface          TYPE zqminsp_instruction_if_s,
      gs_print_opt          TYPE print_co,
      gv_ptype_24           TYPE zbms_len_ptype_24,
      gv_sollwert           TYPE zbms_sollwert,
      gv_nodialog           TYPE fpnodialog,
      gv_called_from_dialog TYPE c,
      gv_matvari_bemerking  TYPE zbms_bemerkung100.

DATA: ls_zqm_ins_inst_prt TYPE zqm_ins_inst_prt,
      lt_zqm_ins_inst_prt TYPE TABLE OF zqm_ins_inst_prt.


*PERFORM get_data.
*PERFORM print_pdf.
*######## Change 17.09.2018 LAGOTMI / Split to interactive Programm
SELECTION-SCREEN BEGIN OF BLOCK s_data WITH FRAME TITLE TEXT-100.
*PARAMETER      p_qmnum  TYPE qmel-qmnum.
PARAMETER       p_pruefl TYPE qals-prueflos.

SELECTION-SCREEN END OF BLOCK s_data.

SELECTION-SCREEN BEGIN OF BLOCK s_form WITH FRAME TITLE TEXT-101.
PARAMETER:     p_form   TYPE fpwbformname DEFAULT 'ZQM_INST_SHORT_FORM',
               p_langu  TYPE spras        DEFAULT 'D',
               p_countr TYPE land1        DEFAULT 'AT'
                            MATCHCODE OBJECT h_t005_land,
               p_ia     TYPE fpinteractive.
SELECTION-SCREEN END OF BLOCK s_form.

SELECTION-SCREEN BEGIN OF BLOCK s_jobp WITH FRAME TITLE TEXT-103.
PARAMETER      p_jobp   TYPE fpjobprofile MODIF ID jpr.
SELECTION-SCREEN END OF BLOCK s_jobp.

SELECTION-SCREEN BEGIN OF BLOCK s_conn WITH FRAME TITLE TEXT-102.
PARAMETER      p_conn   TYPE rfcdest      OBLIGATORY.
SELECTION-SCREEN END OF BLOCK s_conn.

DATA go_fp       TYPE REF TO if_fp.
DATA go_pdf_obj  TYPE REF TO if_fp_pdf_object.
DATA gx_fpex     TYPE REF TO cx_fp_runtime.
DATA gt_profiles TYPE tfpjobprofile.

DATA:
  lv_logo_url     TYPE string,
  fm_name         TYPE rs38l_fnam,
  fp_docparams    TYPE sfpdocparams,
  fp_outputparams TYPE sfpoutputparams,
  lt_daratab      TYPE tfpdara,
  ls_toa_dara     TYPE toa_dara,
  error_string    TYPE string,
  lv_spras        TYPE spras.


INITIALIZATION.
  MOVE cl_fp=>get_ads_connection( ) TO p_conn.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'JPR'.
      TRY.
          IF cl_fp_feature_test=>is_available(
                 iv_connection = p_conn
                 iv_feature    = cl_fp_feature_test=>gc_job_profiles )
              = abap_true.
            CONTINUE.
          ENDIF.
        CATCH cx_fp_runtime_internal
              cx_fp_runtime_system
              cx_fp_runtime_usage.                      "#EC NO_HANDLER
      ENDTRY.
      screen-active = 0.
      MODIFY SCREEN.
      CLEAR p_jobp.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_jobp.
  TRY.
      IF cl_fp_feature_test=>is_available(
             iv_connection = p_conn
             iv_feature    = cl_fp_feature_test=>gc_job_profiles )
          = abap_true.
*       Get job-profiles list from the ADS.
        go_fp = cl_fp=>get_reference( ).
        go_pdf_obj = go_fp->create_pdf_object( connection = p_conn ).
        gt_profiles = go_pdf_obj->get_job_profiles( ).
*       Show the value-help popup.
        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
          EXPORTING
            retfield    = 'NAME'
            dynpprog    = sy-cprog
            dynpnr      = sy-dynnr
            dynprofield = 'P_JOBP'
            value_org   = 'S'
          TABLES
            value_tab   = gt_profiles.
      ENDIF.
    CATCH cx_fp_runtime_internal
          cx_fp_runtime_system
          cx_fp_runtime_usage.                          "#EC NO_HANDLER
  ENDTRY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_conn.
  PERFORM value_help_for_destination USING 'P_CONN'.

START-OF-SELECTION.

  "------- Read Memory buffer
  PERFORM import_data.

  IF qals IS INITIAL.
    lv_spras  = p_langu.
    gs_print_opt-primm = 'X'.
    IF p_form = 'ZQM_INST_SHORT_FORM'.
      gv_nodialog = ''.
      gv_called_from_dialog = 'X'.

      SELECT SINGLE * FROM qals INTO gs_interface-qals WHERE prueflos EQ p_pruefl.
      SELECT SINGLE * FROM qmel INTO gs_interface-qmel WHERE prueflos EQ p_pruefl.
*    CONCATENATE  gs_interface-qals-zzbms_materialnr(9) gs_interface-qals-zzbms_farbe
*    gs_interface-qals-zzbms_umreifung_char1 gs_interface-qals-zzbms_avivage gs_interface-qals-zzbms_len_ptype_stelle18
*    gs_interface-qals-zzbms_len_ptype_stelle19 gs_interface-qals-zzbms_len_ptype_stelle20
*    gs_interface-qals-zzbms_material_variante_prod INTO gv_ptype_24.

      PERFORM get_data.
      PERFORM print_pdf.
    ELSEIF  p_form = 'ZQMINSP_INST_FORM'.
      gv_nodialog = ''.
      gv_called_from_dialog = 'X'.
      SELECT SINGLE * FROM qals INTO gs_interface-qals WHERE prueflos EQ p_pruefl.
      SELECT SINGLE * FROM qmel INTO gs_interface-qmel WHERE prueflos EQ p_pruefl.
*    CONCATENATE  gs_interface-qals-zzbms_materialnr(9) gs_interface-qals-zzbms_farbe
*    gs_interface-qals-zzbms_umreifung_char1 gs_interface-qals-zzbms_avivage gs_interface-qals-zzbms_len_ptype_stelle18
*    gs_interface-qals-zzbms_len_ptype_stelle19 gs_interface-qals-zzbms_len_ptype_stelle20
*    gs_interface-qals-zzbms_material_variante_prod INTO gv_ptype_24.
      PERFORM get_data.
      PERFORM print_pdf.
    ENDIF.
  ELSE.
    gv_nodialog = 'x'.
    gv_called_from_dialog = ''.
    PERFORM get_data.
    IF qals-art = 'ZLAG-01'.
      " Print for Textilelabatory
      p_form = 'ZQM_INST_SHORT_FORM'.

      SELECT * FROM zqm_ins_inst_prt INTO TABLE lt_zqm_ins_inst_prt WHERE form = p_form.
      IF sy-subrc = 0.
        LOOP AT lt_zqm_ins_inst_prt INTO ls_zqm_ins_inst_prt.
          gs_print_opt-desti = ls_zqm_ins_inst_prt-desti.
          gs_print_opt-primm = 'X'.
          PERFORM print_pdf.
        ENDLOOP.
      ENDIF.
*    gs_print_opt-desti = 'LTWN'.
*    gs_print_opt-primm = 'X'.
*    PERFORM print_pdf.
*    " Print for Analyticslabatory
*    p_form = 'ZQM_INST_SHORT_FORM'.
*    gs_print_opt-desti = 'LTJJ'.
*    gs_print_opt-primm = 'X'.
*    PERFORM print_pdf.
    ELSE.
      p_form = 'ZQMINSP_INST_FORM'.
      gs_print_opt-primm = 'X'.
      PERFORM print_pdf.
    ENDIF.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_data .

  PERFORM import_data.
  PERFORM map_data2interface_structure.
ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  IMPORT_DATA
*&---------------------------------------------------------------------*
FORM import_data .
* aktuellen Druckauftrag QM-Daten aus memory
  IMPORT prlst_tmp       TO gs_print_opt
         qapotab         TO g_qapotab
         qamvtab         TO g_qamvtab
         qasvtab         TO g_qasvtab
         prttab          TO g_prttab
         qpmltab         TO g_qpmltab
         i_qals          TO qals
         i_first_print   TO g_first_print
         i_print_message TO g_print_message FROM MEMORY ID 'QM_PRT02'.
*----------------------------------------------------------------------*
* sort the internal tables
* sort QAPOTAB by operation number
  SORT g_qapotab ASCENDING BY mandant prueflos plnfl vornr.

* sort QASVTAB FOR BINARY SEARCH
  SORT g_qasvtab ASCENDING BY  mandant
                               prueflos
                               vorglfnr
                               merknr
                               probenr.
ENDFORM.                    " IMPORT_DATA

*&---------------------------------------------------------------------*
*&      Form  MAP_DATA2INTERFACE_STRUCTURE
*&---------------------------------------------------------------------*
FORM map_data2interface_structure.
  DATA: ls_qapo     TYPE qapo,
        ls_qamv     TYPE qamv,
        ls_ops      TYPE zqminsp_inst_op_s,
        ls_chars    TYPE zqminsp_inst_char_s,
        ls_qmprobes TYPE zqmprobes,
        lt_qmprobes TYPE TABLE OF zqmprobes.
  DATA: lt_return       TYPE TABLE OF bapiret2,
        lt_gradmtrx_itm TYPE TABLE OF zbms_s_bapi_gradmtrx_itm,
        ls_gradmtrx_itm TYPE zbms_s_bapi_gradmtrx_itm,
        ls_zbms_prodauf TYPE zbms_prodauf.
  DATA: l_umreif_c2 TYPE c LENGTH 2.

  IF gv_called_from_dialog <> 'X'.
    gs_interface-qals = qals.
  ENDIF.

  IF gs_interface-qals-zzbms_materialnr IS INITIAL OR
    gs_interface-qals-zzbms_farbe IS INITIAL OR
    gs_interface-qals-zzbms_umreifung_char1 IS INITIAL OR
    gs_interface-qals-zzbms_avivage IS INITIAL OR
     gs_interface-qals-zzbms_len_ptype_stelle18 IS INITIAL OR
     gs_interface-qals-zzbms_len_ptype_stelle19 IS INITIAL  OR
     gs_interface-qals-zzbms_len_ptype_stelle20 IS INITIAL.

    SHIFT gs_interface-qals-aufnr LEFT DELETING LEADING '0'.
    SELECT SINGLE * FROM zbms_prodauf INTO ls_zbms_prodauf WHERE werks = gs_interface-qals-werk AND prodaufnr =  gs_interface-qals-aufnr.

    IF sy-subrc = 0.
      gs_interface-qals-zzbms_materialnr = ls_zbms_prodauf-bmsmatnr.
      gs_interface-qals-zzbms_farbe = ls_zbms_prodauf-farbe.

      l_umreif_c2 = ls_zbms_prodauf-umreif.
      " Steht dann '4 ' ' 4' oder  '04' drin.
      " daher richtig Formatieren:
      SHIFT l_umreif_c2 LEFT DELETING LEADING space.
      SHIFT l_umreif_c2 LEFT DELETING LEADING '0'.
      SHIFT l_umreif_c2 RIGHT DELETING TRAILING space.
      gs_interface-qals-zzbms_umreifung_char1 = l_umreif_c2+1(1).
      gs_interface-qals-zzbms_avivage = ls_zbms_prodauf-avivage.
      gs_interface-qals-zzbms_len_ptype_stelle18 = ls_zbms_prodauf-len_ptype_s18.
      gs_interface-qals-zzbms_len_ptype_stelle19 = ls_zbms_prodauf-len_ptype_s19.
      gs_interface-qals-zzbms_len_ptype_stelle20 = ls_zbms_prodauf-len_ptype_s20.
      gs_interface-qals-zzbms_material_variante_prod = ls_zbms_prodauf-prodvariant.
    ENDIF.
  ENDIF.

  zcl_bms_len_util=>mapp_8flds_to_ptype24(
    EXPORTING
      i_bmsmatnr   = gs_interface-qals-zzbms_materialnr
      i_farbe      = gs_interface-qals-zzbms_farbe
      i_umreif     = gs_interface-qals-zzbms_umreifung_char1
      i_avivage    = gs_interface-qals-zzbms_avivage
      i_ptype_s18  = gs_interface-qals-zzbms_len_ptype_stelle18
      i_ptype_s19  = gs_interface-qals-zzbms_len_ptype_stelle19
      i_ptype_s20  = gs_interface-qals-zzbms_len_ptype_stelle20
      i_prodvariant = gs_interface-qals-zzbms_material_variante_prod
    IMPORTING
      e_ptype_24   = gv_ptype_24 ).

  CALL FUNCTION 'Z_BMS_BAPI_GRADMTRX_GETDETAIL'
    EXPORTING
      i_accessmode    = 'PTY'
*     I_VALID_ON_DAT  =
      i_werks         = gs_interface-qals-werk
      i_bmsmatnr      = gs_interface-qals-zzbms_materialnr
*     I_MATRIX_UGRP   =
*     I_VERSION       =
      i_farbe         = gs_interface-qals-zzbms_farbe
      i_umreif        = gs_interface-qals-zzbms_umreifung_char1
      i_avivage       = gs_interface-qals-zzbms_avivage
      i_len_ptype_s18 = gs_interface-qals-zzbms_len_ptype_stelle18
      i_len_ptype_s19 = gs_interface-qals-zzbms_len_ptype_stelle19
      i_len_ptype_s20 = gs_interface-qals-zzbms_len_ptype_stelle20
      i_prodvariant   = gs_interface-qals-zzbms_material_variante_prod
*     IMPORTING
*     ES_GRADMTRX_HDR =
    TABLES
      et_return       = lt_return
      et_gradmtrx_itm = lt_gradmtrx_itm.

  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

  IF sy-subrc <> 0.
    CLEAR lt_return.
    READ TABLE lt_gradmtrx_itm INTO ls_gradmtrx_itm WITH KEY ddic_fname = 'AUFLAGE'.
    IF sy-subrc = 0.
      gv_sollwert = ls_gradmtrx_itm-sollwert.
    ENDIF.
  ENDIF.





  "[20170407] add probe table to interface
  SELECT * FROM zqmprobes INTO TABLE lt_qmprobes WHERE prueflos EQ gs_interface-qals-prueflos.
  IF sy-subrc EQ 0.
    LOOP AT lt_qmprobes INTO ls_qmprobes.
      SELECT * FROM qprs APPENDING TABLE gs_interface-t_qprs WHERE phynr EQ ls_qmprobes-phynr.
    ENDLOOP.

    READ TABLE lt_qmprobes INTO ls_qmprobes INDEX 1.
    IF sy-subrc EQ 0.
      SELECT SINGLE * FROM qmel INTO gs_interface-qmel WHERE qmnum EQ ls_qmprobes-qmnum.
    ENDIF.
  ENDIF.



  LOOP AT g_qapotab INTO ls_qapo.
    CLEAR: ls_ops.

    ls_ops-qapo = ls_qapo.

    LOOP AT g_qamvtab INTO ls_qamv WHERE vorglfnr EQ ls_ops-qapo-vorglfnr.
      CLEAR: ls_chars.

      ls_chars-qamv = ls_qamv.
      APPEND ls_chars TO ls_ops-t_chars.
    ENDLOOP.

    APPEND ls_ops TO gs_interface-t_ops.
  ENDLOOP.

  SELECT SINGLE bemerkung FROM zbms_matvari INTO @gv_matvari_bemerking WHERE
    werks      = @gs_interface-qals-werk AND
    matvariant = @gs_interface-qals-zzbms_material_variante_prod.
ENDFORM.                    " MAP_DATA2INTERFACE_STRUCTURE

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
      i_name               = p_form
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
  ls_fp_outputparams-nodialog = gv_nodialog.

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

  ls_fp_docparams-langu    = gs_print_opt-spras.
  ls_fp_docparams-fillable = space.

  "one label per entry
  CALL FUNCTION lv_fm_name
    EXPORTING
      /1bcdwb/docparams  = ls_fp_docparams
      s_interface        = gs_interface
      ptype_24           = gv_ptype_24
      matvari_note       = gv_matvari_bemerking
      sollwert           = gv_sollwert
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

*&----------------------------------------------------------------------------------*
*&      Form  entry_ZQMINSP_INST (entry point) for Formular print via customizing
*&----------------------------------------------------------------------------------*
FORM entry_zqminsp_inst.

  p_form = 'ZQMINSP_INST_FORM'.
  gv_nodialog = 'x'.
  gv_called_from_dialog = ''.
  PERFORM get_data.
  PERFORM print_pdf.
ENDFORM.
