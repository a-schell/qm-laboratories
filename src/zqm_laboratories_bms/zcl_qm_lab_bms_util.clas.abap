class ZCL_QM_LAB_BMS_UTIL definition
  public
  final
  create public .

public section.

  class-methods COPY_INSPLOT_KEY_FIELDS
    importing
      !IV_IDENT_KEY type QSLWBEZ
      !IS_SOURCE_STRUCTURE type BAPI2045L4
    changing
      !CS_TARGET_STRUCTURE type ANY
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods COPY_SAMPLE_FIELDS
    importing
      !IV_IDENT_KEY type QSLWBEZ
      !IS_SOURCE_STRUCTURE type BAPI2045D3
    changing
      !CS_TARGET_STRUCTURE type ANY
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_CHAR_REQUIREMENTS
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IV_INSPCHAR type QIBPMERKNR
    exporting
      !ES_CHAR_REQUIREMENTS type ZQM_S_LAB_BMS_CHARREQUIREMENTS
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_CODE_GROUP
    importing
      !IV_SEL_SET type QSEL_SET
      !IV_PLANT type QSEL_SET_P
      !IV_CATALOG_TYPE type QCAT_TYPE
    returning
      value(RV_CODE_GROUP) type QCODEGRP
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_DATA_MNT_FROM_MULTI
    importing
      !IT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA
      !IS_MULTI_EDIT_DATASET type ANY
      !IV_MSTR_CHAR type QMSTR_CHAR
    returning
      value(RS_DATA_TO_MAINTAIN) type ZQM_S_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_DEFAULT_SEL_VALUES
    exporting
      !EV_PLANT type XUVALUE18
      !EV_WORKCENTER type XUVALUE18
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_FIELD_VALUES
    importing
      !IV_WERK type WERKS_D
      !IV_KATALOGART type QKATART
      !IV_AUSWAHLMGE type QAUSWAHLMG
    returning
      value(RT_FIELD_VALUES) type WDY_KEY_VALUE_LIST
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_LINE
    importing
      !IV_INSPLOT type QIBPLOSNR
    returning
      value(RV_LINIENR) type ZBMS_LINIENR
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_MAINTENANCE_TYPE
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    returning
      value(RV_SLWID) type SLWID
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_PHYSICAL_SAMPLE
    importing
      !IV_INSPLOT type QIBPLOSNR
    returning
      value(RV_SAMPLE_NUMBER) type QPHYSPRNR
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_PRODUCTION_TYPE
    importing
      !IV_INSPLOT type QIBPLOSNR
    returning
      value(RV_TYPE) type ZBMS_LEN_PTYPE_24
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_SAMPLE_WHERE_CLAUSE
    importing
      !IO_KEY_STRUCTURE type ref to DATA
    returning
      value(RV_CLAUSE) type STRING
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  type-pools ABAP .
  class-methods GET_TABLE_FIELDS
    importing
      !IV_TABNAME type DDOBJNAME
      !IV_USE_TABNAME_PREFIX type ABAP_BOOL default ABAP_FALSE
    returning
      value(RT_FIELDS) type STRING_TABLE .
  class-methods GET_TESTING_TIME_AND_UNIT
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    exporting
      !EV_UNIT type VGWRTEH
      !EV_TIME type VGWRT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods MANAGE_ALV_TOOLBAR_FUNCTIONS
    importing
      !IO_ALV_INSTANCE type ref to CL_GUI_ALV_GRID
    returning
      value(RT_EXCLUDED_FUNCTIONS) type UI_FUNCTIONS
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
protected section.
private section.

  types:
    BEGIN OF ts_maintenance_type,
          insplot TYPE qibplosnr,
          inspoper TYPE qibpvornr,
          slwid TYPE slwid,
         END OF ts_maintenance_type .
  types:
    tt_maintenance_type TYPE SORTED TABLE OF ts_maintenance_type WITH UNIQUE KEY insplot inspoper .
  types:
    BEGIN OF ts_field_values,
          werk TYPE werks_d,
          spras TYPE langu,
          katalogart TYPE qkatart,
          auswahlmge TYPE qauswahlmg,
          values TYPE wdy_key_value_list,
         END OF ts_field_values .
  types:
    tt_field_values TYPE SORTED TABLE OF ts_field_values WITH UNIQUE KEY werk spras katalogart auswahlmge .
  types:
    BEGIN OF ts_linie,
          insplot TYPE qibplosnr,
          zzlinienr TYPE zbms_linienr,
         END OF ts_linie .
  types:
    tt_linie TYPE SORTED TABLE OF ts_linie WITH UNIQUE KEY insplot .

  class-data AT_CHAR_REQUIREMENTS type ZQM_T_LAB_BMS_CHARREQUIREMENTS .
  class-data AT_FIELD_VALUES_BUFFER type TT_FIELD_VALUES .
  class-data AT_LINIE_BUFFER type TT_LINIE .
  class-data AT_MAINTENANCE_TYPE_BUFFER type TT_MAINTENANCE_TYPE .
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_UTIL IMPLEMENTATION.


