*&---------------------------------------------------------------------*
*& Include ZQM_LAB_BMS_TOP                                   Module Pool      ZQM_LAB_BMS
*&
*&---------------------------------------------------------------------*
PROGRAM zqm_lab_bms.

TYPE-POOLS: esp1.

INCLUDE icons.

* Class definitions
CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_data_changed
         FOR EVENT data_changed OF cl_gui_alv_grid
             IMPORTING er_data_changed,

     handle_double_click
         FOR EVENT double_click OF cl_gui_alv_grid
             IMPORTING e_row e_column es_row_no.

ENDCLASS.                    "lcl_event_receiver DEFINITION

TABLES: zqm_s_lab_bms_selection, zqm_s_lab_bms_value_add_data, caufvd.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_initialized TYPE abap_bool.

DATA obj_runtime TYPE REF TO zif_qm_lab_bms_runtime.

DATA: obj_single_mnt_data_object TYPE REF TO data,
      obj_multi_mnt_data_object TYPE REF TO data.

DATA gt_data_to_maintain TYPE zqm_t_lab_bms_maintain_data.
DATA gt_data_to_display TYPE zqm_t_lab_bms_maintain_data.
DATA gt_historic_data TYPE zqm_t_lab_bms_maintain_data.
DATA gt_header_data TYPE zqm_t_lab_bms_header_data.
DATA gt_time_rep_data TYPE zqm_t_lab_bms_time_rep_data.
DATA gs_additional_value_data TYPE zqm_s_lab_bms_value_add_data.
DATA gv_historical TYPE abap_bool.
DATA gv_selected_row_index TYPE i.

DATA gv_check_errors_occured TYPE abap_bool.

DATA gv_workcenter_screen_number TYPE sy-dynnr.

* Controls
CONTROLS tabstrip_workarea TYPE TABSTRIP.

* Gui control variables
DATA but_workcenter TYPE icons-text.
DATA but_line TYPE icons-text.
DATA: obj_single_mnt_alv_container TYPE REF TO cl_gui_custom_container,
      obj_single_mnt_alv TYPE REF TO cl_gui_alv_grid.
DATA: obj_multi_mnt_alv_container TYPE REF TO cl_gui_custom_container,
      obj_multi_mnt_alv TYPE REF TO cl_gui_alv_grid.
DATA: obj_single_event_receiver TYPE REF TO lcl_event_receiver,
      obj_multi_event_receiver TYPE REF TO lcl_event_receiver,
      obj_time_rep_event_receiver TYPE REF TO lcl_event_receiver.
DATA: gt_multi_fieldcatalog TYPE lvc_t_fcat,
      gt_single_fieldcatalog TYPE lvc_t_fcat.
DATA: gt_single_field_groups TYPE lvc_t_sgrp,
      gt_multi_field_groups TYPE lvc_t_sgrp.
DATA: obj_header_data_alv_container TYPE REF TO cl_gui_custom_container,
      obj_header_data_alv TYPE REF TO cl_gui_alv_grid.
DATA: obj_time_rep_alv_container TYPE REF TO cl_gui_custom_container,
      obj_time_rep_alv TYPE REF TO cl_gui_alv_grid.

* Selection criterias
DATA gv_werk TYPE werks_d.
DATA gv_sample_type TYPE zbms_entnahme_probenart.
DATA ra_workcenter TYPE RANGE OF qprplatz.
DATA ra_line TYPE RANGE OF zbms_linienr.
DATA gv_date TYPE dats.
DATA gv_time TYPE uzeit.
DATA gv_insplot TYPE qibplosnr.
DATA gv_ballen_id TYPE zbms_ballenid.
DATA gv_phynr TYPE qphysprnr.
DATA gv_show_historic_values TYPE abap_bool.
DATA gv_include_date_in_search TYPE abap_bool.
DATA gv_max_hits TYPE int4 VALUE 5.

* Selection screens
SELECTION-SCREEN: BEGIN OF SCREEN 0100 AS SUBSCREEN.
PARAMETERS: p_werk TYPE zqm_s_lab_bms_selection-werk OBLIGATORY.
SELECT-OPTIONS: s_work FOR zqm_s_lab_bms_selection-workcenter.
SELECT-OPTIONS: s_line FOR zqm_s_lab_bms_selection-line.
PARAMETERS: p_smpl TYPE zqm_s_lab_bms_selection-sample_type DEFAULT 'N' OBLIGATORY.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) text-s01.
PARAMETERS: p_date TYPE zqm_s_lab_bms_selection-date OBLIGATORY, p_time TYPE zqm_s_lab_bms_selection-time OBLIGATORY.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_hist AS CHECKBOX.
SELECTION-SCREEN: END OF SCREEN 0100.

SELECTION-SCREEN: BEGIN OF SCREEN 0110 AS SUBSCREEN.
PARAMETERS: p_insp TYPE zqm_s_lab_bms_selection-insplot OBLIGATORY.
SELECT-OPTIONS: s_work1 FOR zqm_s_lab_bms_selection-workcenter.
PARAMETERS: p_smpl1 TYPE zqm_s_lab_bms_selection-sample_type DEFAULT 'SP' OBLIGATORY.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) text-s01.
PARAMETERS: p_date1 TYPE zqm_s_lab_bms_selection-date OBLIGATORY, p_time1 TYPE zqm_s_lab_bms_selection-time OBLIGATORY.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_hist1 AS CHECKBOX.
SELECTION-SCREEN: END OF SCREEN 0110.

