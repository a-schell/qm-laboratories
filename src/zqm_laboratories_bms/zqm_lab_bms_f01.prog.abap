*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_BMS_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  set_date_time
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_date_time.
  CASE gv_workcenter_screen_number.
    WHEN 0200.
      p_date = sy-datlo.
      p_time = |{ sy-timlo+0(2) }0000|.
    WHEN 0210.
      p_date1 = sy-datlo.
      p_time1 = |{ sy-timlo+0(2) }0000|.
    WHEN 0220.
      p_date2 = sy-datlo.
      p_time2 = |{ sy-timlo+0(2) }0000|.
    WHEN 0230.
      p_date3 = sy-datlo.
      p_time3 = |{ sy-timlo+0(2) }0000|.
    WHEN 0240.
      p_date4 = sy-datlo.
      p_time4 = |{ sy-uzeit }|.
      p_hist4 = |X|.
  ENDCASE.
ENDFORM.                    "set_date_time

*&---------------------------------------------------------------------*
*&      Form  set_default_sel_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_default_sel_values.
  DATA: lv_plant TYPE xuvalue18,
        lv_workcenter TYPE xuvalue18.
  DATA wa_workcenter LIKE LINE OF ra_workcenter.

  zcl_qm_lab_bms_util=>get_default_sel_values( IMPORTING ev_plant      = lv_plant
                                                         ev_workcenter = lv_workcenter ).

  IF lv_workcenter IS NOT INITIAL.
    wa_workcenter-sign = 'I'.
    wa_workcenter-option = 'EQ'.
    wa_workcenter-low = lv_workcenter.
  ENDIF.

  CASE sy-dynnr.
    WHEN 0200.
      p_werk = lv_plant.

      IF wa_workcenter IS NOT INITIAL.
        APPEND wa_workcenter TO s_work.
      ENDIF.
    WHEN 0210.
      IF wa_workcenter IS NOT INITIAL.
        APPEND wa_workcenter TO s_work1.
      ENDIF.
    WHEN 0220.
      p_werk2 = lv_plant.

      IF wa_workcenter IS NOT INITIAL.
        APPEND wa_workcenter TO s_work2.
      ENDIF.
    WHEN 0230.
      IF wa_workcenter IS NOT INITIAL.
        APPEND wa_workcenter TO s_work3.
      ENDIF.
    WHEN 0240.
      p_werk4 = lv_plant.

      IF wa_workcenter IS NOT INITIAL.
        APPEND wa_workcenter TO s_work4.
      ENDIF.
  ENDCASE.

  CLEAR: lv_plant, lv_workcenter, wa_workcenter.
ENDFORM.                    "set_default_sel_values

*&---------------------------------------------------------------------*
*&      Form  execute
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM execute.
  DATA obj_bms_reader TYPE REF TO zif_qm_lab_bms_reader.
  DATA lt_search_result TYPE zqm_t_lab_bms_search_result.
  DATA: lt_head_data TYPE zqm_t_lab_bms_head_data,
        wa_head_data TYPE zqm_s_lab_bms_head_data.
  DATA: obj_lines TYPE REF TO data,
        obj_workcenter TYPE REF TO data.
  DATA obj_exception TYPE REF TO zcx_qm_lab_bms_exceptions.
  DATA lv_max_hits TYPE int4.
  DATA lv_error TYPE abap_bool.
  DATA lt_messages TYPE esp1_message_tab_type.
  DATA lv_line_required TYPE abap_bool VALUE abap_true.

  FIELD-SYMBOLS: <wa_search_result> TYPE zqm_s_lab_bms_search_result,
                 <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data,
                 <wa_values> TYPE zqm_s_lab_bms_measure_data,
                 <wa_messages> TYPE esp1_message_wa_type.

* Check values
  PERFORM check_selection_values CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  FREE: gt_data_to_maintain, gt_historic_data, gt_data_to_display.

* Execute search
  TRY.
      obj_bms_reader = zcl_qm_lab_bms_factory=>get_reader( ).

      IF gv_workcenter_screen_number = 0200.
* Get data object references
        GET REFERENCE OF s_line[] INTO obj_lines.
        GET REFERENCE OF s_work[] INTO obj_workcenter.

* Execute search
        lt_search_result = obj_bms_reader->search( iv_werk          = gv_werk
                                                   io_working_group = obj_workcenter
                                                   io_lines         = obj_lines
                                                   iv_sample_type   = gv_sample_type
                                                   iv_date          = gv_date
                                                   iv_time          = gv_time ).
      ELSEIF gv_workcenter_screen_number = 0210.
