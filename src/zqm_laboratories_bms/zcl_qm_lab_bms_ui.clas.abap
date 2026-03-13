*----------------------------------------------------------------------*
*       CLASS ZCL_QM_LAB_BMS_UI DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zcl_qm_lab_bms_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_qm_lab_bms_ui .

    CONSTANTS ac_list_maintenance TYPE slwid VALUE 'LAGQM01'. "#EC NOTEXT
    CONSTANTS ac_multi_maintenance TYPE slwid VALUE 'LAGQM03'. "#EC NOTEXT
    CONSTANTS ac_single_maintenance TYPE slwid VALUE 'LAGQM02'. "#EC NOTEXT
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA at_multi_mnt_column_labels TYPE wdy_key_value_list .

    METHODS _fill_cell_information
      CHANGING
        !co_data_object TYPE REF TO data
      RAISING
        zcx_qm_lab_bms_exceptions .
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_UI IMPLEMENTATION.


  METHOD zif_qm_lab_bms_ui~create_dynamic_multi_col_label.
    DATA lv_fieldname TYPE fieldname.

    FIELD-SYMBOLS: <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_column_labels> TYPE wdy_key_value.

    FREE me->at_multi_mnt_column_labels.

    LOOP AT it_maintain_data ASSIGNING <wa_maintain_data> WHERE slwid = ac_multi_maintenance.
      LOOP AT <wa_maintain_data>-values ASSIGNING <wa_values>.
        lv_fieldname = |VALUE_{ <wa_values>-mstr_char }|.

        READ TABLE me->at_multi_mnt_column_labels
        WITH KEY key = lv_fieldname
        TRANSPORTING NO FIELDS.

        IF sy-subrc IS NOT INITIAL.
          APPEND INITIAL LINE TO me->at_multi_mnt_column_labels ASSIGNING <wa_column_labels>.
          <wa_column_labels>-key = lv_fieldname.

          IF <wa_values>-unit_text IS NOT INITIAL.
            <wa_column_labels>-value = |{ <wa_values>-description } ({ <wa_values>-unit_text })|.
          ELSE.
            <wa_column_labels>-value = <wa_values>-description.
          ENDIF.

          UNASSIGN <wa_column_labels>.
        ENDIF.

        CLEAR lv_fieldname.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~create_dynamic_multi_col_label


  METHOD zif_qm_lab_bms_ui~fill_multi_do.
    DATA: lv_fieldname_to TYPE fieldname,
          lv_fieldname_from TYPE fieldname.
    DATA wa_current_data TYPE zqm_s_lab_bms_maintain_data.
    DATA wa_additional_value_data TYPE zqm_s_lab_bms_value_add_data.

    FIELD-SYMBOLS: <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <lt_data_object> TYPE STANDARD TABLE,
                   <wa_data_object> TYPE any,
                   <lv_value_from> TYPE any,
                   <lv_value_to> TYPE any,
                   <lt_data_table> TYPE ANY TABLE.

    ASSIGN co_data_object->* TO <lt_data_object>.

    LOOP AT it_maintain_data ASSIGNING <wa_maintain_data> WHERE slwid = ac_multi_maintenance.
      LOOP AT <wa_maintain_data>-values ASSIGNING <wa_values>.
        IF wa_current_data-insplot <> <wa_maintain_data>-insplot OR wa_current_data-date <> <wa_maintain_data>-date
          OR wa_current_data-time <> <wa_maintain_data>-time OR wa_current_data-sample_type <> <wa_maintain_data>-sample_type.

          APPEND INITIAL LINE TO <lt_data_object> ASSIGNING <wa_data_object>.
          MOVE-CORRESPONDING <wa_maintain_data> TO <wa_data_object>.

          wa_current_data = <wa_maintain_data>.
        ENDIF.

        lv_fieldname_to = |VALUE_{ <wa_values>-mstr_char }|.

        ASSIGN <wa_values>-value->* TO <lv_value_from>.
        ASSIGN COMPONENT lv_fieldname_to OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.

          IF <wa_maintain_data>-historical = abap_false AND <wa_maintain_data>-locked = abap_false AND <wa_values>-read_only = abap_false.
            lv_fieldname_to = |ENABLED_{ <wa_values>-mstr_char }|.
            ASSIGN COMPONENT lv_fieldname_to OF STRUCTURE <wa_data_object> TO <lv_value_to>.
            IF sy-subrc IS INITIAL.
              <lv_value_to> = abap_true.
            ENDIF.
          ENDIF.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set additional values
        wa_additional_value_data-mstr_char = <wa_values>-mstr_char.
        wa_additional_value_data-zquantity = <wa_values>-zquantity.
        wa_additional_value_data-ztemperature = <wa_values>-ztemperature.
        wa_additional_value_data-ztime = <wa_values>-ztime.

        ASSIGN COMPONENT 'ADDITIONAL_VALUE_DATA' OF STRUCTURE <wa_data_object> TO <lt_data_table>.
        IF sy-subrc IS INITIAL.
          INSERT wa_additional_value_data INTO TABLE <lt_data_table>.
          UNASSIGN <lt_data_table>.
        ENDIF.

        CLEAR: lv_fieldname_from, lv_fieldname_to.
      ENDLOOP.
    ENDLOOP.