SELECTION-SCREEN: BEGIN OF SCREEN 0120 AS SUBSCREEN.
PARAMETERS: p_werk2 TYPE zqm_s_lab_bms_selection-werk OBLIGATORY.
PARAMETER: p_balid2 TYPE zqm_s_lab_bms_selection-ballen_id OBLIGATORY.
SELECT-OPTIONS: s_work2 FOR zqm_s_lab_bms_selection-workcenter.
PARAMETERS: p_smpl2 TYPE zqm_s_lab_bms_selection-sample_type DEFAULT 'N' OBLIGATORY.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) text-s01.
PARAMETERS: p_date2 TYPE zqm_s_lab_bms_selection-date OBLIGATORY, p_time2 TYPE zqm_s_lab_bms_selection-time OBLIGATORY.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_hist2 AS CHECKBOX.
SELECTION-SCREEN: END OF SCREEN 0120.

SELECTION-SCREEN: BEGIN OF SCREEN 0130 AS SUBSCREEN.
PARAMETER: p_phynr TYPE zqm_s_lab_bms_selection-phynr OBLIGATORY.
SELECT-OPTIONS: s_work3 FOR zqm_s_lab_bms_selection-workcenter.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) text-s01.
PARAMETERS: p_date3 TYPE zqm_s_lab_bms_selection-date OBLIGATORY, p_time3 TYPE zqm_s_lab_bms_selection-time OBLIGATORY.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_hist3 AS CHECKBOX.
SELECTION-SCREEN: END OF SCREEN 0130.

SELECTION-SCREEN: BEGIN OF SCREEN 0140 AS SUBSCREEN.
PARAMETERS: p_werk4 TYPE zqm_s_lab_bms_selection-werk OBLIGATORY.
PARAMETER: p_balid4 TYPE zqm_s_lab_bms_selection-ballen_id OBLIGATORY.
SELECT-OPTIONS: s_work4 FOR zqm_s_lab_bms_selection-workcenter.
SELECT-OPTIONS: s_line4 FOR zqm_s_lab_bms_selection-line OBLIGATORY.
PARAMETERS: p_smpl4 TYPE zqm_s_lab_bms_selection-sample_type DEFAULT 'N' OBLIGATORY.
PARAMETERS: p_date4 TYPE zqm_s_lab_bms_selection-date OBLIGATORY, p_time4 TYPE zqm_s_lab_bms_selection-time OBLIGATORY.
PARAMETERS: p_dtinc4 AS CHECKBOX.
PARAMETERS: p_hist4 AS CHECKBOX.
SELECTION-SCREEN: END OF SCREEN 0140.

* Class implementations
CLASS lcl_event_receiver IMPLEMENTATION.
  METHOD handle_data_changed.
    DATA lt_messages TYPE bapiret2_t.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    IF gv_ok_code = 'SAVE'.
      IF me = obj_single_event_receiver.
        lt_messages = obj_runtime->check_data( iv_data_type       = 'S'
                                               it_modified_cells  = er_data_changed->mt_mod_cells
                                               it_maintain_data   = gt_data_to_maintain
                                               io_data_object     = obj_single_mnt_data_object ).
      ELSEIF me = obj_multi_event_receiver.
        lt_messages = obj_runtime->check_data( iv_data_type       = 'M'
                                               it_modified_cells  = er_data_changed->mt_mod_cells
                                               it_maintain_data   = gt_data_to_maintain
                                               io_data_object     = obj_multi_mnt_data_object ).
      ELSE.
        RETURN.
      ENDIF.

      IF lt_messages[] IS NOT INITIAL.
        LOOP AT lt_messages ASSIGNING <wa_messages>.
          er_data_changed->add_protocol_entry( i_msgid     = <wa_messages>-id
                                               i_msgno     = <wa_messages>-number
                                               i_msgty     = <wa_messages>-type
                                               i_msgv1     = <wa_messages>-message_v1
                                               i_msgv2     = <wa_messages>-message_v2
                                               i_msgv3     = <wa_messages>-message_v3
                                               i_msgv4     = <wa_messages>-message_v4
                                               i_fieldname = <wa_messages>-field
                                               i_row_id    = <wa_messages>-row ).
        ENDLOOP.

        er_data_changed->display_protocol( i_optimize_columns = abap_true ).

        gv_check_errors_occured = abap_true.
      ENDIF.
    ENDIF.

    FREE lt_messages.
  ENDMETHOD.                    "handle_data_changed

  METHOD handle_double_click.
    DATA: lv_row_index TYPE int4,
          lv_column_id TYPE string.

    lv_row_index = e_row-index.
    lv_column_id = e_column-fieldname.

    PERFORM show_additional_value_data USING lv_row_index
                                             lv_column_id.

    CLEAR: lv_row_index, lv_column_id.
  ENDMETHOD.                    "handle_double_click
ENDCLASS.                    "lcl_event_receiver IMPLEMENTATION