METHOD copy_insplot_key_fields.
  DATA lt_operations_mapping TYPE zqm_t_lab_bms_inspop_mapping.

  FIELD-SYMBOLS: <wa_operations_mapping> TYPE zqm_s_lab_bms_inspop_mapping,
                 <lv_value_to> TYPE any,
                 <lv_value_from> TYPE any,
                 <wa_target_strucuture> TYPE any.

  ASSIGN cs_target_structure TO <wa_target_strucuture>.

* Get operations mapping
  lt_operations_mapping = zcl_qm_lab_bms_customizing=>get_insp_operation_mapping( iv_ident_key = iv_ident_key ).

  LOOP AT lt_operations_mapping ASSIGNING <wa_operations_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_insp_point.
    ASSIGN COMPONENT <wa_operations_mapping>-target_field OF STRUCTURE is_source_structure TO <lv_value_from>.
    ASSIGN COMPONENT <wa_operations_mapping>-source_field OF STRUCTURE <wa_target_strucuture> TO <lv_value_to>.
    IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
      <lv_value_to> = <lv_value_from>.
    ENDIF.
    UNASSIGN: <lv_value_to>, <lv_value_from>.
  ENDLOOP.

  FREE lt_operations_mapping.
ENDMETHOD.


METHOD copy_sample_fields.
  DATA lt_operations_mapping TYPE zqm_t_lab_bms_inspop_mapping.

  FIELD-SYMBOLS: <wa_operations_mapping> TYPE zqm_s_lab_bms_inspop_mapping,
                 <lv_value_to> TYPE any,
                 <lv_value_from> TYPE any,
                 <wa_target_strucuture> TYPE any.

  ASSIGN cs_target_structure TO <wa_target_strucuture>.

* Get operations mapping
  lt_operations_mapping = zcl_qm_lab_bms_customizing=>get_insp_operation_mapping( iv_ident_key = iv_ident_key ).

  LOOP AT lt_operations_mapping ASSIGNING <wa_operations_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_sample.
    ASSIGN COMPONENT <wa_operations_mapping>-target_field OF STRUCTURE is_source_structure TO <lv_value_from>.
    ASSIGN COMPONENT <wa_operations_mapping>-source_field OF STRUCTURE <wa_target_strucuture> TO <lv_value_to>.
    IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
      <lv_value_to> = <lv_value_from>.
    ENDIF.
    UNASSIGN: <lv_value_to>, <lv_value_from>.
  ENDLOOP.

  FREE lt_operations_mapping.
ENDMETHOD.


METHOD get_char_requirements.
  DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.
  DATA wa_char_requirements_ext TYPE zqm_s_lab_bms_charrequirements.

  FIELD-SYMBOLS: <wa_char_requirements_ext> TYPE zqm_s_lab_bms_charrequirements,
                 <wa_char_requirements> TYPE bapi2045d1.

  READ TABLE at_char_requirements
  ASSIGNING <wa_char_requirements_ext>
  WITH KEY insplot  = iv_insplot
           inspoper = iv_inspoper
           inspchar = iv_inspchar.

  IF sy-subrc IS NOT INITIAL.
    CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
      EXPORTING
        insplot                = iv_insplot
        inspoper               = iv_inspoper
        read_char_requirements = abap_true