* Fill cell data
    me->_fill_cell_information( CHANGING co_data_object = co_data_object ).

    SORT <lt_data_object> BY ('LINIE') ('HISTORICAL') DESCENDING ('DATE') ('TIME').

    CLEAR: wa_current_data, lv_fieldname_to, lv_fieldname_from.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~fill_multi_do


  METHOD zif_qm_lab_bms_ui~fill_single_do.
    DATA lt_maintain_data_hist TYPE zqm_t_lab_bms_maintain_data.
    DATA lv_lines TYPE i.
    DATA wa_celltab TYPE lvc_s_styl.
    DATA lt_columns_customizing TYPE zqm_t_lab_bms_alv_customizing.

    FIELD-SYMBOLS: <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_maintain_data_hist> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_values_hist> TYPE zqm_s_lab_bms_measure_data,
                   <lt_data_object> TYPE STANDARD TABLE,
                   <wa_data_object> TYPE any,
                   <lv_value_from> TYPE any,
                   <lv_value_to> TYPE any,
                   <lt_celltab> TYPE lvc_t_styl,
                   <wa_columns_customizing> TYPE zqm_s_lab_bms_alv_customizing.

    ASSIGN co_data_object->* TO <lt_data_object>.

* Get colum customizing
    lt_columns_customizing = zcl_qm_lab_bms_customizing=>get_alv_colum_customizing( iv_alv_type = 1 ).

    LOOP AT it_maintain_data ASSIGNING <wa_maintain_data> WHERE historical = abap_false
                                                            AND ( slwid = ac_single_maintenance OR
                                                                  slwid = ac_list_maintenance ).
* Prepare historical data
      lt_maintain_data_hist[] = it_maintain_data[].

      DELETE lt_maintain_data_hist
      WHERE historical = abap_false
         OR ( insplot <> <wa_maintain_data>-insplot OR
              inspoper <> <wa_maintain_data>-inspoper ).

      lv_lines = lines( lt_maintain_data_hist ).

      LOOP AT <wa_maintain_data>-values ASSIGNING <wa_values>.
        APPEND INITIAL LINE TO <lt_data_object> ASSIGNING <wa_data_object>.
        MOVE-CORRESPONDING <wa_maintain_data> TO <wa_data_object>.

* Set inspchar
        ASSIGN COMPONENT 'INSPCHAR' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'INSPCHAR' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set operation text
        ASSIGN COMPONENT 'TXT_OPER' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'TXT_OPER' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set description
        ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set enabled field value
        ASSIGN COMPONENT 'ENABLED' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF sy-subrc IS INITIAL.
          IF <wa_maintain_data>-locked = abap_true OR <wa_values>-read_only = abap_true.
            <lv_value_to> = abap_false.
          ELSE.
            <lv_value_to> = abap_true.
          ENDIF.
        ENDIF.
        UNASSIGN <lv_value_to>.

* Get actual value
        ASSIGN <wa_values>-value->* TO <lv_value_from>.
        ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set last historical value
        IF lt_maintain_data_hist[] IS NOT INITIAL.
          READ TABLE lt_maintain_data_hist
          ASSIGNING <wa_maintain_data_hist>
          INDEX lv_lines.

          IF sy-subrc IS INITIAL.
            READ TABLE <wa_maintain_data_hist>-values
            ASSIGNING <wa_values_hist>
            WITH KEY inspchar = <wa_values>-inspchar.

            IF sy-subrc IS INITIAL.
* Get last value
              ASSIGN <wa_values_hist>-value->* TO <lv_value_from>.
              ASSIGN COMPONENT 'LAST_VALUE' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
              IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
                <lv_value_to> = <lv_value_from>.
              ENDIF.
              UNASSIGN: <lv_value_from>, <lv_value_to>.
            ENDIF.
          ENDIF.
        ENDIF.

* Set inspchar
        ASSIGN COMPONENT 'UNIT_TEXT' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'UNIT_TEXT' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set inspector
        ASSIGN COMPONENT 'INSPECTOR' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'INSPECTOR' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set inspection date and time
        ASSIGN COMPONENT 'INSPECTION_DATE' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'INSPECTION_DATE' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set inspector
        ASSIGN COMPONENT 'INSPECTION_TIME' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'INSPECTION_TIME' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set remark
        ASSIGN COMPONENT 'REMARK' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'REMARK' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

        ASSIGN COMPONENT 'ZQUANTITY' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'ZQUANTITY' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

        ASSIGN COMPONENT 'ZTIME' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'ZTIME' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

        ASSIGN COMPONENT 'ZTEMPERATURE' OF STRUCTURE <wa_values> TO <lv_value_from>.
        ASSIGN COMPONENT 'ZTEMPERATURE' OF STRUCTURE <wa_data_object> TO <lv_value_to>.
        IF <lv_value_from> IS ASSIGNED AND <lv_value_to> IS ASSIGNED.
          <lv_value_to> = <lv_value_from>.
        ENDIF.
        UNASSIGN: <lv_value_from>, <lv_value_to>.

