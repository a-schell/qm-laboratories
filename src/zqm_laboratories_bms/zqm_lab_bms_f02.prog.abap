*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_BMS_F02
*&---------------------------------------------------------------------*
FORM set_workcenter_button_icon.
  IF ra_workcenter[] IS INITIAL.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = 'ICON_ENTER_MORE'
        text   = ''
      IMPORTING
        result = but_workcenter.
  ELSE.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = 'ICON_DISPLAY_MORE'
        text   = ''
      IMPORTING
        result = but_workcenter.
  ENDIF.
ENDFORM.                    "set_workcenter_button_icon

*&---------------------------------------------------------------------*
*&      Form  set_line_button_icon
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_line_button_icon.
  IF ra_line[] IS INITIAL.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = 'ICON_ENTER_MORE'
        text   = ''
      IMPORTING
        result = but_line.
  ELSE.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = 'ICON_DISPLAY_MORE'
        text   = ''
      IMPORTING
        result = but_line.
  ENDIF.
ENDFORM.                    "set_line_button_icon

*&---------------------------------------------------------------------*
*&      Form  handle_tabstrip
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LV_OK_CODE text
*----------------------------------------------------------------------*
FORM handle_tabstrip USING lv_ok_code TYPE sy-ucomm.
* Set active tab
  tabstrip_workarea-activetab = lv_ok_code.
ENDFORM.                    "handle_tabstrip

*&---------------------------------------------------------------------*
*&      Form  init_screen_0310
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_screen_0310.
  CREATE OBJECT obj_single_mnt_alv_container
    EXPORTING
      container_name = 'CUSTCTRL_SINGLE_MAINTAIN_ALV'.

  CREATE OBJECT obj_single_mnt_alv
    EXPORTING
      i_parent = obj_single_mnt_alv_container.

  CREATE OBJECT obj_single_event_receiver.
  SET HANDLER obj_single_event_receiver->handle_data_changed FOR obj_single_mnt_alv.
ENDFORM.                    "init_screen_0310

*&---------------------------------------------------------------------*
*&      Form  init_screen_0320
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_screen_0320.
  IF obj_multi_mnt_alv_container IS BOUND.
    obj_multi_mnt_alv_container->free( ).
    FREE obj_multi_mnt_alv_container.
  ENDIF.

  IF obj_multi_mnt_alv IS BOUND.
    obj_multi_mnt_alv->free( ).
    FREE obj_multi_mnt_alv.
  ENDIF.

  CREATE OBJECT obj_multi_mnt_alv_container
    EXPORTING
      container_name = 'CUSTCTRL_MULTI_MAINTAIN_ALV'.

  CREATE OBJECT obj_multi_mnt_alv
    EXPORTING
      i_parent = obj_multi_mnt_alv_container.

  CREATE OBJECT obj_multi_event_receiver.
  SET HANDLER obj_multi_event_receiver->handle_data_changed FOR obj_multi_mnt_alv.
  SET HANDLER obj_multi_event_receiver->handle_double_click FOR obj_multi_mnt_alv.
ENDFORM.                    "init_screen_0320

*&---------------------------------------------------------------------*
*&      Form  init_screen_0400
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_screen_0400.
  IF obj_header_data_alv_container IS BOUND.
    obj_header_data_alv_container->free( ).
    FREE obj_header_data_alv_container.
  ENDIF.

  IF obj_header_data_alv IS BOUND.
    obj_header_data_alv->free( EXCEPTIONS cntl_error = 1 ).
    FREE obj_header_data_alv.
  ENDIF.

  CREATE OBJECT obj_header_data_alv_container
    EXPORTING
      container_name = 'CUSTCTRL_HEADER_DATA_ALV'.

  CREATE OBJECT obj_header_data_alv
    EXPORTING
      i_parent = obj_header_data_alv_container.
ENDFORM.                    "init_screen_0400