*       CHAR_FILTER_NO         = '1   '
*       CHAR_FILTER_TCODE      = 'QE11'
*       MAX_INSPPOINTS         = 100
*       INSPPOINT_FROM         = 0
      TABLES
        char_requirements      = lt_char_requirements.

    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_laboratories
        EXPORTING
          textid = zcx_qm_laboratories=>no_char_requ_found.
    ENDIF.

    LOOP AT lt_char_requirements ASSIGNING <wa_char_requirements>.
      wa_char_requirements_ext-insplot  = <wa_char_requirements>-insplot.
      wa_char_requirements_ext-inspoper = <wa_char_requirements>-inspoper.
      wa_char_requirements_ext-inspchar = <wa_char_requirements>-inspchar.
      wa_char_requirements_ext-mstr_char = <wa_char_requirements>-mstr_char.

      IF <wa_char_requirements>-psel_set1 IS NOT INITIAL.
        wa_char_requirements_ext-fieldname = 'CODE1'.
        wa_char_requirements_ext-code_grp_fieldname = 'CODE_GRP1'.
        wa_char_requirements_ext-sel_set = <wa_char_requirements>-sel_set1.
        wa_char_requirements_ext-sel_set_p = <wa_char_requirements>-psel_set1.
        wa_char_requirements_ext-cat_type = <wa_char_requirements>-cat_type1.

        wa_char_requirements_ext-code_group = get_code_group( iv_sel_set      = <wa_char_requirements>-sel_set1
                                                              iv_plant        = <wa_char_requirements>-psel_set1
                                                              iv_catalog_type = <wa_char_requirements>-cat_type1 ).
      ELSE.
        wa_char_requirements_ext-fieldname = 'MEAN_VALUE'.
      ENDIF.

      INSERT wa_char_requirements_ext INTO TABLE at_char_requirements.

      CLEAR: wa_char_requirements_ext.
    ENDLOOP.

    READ TABLE at_char_requirements
    ASSIGNING <wa_char_requirements_ext>
    WITH KEY insplot  = iv_insplot
             inspoper = iv_inspoper
             inspchar = iv_inspchar.
  ENDIF.

  IF <wa_char_requirements_ext> IS ASSIGNED.
    es_char_requirements = <wa_char_requirements_ext>.
  ENDIF.

  FREE: lt_char_requirements.
ENDMETHOD.


METHOD get_code_group.
* Get catalog from database
  SELECT SINGLE codegruppe
  FROM qpac
  INTO rv_code_group
  WHERE werks = iv_plant
    AND katalogart = iv_catalog_type
    AND auswahlmge = iv_sel_set
    AND gueltigab <= sy-datum.
ENDMETHOD.


METHOD get_data_mnt_from_multi.
  FIELD-SYMBOLS: <lv_insplot> TYPE any,
                 <lv_linie> TYPE any,
                 <lv_ballennr> TYPE any,
                 <lv_date> TYPE any,
                 <lv_time> TYPE any,
                 <lv_sample_type> TYPE any,
                 <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data.

  ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE is_multi_edit_dataset TO <lv_insplot>.
  ASSIGN COMPONENT 'LINIE' OF STRUCTURE is_multi_edit_dataset TO <lv_linie>.
  ASSIGN COMPONENT 'BALLENNR' OF STRUCTURE is_multi_edit_dataset TO <lv_ballennr>.
  ASSIGN COMPONENT 'DATE' OF STRUCTURE is_multi_edit_dataset TO <lv_date>.
  ASSIGN COMPONENT 'TIME' OF STRUCTURE is_multi_edit_dataset TO <lv_time>.
  ASSIGN COMPONENT 'SAMPLE_TYPE' OF STRUCTURE is_multi_edit_dataset TO <lv_sample_type>.

  IF <lv_insplot> IS NOT ASSIGNED OR  <lv_linie> IS NOT ASSIGNED OR <lv_ballennr> IS NOT ASSIGNED OR
     <lv_date> IS NOT ASSIGNED OR <lv_time> IS NOT ASSIGNED OR <lv_sample_type> IS NOT ASSIGNED.

    RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
      EXPORTING
        textid = zcx_qm_lab_bms_exceptions=>not_a_multi_edit_dataset.
  ENDIF.

  LOOP AT it_data_to_maintain ASSIGNING <wa_data_to_maintain> WHERE slwid       = zcl_qm_lab_bms_ui=>ac_multi_maintenance
                                                                AND date        = <lv_date>
                                                                AND time        = <lv_time>
                                                                AND insplot     = <lv_insplot>
                                                                AND linie       = <lv_linie>
                                                                AND sample_type = <lv_sample_type>
                                                                AND ballennr    = <lv_ballennr>.

    READ TABLE <wa_data_to_maintain>-values
    WITH KEY mstr_char = iv_mstr_char
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS INITIAL.
      rs_data_to_maintain = <wa_data_to_maintain>.
      RETURN.
    ENDIF.
  ENDLOOP.

  RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
    EXPORTING
      textid = zcx_qm_lab_bms_exceptions=>no_dataset_found.
ENDMETHOD.