* Set editable fields
        ASSIGN COMPONENT 'CELLTAB' OF STRUCTURE <wa_data_object> TO <lt_celltab>.
        IF sy-subrc IS INITIAL.
          IF <wa_maintain_data>-locked = abap_true OR <wa_values>-read_only = abap_true.
            wa_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
          ELSE.
            LOOP AT lt_columns_customizing ASSIGNING <wa_columns_customizing>.
              wa_celltab-fieldname = <wa_columns_customizing>-fieldname.

              IF <wa_columns_customizing>-editable = abap_true.
                wa_celltab-style = cl_gui_alv_grid=>mc_style_enabled.
              ELSE.
                wa_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
              ENDIF.
            ENDLOOP.
          ENDIF.

          INSERT wa_celltab INTO TABLE <lt_celltab>.
        ENDIF.
        UNASSIGN <lv_value_to>.

        UNASSIGN <wa_data_object>.
      ENDLOOP.

      FREE lt_maintain_data_hist.
      CLEAR lv_lines.
    ENDLOOP.

    SORT <lt_data_object> BY ('LINIE') ('INSPOPER') ('INSPCHAR').

    FREE lt_columns_customizing.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~fill_single_do


  METHOD zif_qm_lab_bms_ui~get_multi_column_lables.
    rt_column_labels = me->at_multi_mnt_column_labels.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_multi_column_lables


  METHOD zif_qm_lab_bms_ui~get_multi_do.
    DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
          obj_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE abap_component_tab.
    DATA lv_fieldname TYPE fieldname.
    DATA lt_maintain_data TYPE zqm_t_lab_bms_maintain_data_st.

    FIELD-SYMBOLS: <wa_components> TYPE abap_componentdescr,
                   <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data.

* Build components
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPLOT'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPLOSNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'LINIE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_LINIENR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'BALLENNR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_BALLENNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'DATE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'DATS' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'TIME'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'UZEIT' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'SAMPLE_TYPE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_ENTNAHME_PROBENART' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'PHYNR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QPHYSPRNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'HISTORICAL'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'BOOLEAN' ).

    lt_maintain_data[] = it_maintain_data[].
    SORT lt_maintain_data BY insplot inspoper.

    LOOP AT lt_maintain_data ASSIGNING <wa_maintain_data> WHERE historical = abap_false
                                                            AND slwid = ac_multi_maintenance.
      LOOP AT <wa_maintain_data>-values ASSIGNING <wa_values>.
        lv_fieldname = |VALUE_{ <wa_values>-mstr_char }|.

        READ TABLE lt_components
        WITH KEY name = lv_fieldname
        TRANSPORTING NO FIELDS.

        IF sy-subrc IS NOT INITIAL.
          APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
          <wa_components>-name = lv_fieldname.
          <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
          APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
          <wa_components>-name = |ENABLED_{ <wa_values>-mstr_char }|.
          <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'BOOLEAN' ).
          APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
          <wa_components>-name = |DD_HDNL_{ <wa_values>-mstr_char }|.
          <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'INT4' ).
        ENDIF.

        CLEAR lv_fieldname.
      ENDLOOP.
    ENDLOOP.

    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'ADDITIONAL_VALUE_DATA'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZQM_T_LAB_BMS_VALUE_ADD_DATA' ).

    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'CELLTAB'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'LVC_T_STYL' ).

* Create data object
    obj_struct_descr = cl_abap_structdescr=>create( lt_components ).
    obj_table_descr ?= cl_abap_tabledescr=>create( obj_struct_descr ).
    CREATE DATA ro_data_object TYPE HANDLE obj_table_descr.

    FREE: obj_struct_descr, obj_table_descr.
    FREE: lt_components, lt_maintain_data.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_multi_do


  METHOD zif_qm_lab_bms_ui~get_multi_fieldcat.
    DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
          obj_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE abap_compdescr_tab.
    DATA lt_columns_customizing TYPE zqm_t_lab_bms_alv_customizing.
    DATA lv_fieldname TYPE fieldname.
    DATA lv_sp_group_count TYPE i.

    FIELD-SYMBOLS: <wa_fieldcatalog> TYPE lvc_s_fcat,
                   <wa_components> TYPE abap_compdescr,
                   <wa_columns_customizing> TYPE zqm_s_lab_bms_alv_customizing,
                   <lv_field_from> TYPE any,
                   <wa_column_labels> TYPE wdy_key_value,
                   <wa_field_groups> TYPE lvc_s_sgrp.

* Get colum customizing
    lt_columns_customizing = zcl_qm_lab_bms_customizing=>get_alv_colum_customizing( iv_alv_type = 2 ).