* Get data object references
        GET REFERENCE OF s_work1[] INTO obj_workcenter.

        lt_search_result = obj_bms_reader->search_by_insplot( iv_insplot       = gv_insplot
                                                              io_working_group = obj_workcenter
                                                              iv_sample_type   = gv_sample_type
                                                              iv_date          = gv_date
                                                              iv_time          = gv_time ).
      ELSEIF gv_workcenter_screen_number = 0220.
* Get data object references
        GET REFERENCE OF s_work2[] INTO obj_workcenter.

        lt_search_result = obj_bms_reader->search_by_ballen_id( iv_werk          = gv_werk
                                                                iv_ballen_id     = gv_ballen_id
                                                                io_working_group = obj_workcenter
                                                                iv_sample_type   = gv_sample_type
                                                                iv_date          = gv_date
                                                                iv_time          = gv_time ).
      ELSEIF gv_workcenter_screen_number = 0230.
* Get data object references
        GET REFERENCE OF s_work3[] INTO obj_workcenter.

        lt_search_result = obj_bms_reader->search_by_physical_sample( iv_phynr         = gv_phynr
                                                                      io_working_group = obj_workcenter
                                                                      iv_date          = gv_date
                                                                      iv_time          = gv_time ).

        lv_line_required = abap_false.
      ELSEIF gv_workcenter_screen_number = 0240.
* Get data object references
        GET REFERENCE OF s_work4[] INTO obj_workcenter.
        GET REFERENCE OF s_line4[] INTO obj_lines.

        lt_search_result = obj_bms_reader->search_by_insplot_ballen_id( iv_werk          = gv_werk
                                                                        iv_ballen_id     = gv_ballen_id
                                                                        io_working_group = obj_workcenter
                                                                        io_lines         = obj_lines
                                                                        iv_sample_type   = gv_sample_type
                                                                        iv_date          = gv_date
                                                                        iv_time          = gv_time
                                                                        iv_include_date  = gv_include_date_in_search ).
      ENDIF.

* Transform search result into head data
      LOOP AT lt_search_result ASSIGNING <wa_search_result>.
        MOVE-CORRESPONDING <wa_search_result> TO wa_head_data.
        INSERT wa_head_data INTO TABLE lt_head_data.
        CLEAR wa_head_data.
      ENDLOOP.

      IF obj_runtime IS NOT BOUND.
* Get runtime object
        obj_runtime = zcl_qm_lab_bms_factory=>get_runtime( ).
      ENDIF.

      gt_data_to_maintain = obj_runtime->get_data_for_maintain( it_head_data        = lt_head_data
                                                                iv_is_line_required = lv_line_required ).

* Read historic values if requested
      IF gv_show_historic_values = abap_true.
        lv_max_hits = gv_max_hits + 1.

        IF gv_workcenter_screen_number = 0240.
          gt_historic_data = obj_runtime->get_historical_sample_values( it_data_to_maintain = gt_data_to_maintain
                                                                        iv_ballennr         = gv_ballen_id
                                                                        iv_max_hits         = 9999999 ).
        ELSE.
          gt_historic_data = obj_runtime->get_historical_sample_values( it_data_to_maintain = gt_data_to_maintain
                                                                        iv_max_hits         = lv_max_hits ).
        ENDIF.
      ENDIF.

* Show popup with lock messages
      LOOP AT gt_data_to_maintain ASSIGNING <wa_data_to_maintain> WHERE locked = abap_true.
        LOOP AT <wa_data_to_maintain>-values ASSIGNING <wa_values>.
          APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
          <wa_messages>-msgty = 'E'.
          <wa_messages>-msgid = 'ZQM_LABORATORIES_BMS'.
          <wa_messages>-msgno = 013.
          <wa_messages>-msgv1 = <wa_values>-description.
          <wa_messages>-msgv2 = <wa_data_to_maintain>-linie.
          <wa_messages>-msgv3 = <wa_data_to_maintain>-lock_user.
          UNASSIGN <wa_messages>.
        ENDLOOP.
      ENDLOOP.

      IF lt_messages[] IS NOT INITIAL.