*&---------------------------------------------------------------------*
*&      Form  INIT_SCREEN_0410
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_screen_0410.
  IF obj_time_rep_alv_container IS BOUND.
    obj_time_rep_alv_container->free( ).
    FREE obj_time_rep_alv_container.
  ENDIF.

  IF obj_time_rep_alv IS BOUND.
    obj_time_rep_alv->free( EXCEPTIONS cntl_error = 1 ).
    FREE obj_time_rep_alv.
  ENDIF.

  CREATE OBJECT obj_time_rep_alv_container
    EXPORTING
      container_name = 'CUSTCTRL_TIME_REPORTING_ALV'.

  CREATE OBJECT obj_time_rep_alv
    EXPORTING
      i_parent = obj_time_rep_alv_container.
ENDFORM.                    " INIT_SCREEN_0410


*&---------------------------------------------------------------------*
*&      Form  init_grids
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM prepare_screen.
  DATA lv_ok_code TYPE sy-ucomm.

  FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

* Build data to display
  gt_data_to_display[] = gt_data_to_maintain[].

  IF gv_show_historic_values = abap_true.
    PERFORM add_historic_values CHANGING gt_data_to_display.
  ENDIF.

* Create single maintain object and init ALV grid
  PERFORM fill_single_data_objects USING gt_data_to_display.

  IF obj_single_mnt_data_object IS BOUND.
    PERFORM init_single_mnt_alv.
  ENDIF.

* Create multi maintain object and init ALV grid
  PERFORM fill_multi_data_objects USING gt_data_to_display.

  IF obj_multi_mnt_data_object IS BOUND.
    PERFORM init_multi_mnt_alv.
  ENDIF.

* Activate multi edit tabstrib if no data in single edit available
  IF obj_single_mnt_data_object IS BOUND.
    ASSIGN obj_single_mnt_data_object->* TO <lt_data>.
    IF <lt_data>[] IS INITIAL.
      IF obj_multi_mnt_data_object IS BOUND.
        ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
        IF <lt_data>[] IS NOT INITIAL.
          lv_ok_code = 'MULTIMNT'.

          PERFORM handle_tabstrip USING lv_ok_code.

          CLEAR lv_ok_code.
        ENDIF.
      ENDIF.
    ELSE.
      lv_ok_code = 'SINGLEMNT'.
      PERFORM handle_tabstrip USING lv_ok_code.
      CLEAR lv_ok_code.
    ENDIF.
  ENDIF.

* Check if locked operations in result
  READ TABLE gt_data_to_display
  WITH KEY locked = abap_true
  TRANSPORTING NO FIELDS.

  IF sy-subrc IS INITIAL.
    MESSAGE w007(zqm_laboratories_bms).
  ENDIF.
ENDFORM.                    "init_grids

*&---------------------------------------------------------------------*
*&      Form  init_single_mnt_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_single_mnt_alv.
  DATA obj_exception TYPE REF TO zcx_qm_lab_bms_exceptions.
  DATA wa_layout TYPE lvc_s_layo.
  DATA lv_message TYPE string.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.
  DATA lt_excluded_functions TYPE ui_functions.

  FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE.

  FREE: gt_single_fieldcatalog, gt_single_field_groups.

  TRY.
      ASSIGN obj_single_mnt_data_object->* TO <lt_data>.

      obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).

      obj_ui_helper->get_single_fieldcat( EXPORTING io_data_object = obj_single_mnt_data_object
                                          IMPORTING et_fieldcatalog = gt_single_fieldcatalog
                                                    et_field_groups = gt_single_field_groups ).

* Set dropdowns
      obj_ui_helper->set_single_dd( io_data_object   = obj_single_mnt_data_object
                                    it_maintain_data = gt_data_to_display
                                    io_grid_instance = obj_single_mnt_alv ).