* Get structure description
    obj_table_descr ?= cl_abap_tabledescr=>describe_by_data_ref( io_data_object ).
    obj_struct_descr ?= obj_table_descr->get_table_line_type( ).

    lt_components[] = obj_struct_descr->components[].

    LOOP AT lt_components ASSIGNING <wa_components>.
      IF <wa_components>-name NP 'VALUE_*'.
        READ TABLE lt_columns_customizing
        ASSIGNING <wa_columns_customizing>
        WITH KEY fieldname = <wa_components>-name.

        IF sy-subrc IS NOT INITIAL.
          CONTINUE.
        ENDIF.
      ENDIF.

      APPEND INITIAL LINE TO et_fieldcatalog ASSIGNING <wa_fieldcatalog>.
      <wa_fieldcatalog>-fieldname = <wa_components>-name.
      <wa_fieldcatalog>-inttype = <wa_components>-type_kind.
      <wa_fieldcatalog>-intlen = <wa_components>-length.
      <wa_fieldcatalog>-decimals = <wa_components>-decimals.

      IF <wa_components>-name NP 'VALUE_*'.
        <wa_fieldcatalog>-ref_field = <wa_columns_customizing>-ref_field.
        <wa_fieldcatalog>-ref_table = <wa_columns_customizing>-ref_table.

        IF <wa_columns_customizing>-custom_column_header = abap_true.
          <wa_fieldcatalog>-coltext = <wa_columns_customizing>-text30.
        ENDIF.

        <wa_fieldcatalog>-edit = <wa_columns_customizing>-editable.

        IF <wa_columns_customizing>-outputlen > 0.
          <wa_fieldcatalog>-outputlen = <wa_columns_customizing>-outputlen.
        ENDIF.

        IF <wa_columns_customizing>-group_values = abap_true.
          lv_sp_group_count = lv_sp_group_count + 1.

          APPEND INITIAL LINE TO et_field_groups ASSIGNING <wa_field_groups>.
          <wa_field_groups>-sp_group = lv_sp_group_count.
          <wa_field_groups>-text = |Group { lv_sp_group_count }|.
          UNASSIGN <wa_field_groups>.

          <wa_fieldcatalog>-sp_group = lv_sp_group_count.
        ENDIF.

        IF <wa_columns_customizing>-dropdown_enabled = abap_true.
          <wa_fieldcatalog>-drdn_field = 'DROP_DOWN_HANDLE'.
          <wa_fieldcatalog>-drdn_alias = abap_true.
          <wa_fieldcatalog>-checktable = '!'.
        ENDIF.
      ELSE.
        READ TABLE me->at_multi_mnt_column_labels
        ASSIGNING <wa_column_labels>
        WITH KEY key = <wa_components>-name.

        IF sy-subrc IS INITIAL.
          <wa_fieldcatalog>-coltext = <wa_column_labels>-value.
        ENDIF.

        lv_fieldname = <wa_components>-name.
        REPLACE 'VALUE' IN lv_fieldname WITH 'DD_HDNL'.

        <wa_fieldcatalog>-drdn_field = lv_fieldname.
        <wa_fieldcatalog>-drdn_alias = abap_true.
        <wa_fieldcatalog>-checktable = '!'.

        <wa_fieldcatalog>-edit = abap_true.
      ENDIF.

      CLEAR lv_fieldname.
      UNASSIGN: <wa_fieldcatalog>, <wa_columns_customizing>.
    ENDLOOP.

    CLEAR lv_sp_group_count.
    FREE: obj_struct_descr, obj_table_descr.
    FREE: lt_components, lt_columns_customizing.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_multi_fieldcat


  METHOD zif_qm_lab_bms_ui~get_multi_first_enabled_cell.
    DATA: lv_row_index TYPE int4,
          lv_cell_index TYPE int1.
    DATA lv_fieldname TYPE fieldname.

    FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                   <wa_data> TYPE any,
                   <lv_enabled> TYPE any,
                   <wa_fieldcatalog> TYPE lvc_s_fcat.

    ASSIGN io_data_object->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING <wa_data>.
      lv_row_index = sy-tabix.

      LOOP AT it_fieldcatalog ASSIGNING <wa_fieldcatalog> WHERE fieldname CP 'VALUE_*'.
        lv_fieldname = <wa_fieldcatalog>-fieldname.
        REPLACE FIRST OCCURRENCE OF 'VALUE' IN lv_fieldname WITH 'ENABLED'.

        ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_data> TO <lv_enabled>.
        IF sy-subrc IS NOT INITIAL.
          RETURN.
        ENDIF.

        IF <lv_enabled> = abap_true.
          es_row_id-index = lv_row_index.
          es_cell_id-fieldname = <wa_fieldcatalog>-fieldname.
          RETURN.
        ENDIF.

        CLEAR lv_fieldname.
      ENDLOOP.
    ENDLOOP.

    CLEAR: lv_row_index, lv_cell_index.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_multi_first_enabled_cell


  METHOD zif_qm_lab_bms_ui~get_single_do.
    DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
          obj_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE abap_component_tab.

    FIELD-SYMBOLS <wa_components> TYPE abap_componentdescr.

* Build components
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPLOT'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPLOSNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPSAMPLE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPPROBE' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPOPER'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPVORNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPCHAR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPMERKNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'TXT_OPER'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QKURZTEXT' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'DESCRIPTION'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'SAMPLE_TYPE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_ENTNAHME_PROBENART' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'LINIE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_LINIENR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'BALLENNR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_BALLENNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'DATE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'DATS' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'TIME'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'UZEIT' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'PHYNR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QPHYSPRNR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'LAST_VALUE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'VALUE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'UNIT_TEXT'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QMEASUNITT' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPECTOR'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QINSPECTOR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'REMARK'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QRES_REMAR' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPECTION_DATE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'DATS' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'INSPECTION_TIME'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'SYUZEIT' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'ZQUANTITY'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZQM_QUANTITY' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'ZTIME'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZQM_TIME' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'ZTEMPERATURE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZQM_TEMPERATURE' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'DROP_DOWN_HANDLE'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'INT4' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'ENABLED'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'BOOLEAN' ).
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = 'CELLTAB'.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'LVC_T_STYL' ).