METHOD get_default_sel_values.
  DATA lt_return TYPE bapiret2_t.
  DATA lt_parameter TYPE rssbr_t_badi_parameter.

  FIELD-SYMBOLS <wa_parameter> TYPE bapiparam.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username      = sy-uname
      cache_results = 'X'
    TABLES
      parameter     = lt_parameter
      return        = lt_return.

  READ TABLE lt_parameter
  ASSIGNING <wa_parameter>
  WITH KEY parid = 'WRK'.

  IF sy-subrc IS INITIAL.
    ev_plant = <wa_parameter>-parva.
  ENDIF.

  READ TABLE lt_parameter
  ASSIGNING <wa_parameter>
  WITH KEY parid = 'QAP'.

  IF sy-subrc IS INITIAL.
    ev_workcenter = <wa_parameter>-parva.
  ENDIF.

  FREE: lt_parameter, lt_return.
ENDMETHOD.


METHOD get_field_values.
  DATA wa_field_values TYPE wdy_key_value.
  DATA lt_qpct TYPE STANDARD TABLE OF qpct.
  DATA lv_langu TYPE langu.
  DATA wa_field_values_buffer TYPE ts_field_values.

  FIELD-SYMBOLS: <wa_qpct> TYPE qpct,
                 <wa_field_values_buffer> TYPE ts_field_values.

  DO 2 TIMES.
    IF sy-index = 1.
      lv_langu = sy-langu.
    ELSE.
      lv_langu = 'EN'.
    ENDIF.

* Check buffer table
    READ TABLE at_field_values_buffer
    ASSIGNING <wa_field_values_buffer>
    WITH KEY werk = iv_werk
             spras = lv_langu
             katalogart = iv_katalogart
             auswahlmge = iv_auswahlmge.

    IF sy-subrc IS INITIAL.
      rt_field_values = <wa_field_values_buffer>-values.
      RETURN.
    ENDIF.

* Get catalog values from database
    SELECT *
    FROM qpct AS a
    INNER JOIN qpac AS b
    ON b~katalogart = a~katalogart
    AND b~codegruppe = a~codegruppe
    AND b~code = a~code
    INTO CORRESPONDING FIELDS OF TABLE lt_qpct
    WHERE b~werks = iv_werk
      AND b~katalogart = iv_katalogart
      AND b~auswahlmge = iv_auswahlmge
      AND b~gueltigab <= sy-datum
      AND a~sprache = lv_langu.

    IF sy-subrc IS INITIAL.
      EXIT.
    ENDIF.
  ENDDO.

  IF sy-subrc IS INITIAL.
    LOOP AT lt_qpct ASSIGNING <wa_qpct>.
      wa_field_values-key = <wa_qpct>-code.
      wa_field_values-value = <wa_qpct>-code.
*      wa_field_values-value = <wa_qpct>-kurztext.
      INSERT wa_field_values INTO TABLE rt_field_values.
      CLEAR wa_field_values.
    ENDLOOP.

    READ TABLE rt_field_values
    WITH KEY key = ''
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      wa_field_values-key = ''.
      wa_field_values-value = ''.
      INSERT wa_field_values INTO rt_field_values INDEX 1.
      CLEAR wa_field_values.
    ENDIF.
  ENDIF.

* Add values to buffer
  wa_field_values_buffer-werk = iv_werk.
  wa_field_values_buffer-spras = lv_langu.
  wa_field_values_buffer-katalogart = iv_katalogart.
  wa_field_values_buffer-auswahlmge = iv_auswahlmge.
  wa_field_values_buffer-values = rt_field_values.

  INSERT wa_field_values_buffer INTO TABLE at_field_values_buffer.

  FREE lt_qpct.
  CLEAR: lv_langu, wa_field_values, wa_field_values_buffer.
ENDMETHOD.


METHOD get_line.
  DATA wa_linie_buffer TYPE ts_linie.

  FIELD-SYMBOLS <wa_linie_buffer> TYPE ts_linie.

* Search buffer
  READ TABLE at_linie_buffer
  ASSIGNING <wa_linie_buffer>
  WITH KEY insplot = iv_insplot.

  IF sy-subrc IS INITIAL.
    rv_linienr = <wa_linie_buffer>-zzlinienr.
    RETURN.
  ENDIF.

* Get line
  SELECT SINGLE zzlinienr
  FROM qals
  INTO rv_linienr
   WHERE prueflos = iv_insplot.