* Show messages
        CALL FUNCTION 'C14Z_MESSAGES_SHOW_AS_POPUP'
          TABLES
            i_message_tab = lt_messages.
      ENDIF.

      FREE: obj_workcenter, obj_lines.
      FREE: lt_search_result, lt_messages.
    CATCH zcx_qm_lab_bms_exceptions INTO obj_exception.
  ENDTRY.

  CLEAR: lv_max_hits, lv_line_required.
  FREE: lt_head_data, lt_search_result.
  FREE: obj_lines, obj_workcenter, obj_bms_reader.
ENDFORM.                    "execute

*&---------------------------------------------------------------------*
*&      Form  check_selection_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_selection_values CHANGING cv_error.
  DATA lv_domvalue TYPE dd07d-domvalue.

* Check date and time
  IF gv_date > sy-datlo.
    MESSAGE text-w01 TYPE 'W' DISPLAY LIKE 'E'.
    cv_error = abap_true.
  ENDIF.

  IF gv_date = sy-datlo AND gv_time > sy-timlo.
    MESSAGE text-w02 TYPE 'W' DISPLAY LIKE 'E'.
    cv_error = abap_true.
  ENDIF.

  IF gv_sample_type IS NOT INITIAL.
    lv_domvalue = gv_sample_type.

    CALL FUNCTION 'FM_DOMAINVALUE_CHECK'
      EXPORTING
        i_domname         = 'ZBMS_ENTNAHME_PROBENART'
        i_domvalue        = lv_domvalue
      EXCEPTIONS
        input_error       = 1
        value_not_allowed = 2
        OTHERS            = 3.

    IF sy-subrc IS NOT INITIAL.
      MESSAGE text-w03 TYPE 'W' DISPLAY LIKE 'E'.
      cv_error = abap_true.
    ENDIF.

    CLEAR lv_domvalue.
  ENDIF.
ENDFORM.                    "check_selection_values

*&---------------------------------------------------------------------*
*&      Form  fill_single_data_objects
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_DATA_TO_MAINTAIN  text
*----------------------------------------------------------------------*
FORM fill_single_data_objects USING it_data_to_maintain TYPE zqm_t_lab_bms_maintain_data.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.

* Build data objects and adjust alv for single and multi maintenance
  obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).

* Create data object and fill it
  obj_single_mnt_data_object = obj_ui_helper->get_single_do( ).
  obj_ui_helper->fill_single_do( EXPORTING it_maintain_data = it_data_to_maintain
                                 CHANGING co_data_object = obj_single_mnt_data_object ).

  FREE obj_ui_helper.
ENDFORM.                    "fill_single_data_objects

*&---------------------------------------------------------------------*
*&      Form  fill_multi_data_objects
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_DATA_TO_MAINTAIN  text
*----------------------------------------------------------------------*
FORM fill_multi_data_objects USING it_data_to_maintain TYPE zqm_t_lab_bms_maintain_data.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.

* Build data objects and adjust alv for single and multi maintenance
  obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).

* Create data object and fill it
  obj_multi_mnt_data_object = obj_ui_helper->get_multi_do( it_maintain_data = it_data_to_maintain ).
  obj_ui_helper->fill_multi_do( EXPORTING it_maintain_data = it_data_to_maintain
                                CHANGING co_data_object = obj_multi_mnt_data_object ).

  FREE obj_ui_helper.
ENDFORM.                    "fill_multi_data_objects

*&---------------------------------------------------------------------*
*&      Form  save
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM save.
  DATA lv_popup_answer TYPE char1.
  DATA: lt_messages TYPE bapiret2_t.
  DATA obj_temp_data TYPE REF TO data.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.

  CLEAR gv_check_errors_occured.

  IF gt_data_to_maintain[] IS INITIAL.
    RETURN.
  ENDIF.

* Ask for save
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = text-q01
      text_button_1         = 'Ja'(001)
      text_button_2         = 'Nein'(002)
      display_cancel_button = abap_false
    IMPORTING
      answer                = lv_popup_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.

  IF lv_popup_answer = 2.
    RETURN.
  ENDIF.

* Read data changes and do check
  obj_single_mnt_alv->check_changed_data( ).
  obj_multi_mnt_alv->check_changed_data( ).

  IF gv_check_errors_occured = abap_true.
    RETURN.
  ENDIF.

  obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).