*      wa_layout-cwidth_opt = abap_true.
      wa_layout-stylefname = 'CELLTAB'.

      lt_excluded_functions = zcl_qm_lab_bms_util=>manage_alv_toolbar_functions( io_alv_instance = obj_single_mnt_alv ).

      obj_single_mnt_alv->set_table_for_first_display( EXPORTING is_layout = wa_layout
                                                                 it_toolbar_excluding = lt_excluded_functions
                                                                 it_special_groups    = gt_single_field_groups
                                                       CHANGING it_outtab            = <lt_data>
                                                                it_fieldcatalog      = gt_single_fieldcatalog ).
    CATCH zcx_qm_lab_bms_exceptions INTO obj_exception.
      lv_message = obj_exception->get_text( ).
      MESSAGE lv_message TYPE 'E'.

      CLEAR lv_message.
      FREE obj_exception.
  ENDTRY.

  CLEAR wa_layout.
  FREE obj_ui_helper.
  FREE lt_excluded_functions.
ENDFORM.                    "init_single_mnt_alv

*&---------------------------------------------------------------------*
*&      Form  init_multi_mnt_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_multi_mnt_alv.
  DATA obj_exception TYPE REF TO zcx_qm_lab_bms_exceptions.
  DATA wa_layout TYPE lvc_s_layo.
  DATA lv_message TYPE string.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.
  DATA lt_excluded_functions TYPE ui_functions.

  FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE.

  TRY.
      FREE: gt_multi_field_groups, gt_multi_fieldcatalog.

      ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.

      obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).
      obj_ui_helper->create_dynamic_multi_col_label( it_maintain_data = gt_data_to_display ).

      obj_ui_helper->get_multi_fieldcat( EXPORTING io_data_object = obj_multi_mnt_data_object
                                         IMPORTING et_fieldcatalog = gt_multi_fieldcatalog
                                                   et_field_groups = gt_multi_field_groups ).

* Set dropdowns
      obj_ui_helper->set_multi_dd( io_data_object   = obj_multi_mnt_data_object
                                   it_maintain_data = gt_data_to_display
                                   io_grid_instance = obj_multi_mnt_alv ).

      wa_layout-stylefname = 'CELLTAB'.
*      wa_layout-cwidth_opt = abap_true.

      lt_excluded_functions = zcl_qm_lab_bms_util=>manage_alv_toolbar_functions( io_alv_instance = obj_multi_mnt_alv ).

      obj_multi_mnt_alv->set_table_for_first_display( EXPORTING is_layout = wa_layout
                                                                it_toolbar_excluding = lt_excluded_functions
                                                                it_special_groups    = gt_multi_field_groups
                                                      CHANGING it_outtab            = <lt_data>
                                                               it_fieldcatalog      = gt_multi_fieldcatalog ).

      zcl_qm_lab_bms_util=>manage_alv_toolbar_functions( io_alv_instance = obj_multi_mnt_alv ).
    CATCH zcx_qm_lab_bms_exceptions INTO obj_exception.
      lv_message = obj_exception->get_text( ).
      MESSAGE lv_message TYPE 'E'.

      CLEAR lv_message.
      FREE obj_exception.
  ENDTRY.

  CLEAR wa_layout.
  FREE obj_ui_helper.
  FREE lt_excluded_functions.
ENDFORM.                    "init_multi_mnt_alv

*&---------------------------------------------------------------------*
*&      Form  init_header_data_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_header_data_alv.
  DATA wa_layout TYPE lvc_s_layo.
  DATA lt_fieldcatalog TYPE lvc_t_fcat.

* Set layout
  wa_layout-cwidth_opt = abap_true.
  wa_layout-stylefname = 'CELLTAB'.

* Get fieldcatalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'ZQM_S_LAB_BMS_HEADER_DATA'
    CHANGING
      ct_fieldcat            = lt_fieldcatalog
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

* Init alv
  obj_header_data_alv->set_table_for_first_display( EXPORTING is_layout = wa_layout
                                                    CHANGING it_outtab            = gt_header_data
                                                             it_fieldcatalog      = lt_fieldcatalog ).

  FREE lt_fieldcatalog.
  CLEAR wa_layout.