* Create data object
    obj_struct_descr = cl_abap_structdescr=>create( lt_components ).
    obj_table_descr ?= cl_abap_tabledescr=>create( obj_struct_descr ).
    CREATE DATA ro_data_object TYPE HANDLE obj_table_descr.

    FREE: obj_struct_descr, obj_table_descr.
    FREE lt_components.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_single_do


  METHOD zif_qm_lab_bms_ui~get_single_fieldcat.
    DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
          obj_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE abap_compdescr_tab.
    DATA lt_columns_customizing TYPE zqm_t_lab_bms_alv_customizing.
    DATA lv_sp_group_count TYPE i.

    FIELD-SYMBOLS: <wa_fieldcatalog> TYPE lvc_s_fcat,
                   <wa_components> TYPE abap_compdescr,
                   <wa_columns_customizing> TYPE zqm_s_lab_bms_alv_customizing,
                   <wa_field_groups> TYPE lvc_s_sgrp.

* Get colum customizing
    lt_columns_customizing = zcl_qm_lab_bms_customizing=>get_alv_colum_customizing( iv_alv_type = 1 ).

* Get structure description
    obj_table_descr ?= cl_abap_tabledescr=>describe_by_data_ref( io_data_object ).
    obj_struct_descr ?= obj_table_descr->get_table_line_type( ).

    lt_components[] = obj_struct_descr->components[].

    LOOP AT lt_components ASSIGNING <wa_components>.
      READ TABLE lt_columns_customizing
      ASSIGNING <wa_columns_customizing>
      WITH KEY fieldname = <wa_components>-name.

      IF sy-subrc IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO et_fieldcatalog ASSIGNING <wa_fieldcatalog>.
      <wa_fieldcatalog>-fieldname = <wa_components>-name.
      <wa_fieldcatalog>-inttype = <wa_components>-type_kind.
      <wa_fieldcatalog>-intlen = <wa_components>-length.
      <wa_fieldcatalog>-decimals = <wa_components>-decimals.
      <wa_fieldcatalog>-edit = <wa_columns_customizing>-editable.
      <wa_fieldcatalog>-ref_field = <wa_columns_customizing>-ref_field.
      <wa_fieldcatalog>-ref_table = <wa_columns_customizing>-ref_table.

      IF <wa_columns_customizing>-custom_column_header = abap_true.
        <wa_fieldcatalog>-coltext = <wa_columns_customizing>-text30.
      ENDIF.

      IF <wa_columns_customizing>-field_position > 0.
        <wa_fieldcatalog>-col_pos = <wa_columns_customizing>-field_position.
      ENDIF.

      IF <wa_columns_customizing>-outputlen > 0.
        <wa_fieldcatalog>-outputlen = <wa_columns_customizing>-outputlen.
      ENDIF.

      IF <wa_columns_customizing>-group_values = abap_true.
        lv_sp_group_count = lv_sp_group_count + 1.

        APPEND INITIAL LINE TO et_field_groups ASSIGNING <wa_field_groups>.
        <wa_field_groups>-sp_group = lv_sp_group_count.
        <wa_field_groups>-text = |Group { lv_sp_group_count }|.
        UNASSIGN <wa_field_groups>.

        <wa_fieldcatalog>-sp_group = lv_sp_group_count.
      ENDIF.

      IF <wa_columns_customizing>-dropdown_enabled = abap_true.
        <wa_fieldcatalog>-drdn_field = 'DROP_DOWN_HANDLE'.
        <wa_fieldcatalog>-drdn_alias = abap_true.
        <wa_fieldcatalog>-checktable = '!'.
      ENDIF.

      UNASSIGN: <wa_fieldcatalog>, <wa_columns_customizing>.
    ENDLOOP.

    CLEAR lv_sp_group_count.
    FREE: lt_components, lt_columns_customizing.
    FREE: obj_struct_descr, obj_table_descr.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_single_fieldcat


  METHOD zif_qm_lab_bms_ui~get_single_first_enabled_cell.
    DATA: lv_row_index TYPE int4,
          lv_cell_index TYPE int1.

    FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                   <wa_data> TYPE any,
                   <lv_enabled> TYPE any.

    ASSIGN io_data_object->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING <wa_data>.
      lv_row_index = sy-tabix.

      ASSIGN COMPONENT 'ENABLED' OF STRUCTURE <wa_data> TO <lv_enabled>.
      IF sy-subrc IS NOT INITIAL.
        RETURN.
      ENDIF.

      IF <lv_enabled> = abap_true.
        es_row_id-index = lv_row_index.
        es_cell_id-fieldname = 'VALUE'.
        EXIT.
      ENDIF.
    ENDLOOP.

    CLEAR: lv_row_index, lv_cell_index.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~get_single_first_enabled_cell


  METHOD zif_qm_lab_bms_ui~set_multi_dd.
    DATA lv_fieldname TYPE fieldname.
    DATA lt_dd_values TYPE lvc_t_drop.
    DATA lt_dd_alias_values TYPE lvc_t_dral.
    DATA lt_handled_fields TYPE wdy_key_value_list.
    DATA lv_handle_count TYPE int4.

    FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                   <wa_data> TYPE any,
                   <lv_insplot> TYPE any,
                   <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <lv_dd_hdnl> TYPE any,
                   <wa_handled_fields> TYPE wdy_key_value,
                   <wa_field_values> TYPE wdy_key_value,
                   <wa_dd_values> TYPE lvc_s_drop,
                   <wa_dd_alias_values> TYPE lvc_s_dral.

    ASSIGN io_data_object->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING <wa_data>.
      UNASSIGN <lv_insplot>.
      ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.

      IF <lv_insplot> IS NOT ASSIGNED.
        RETURN.
      ENDIF.

      LOOP AT it_maintain_data ASSIGNING <wa_maintain_data> WHERE insplot = <lv_insplot>.
        LOOP AT <wa_maintain_data>-values ASSIGNING <wa_values>.
          UNASSIGN <lv_dd_hdnl>.
          CLEAR lv_fieldname.

          lv_fieldname = |DD_HDNL_{ <wa_values>-mstr_char }|.