* Update data to maintain structure
  obj_ui_helper->update_dtm_from_single( EXPORTING io_single_maintain_data = obj_single_mnt_data_object
                                         CHANGING ct_data_to_maintain = gt_data_to_maintain ).

  obj_ui_helper->update_dtm_from_multi( EXPORTING io_multi_maintain_data = obj_multi_mnt_data_object
                                        CHANGING ct_data_to_maintain = gt_data_to_maintain ).

  obj_runtime->save_data( IMPORTING et_messages = lt_messages
                          CHANGING ct_data_to_maintain = gt_data_to_maintain ).

  READ TABLE lt_messages
  WITH KEY type = 'E'
  TRANSPORTING NO FIELDS.

  IF sy-subrc IS INITIAL.
* Warning message
    MESSAGE text-m02 TYPE 'W'.
  ELSE.
    IF sy-tcode = 'ZQM_LAB_BMS_4'.
* Show time reporting popup
      CALL SCREEN 0410
      STARTING AT 1 1.
    ENDIF.

    IF gv_workcenter_screen_number = 0240.
      p_time4  = p_time4  + 1.

      IF p_time4  = |000000|.
        p_date4 = p_date4 + 1.
      ENDIF.

      PERFORM transfer_screenvalues.
    ENDIF.

* Data saved popup message
    MESSAGE text-m01 TYPE 'I'.

* Reload data
    PERFORM execute.
    PERFORM prepare_screen.
    obj_single_mnt_alv->refresh_table_display( ).
    obj_multi_mnt_alv->refresh_table_display( ).
  ENDIF.

  FREE lt_messages.
ENDFORM.                    "save

*&---------------------------------------------------------------------*
*&      Form  add_historic_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_DATA_TO_MAINTAIN  text
*----------------------------------------------------------------------*
FORM add_historic_values CHANGING ct_data_to_maintain TYPE zqm_t_lab_bms_maintain_data.
  FIELD-SYMBOLS <wa_historic_data> TYPE zqm_s_lab_bms_maintain_data.

  LOOP AT gt_historic_data ASSIGNING <wa_historic_data>.
    READ TABLE ct_data_to_maintain
    WITH KEY date = <wa_historic_data>-date
             time = <wa_historic_data>-time
             insplot = <wa_historic_data>-insplot
             inspsample = <wa_historic_data>-inspsample
             inspoper = <wa_historic_data>-inspoper
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      INSERT <wa_historic_data> INTO TABLE ct_data_to_maintain.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "add_historic_values

*&---------------------------------------------------------------------*
*&      Form  load_header_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LV_OK_CODE text
*----------------------------------------------------------------------*
FORM load_header_data USING lv_ok_code TYPE sy-ucomm.
  DATA wa_header_data TYPE zqm_s_lab_bms_header_data.

  FIELD-SYMBOLS: <lt_data> TYPE ANY TABLE,
                 <wa_data> TYPE any,
                 <lv_linie> TYPE any,
                 <lv_insplot> TYPE any,
                 <wa_header_data> TYPE zqm_s_lab_bms_header_data.

  FREE: gt_header_data.

  IF lv_ok_code = 'HEAD_S'.
    IF obj_single_mnt_data_object IS NOT BOUND.
      RETURN.
    ENDIF.

    ASSIGN obj_single_mnt_data_object->* TO <lt_data>.
  ELSEIF lv_ok_code = 'HEAD_M'.
    IF obj_multi_mnt_data_object IS NOT BOUND.
      RETURN.
    ENDIF.

    ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
  ENDIF.

* Build header data
  LOOP AT <lt_data> ASSIGNING <wa_data>.
    ASSIGN COMPONENT 'LINIE' OF STRUCTURE <wa_data> TO <lv_linie>.
    IF sy-subrc IS INITIAL.
      wa_header_data-linie = <lv_linie>.
    ENDIF.

    ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
    IF sy-subrc IS INITIAL.
      wa_header_data-insplot = <lv_insplot>.
    ENDIF.

    APPEND wa_header_data TO gt_header_data.
  ENDLOOP.

  SORT gt_header_data BY linie insplot.
  DELETE ADJACENT DUPLICATES FROM gt_header_data COMPARING linie insplot.

* Get production types
  LOOP AT gt_header_data ASSIGNING <wa_header_data>.
    <wa_header_data>-production_type = zcl_qm_lab_bms_util=>get_production_type( iv_insplot = <wa_header_data>-insplot ).
  ENDLOOP.
ENDFORM.                    "show_header_data