ENDFORM.                    "init_header_data_alv

*&---------------------------------------------------------------------*
*&      Form  init_time_rep_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_time_rep_alv.
  DATA wa_layout TYPE lvc_s_layo.
  DATA lt_fieldcatalog TYPE lvc_t_fcat.

  FIELD-SYMBOLS <wa_fieldcatalog> TYPE lvc_s_fcat.

* Set layout
  wa_layout-cwidth_opt = abap_true.
  wa_layout-stylefname = 'CELLTAB'.

* Get fieldcatalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'ZQM_S_LAB_BMS_TIME_REP_DATA'
    CHANGING
      ct_fieldcat            = lt_fieldcatalog
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  LOOP AT lt_fieldcatalog ASSIGNING <wa_fieldcatalog>.
    IF <wa_fieldcatalog>-fieldname = 'AMOUNT'.
      <wa_fieldcatalog>-edit = abap_true.
      <wa_fieldcatalog>-no_zero = abap_true.
    ENDIF.
  ENDLOOP.

* Init alv
  obj_time_rep_alv->set_table_for_first_display( EXPORTING is_layout = wa_layout
                                                 CHANGING it_outtab            = gt_time_rep_data
                                                          it_fieldcatalog      = lt_fieldcatalog ).

  CREATE OBJECT obj_time_rep_event_receiver.
  SET HANDLER obj_time_rep_event_receiver->handle_data_changed FOR obj_time_rep_alv.

  FREE lt_fieldcatalog.
  CLEAR wa_layout.
ENDFORM.                    "init_time_rep_alv

*&---------------------------------------------------------------------*
*&      Form  init_grid_focus
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_grid_focus.
  DATA obj_ui_helper TYPE REF TO zif_qm_lab_bms_ui.
  DATA: wa_row_id TYPE lvc_s_row,
        wa_cell_id TYPE lvc_s_col.

  obj_ui_helper = zcl_qm_lab_bms_factory=>get_ui_helper( ).

  IF tabstrip_workarea-activetab = 'MULTIMNT'.
    IF obj_multi_mnt_alv IS BOUND AND obj_multi_mnt_data_object IS BOUND.
      obj_ui_helper->get_multi_first_enabled_cell( EXPORTING io_data_object  = obj_multi_mnt_data_object
                                                             it_fieldcatalog = gt_multi_fieldcatalog
                                                   IMPORTING es_row_id  = wa_row_id
                                                             es_cell_id = wa_cell_id ).

      obj_multi_mnt_alv->set_current_cell_via_id( is_row_id    = wa_row_id
                                                  is_column_id = wa_cell_id ).

      cl_gui_alv_grid=>set_focus( obj_multi_mnt_alv ).
    ENDIF.
  ELSEIF tabstrip_workarea-activetab = 'SINGLEMNT'.
    IF obj_single_mnt_alv IS BOUND AND obj_single_mnt_data_object IS BOUND.
      obj_ui_helper->get_single_first_enabled_cell( EXPORTING io_data_object = obj_single_mnt_data_object
                                                              it_fieldcatalog = gt_single_fieldcatalog
                                                    IMPORTING es_row_id  = wa_row_id
                                                              es_cell_id = wa_cell_id ).

      obj_single_mnt_alv->set_current_cell_via_id( is_row_id    = wa_row_id
                                                   is_column_id = wa_cell_id ).

      cl_gui_alv_grid=>set_focus( obj_single_mnt_alv ).
    ENDIF.
  ENDIF.

  CLEAR: wa_row_id, wa_cell_id.
  FREE obj_ui_helper.
ENDFORM.                    "init_grid_focus