* Add to buffer
  wa_linie_buffer-insplot = iv_insplot.
  wa_linie_buffer-zzlinienr = rv_linienr.

  INSERT wa_linie_buffer INTO TABLE at_linie_buffer.

  CLEAR wa_linie_buffer.
ENDMETHOD.


METHOD get_maintenance_type.
  DATA wa_afvc TYPE afvc.
  DATA: lv_plnty TYPE plnty,
        lv_plnnr TYPE plnnr,
        lv_plnkn TYPE plnkn.
  DATA wa_maintenance_type TYPE ts_maintenance_type.
  DATA lv_index TYPE int1.

  FIELD-SYMBOLS <wa_maintenance_type> TYPE ts_maintenance_type.

* Try to find value in buffer table
  READ TABLE at_maintenance_type_buffer
  ASSIGNING <wa_maintenance_type>
  WITH KEY insplot = iv_insplot
           inspoper = iv_inspoper.

  IF sy-subrc IS INITIAL.
    rv_slwid = <wa_maintenance_type>-slwid.
    RETURN.
  ENDIF.

  SELECT SINGLE a~plnty
                a~plnnr
                a~zaehl
                a~vplty
                a~vplnr
  INTO CORRESPONDING FIELDS OF wa_afvc
  FROM afvc AS a
  JOIN qals AS b
    ON b~aufpl = a~aufpl
  WHERE b~prueflos = iv_insplot
    AND a~vornr = iv_inspoper.

  DO 2 TIMES.
    lv_index = lv_index + 1.

    CASE lv_index.
      WHEN 1.
        IF wa_afvc-vplnr IS NOT INITIAL.
          lv_plnty = wa_afvc-vplty.
          lv_plnnr = wa_afvc-vplnr.
          lv_plnkn = wa_afvc-zaehl.
        ELSE.
          CONTINUE.
        ENDIF.
      WHEN 2.
        lv_plnty = wa_afvc-plnty.
        lv_plnnr = wa_afvc-plnnr.
        lv_plnkn = wa_afvc-zaehl.
    ENDCASE.

    SELECT slwid
    INTO rv_slwid
    FROM plpo
    WHERE plnty = lv_plnty
      AND plnnr = lv_plnnr
      AND plnkn = lv_plnkn
    ORDER BY plnty
             plnnr
             zaehl DESCENDING.

      EXIT.
    ENDSELECT.

    IF rv_slwid IS NOT INITIAL.
* Add to buffer table
      wa_maintenance_type-insplot = iv_insplot.
      wa_maintenance_type-inspoper = iv_inspoper.
      wa_maintenance_type-slwid = rv_slwid.

      INSERT wa_maintenance_type INTO TABLE at_maintenance_type_buffer.
      RETURN.

      CLEAR wa_maintenance_type.
    ENDIF.
  ENDDO.

  CLEAR: wa_afvc, lv_plnty, lv_plnnr, lv_index, lv_plnkn.
ENDMETHOD.


METHOD get_physical_sample.
  IF iv_insplot IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
      EXPORTING
        textid = zcx_qm_lab_bms_exceptions=>insplot_missing.
  ENDIF.

* Find physical sample number
  SELECT SINGLE phynr
  INTO rv_sample_number
  FROM qprs
  WHERE plos2 = iv_insplot.
ENDMETHOD.


METHOD get_production_type.
  DATA wa_qals TYPE qals.

* Get qals data
  SELECT SINGLE zzbms_materialnr
                zzbms_farbe
                zzbms_umreifung_char1
                zzbms_avivage
                zzbms_len_ptype_stelle18
                zzbms_len_ptype_stelle19
                zzbms_len_ptype_stelle20
                zzbms_material_variante_prod
  INTO CORRESPONDING FIELDS OF wa_qals
  FROM qals
  WHERE prueflos = iv_insplot.

* Calculate production type
  zcl_bms_len_util=>mapp_8flds_to_ptype24( EXPORTING i_bmsmatnr    = wa_qals-zzbms_materialnr
                                                     i_farbe       = wa_qals-zzbms_farbe
                                                     i_umreif      = wa_qals-zzbms_umreifung_char1
                                                     i_avivage     = wa_qals-zzbms_avivage
                                                     i_ptype_s18   = wa_qals-zzbms_len_ptype_stelle18
                                                     i_ptype_s19   = wa_qals-zzbms_len_ptype_stelle19
                                                     i_ptype_s20   = wa_qals-zzbms_len_ptype_stelle20
                                                     i_prodvariant = wa_qals-zzbms_material_variante_prod
                                           IMPORTING e_ptype_24 = rv_type ).

  CLEAR wa_qals.
