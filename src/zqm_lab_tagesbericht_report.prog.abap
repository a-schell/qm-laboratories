*&---------------------------------------------------------------------*
*& Report  ZQM_LAB_TAGESBERICHT_REPORT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 03.01.2016
*& DESCRIPTION: sort and print inspection lot
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqm_lab_tagesbericht_report.

INCLUDE zqm_lab_tagesbericht_report_cl. "local classes

DATA: go_tree_list        TYPE REF TO cl_gui_alv_tree,
      go_tree_sort        TYPE REF TO cl_gui_alv_tree,
      go_drdr_list        TYPE REF TO cl_dragdrop,
      go_drdr_sort        TYPE REF TO cl_dragdrop,
      go_cont_list        TYPE REF TO cl_gui_custom_container,
      go_cont_sort        TYPE REF TO cl_gui_custom_container,
      go_cont_obj_list    TYPE REF TO cl_gui_docking_container,
      go_cont_obj_sort    TYPE REF TO cl_gui_docking_container,
      go_evt_rec_list     TYPE REF TO lcl_tree_event_receiver,
      go_evt_rec_sort     TYPE REF TO lcl_tree_event_receiver,
      go_toolbar_list     TYPE REF TO cl_gui_toolbar,
      go_toolbar_sort     TYPE REF TO cl_gui_toolbar,
      go_tb_evt_rec_list  TYPE REF TO lcl_toolbar_event_receiver,
      go_tb_evt_rec_sort  TYPE REF TO lcl_toolbar_event_receiver,
      go_header_list      TYPE REF TO cl_gui_html_viewer,
      go_header_sort      TYPE REF TO cl_gui_html_viewer,
      go_dyndoc_list      TYPE REF TO cl_dd_document,
      go_dyndoc_sort      TYPE REF TO cl_dd_document,
      gv_handle_list      TYPE i,
      gv_handle_sort      TYPE i,
      gt_qals             TYPE qals_tab,
      gt_result           TYPE zqm_lab_tagesbericht_t,
      gt_result_list      TYPE zqm_lab_tagesbericht_t,
      gt_result_sort      TYPE zqm_lab_tagesbericht_t,
      gv_controls_created TYPE c,
      gv_repid            TYPE syrepid,
      gt_fieldcat         TYPE lvc_t_fcat,
      gs_hierarchy_header TYPE treev_hhdr,
      gv_sort             TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_werks TYPE werks_d OBLIGATORY,
            p_arbpl TYPE zzarbpl OBLIGATORY MATCHCODE OBJECT ZQM_WORKPLACE,
            p_datum TYPE qprstart OBLIGATORY  DEFAULT sy-datum,
            p_art   TYPE qpart OBLIGATORY MATCHCODE OBJECT sh_tq30 DEFAULT 'ZLAG-00'.

SELECTION-SCREEN SKIP.

PARAMETERS: p_frei  RADIOBUTTON GROUP rd1 DEFAULT 'X',
            p_gene RADIOBUTTON GROUP rd1, "show released inspection lots
            p_pako RADIOBUTTON GROUP rd1. "show completed inspection lots
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM enqueue_inspection_lots.
  PERFORM initialize_dragdrop.

END-OF-SELECTION.

  gv_repid = sy-repid.
  CALL SCREEN 100.

  "includes
  INCLUDE zqm_lab_tagesbericht_reporto01. "output
  INCLUDE zqm_lab_tagesbericht_reportf01. "functions
  INCLUDE zqm_lab_tagesbericht_reporti01. "input