* Check if field exist in data structure
          ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_data> TO <lv_dd_hdnl>.
          IF sy-subrc IS NOT INITIAL.
            CONTINUE.
          ENDIF.

* Check if field is allredy handled
          READ TABLE lt_handled_fields
          ASSIGNING <wa_handled_fields>
          WITH KEY key = lv_fieldname.

          IF sy-subrc IS INITIAL.
            <lv_dd_hdnl> = <wa_handled_fields>-value.
            CONTINUE.
          ENDIF.

          IF <wa_values>-field_values[] IS NOT INITIAL.
            lv_handle_count = lv_handle_count + 1.

            LOOP AT <wa_values>-field_values ASSIGNING <wa_field_values>.
              APPEND INITIAL LINE TO lt_dd_values ASSIGNING <wa_dd_values>.
              <wa_dd_values>-handle = lv_handle_count.
              <wa_dd_values>-value = <wa_field_values>-key.
              UNASSIGN <wa_dd_values>.

*          APPEND INITIAL LINE TO lt_dd_alias_values ASSIGNING <wa_dd_alias_values>.
*          <wa_dd_alias_values>-handle = lv_handle_count.
*          <wa_dd_alias_values>-int_value = <wa_field_values>-key.
*          <wa_dd_alias_values>-value = <wa_field_values>-value.
*          UNASSIGN <wa_dd_alias_values>.
            ENDLOOP.

            <lv_dd_hdnl> = lv_handle_count.

            APPEND INITIAL LINE TO lt_handled_fields ASSIGNING <wa_handled_fields>.
            <wa_handled_fields>-key = lv_fieldname.
            <wa_handled_fields>-value = lv_handle_count.
            UNASSIGN <wa_handled_fields>.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    IF lt_dd_values[] IS NOT INITIAL.
      io_grid_instance->set_drop_down_table( it_drop_down       = lt_dd_values
                                             it_drop_down_alias = lt_dd_alias_values ).
    ENDIF.

    FREE: lt_handled_fields, lt_dd_values, lt_dd_alias_values.
    CLEAR: lv_handle_count.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~set_multi_dd


  METHOD zif_qm_lab_bms_ui~set_single_dd.
    DATA lv_handle_count TYPE int4.
    DATA lt_dd_values TYPE lvc_t_drop.
    DATA lt_dd_alias_values TYPE lvc_t_dral.

    FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                   <wa_data> TYPE any,
                   <lv_insplot> TYPE any,
                   <lv_inspoper> TYPE any,
                   <lv_inspchar> TYPE any,
                   <lv_inspsample> TYPE any,
                   <lv_drop_down_handle> TYPE any,
                   <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_field_values> TYPE wdy_key_value,
                   <wa_dd_values> TYPE lvc_s_drop,
                   <wa_dd_alias_values> TYPE lvc_s_dral.

    ASSIGN io_data_object->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING <wa_data>.
      ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
      ASSIGN COMPONENT 'INSPOPER' OF STRUCTURE <wa_data> TO <lv_inspoper>.
      ASSIGN COMPONENT 'INSPCHAR' OF STRUCTURE <wa_data> TO <lv_inspchar>.
      ASSIGN COMPONENT 'INSPSAMPLE' OF STRUCTURE <wa_data> TO <lv_inspsample>.
      ASSIGN COMPONENT 'DROP_DOWN_HANDLE' OF STRUCTURE <wa_data> TO <lv_drop_down_handle>.

      IF <lv_insplot> IS NOT ASSIGNED OR <lv_inspoper> IS NOT ASSIGNED OR <lv_inspchar> IS NOT ASSIGNED OR <lv_drop_down_handle> IS NOT ASSIGNED.
        RETURN.
      ENDIF.

      READ TABLE it_maintain_data
      ASSIGNING <wa_maintain_data>
      WITH KEY insplot = <lv_insplot>
               inspoper = <lv_inspoper>
               inspsample = <lv_inspsample>.

      READ TABLE <wa_maintain_data>-values
      ASSIGNING <wa_values>
      WITH KEY inspchar = <lv_inspchar>.

      IF <wa_values>-field_values[] IS NOT INITIAL.
        lv_handle_count = lv_handle_count + 1.

        LOOP AT <wa_values>-field_values ASSIGNING <wa_field_values>.
          APPEND INITIAL LINE TO lt_dd_values ASSIGNING <wa_dd_values>.
          <wa_dd_values>-handle = lv_handle_count.
          <wa_dd_values>-value = <wa_field_values>-key.
          UNASSIGN <wa_dd_values>.