*&---------------------------------------------------------------------*
*&      Form  load_time_reporting_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_time_reporting_data.
  DATA wa_time_rep_data TYPE zqm_s_lab_bms_time_rep_data.
  DATA: lv_time TYPE vgwrt,
        lv_unit TYPE vgwrteh.

  FIELD-SYMBOLS <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data.

  FREE gt_time_rep_data.

  LOOP AT gt_data_to_maintain ASSIGNING <wa_data_to_maintain>.
    wa_time_rep_data-insplot = <wa_data_to_maintain>-insplot.
    wa_time_rep_data-vornr = <wa_data_to_maintain>-inspoper.
    wa_time_rep_data-txt_oper = <wa_data_to_maintain>-txt_oper.

    zcl_qm_lab_bms_util=>get_testing_time_and_unit( EXPORTING iv_insplot  = <wa_data_to_maintain>-insplot
                                                              iv_inspoper = <wa_data_to_maintain>-inspoper
                                                    IMPORTING ev_time = lv_time
                                                              ev_unit = lv_unit ).

    wa_time_rep_data-time_unit = lv_unit.
    wa_time_rep_data-vgw01 = lv_time.

    APPEND wa_time_rep_data TO gt_time_rep_data.
    CLEAR wa_time_rep_data.
  ENDLOOP.

  CLEAR: wa_time_rep_data, lv_unit, lv_time.
ENDFORM.                    "load_time_reporting_data

*&---------------------------------------------------------------------*
*&      Form  save_time_reporting
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM save_time_reporting.
  DATA lt_messages TYPE bapiret2_t.

* Get data
  obj_time_rep_alv->check_changed_data( ).

* Save data
  lt_messages = obj_runtime->save_time_reporting( it_data = gt_time_rep_data ).

  FREE lt_messages.
ENDFORM.                    "save_time_reporting

*&---------------------------------------------------------------------*
*&      Form  show_time_reporting
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM show_time_reporting.
  DATA lt_messages TYPE bapiret2_t.
  DATA lt_messages_display TYPE esp1_message_tab_type.
  DATA lt_selected_rows TYPE lvc_t_row.
  DATA lv_insplot TYPE qibplosnr.

  FIELD-SYMBOLS: <wa_messages> TYPE bapiret2,
                 <wa_messages_display> TYPE esp1_message_wa_type,
                 <lt_data> TYPE STANDARD TABLE,
                 <wa_data> TYPE any,
                 <lv_insplot> TYPE any,
                 <wa_selected_rows> TYPE lvc_s_row.

* Get selected dataset
  IF tabstrip_workarea-activetab = 'MULTIMNT'.
    IF obj_multi_mnt_alv IS BOUND.
      obj_multi_mnt_alv->get_selected_rows( IMPORTING et_index_rows = lt_selected_rows ).
    ENDIF.

    IF obj_multi_mnt_data_object IS BOUND.
      ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
    ENDIF.
  ELSEIF tabstrip_workarea-activetab = 'SINGLEMNT'.
    IF obj_single_mnt_alv IS BOUND.
      obj_single_mnt_alv->get_selected_rows( IMPORTING et_index_rows = lt_selected_rows ).
    ENDIF.

    IF obj_single_mnt_data_object IS BOUND.
      ASSIGN obj_single_mnt_data_object->* TO <lt_data>.
    ENDIF.
  ENDIF.

  IF lines( lt_selected_rows ) <> 1.
    MESSAGE ID 'ZQM_LABORATORIES_BMS' TYPE 'E' NUMBER 016.
    RETURN.
  ELSE.
    READ TABLE lt_selected_rows
    ASSIGNING <wa_selected_rows>
    INDEX 1.
  ENDIF.

* Get dataset
  READ TABLE <lt_data>
  ASSIGNING <wa_data>
  INDEX <wa_selected_rows>-index.

* Get inspection lot
  ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
  lv_insplot = <lv_insplot>.

* Show data
  lt_messages = obj_runtime->show_time_reporting( iv_insplot = lv_insplot ).

  IF lt_messages[] IS NOT INITIAL.
    LOOP AT lt_messages ASSIGNING <wa_messages>.
      APPEND INITIAL LINE TO lt_messages_display ASSIGNING <wa_messages_display>.
      <wa_messages_display>-msgid = <wa_messages>-id.
      <wa_messages_display>-msgty = <wa_messages>-type.
      <wa_messages_display>-msgno = <wa_messages>-number.
      <wa_messages_display>-msgv1 = <wa_messages>-message_v1.
      <wa_messages_display>-msgv2 = <wa_messages>-message_v2.
      <wa_messages_display>-msgv3 = <wa_messages>-message_v3.
      <wa_messages_display>-msgv4 = <wa_messages>-message_v4.
      UNASSIGN <wa_messages_display>.
    ENDLOOP.