ENDMETHOD.


METHOD get_sample_where_clause.
  DATA obj_struct TYPE REF TO cl_abap_structdescr.
  DATA lt_components TYPE abap_component_tab.

  FIELD-SYMBOLS: <wa_key_structure> TYPE any,
                 <lv_field> TYPE any,
                 <wa_components> TYPE abap_componentdescr.

  ASSIGN io_key_structure->* TO <wa_key_structure>.

* Get fields of structure to determine user fields
  obj_struct ?= cl_abap_structdescr=>describe_by_data( p_data = <wa_key_structure> ).
  lt_components = obj_struct->get_components( ).

  LOOP AT lt_components ASSIGNING <wa_components>.
    IF sy-tabix > 1.
      rv_clause = |{ rv_clause } and |.
    ENDIF.

    ASSIGN COMPONENT <wa_components>-name OF STRUCTURE <wa_key_structure> TO <lv_field>.

    rv_clause = |{ rv_clause } { <wa_components>-name } = '{ <lv_field> }'|.

    UNASSIGN <lv_field>.
  ENDLOOP.

  CONDENSE rv_clause.

  FREE obj_struct.
  FREE lt_components.
ENDMETHOD.


METHOD get_table_fields.
  DATA lt_dfies TYPE dfies_tab.
  DATA lv_fieldname TYPE string.

  FIELD-SYMBOLS <wa_dfies> TYPE dfies.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname   = iv_tabname
    TABLES
      dfies_tab = lt_dfies.

  LOOP AT lt_dfies ASSIGNING <wa_dfies>.
    IF iv_use_tabname_prefix = abap_true.
      lv_fieldname = |{ <wa_dfies>-tabname }~{ <wa_dfies>-fieldname }|.
    ELSE.
      lv_fieldname = <wa_dfies>-fieldname.
    ENDIF.

    APPEND lv_fieldname TO rt_fields.
    CLEAR lv_fieldname.
  ENDLOOP.

  FREE lt_dfies.
ENDMETHOD.


METHOD get_testing_time_and_unit.
  DATA wa_afvc TYPE afvc.
  DATA: lv_plnty TYPE plnty,
        lv_plnnr TYPE plnnr,
        lv_plnkn TYPE plnkn.
  DATA lv_index TYPE int1.

  SELECT SINGLE *
  INTO CORRESPONDING FIELDS OF wa_afvc
  FROM afvc AS a
  JOIN qals AS b
    ON b~aufpl = a~aufpl
  WHERE b~prueflos = iv_insplot
    AND a~vornr = iv_inspoper.

  DO 2 TIMES.
    lv_index = lv_index + 1.

    CASE lv_index.
      WHEN 1.
        IF wa_afvc-vplnr IS NOT INITIAL.
          lv_plnty = wa_afvc-vplty.
          lv_plnkn = wa_afvc-plnkn.
          lv_plnnr = wa_afvc-vplnr.
        ELSE.
          CONTINUE.
        ENDIF.
      WHEN 2.
        lv_plnty = wa_afvc-plnty.
        lv_plnkn = wa_afvc-plnkn.
        lv_plnnr = wa_afvc-plnnr.
    ENDCASE.

    SELECT SINGLE vge01
                  vgw01
    INTO (ev_unit, ev_time)
    FROM plpo
    WHERE plnty = lv_plnty
      AND plnnr = lv_plnnr
      AND plnkn = lv_plnkn.

    IF ev_unit IS INITIAL.
      ev_unit = 'MIN'.
    ENDIF.

    IF ev_time IS NOT INITIAL.
      RETURN.
    ENDIF.
  ENDDO.

  CLEAR: wa_afvc, lv_plnty, lv_plnnr, lv_plnkn, lv_index.
ENDMETHOD.


METHOD manage_alv_toolbar_functions.
  FIELD-SYMBOLS <wa_excluded_functions> TYPE ui_func.

  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_sum.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_detail.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_check.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_refresh.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_cut.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_copy.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_insert_row.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_append_row.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_delete_row.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_copy_row.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_loc_undo.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_find.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_print.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_views.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_mb_export.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_mb_sum.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_mb_paste.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_graph.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_fc_info.
  APPEND INITIAL LINE TO rt_excluded_functions ASSIGNING <wa_excluded_functions>.
  <wa_excluded_functions> = cl_gui_alv_grid=>mc_mb_variant.
ENDMETHOD.
ENDCLASS.