*        APPEND INITIAL LINE TO lt_dd_alias_values ASSIGNING <wa_dd_alias_values>.
*        <wa_dd_alias_values>-handle = lv_handle_count.
*        <wa_dd_alias_values>-int_value = <wa_field_values>-key.
*        <wa_dd_alias_values>-value = <wa_field_values>-value.
*        UNASSIGN <wa_dd_alias_values>.
        ENDLOOP.

        <lv_drop_down_handle> = lv_handle_count.
      ENDIF.

      UNASSIGN: <lv_insplot>, <lv_inspoper>, <lv_inspchar>, <lv_drop_down_handle>, <wa_maintain_data>, <wa_values>, <lv_inspsample>.
    ENDLOOP.

    IF lt_dd_values[] IS NOT INITIAL.
      io_grid_instance->set_drop_down_table( it_drop_down       = lt_dd_values
                                             it_drop_down_alias = lt_dd_alias_values ).
    ENDIF.

    CLEAR: lv_handle_count.
    FREE: lt_dd_values, lt_dd_alias_values.
  ENDMETHOD.                    "zif_qm_lab_bms_ui~set_single_dd


method ZIF_QM_LAB_BMS_UI~UPDATE_DTM_FROM_MULTI.
  data: obj_struct_descr type ref to cl_abap_structdescr,
        obj_table_descr type ref to cl_abap_tabledescr.
  data lt_components type abap_compdescr_tab.
  data lv_fieldname type fieldname.
  data lv_mstr_char type qmstr_char.
  data lv_field_prefix type string.

  field-symbols: <wa_data_to_maintain> type zqm_s_lab_bms_maintain_data,
                 <wa_values> type zqm_s_lab_bms_measure_data,
                 <wa_components> type abap_compdescr,
                 <lt_data> type any table,
                 <wa_data> type any,
                 <lt_additional_value_data> type zqm_t_lab_bms_value_add_data,
                 <wa_additional_value_data> type zqm_s_lab_bms_value_add_data,
                 <lv_insplot> type any,
                 <lv_value_from> type any,
                 <lv_value_to> type any,
                 <lv_zquantity> type any,
                 <lv_ztime> type any,
                 <lv_ztemperature> type any.

  assign io_multi_maintain_data->* to <lt_data>.

  if <lt_data>[] is initial.
    return.
  endif.

* Get structure description
  obj_table_descr ?= cl_abap_tabledescr=>describe_by_data_ref( io_multi_maintain_data ).
  obj_struct_descr ?= obj_table_descr->get_table_line_type( ).

  lt_components[] = obj_struct_descr->components[].

  loop at <lt_data> assigning <wa_data> where ('HISTORICAL = abap_false').
    assign component 'INSPLOT' of structure <wa_data> to <lv_insplot>.
    assign component 'ADDITIONAL_VALUE_DATA' of structure <wa_data> to <lt_additional_value_data>.

    loop at lt_components assigning <wa_components> where name cp 'VALUE_*'.
      unassign: <wa_additional_value_data>, <wa_values>, <wa_data_to_maintain>.

      lv_fieldname = <wa_components>-name.
      split lv_fieldname at '_' into lv_field_prefix lv_mstr_char.

      read table <lt_additional_value_data>
      assigning <wa_additional_value_data>
      with key ('MSTR_CHAR') = lv_mstr_char.

      if sy-subrc is not initial.