* Show messages
    CALL FUNCTION 'C14Z_MESSAGES_SHOW_AS_POPUP'
      TABLES
        i_message_tab = lt_messages_display.

    FREE lt_messages_display.
  ENDIF.

  CLEAR lv_insplot.
  FREE: lt_messages, lt_selected_rows.
ENDFORM.                    "show_time_reporting

*&---------------------------------------------------------------------*
*&      Form  show_additional_value_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM show_additional_value_data USING iv_row_index TYPE int4
                                      iv_column_id TYPE string.

  DATA lv_mstr_char TYPE qmstr_char.
  DATA lv_column TYPE string.
  DATA wa_data_to_maintain TYPE zqm_s_lab_bms_maintain_data.

  FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                 <wa_data> TYPE any,
                 <lv_column> TYPE any,
                 <lt_additional_value_data> TYPE zqm_t_lab_bms_value_add_data,
                 <wa_additional_value_data> TYPE zqm_s_lab_bms_value_add_data.

  IF iv_column_id NP 'VALUE_*'.
    RETURN.
  ENDIF.

  IF obj_multi_mnt_data_object IS BOUND.
    ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
  ENDIF.

  READ TABLE <lt_data>
  ASSIGNING <wa_data>
  INDEX iv_row_index.

  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  ASSIGN COMPONENT 'ADDITIONAL_VALUE_DATA' OF STRUCTURE <wa_data> TO <lt_additional_value_data>.
  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  ASSIGN COMPONENT iv_column_id OF STRUCTURE <wa_data> TO <lv_column>.
  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  lv_column = iv_column_id.
  REPLACE FIRST OCCURRENCE OF 'VALUE_' IN lv_column WITH ''.
  lv_mstr_char = lv_column.

  READ TABLE <lt_additional_value_data>
  ASSIGNING <wa_additional_value_data>
  WITH KEY mstr_char = lv_mstr_char.

  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  TRY.
      wa_data_to_maintain = zcl_qm_lab_bms_util=>get_data_mnt_from_multi( it_data_to_maintain   = gt_data_to_display
                                                                          is_multi_edit_dataset = <wa_data>
                                                                          iv_mstr_char          = lv_mstr_char ).
    CATCH zcx_qm_lab_bms_exceptions.
      MESSAGE text-e01 TYPE 'E'.
      RETURN.
  ENDTRY.

  gs_additional_value_data = <wa_additional_value_data>.
  gv_selected_row_index = iv_row_index.
  gv_historical = wa_data_to_maintain-historical.

* Show header data popup
  CALL SCREEN 0420
  STARTING AT 5 5.

  CLEAR: lv_mstr_char, lv_column.
ENDFORM.                    "show_additional_value_data

*&---------------------------------------------------------------------*
*&      Form  take_additional_value_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM take_additional_value_data.
  FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                 <wa_data> TYPE any,
                 <lt_additional_value_data> TYPE zqm_t_lab_bms_value_add_data,
                 <wa_additional_value_data> TYPE zqm_s_lab_bms_value_add_data.

  IF obj_multi_mnt_data_object IS BOUND.
    ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
  ENDIF.

  READ TABLE <lt_data>
  ASSIGNING <wa_data>
  INDEX gv_selected_row_index.

  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  ASSIGN COMPONENT 'ADDITIONAL_VALUE_DATA' OF STRUCTURE <wa_data> TO <lt_additional_value_data>.
  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  READ TABLE <lt_additional_value_data>
  ASSIGNING <wa_additional_value_data>
  WITH KEY mstr_char = gs_additional_value_data-mstr_char.

  IF sy-subrc IS NOT INITIAL.
    RETURN.
  ENDIF.

  <wa_additional_value_data>-zquantity = gs_additional_value_data-zquantity.
  <wa_additional_value_data>-ztemperature = gs_additional_value_data-ztemperature.
  <wa_additional_value_data>-ztime = gs_additional_value_data-ztime.

  CLEAR: gs_additional_value_data, gv_selected_row_index, gv_historical.
ENDFORM.                    "take_additional_value_data

*&---------------------------------------------------------------------*
*&      Form  DISPOSE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM dispose.
  IF obj_runtime IS BOUND.
    obj_runtime->dispose( ).
  ENDIF.
ENDFORM.                    "DISPOSE