*&---------------------------------------------------------------------*
*&      Form  show_attachment_popup
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LV_OK_CODE text
*----------------------------------------------------------------------*
FORM show_attachment_popup USING lv_ok_code TYPE sy-ucomm.
  DATA lt_selected_rows TYPE lvc_t_row.
  DATA wa_object TYPE borident.
  DATA wa_selected_column TYPE lvc_s_col.
  DATA lv_selected_row TYPE i.
  DATA lv_index TYPE i.
  DATA lv_operation TYPE qibpvornr.
  DATA lv_display_mode TYPE sgs_rwmod.
  DATA wa_data_to_maintain TYPE zqm_s_lab_bms_maintain_data.
  DATA lv_fielname TYPE lvc_fname.
  DATA lv_mstr_char TYPE qmstr_char.

  FIELD-SYMBOLS: <wa_messages> TYPE bapiret2,
                 <lt_data> TYPE STANDARD TABLE,
                 <wa_data> TYPE any,
                 <wa_selected_rows> TYPE lvc_s_row,
                 <lv_insplot> TYPE any,
                 <lv_inspsample> TYPE any,
                 <lv_inspoper> TYPE any.

  CONSTANTS co_bustype TYPE swo_objtyp VALUE 'BUS204503'.

  CASE lv_ok_code.
    WHEN 'ATTA_S'.
      IF obj_single_mnt_alv IS BOUND.
        obj_single_mnt_alv->get_selected_rows( IMPORTING et_index_rows = lt_selected_rows ).
      ENDIF.

      IF obj_single_mnt_data_object IS BOUND.
        ASSIGN obj_single_mnt_data_object->* TO <lt_data>.
      ENDIF.

      READ TABLE lt_selected_rows
      ASSIGNING <wa_selected_rows>
      INDEX 1.

      IF lines( lt_selected_rows ) <> 1.
        MESSAGE ID 'ZQM_LABORATORIES_BMS' TYPE 'E' NUMBER 016.
        RETURN.
      ENDIF.

      lv_index = <wa_selected_rows>-index.
    WHEN 'ATTA_M'.
      IF obj_multi_mnt_alv IS BOUND.
        obj_multi_mnt_alv->get_current_cell( IMPORTING e_row         = lv_selected_row
                                                        es_col_id    = wa_selected_column ).

        IF wa_selected_column-fieldname NP 'VALUE_*'.
          MESSAGE ID 'ZQM_LABORATORIES_BMS' TYPE 'E' NUMBER 020.
          RETURN.
        ENDIF.

        lv_index = lv_selected_row.
      ENDIF.

      IF obj_multi_mnt_data_object IS BOUND.
        ASSIGN obj_multi_mnt_data_object->* TO <lt_data>.
      ENDIF.
  ENDCASE.

* Get dataset
  READ TABLE <lt_data>
  ASSIGNING <wa_data>
  INDEX lv_index.

* Get inspection lot fields
  CASE lv_ok_code.
    WHEN 'ATTA_S'.
      ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
      ASSIGN COMPONENT 'INSPSAMPLE' OF STRUCTURE <wa_data> TO <lv_inspsample>.
      ASSIGN COMPONENT 'INSPOPER' OF STRUCTURE <wa_data> TO <lv_inspoper>.

      lv_display_mode = 'E'.
    WHEN 'ATTA_M'.
      ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
      ASSIGN lv_operation TO <lv_inspoper>.