* This char doesn`t exist on this inspection lot
        continue.
      endif.

      loop at ct_data_to_maintain assigning <wa_data_to_maintain> where slwid   = zcl_qm_lab_bms_ui=>ac_multi_maintenance
                                                                    and insplot = <lv_insplot>.
        read table <wa_data_to_maintain>-values
        assigning <wa_values>
        with key mstr_char = lv_mstr_char.

        if sy-subrc is initial.
          exit.
        endif.
      endloop.

      assign component 'ZQUANTITY' of structure <wa_additional_value_data> to <lv_zquantity>.
      assign component 'ZTIME' of structure <wa_additional_value_data> to <lv_ztime>.
      assign component 'ZTEMPERATURE' of structure <wa_additional_value_data> to <lv_ztemperature>.
      assign component <wa_components>-name of structure <wa_data> to <lv_value_from>.

      if <wa_values> is assigned.
        assign <wa_values>-value->* to <lv_value_to>.

        <lv_value_to> = <lv_value_from>.
        <wa_values>-zquantity = <lv_zquantity>.
        <wa_values>-ztemperature = <lv_ztemperature>.
        <wa_values>-ztime = <lv_ztime>.
      endif.

      clear: lv_fieldname, lv_mstr_char, lv_field_prefix.
    endloop.
  endloop.

  free lt_components.
  free: obj_struct_descr, obj_table_descr.
endmethod.


METHOD zif_qm_lab_bms_ui~update_dtm_from_single.
  FIELD-SYMBOLS: <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data,
                 <wa_values> TYPE zqm_s_lab_bms_measure_data,
                 <lt_data> TYPE ANY TABLE,
                 <wa_data> TYPE any,
                 <lv_insplot> TYPE any,
                 <lv_inspoper> TYPE any,
                 <lv_inspchar> TYPE any,
                 <lv_value_from> TYPE any,
                 <lv_value_to> TYPE any,
                 <lv_inspector> TYPE any,
                 <lv_zquantity> TYPE any,
                 <lv_ztime> TYPE any,
                 <lv_ztemperature> TYPE any.

  CONSTANTS: co_not_any_inspector TYPE string VALUE 'N.A.'.

  ASSIGN io_single_maintain_data->* TO <lt_data>.

  LOOP AT <lt_data> ASSIGNING <wa_data>.
    ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
    ASSIGN COMPONENT 'INSPOPER' OF STRUCTURE <wa_data> TO <lv_inspoper>.
    ASSIGN COMPONENT 'INSPCHAR' OF STRUCTURE <wa_data> TO <lv_inspchar>.
    ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa_data> TO <lv_value_from>.
    ASSIGN COMPONENT 'INSPECTOR' OF STRUCTURE <wa_data> TO <lv_inspector>.
    ASSIGN COMPONENT 'ZQUANTITY' OF STRUCTURE <wa_data> TO <lv_zquantity>.
    ASSIGN COMPONENT 'ZTIME' OF STRUCTURE <wa_data> TO <lv_ztime>.
    ASSIGN COMPONENT 'ZTEMPERATURE' OF STRUCTURE <wa_data> TO <lv_ztemperature>.

    READ TABLE ct_data_to_maintain
    ASSIGNING <wa_data_to_maintain>
    WITH KEY insplot = <lv_insplot>
             inspoper = <lv_inspoper>.

    IF sy-subrc IS INITIAL.
      READ TABLE <wa_data_to_maintain>-values
      ASSIGNING <wa_values>
      WITH KEY inspchar = <lv_inspchar>.

      IF sy-subrc IS INITIAL.
        ASSIGN <wa_values>-value->* TO <lv_value_to>.

        <lv_value_to> = <lv_value_from>.
        <wa_values>-inspector = <lv_inspector>.
        <wa_values>-zquantity = <lv_zquantity>.
        <wa_values>-ztemperature = <lv_ztemperature>.
        <wa_values>-ztime = <lv_ztime>.

        IF <wa_values>-inspector IS INITIAL.
          <wa_values>-inspector = co_not_any_inspector.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMETHOD.


  METHOD _fill_cell_information.
    DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
          obj_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE abap_compdescr_tab.
    DATA wa_celltab TYPE lvc_s_styl.
    DATA lv_fieldname TYPE fieldname.

    FIELD-SYMBOLS: <lt_data_object> TYPE STANDARD TABLE,
                   <wa_data_object> TYPE any,
                   <lv_enabled_field> TYPE any,
                   <lt_celltab> TYPE lvc_t_styl,
                   <wa_components> TYPE abap_compdescr.

* Get structure description
    obj_table_descr ?= cl_abap_tabledescr=>describe_by_data_ref( co_data_object ).
    obj_struct_descr ?= obj_table_descr->get_table_line_type( ).

    lt_components[] = obj_struct_descr->components[].

    DELETE lt_components
    WHERE name = 'CELLTAB'.

    ASSIGN co_data_object->* TO <lt_data_object>.

    LOOP AT <lt_data_object> ASSIGNING <wa_data_object>.
      ASSIGN COMPONENT 'CELLTAB' OF STRUCTURE <wa_data_object> TO <lt_celltab>.

      LOOP AT lt_components ASSIGNING <wa_components>.
        wa_celltab-fieldname = <wa_components>-name.

        IF <wa_components>-name CP 'VALUE_*'.
          lv_fieldname = <wa_components>-name.
          REPLACE FIRST OCCURRENCE OF 'VALUE' IN lv_fieldname WITH 'ENABLED'.

          ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_data_object> TO <lv_enabled_field>.
          IF sy-subrc IS INITIAL.
            IF <lv_enabled_field> = abap_true.
              wa_celltab-style = cl_gui_alv_grid=>mc_style_enabled.
            ELSE.
              wa_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
            ENDIF.
          ENDIF.

          CLEAR lv_fieldname.
        ELSE.
          wa_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
        ENDIF.

        INSERT wa_celltab INTO TABLE <lt_celltab>.

        CLEAR wa_celltab.
      ENDLOOP.

      UNASSIGN <lt_celltab>.
    ENDLOOP.

    FREE lt_components.
    FREE: obj_struct_descr, obj_table_descr.
  ENDMETHOD.                    "_fill_cell_information
ENDCLASS.