* Adapt fieldname and remove prefix
      lv_fielname = wa_selected_column-fieldname.
      REPLACE FIRST OCCURRENCE OF 'VALUE_' IN lv_fielname WITH ''.
      lv_mstr_char = lv_fielname.

      TRY.
          wa_data_to_maintain = zcl_qm_lab_bms_util=>get_data_mnt_from_multi( it_data_to_maintain   = gt_data_to_display
                                                                              is_multi_edit_dataset = <wa_data>
                                                                              iv_mstr_char          = lv_mstr_char ).
        CATCH zcx_qm_lab_bms_exceptions.
          MESSAGE text-e02 TYPE 'E'.
          RETURN.
      ENDTRY.

      READ TABLE wa_data_to_maintain-values
      WITH KEY mstr_char = lv_fielname
      TRANSPORTING NO FIELDS.

      IF sy-subrc IS INITIAL.
        lv_operation = wa_data_to_maintain-inspoper.
        ASSIGN COMPONENT 'INSPSAMPLE' OF STRUCTURE wa_data_to_maintain TO <lv_inspsample>.
      ENDIF.
  ENDCASE.

  CASE lv_ok_code.
    WHEN 'ATTA_S'.
      lv_display_mode = 'E'.
    WHEN 'ATTA_M'.
      IF wa_data_to_maintain-historical = abap_true.
        lv_display_mode = 'D'.
      ELSE.
        lv_display_mode = 'E'.
      ENDIF.
  ENDCASE.

  IF <lv_inspsample> IS INITIAL.
    MESSAGE ID 'ZQM_LABORATORIES_BMS' TYPE 'E' NUMBER 019.
    RETURN.
  ENDIF.

  wa_object-objkey = |{ <lv_insplot> }{ <lv_inspoper> }{ <lv_inspsample> }|.
  wa_object-objtype = co_bustype.

  CALL FUNCTION 'GOS_EXECUTE_SERVICE'
    EXPORTING
      ip_service       = 'VIEW_ATTA'
      is_object        = wa_object
      ip_no_commit     = ' '
      ip_popup         = 'X'
      ip_rwmod         = lv_display_mode
    EXCEPTIONS
      execution_failed = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  FREE lt_selected_rows.
  CLEAR: wa_object, lv_display_mode, wa_data_to_maintain, lv_mstr_char, lv_fielname.
ENDFORM.                    "open_attachment_popup

*&---------------------------------------------------------------------*
*&      Form  tranfer_screenvalues
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM transfer_screenvalues.
  CASE gv_workcenter_screen_number.
    WHEN 0200.
      ra_line[] = s_line[].
      ra_workcenter[] = s_work[].
      gv_sample_type = p_smpl.
      gv_date = p_date.
      gv_time = p_time.
      gv_werk = p_werk.
      gv_show_historic_values = p_hist.

    WHEN 0210.
      gv_insplot = p_insp.
      ra_workcenter[] = s_work1[].
      gv_sample_type = p_smpl1.
      gv_date = p_date1.
      gv_time = p_time1.
      gv_show_historic_values = p_hist1.

    WHEN 0220.
      gv_werk = p_werk2.
      gv_ballen_id = p_balid2.
      ra_workcenter[] = s_work2[].
      gv_sample_type = p_smpl2.
      gv_date = p_date2.
      gv_time = p_time2.
      gv_show_historic_values = p_hist2.

    WHEN 0230.
      gv_phynr = p_phynr.
      gv_date = p_date3.
      gv_time = p_time3.
      gv_show_historic_values = p_hist3.

    WHEN 0240.
      gv_werk = p_werk4.
      gv_ballen_id = p_balid4.
      ra_workcenter[] = s_work4[].
      ra_line[] = s_line4[].
      gv_sample_type = p_smpl4.
      gv_date = p_date4.
      gv_time = p_time4.
      gv_show_historic_values = p_hist4.
      gv_include_date_in_search = p_dtinc4.
  ENDCASE.
ENDFORM.                    "tranfer_screenvalues

*&---------------------------------------------------------------------*
*&      Form  set_cursor
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_cursor.
  CASE gv_workcenter_screen_number.
    WHEN 0200.
      SET CURSOR FIELD s_line.

    WHEN 0210.
      SET CURSOR FIELD p_insp.

    WHEN 0220.
      SET CURSOR FIELD p_balid2.

    WHEN 0230.
      SET CURSOR FIELD p_phynr.

    WHEN 0240.
      SET CURSOR FIELD p_balid4.
  ENDCASE.
ENDFORM.                    "set_cursor
