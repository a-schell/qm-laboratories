*----------------------------------------------------------------------*
*       CLASS ZCL_QM_LAB_BMS_RUNTIME DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zcl_qm_lab_bms_runtime DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_qm_lab_bms_runtime .

    TYPES:
      BEGIN OF  ts_components.
            INCLUDE TYPE abap_componentdescr.
    TYPES: fieldtext TYPE string.
    TYPES:   END OF ts_components .

    TYPES:
      tt_components TYPE STANDARD TABLE OF ts_components WITH KEY name .

    TYPES: tt_tq79 TYPE SORTED TABLE OF tq79 WITH UNIQUE KEY slwbez.
  PROTECTED SECTION.
private section.

  class-data AT_CHAR_REQUIREMENTS type ZQM_T_LABORATORIES_CHARREQU .
  data AT_CURRENT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA .
  data AT_QALS_BUFFER type QALS_TAB .
  class-data AT_TQ79_BUFFER type TT_TQ79 .

  methods _BUILD_KEY_STRUCTURE
    importing
      !IS_HEADER_DATA type ZQM_S_LAB_BMS_HEAD_DATA
    returning
      value(RO_KEY_DATA) type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  type-pools ABAP .
  methods _CHECK_DATA_TO_MAINTAIN
    importing
      !IS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
      !IV_IS_LINE_REQUIRED type ABAP_BOOL
      !IV_WRITE_APPL_LOG type ABAP_BOOL default ABAP_TRUE
    returning
      value(RV_ERROR) type ABAP_BOOL
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _CREATE_VALUE_DATA
    importing
      !IS_HEADER_DATA type ZQM_S_LAB_BMS_HEAD_DATA
    returning
      value(RT_VALUES) type ZQM_T_LAB_BMS_MEASURE_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _DO_CALCULATIONS
    importing
      !IS_INSP_POINT type BAPI2045L4
      !IS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
    exporting
      !ET_MESSAGES type BAPIRET2_T
    changing
      !CT_SAMPLE_RESULTS type RPLM_TT_BAPI2045D3
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _FILL_KEY_STRUCTURE
    importing
      !IS_HEADER_DATA type ZQM_S_LAB_BMS_HEAD_DATA
    changing
      !CO_KEY_STRUCTURE type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _GET_ADDITIONAL_HEADER_DATA
    changing
      !CS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _GET_ADDITIONAL_VALUES_DATA
    changing
      !CS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _GET_CHAR_REQUIREMENTS
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IV_INSPCHAR type QIBPMERKNR
    returning
      value(RS_CHAR_REQUIREMENTS) type ZQM_S_LABORATORIES_CHARREQU
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _GET_CODE_GROUP
    importing
      !IV_SEL_SET type QSEL_SET
      !IV_PLANT type QSEL_SET_P
      !IV_CATALOG_TYPE type QCAT_TYPE
    returning
      value(RV_CODE_GROUP) type QCODEGRP
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _GET_EXISTING_SAMPLE_VALUES
    changing
      !CS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _LOCK
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    exporting
      !EV_ALREADY_LOCKED type ABAP_BOOL
      !EV_LOCK_USER type SY-UNAME
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _SAVE_ADDITIONAL_VALUES_DATA
    importing
      !IS_DATA_TO_MAINTAIN type ZQM_S_LAB_BMS_MAINTAIN_DATA
    returning
      value(RT_MESSAGES) type BAPIRET2_T
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _UNLOCK
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods _WRITE_APPLICATION_LOG
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IT_MESSAGES type BAPIRET2_T optional
      !IS_MESSAGE type BAPIRET2 optional
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_RUNTIME IMPLEMENTATION.


  METHOD zif_qm_lab_bms_runtime~check_data.
    DATA: lv_insplot TYPE qibplosnr,
          lv_inspoper TYPE qibpvornr,
          lv_inspchar TYPE qibpmerknr,
          lv_mstr_char TYPE qmstr_char.
    DATA lv_field_prefix TYPE string.
    DATA lv_fieldname TYPE fieldname.
    DATA lv_converted_value TYPE swaexpdef-expr.
    DATA lv_decimals TYPE dfies-decimals.
    DATA lv_value TYPE string.

    FIELD-SYMBOLS: <wa_modified_cells> TYPE lvc_s_modi,
                   <lt_data> TYPE STANDARD TABLE,
                   <wa_data> TYPE any,
                   <lv_insplot> TYPE qibplosnr,
                   <lv_inspoper> TYPE qibpvornr,
                   <lv_inspchar> TYPE qibpmerknr,
                   <lv_dd_hndl> TYPE any,
                   <wa_maintain_data> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_messages> TYPE bapiret2.

    CONSTANTS: co_numeric TYPE string VALUE '0123456789,.- '.

    ASSIGN io_data_object->* TO <lt_data>.

    LOOP AT it_modified_cells ASSIGNING <wa_modified_cells> WHERE fieldname CP 'VALUE*'.
      CLEAR lv_inspoper.
      UNASSIGN <wa_maintain_data>.

      CASE iv_data_type.
        WHEN 'S'.
* Single edit value changed
          READ TABLE <lt_data>
          ASSIGNING <wa_data>
          INDEX <wa_modified_cells>-row_id.

* Get key values
          ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
          ASSIGN COMPONENT 'INSPOPER' OF STRUCTURE <wa_data> TO <lv_inspoper>.
          ASSIGN COMPONENT 'INSPCHAR' OF STRUCTURE <wa_data> TO <lv_inspchar>.
          ASSIGN COMPONENT 'DROP_DOWN_HANDLE' OF STRUCTURE <wa_data> TO <lv_dd_hndl>.

          lv_insplot = <lv_insplot>.
          lv_inspoper = <lv_inspoper>.
          lv_inspchar = <lv_inspchar>.

          READ TABLE it_maintain_data
          ASSIGNING <wa_maintain_data>
          WITH KEY insplot = lv_insplot
                   inspoper = lv_inspoper.

        WHEN 'M'.
* Multi edit value change
          READ TABLE <lt_data>
          ASSIGNING <wa_data>
          INDEX <wa_modified_cells>-row_id.

* Get key values
          ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
          lv_insplot = <lv_insplot>.
          SPLIT <wa_modified_cells>-fieldname AT '_' INTO lv_field_prefix lv_mstr_char.

          lv_fieldname = <wa_modified_cells>-fieldname.
          REPLACE FIRST OCCURRENCE OF 'VALUE' IN lv_fieldname WITH 'DD_HDNL'.
          ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_data> TO <lv_dd_hndl>.

          LOOP AT it_maintain_data ASSIGNING <wa_maintain_data> WHERE insplot = lv_insplot.
            READ TABLE <wa_maintain_data>-values
            WITH KEY mstr_char = lv_mstr_char
            ASSIGNING <wa_values>.

            IF sy-subrc IS INITIAL.
              lv_inspchar = <wa_values>-inspchar.
              lv_inspoper = <wa_maintain_data>-inspoper.
              EXIT.
            ENDIF.
          ENDLOOP.
      ENDCASE.

      IF <lv_dd_hndl> IS NOT INITIAL.
* No value check because it`s an value list
        CONTINUE.
      ENDIF.

      IF <wa_maintain_data> IS ASSIGNED.
        READ TABLE <wa_maintain_data>-values
        ASSIGNING <wa_values>
        WITH KEY inspchar = lv_inspchar.

        IF sy-subrc IS INITIAL.
          lv_value = <wa_modified_cells>-value.

          IF lv_value CN co_numeric.
            APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
            <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
            <wa_messages>-number = 004.
            <wa_messages>-type = 'E'.
            <wa_messages>-message_v1 = <wa_modified_cells>-value.
            <wa_messages>-row = <wa_modified_cells>-row_id.
            <wa_messages>-field = <wa_modified_cells>-fieldname.
            UNASSIGN <wa_messages>.
          ELSE.
            TRY.
                CALL FUNCTION 'Z_QM_NUMBER_CONVERSION'
                  EXPORTING
                    iv_external = <wa_modified_cells>-value
                  IMPORTING
                    ev_internal = lv_converted_value.

                CALL FUNCTION 'SWA_DETERMINE_DECIMALS'
                  EXPORTING
                    expression = lv_converted_value
                  IMPORTING
                    decimals   = lv_decimals.

                IF lv_decimals > <wa_values>-dec_places.
                  APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
                  <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
                  <wa_messages>-number = 005.
                  <wa_messages>-type = 'E'.
                  <wa_messages>-message_v1 = <wa_modified_cells>-value.

                  <wa_messages>-message_v2 = <wa_values>-dec_places.
                  CONDENSE <wa_messages>-message_v2 NO-GAPS.

                  <wa_messages>-row = <wa_modified_cells>-row_id.
                  <wa_messages>-field = <wa_modified_cells>-fieldname.
                  UNASSIGN <wa_messages>.
                ENDIF.
              CATCH cx_sy_conversion_no_number.
* It`s okay. Number can have already the right format. Non numeric values get catched earlier
            ENDTRY.

            CLEAR: lv_decimals, lv_converted_value.
          ENDIF.
        ENDIF.
      ENDIF.

      CLEAR: lv_inspoper, lv_insplot, lv_inspchar, lv_fieldname, lv_field_prefix.
    ENDLOOP.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~check_data


  METHOD zif_qm_lab_bms_runtime~dispose.
    FIELD-SYMBOLS <wa_current_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data.

    LOOP AT at_current_data_to_maintain ASSIGNING <wa_current_data_to_maintain>.
      me->_unlock( iv_insplot = <wa_current_data_to_maintain>-insplot
                   iv_inspoper = <wa_current_data_to_maintain>-inspoper ).
    ENDLOOP.

    FREE: at_current_data_to_maintain.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~dispose


  METHOD zif_qm_lab_bms_runtime~get_data_for_maintain.
    DATA wa_data TYPE zqm_s_lab_bms_maintain_data.

    FIELD-SYMBOLS: <wa_head_data> TYPE zqm_s_lab_bms_head_data,
                   <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data.

* Unlock current data
    IF at_current_data_to_maintain[] IS NOT INITIAL.
      LOOP AT at_current_data_to_maintain ASSIGNING <wa_data_to_maintain>.
        me->_unlock( iv_insplot = <wa_data_to_maintain>-insplot
                     iv_inspoper = <wa_data_to_maintain>-inspoper ).
      ENDLOOP.
    ENDIF.

    LOOP AT it_head_data ASSIGNING <wa_head_data>.
      CLEAR wa_data.

      MOVE-CORRESPONDING <wa_head_data> TO wa_data.

      me->_get_additional_header_data( CHANGING cs_data_to_maintain = wa_data ).

* Build key structure
      wa_data-key_values = me->_build_key_structure( is_header_data = <wa_head_data> ).

* Build value object and fill data
      wa_data-values = me->_create_value_data( is_header_data = <wa_head_data> ).
      me->_get_existing_sample_values( CHANGING cs_data_to_maintain = wa_data ).

* Fill additional data
      me->_get_additional_values_data( CHANGING cs_data_to_maintain = wa_data ).

* Lock data
      me->_lock( EXPORTING iv_insplot = wa_data-insplot
                           iv_inspoper = wa_data-inspoper
                 IMPORTING ev_already_locked = wa_data-locked
                           ev_lock_user      = wa_data-lock_user ).

      IF me->_check_data_to_maintain( is_data_to_maintain = wa_data
                                      iv_is_line_required = iv_is_line_required ) = abap_false.

        INSERT wa_data INTO TABLE rt_data.
      ENDIF.
    ENDLOOP.

    at_current_data_to_maintain[] = rt_data[].
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~get_data_for_maintain


  METHOD zif_qm_lab_bms_runtime~get_historical_sample_values.
    DATA: lt_inspection_points TYPE STANDARD TABLE OF bapi2045l4,
          lt_sample_results TYPE STANDARD TABLE OF bapi2045d3.
    DATA lv_count TYPE int4.
    DATA wa_head_data TYPE zqm_s_lab_bms_head_data.
    DATA lt_values TYPE zqm_t_lab_bms_measure_data.
    DATA wa_historical_data TYPE zqm_s_lab_bms_maintain_data.
    DATA wa_values TYPE zqm_s_lab_bms_measure_data.

    FIELD-SYMBOLS: <wa_inspection_points> TYPE bapi2045l4,
                   <wa_sample_results> TYPE bapi2045d3,
                   <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data,
                   <lv_value_to> TYPE any,
                   <lv_value_from> TYPE any,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data.

    LOOP AT it_data_to_maintain ASSIGNING <wa_data_to_maintain>.
* Find inspection points with sample results
      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot             = <wa_data_to_maintain>-insplot
          inspoper            = <wa_data_to_maintain>-inspoper
          read_insppoints     = abap_true
          read_sample_results = abap_true
          char_filter_no      = '1   '
          char_filter_tcode   = 'QE11'
          max_insppoints      = 300
          insppoint_from      = 0
        TABLES
          insppoints          = lt_inspection_points
          sample_results      = lt_sample_results.

      IF <wa_data_to_maintain>-inspsample IS NOT INITIAL.
        DELETE lt_inspection_points
        WHERE insppoint = <wa_data_to_maintain>-inspsample.
      ENDIF.

      DELETE lt_inspection_points
      WHERE ( userd1 > <wa_data_to_maintain>-date )
         OR ( userd1 = <wa_data_to_maintain>-date AND
              usert1 > <wa_data_to_maintain>-time )
         OR ( userd1 = <wa_data_to_maintain>-date AND
              usert1 = <wa_data_to_maintain>-time ).

      SORT lt_inspection_points BY userd1 DESCENDING usert1 DESCENDING.

      LOOP AT lt_inspection_points ASSIGNING <wa_inspection_points>.
        FREE lt_values.
        CLEAR: wa_head_data, wa_historical_data.

        lv_count = lv_count + 1.

        MOVE-CORRESPONDING <wa_data_to_maintain> TO wa_head_data.
        lt_values = me->_create_value_data( is_header_data = wa_head_data ).

        zcl_qm_lab_bms_util=>copy_insplot_key_fields( EXPORTING iv_ident_key        = <wa_data_to_maintain>-ident_key
                                                                is_source_structure = <wa_inspection_points>
                                                      CHANGING cs_target_structure = wa_historical_data ).

        IF iv_ballennr IS SUPPLIED.
          IF wa_historical_data-ballennr <> iv_ballennr.
            CONTINUE.
          ENDIF.
        ENDIF.

        wa_historical_data-insplot = <wa_inspection_points>-insplot.
        wa_historical_data-inspoper = <wa_inspection_points>-inspoper.
        wa_historical_data-inspsample = <wa_inspection_points>-insppoint.
        wa_historical_data-historical = abap_true.

        me->_get_additional_header_data( CHANGING cs_data_to_maintain = wa_historical_data ).


        LOOP AT lt_sample_results ASSIGNING <wa_sample_results> WHERE insplot = <wa_inspection_points>-insplot
                                                                  AND inspoper = <wa_inspection_points>-inspoper
                                                                  AND inspsample = <wa_inspection_points>-insppoint.
          READ TABLE lt_values
          INTO wa_values
          WITH KEY inspchar = <wa_sample_results>-inspchar.

          IF sy-subrc IS INITIAL.
            ASSIGN wa_values-value->* TO <lv_value_to>.

            IF wa_values-value_fieldname = 'MEAN_VALUE'.
              ASSIGN COMPONENT 'ORIGINAL_INPUT' OF STRUCTURE <wa_sample_results> TO <lv_value_from>.
            ELSE.
              ASSIGN COMPONENT wa_values-value_fieldname OF STRUCTURE <wa_sample_results> TO <lv_value_from>.
            ENDIF.

            IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
              <lv_value_to> = <lv_value_from>.
            ENDIF.

            zcl_qm_lab_bms_util=>copy_sample_fields( EXPORTING iv_ident_key        = <wa_data_to_maintain>-ident_key
                                                               is_source_structure = <wa_sample_results>
                                                     CHANGING cs_target_structure = wa_values ).

            INSERT wa_values INTO TABLE wa_historical_data-values.

            CLEAR wa_values.
          ENDIF.
        ENDLOOP.

* Fill additional data
        me->_get_additional_values_data( CHANGING cs_data_to_maintain = wa_historical_data ).

        INSERT wa_historical_data INTO TABLE rt_historical_data.

        IF lv_count = iv_max_hits.
          EXIT.
        ENDIF.
      ENDLOOP.

      CLEAR lv_count.
      FREE: lt_inspection_points, lt_sample_results.
    ENDLOOP.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~get_historical_sample_values


  METHOD zif_qm_lab_bms_runtime~is_multi_maintainable.

  ENDMETHOD.                    "zif_qm_lab_bms_runtime~is_multi_maintainable


  METHOD zif_qm_lab_bms_runtime~save_data.
    DATA lt_field_mapping TYPE zqm_t_lab_bms_inspop_mapping.
    DATA wa_char_requirements TYPE zqm_s_lab_bms_charrequirements.
    DATA: lt_sample_results TYPE STANDARD TABLE OF bapi2045d3,
          lt_sample_results_work TYPE STANDARD TABLE OF bapi2045d3.
    DATA lv_conversion_value TYPE string.
    DATA lt_insp_point TYPE STANDARD TABLE OF bapi2045l4.
    DATA lv_index TYPE i.
    DATA lt_messages TYPE bapiret2_t.
    DATA wa_return TYPE bapiret2.
    DATA wa_data_to_maintain TYPE zqm_s_lab_bms_maintain_data.

    FIELD-SYMBOLS: <wa_data_to_maintain> TYPE zqm_s_lab_bms_maintain_data,
                   <wa_field_mapping> TYPE zqm_s_lab_bms_inspop_mapping,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_sample_results> TYPE bapi2045d3,
                   <wa_insp_point> TYPE bapi2045l4,
                   <lv_value_to> TYPE any,
                   <lv_value_from> TYPE any.

    LOOP AT ct_data_to_maintain ASSIGNING <wa_data_to_maintain>.
* Get field mapping
      lt_field_mapping = zcl_qm_lab_bms_customizing=>get_insp_operation_mapping( iv_ident_key = <wa_data_to_maintain>-ident_key ).

      LOOP AT <wa_data_to_maintain>-values ASSIGNING <wa_values>.
* Get char requirments
        zcl_qm_lab_bms_util=>get_char_requirements( EXPORTING iv_insplot  = <wa_data_to_maintain>-insplot
                                                              iv_inspoper = <wa_data_to_maintain>-inspoper
                                                              iv_inspchar = <wa_values>-inspchar
                                                    IMPORTING es_char_requirements = wa_char_requirements ).

        APPEND INITIAL LINE TO lt_sample_results ASSIGNING <wa_sample_results>.
        <wa_sample_results>-insplot = <wa_data_to_maintain>-insplot.
        <wa_sample_results>-inspoper = <wa_data_to_maintain>-inspoper.
        <wa_sample_results>-inspchar = <wa_values>-inspchar.

        UNASSIGN <lv_value_to>.
        ASSIGN COMPONENT wa_char_requirements-fieldname OF STRUCTURE <wa_sample_results> TO <lv_value_to>.
        IF sy-subrc IS INITIAL.
          ASSIGN <wa_values>-value->* TO <lv_value_from>.
          <lv_value_to> = <lv_value_from>.

          IF <lv_value_to> IS NOT INITIAL AND wa_char_requirements-code_grp_fieldname IS NOT INITIAL.
            ASSIGN COMPONENT wa_char_requirements-code_grp_fieldname OF STRUCTURE <wa_sample_results> TO <lv_value_to>.
            IF sy-subrc IS INITIAL.
              <lv_value_to> = wa_char_requirements-code_group.
            ENDIF.
          ELSE.
            IF <lv_value_to> IS NOT INITIAL.
              TRY.
                  lv_conversion_value = <lv_value_to>.

                  CALL FUNCTION 'Z_QM_NUMBER_CONVERSION'
                    EXPORTING
                      iv_external = lv_conversion_value
                    IMPORTING
                      ev_internal = lv_conversion_value.

                  <lv_value_to> = lv_conversion_value.
                  CLEAR lv_conversion_value.
                CATCH cx_sy_conversion_no_number.
* It`s okay. Number can have already the right format. Non numeric values get catched earlier
              ENDTRY.
            ENDIF.
          ENDIF.
        ENDIF.

        LOOP AT lt_field_mapping ASSIGNING <wa_field_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_sample.
          UNASSIGN: <lv_value_to>, <lv_value_from>.
          ASSIGN COMPONENT <wa_field_mapping>-source_field OF STRUCTURE <wa_values> TO <lv_value_from>.
          ASSIGN COMPONENT <wa_field_mapping>-target_field OF STRUCTURE <wa_sample_results> TO <lv_value_to>.

          IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
            <lv_value_to> = <lv_value_from>.
          ENDIF.
        ENDLOOP.

        READ TABLE lt_insp_point
        WITH KEY insplot = <wa_data_to_maintain>-insplot
                 inspoper = <wa_data_to_maintain>-inspoper
        TRANSPORTING NO FIELDS.

        IF sy-subrc IS NOT INITIAL.
          APPEND INITIAL LINE TO lt_insp_point ASSIGNING <wa_insp_point>.
          <wa_insp_point>-insplot = <wa_data_to_maintain>-insplot.
          <wa_insp_point>-inspoper = <wa_data_to_maintain>-inspoper.
          <wa_insp_point>-insppoint = <wa_data_to_maintain>-inspsample.

          LOOP AT lt_field_mapping ASSIGNING <wa_field_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_insp_point.
            UNASSIGN: <lv_value_to>, <lv_value_from>.
            ASSIGN COMPONENT <wa_field_mapping>-source_field OF STRUCTURE <wa_data_to_maintain> TO <lv_value_from>.
            ASSIGN COMPONENT <wa_field_mapping>-target_field OF STRUCTURE <wa_insp_point> TO <lv_value_to>.

            IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
              <lv_value_to> = <lv_value_from>.
            ENDIF.
          ENDLOOP.

          UNASSIGN <wa_insp_point>.
        ENDIF.

        CLEAR wa_char_requirements.
      ENDLOOP.

      FREE lt_field_mapping.
    ENDLOOP.

    CLEAR lv_index.

    SORT lt_insp_point BY insplot inspoper.

    LOOP AT lt_insp_point ASSIGNING <wa_insp_point>.
      lv_index = lv_index + 1.

      lt_sample_results_work[] = lt_sample_results[].

      DELETE lt_sample_results_work
      WHERE insplot <> <wa_insp_point>-insplot
         OR inspoper <> <wa_insp_point>-inspoper.

* Try to find data for maintain
      READ TABLE ct_data_to_maintain
      ASSIGNING <wa_data_to_maintain>
      WITH KEY insplot = <wa_insp_point>-insplot
               inspoper = <wa_insp_point>-inspoper.

* Do calculations
      me->_do_calculations( EXPORTING is_insp_point = <wa_insp_point>
                                      is_data_to_maintain = <wa_data_to_maintain>
                            IMPORTING et_messages = lt_messages
                            CHANGING ct_sample_results = lt_sample_results_work ).

      APPEND LINES OF lt_messages TO et_messages.
      FREE lt_messages.

* Save data
      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING
          insplot              = <wa_insp_point>-insplot
          inspoper             = <wa_insp_point>-inspoper
          insppointdata        = <wa_insp_point>
          handheld_application = ' '
        IMPORTING
          return               = wa_return
        TABLES
          sample_results       = lt_sample_results_work
          returntable          = lt_messages.

      IF wa_return-type = 'E' OR wa_return-type = 'A'.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        me->_write_application_log( iv_insplot  = <wa_insp_point>-insplot
                                    iv_inspoper = <wa_insp_point>-inspoper
                                    it_messages = lt_messages ).

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        READ TABLE lt_sample_results_work
        ASSIGNING <wa_sample_results>
        INDEX 1.

* Get created order number
        wa_data_to_maintain = <wa_data_to_maintain>.
        wa_data_to_maintain-inspsample = <wa_sample_results>-inspsample.
        DELETE TABLE ct_data_to_maintain FROM <wa_data_to_maintain>.
        INSERT wa_data_to_maintain INTO TABLE ct_data_to_maintain.

* Save additional values
        APPEND LINES OF me->_save_additional_values_data( is_data_to_maintain = wa_data_to_maintain ) TO et_messages.
      ENDIF.

      IF wa_return IS NOT INITIAL.
        APPEND wa_return TO et_messages.
      ENDIF.

      FREE lt_messages.
    ENDLOOP.

    FREE lt_sample_results.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~save_data


  METHOD zif_qm_lab_bms_runtime~save_time_reporting.
    DATA lt_data TYPE zqm_t_lab_bms_time_rep_data.
    DATA: lv_aufpl TYPE co_aufpl,
          lv_aufnr TYPE qaufnr_co,
          lv_plnfl TYPE plnfolge.
    DATA: wa_afrud TYPE afrud,
          wa_afvgd TYPE afvgd,
          wa_caufvd TYPE caufvd,
          lv_aktyp TYPE rc27s-aktyp,
          wa_operkey TYPE cooprkey.
    DATA lt_afrud TYPE STANDARD TABLE OF afrud.

    FIELD-SYMBOLS: <wa_data> TYPE zqm_s_lab_bms_time_rep_data,
                   <wa_messages> TYPE bapiret2.

    lt_data[] = it_data[].
    SORT lt_data BY insplot.

    LOOP AT lt_data ASSIGNING <wa_data> WHERE amount > 0.
      CLEAR: lv_aufpl, lv_aufnr, lv_plnfl.

* Get QALS values for inspection lot
      SELECT SINGLE a~aufpl
                    a~aufnr_co
                    b~plnfl
      FROM qals AS a
      INNER JOIN afvc AS b
      ON b~aufpl = a~aufpl
      INTO (lv_aufpl, lv_aufnr, lv_plnfl)
      WHERE a~prueflos = <wa_data>-insplot
        AND b~vornr = <wa_data>-vornr.

      IF sy-subrc IS NOT INITIAL.
        APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
        <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
        <wa_messages>-type = 'E'.
        <wa_messages>-number = 014.
        <wa_messages>-message_v1 = <wa_data>-insplot.

        me->_write_application_log( iv_insplot  = <wa_data>-insplot
                                    iv_inspoper = <wa_data>-vornr
                                    is_message  = <wa_messages> ).

        UNASSIGN <wa_messages>.
        CONTINUE.
      ENDIF.

      lv_aktyp = 'H'.

      wa_operkey-aufnr = lv_aufnr.
      wa_operkey-aplfl = lv_plnfl.
      wa_operkey-vornr = <wa_data>-vornr.

* Prepare data
      CALL FUNCTION 'CO_RU_CONFIRMATION_PREPARE'
        EXPORTING
          aktyp_imp               = lv_aktyp
          aufpl_imp               = lv_aufpl
          autyp_imp               = '06'
          oper_key                = wa_operkey
          no_dialog_flag          = abap_true
          suppress_suggestion     = abap_true
          no_msg_qm_char          = abap_true
        IMPORTING
          afrud_exp               = wa_afrud
          afvgd_exp               = wa_afvgd
          aktyp_exp               = lv_aktyp
          caufvd_exp              = wa_caufvd
        EXCEPTIONS
          order_already_locked    = 1
          new_status_not_possible = 2
          interrupt_by_user       = 3
          OTHERS                  = 8.

      IF sy-subrc IS NOT INITIAL.
        CASE sy-subrc.
          WHEN 1.
            APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
            <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
            <wa_messages>-type = 'E'.
            <wa_messages>-number = 024.
            <wa_messages>-message_v1 = <wa_data>-insplot.
          WHEN OTHERS.
            APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
            <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
            <wa_messages>-type = 'E'.
            <wa_messages>-number = 025.
            <wa_messages>-message_v1 = <wa_data>-insplot.
        ENDCASE.

        me->_write_application_log( iv_insplot  = <wa_data>-insplot
                                    iv_inspoper = <wa_data>-vornr
                                    is_message  = <wa_messages> ).

        UNASSIGN <wa_messages>.
        CONTINUE.
      ENDIF.

* Set data
      wa_afrud-orind = '7'.

      CALL FUNCTION 'CO_RU_CONFIRMATION_CHECK'
        EXPORTING
          afrud_in  = wa_afrud
          aktyp_in  = lv_aktyp
          caufvd_in = wa_caufvd
        IMPORTING
          afrud_exp = wa_afrud.

* Set values
      wa_afrud-ile01 = <wa_data>-time_unit.
      wa_afrud-ism01 = <wa_data>-amount.

* Save data
      CALL FUNCTION 'CO_RU_CONFIRMATION_ADD'
        EXPORTING
          afrud_in                = wa_afrud
          aktyp_in                = lv_aktyp
          aktyp_pic_in            = 'H'
          caufvd_in               = wa_caufvd
        TABLES
          afrud_tab               = lt_afrud
        EXCEPTIONS
          conversion_error        = 1
          order_data_not_found    = 2
          stand_conf_not_possible = 3
          dialog_necessary        = 4
          wrong_sequence          = 5
          prt_error               = 6
          OTHERS                  = 7.

      IF sy-subrc IS NOT INITIAL.
        APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
        <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
        <wa_messages>-type = 'E'.
        <wa_messages>-number = 025.
        <wa_messages>-message_v1 = <wa_data>-insplot.

        me->_write_application_log( iv_insplot  = <wa_data>-insplot
                                    iv_inspoper = <wa_data>-vornr
                                    is_message  = <wa_messages> ).

        UNASSIGN <wa_messages>.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'CO_RU_CONFIRMATION_POST'
        EXPORTING
          trans_typ     = 'H'
        EXCEPTIONS
          posting_error = 1
          OTHERS        = 2.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      WAIT UP TO 1 SECONDS.

      CALL FUNCTION 'CO_RU_ORDER_DEQUEUE'
        EXPORTING
          aufnr_imp = lv_aufnr.

      FREE lt_afrud.
      CLEAR: wa_operkey, wa_afrud, wa_afvgd, lv_aktyp, wa_caufvd.
    ENDLOOP.

    FREE lt_data.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~save_time_reporting


  METHOD zif_qm_lab_bms_runtime~show_time_reporting.
    DATA lv_aufpl TYPE qals-aufpl.
    DATA lv_aufnr TYPE qaufnr_co.
    DATA lv_update_flag TYPE qm00-qkz.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    IF iv_insplot IS INITIAL.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
      <wa_messages>-number = 012.
      <wa_messages>-type = 'E'.
      UNASSIGN <wa_messages>.
      RETURN.
    ENDIF.

* Get aufpl
    SELECT SINGLE aufpl
    FROM qals
    INTO lv_aufpl
    WHERE prueflos = iv_insplot.

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
      <wa_messages>-number = 017.
      <wa_messages>-type = 'E'.
      <wa_messages>-message_v1 = iv_insplot.
      UNASSIGN <wa_messages>.
      RETURN.
    ENDIF.

* Open standard popup for time reporting
    CALL FUNCTION 'QELA_CONFIRMATION_LIST'
      EXPORTING
        i_aufpl       = lv_aufpl
*       I_RUECK       =
        i_update      = abap_true
        i_prueflos    = iv_insplot
        i_sondauf     = ''
      IMPORTING
        e_upd_flag    = lv_update_flag
      EXCEPTIONS
        no_data_found = 1
        OTHERS        = 2.

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
      <wa_messages>-number = 015.
      <wa_messages>-type = 'E'.
      <wa_messages>-message_v1 = iv_insplot.
      UNASSIGN <wa_messages>.
    ENDIF.

    IF lv_update_flag = abap_true.
      CALL FUNCTION 'CO_RU_CONFIRMATION_POST'
        EXPORTING
          trans_typ     = 'H'
        EXCEPTIONS
          posting_error = 1
          OTHERS        = 2.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      SELECT SINGLE aufnr_co
      FROM qals
      INTO lv_aufnr
      WHERE prueflos = iv_insplot.

      CALL FUNCTION 'CO_RU_ORDER_DEQUEUE'
        EXPORTING
          aufnr_imp = lv_aufnr.
    ENDIF.

    CLEAR: lv_aufpl, lv_update_flag, lv_aufnr.
  ENDMETHOD.                    "zif_qm_lab_bms_runtime~show_time_reporting


  METHOD _build_key_structure.
    DATA wa_tq79 TYPE tq79.
    DATA lv_langu TYPE spras.
    DATA lt_components TYPE abap_component_tab.
    DATA lv_fieldname TYPE string.
    DATA lt_fields TYPE STANDARD TABLE OF ls_fields.
    DATA obj_struct_descr TYPE REF TO cl_abap_structdescr.

    FIELD-SYMBOLS: <wa_fields> TYPE ls_fields,
                   <lv_field> TYPE any,
                   <wa_components> TYPE abap_componentdescr.

    READ TABLE at_tq79_buffer
    INTO wa_tq79
    WITH KEY slwbez = is_header_data-ident_key.

    IF sy-subrc IS NOT INITIAL.
* Find inspection point key values
      SELECT SINGLE *
      INTO wa_tq79
      FROM tq79
      WHERE slwbez = is_header_data-ident_key.

      IF sy-subrc IS NOT INITIAL.
        RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
          EXPORTING
            textid     = zcx_qm_lab_bms_exceptions=>no_keyfields_found
            a_inspplot = is_header_data-insplot.
      ENDIF.

      INSERT wa_tq79 INTO TABLE at_tq79_buffer.
    ENDIF.

    DO 6 TIMES.
      CASE sy-index.
        WHEN 1.
          ASSIGN COMPONENT 'USERC1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERC1AKT'.
        WHEN 2.
          ASSIGN COMPONENT 'USERC2AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERC2AKT'.
        WHEN 3.
          ASSIGN COMPONENT 'USERN1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERN1AKT'.
        WHEN 4.
          ASSIGN COMPONENT 'USERN2AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERN2AKT'.
        WHEN 5.
          ASSIGN COMPONENT 'USERD1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERD1AKT'.
        WHEN 6.
          ASSIGN COMPONENT 'USERT1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
          lv_fieldname = 'USERT1AKT'.
      ENDCASE.

      IF <lv_field> IS NOT INITIAL.
        APPEND INITIAL LINE TO lt_fields ASSIGNING <wa_fields>.
        <wa_fields>-index = <lv_field>.
        <wa_fields>-name = lv_fieldname.
        UNASSIGN: <wa_fields>.
      ENDIF.

      UNASSIGN <lv_field>.
      CLEAR: lv_fieldname.
    ENDDO.

    SORT lt_fields BY index.

    LOOP AT lt_fields ASSIGNING <wa_fields>.
      APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
      <wa_components>-name = <wa_fields>-name.

      IF <wa_components>-name CP 'USERC2AKT'.
        <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
      ELSEIF <wa_components>-name CP 'USERC1AKT'.
        <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
      ELSEIF <wa_components>-name CP 'USERN*'.
        <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'INT4' ).
      ELSEIF <wa_components>-name CP 'USERD*'.
        <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'DATS' ).
      ELSEIF <wa_components>-name CP 'USERT*'.
        <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'UZEIT' ).
      ENDIF.

      UNASSIGN: <lv_field>, <wa_components>.
    ENDLOOP.

* Create data object
    obj_struct_descr = cl_abap_structdescr=>create( lt_components ).
    CREATE DATA ro_key_data TYPE HANDLE obj_struct_descr.

* Fill key structure with values
    me->_fill_key_structure( EXPORTING is_header_data = is_header_data
                             CHANGING co_key_structure = ro_key_data ).

    FREE: obj_struct_descr.
    FREE: lt_fields.
    CLEAR: wa_tq79, lv_fieldname.
  ENDMETHOD.                    "_build_key_structure


  METHOD _check_data_to_maintain.
    DATA lt_messages TYPE bapiret2_t.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    CONSTANTS: co_msg_id TYPE string VALUE 'ZQM_LABORATORIES_BMS',
               co_msg_type_warning TYPE c VALUE 'W'.

    IF is_data_to_maintain-slwid IS INITIAL.
      APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = co_msg_id.
      <wa_messages>-number = 009.
      <wa_messages>-type = co_msg_type_warning.
      UNASSIGN <wa_messages>.

      rv_error = abap_true.
    ENDIF.

    IF iv_is_line_required = abap_true AND is_data_to_maintain-linie IS INITIAL.
      APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = co_msg_id.
      <wa_messages>-number = 010.
      <wa_messages>-type = co_msg_type_warning.
      UNASSIGN <wa_messages>.

      rv_error = abap_true.
    ENDIF.

    IF rv_error = abap_true.
      APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = co_msg_id.
      <wa_messages>-number = 011.
      <wa_messages>-type = co_msg_type_warning.
      UNASSIGN <wa_messages>.
    ENDIF.

    IF iv_write_appl_log = abap_true.
      me->_write_application_log( iv_insplot = is_data_to_maintain-insplot
                                  iv_inspoper = is_data_to_maintain-inspoper
                                  it_messages = lt_messages ).
    ENDIF.

    FREE lt_messages.
  ENDMETHOD.                    "_check_data_to_maintain


  METHOD _create_value_data.
    DATA obj_data_descr TYPE REF TO cl_abap_datadescr.
    DATA obj_dec TYPE REF TO data.
    DATA obj_calculation TYPE REF TO zcl_qm_char_calculation.
    DATA: wa_operation TYPE bapi2045l2,
          wa_insppoint_requirements TYPE bapi2045d5.
    DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.
    DATA wa_values TYPE zqm_s_lab_bms_measure_data.
    DATA lt_qpmt_tab TYPE TABLE OF qpmt.
    DATA lt_bapiret  TYPE TABLE OF bapiret2.
    DATA lv_htype TYPE dd01v-datatype.

    FIELD-SYMBOLS: <wa_char_requirements> TYPE bapi2045d1,
                   <wa_qpmt> TYPE qpmt.

    CREATE OBJECT obj_calculation.

* Get inspeaction point requirement
    CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
      EXPORTING
        insplot                = is_header_data-insplot
        inspoper               = is_header_data-inspoper
        read_char_requirements = abap_true
      IMPORTING
        operation              = wa_operation
        insppoint_requirements = wa_insppoint_requirements
      TABLES
        char_requirements      = lt_char_requirements.

    LOOP AT lt_char_requirements ASSIGNING <wa_char_requirements>.
* Create data object for value field
      obj_data_descr ?= cl_abap_elemdescr=>describe_by_name( 'QMEAN_VAL' ).

      wa_values-inspchar = <wa_char_requirements>-inspchar.
      wa_values-mstr_char = <wa_char_requirements>-mstr_char.
      wa_values-description = <wa_char_requirements>-char_descr.
      wa_values-dec_places = <wa_char_requirements>-dec_places.
      wa_values-unit = <wa_char_requirements>-meas_unit.
      wa_values-unit_text = <wa_char_requirements>-meas_unit.
      wa_values-up_tol_lmt = <wa_char_requirements>-up_tol_lmt.
      wa_values-lw_tol_lmt = <wa_char_requirements>-lw_tol_lmt.

* Read Info fields from Characteristics LAGAHW 21.06.2019
      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = <wa_char_requirements>-infofield1
        IMPORTING
          htype     = lv_htype.

      IF lv_htype CO 'NUMC'.
        wa_values-zquantity = <wa_char_requirements>-infofield1.
      ENDIF.

      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = <wa_char_requirements>-infofield2
        IMPORTING
          htype     = lv_htype.

      IF lv_htype CO 'NUMC'.
        wa_values-ztemperature = <wa_char_requirements>-infofield2.
      ENDIF.

      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = <wa_char_requirements>-infofield3
        IMPORTING
          htype     = lv_htype.

      IF lv_htype CO 'NUMC'.
        wa_values-ztime = <wa_char_requirements>-infofield3.
      ENDIF.

      FREE: lt_qpmt_tab, lt_bapiret.

      cl_qmip_master_inspchar=>read_mic( EXPORTING iv_werk           = <wa_char_requirements>-pmstr_char
                                                   iv_mkmnr          = <wa_char_requirements>-mstr_char
                                                   iv_version        = <wa_char_requirements>-vmstr_char
                                         IMPORTING et_qpmt           = lt_qpmt_tab
                                                   et_return         = lt_bapiret ).

      READ TABLE lt_bapiret
      TRANSPORTING NO FIELDS
      WITH KEY type = 'E'.

      IF sy-subrc IS NOT INITIAL.
        READ TABLE lt_qpmt_tab
        ASSIGNING <wa_qpmt>
        WITH KEY sprache = sy-langu.

        IF sy-subrc IS INITIAL.
          wa_values-description = <wa_qpmt>-kurztext.
        ENDIF.
      ENDIF.

      IF <wa_char_requirements>-char_type = '01'.
        wa_values-value_fieldname = 'MEAN_VALUE'.
      ELSE.
        wa_values-value_fieldname = 'CODE1'.
      ENDIF.

* Check if char should be calculated
      IF obj_calculation->is_char_calculated( iv_werks = is_header_data-plant
                                              iv_mkmnr = wa_values-mstr_char ) = abap_true.

        wa_values-read_only = abap_true.
      ENDIF.

      CREATE DATA wa_values-value TYPE HANDLE obj_data_descr.

      IF <wa_char_requirements>-sel_set1 IS NOT INITIAL.
        wa_values-field_values = zcl_qm_lab_bms_util=>get_field_values( iv_werk       = wa_operation-plant
                                                                        iv_katalogart = <wa_char_requirements>-cat_type1
                                                                        iv_auswahlmge = <wa_char_requirements>-sel_set1 ).
      ENDIF.

      INSERT wa_values INTO TABLE rt_values.

      FREE obj_dec.
      CLEAR: wa_values.
    ENDLOOP.

    FREE: obj_data_descr, obj_calculation.
    CLEAR: wa_operation,wa_insppoint_requirements.
    FREE: lt_char_requirements.
  ENDMETHOD.                    "_create_value_data


METHOD _do_calculations.
  DATA obj_calculation TYPE REF TO zcl_qm_char_calculation.
  DATA obj_calc_exception TYPE REF TO zcx_qm_char_calculation.
  DATA lt_source_chars TYPE zqm_t_qmerknr.
  DATA: lt_calculation_source TYPE zqm_t_calculation_source,
        wa_calculation_source TYPE zqm_s_calculation_source.
  DATA wa_char_requirements TYPE zqm_s_lab_bms_charrequirements.
  DATA lv_value TYPE string.

  FIELD-SYMBOLS: <wa_sample_results> TYPE bapi2045d3,
                 <wa_sample_results_source> TYPE bapi2045d3,
                 <wa_source_chars> TYPE qmerknr,
                 <wa_values> TYPE zqm_s_lab_bms_measure_data,
                 <wa_values_source> TYPE zqm_s_lab_bms_measure_data,
                 <wa_messages> TYPE bapiret2.

  CREATE OBJECT obj_calculation.

  LOOP AT ct_sample_results ASSIGNING <wa_sample_results>.
    CLEAR lv_value.

    TRY.
* Get master char
        READ TABLE is_data_to_maintain-values
        ASSIGNING <wa_values>
        WITH KEY inspchar = <wa_sample_results>-inspchar.

* Check if char should be calculated
        IF obj_calculation->is_char_calculated( iv_werks = is_data_to_maintain-plant
                                                iv_mkmnr = <wa_values>-mstr_char ) = abap_true.

* Get source chars for calculation
          FREE lt_source_chars.
          lt_source_chars = obj_calculation->get_source_chars( iv_werks = is_data_to_maintain-plant
                                                               iv_mkmnr = <wa_values>-mstr_char ).

* Loop over source chars and collect values from sample result table to do calculation
          LOOP AT lt_source_chars ASSIGNING <wa_source_chars>.
            READ TABLE is_data_to_maintain-values
            ASSIGNING <wa_values_source>
            WITH KEY mstr_char = <wa_source_chars>.

            IF sy-subrc IS INITIAL.
              READ TABLE ct_sample_results
              ASSIGNING <wa_sample_results_source>
              WITH KEY inspchar = <wa_values_source>-inspchar.

              IF sy-subrc IS INITIAL.
* Get char requirments
                zcl_qm_lab_bms_util=>get_char_requirements( EXPORTING iv_insplot  = <wa_sample_results>-insplot
                                                                      iv_inspoper = <wa_sample_results>-inspoper
                                                                      iv_inspchar = <wa_sample_results>-inspchar
                                                            IMPORTING es_char_requirements = wa_char_requirements ).

                wa_calculation_source-mkmnr = <wa_values_source>-mstr_char.

                IF wa_char_requirements-code_grp_fieldname IS NOT INITIAL.
                  wa_calculation_source-value = <wa_sample_results_source>-code1.
                ELSE.
                  wa_calculation_source-value = <wa_sample_results_source>-mean_value.
                ENDIF.

                INSERT wa_calculation_source INTO TABLE lt_calculation_source.

                CLEAR: wa_calculation_source, wa_char_requirements.
              ENDIF.
            ENDIF.
          ENDLOOP.

* Calculate characteristics
          lv_value = obj_calculation->calculate( iv_werks = is_data_to_maintain-plant
                                                 iv_mkmnr = <wa_values>-mstr_char
                                                 it_source_chars = lt_calculation_source ).

          SHIFT lv_value LEFT DELETING LEADING '0'.
          IF lv_value IS INITIAL.
            lv_value = 0.
          ENDIF.

          <wa_sample_results>-mean_value = lv_value.

          UNASSIGN: <wa_values_source>, <wa_values>, <wa_sample_results_source>.
          FREE: lt_source_chars, lt_calculation_source.
          CLEAR wa_calculation_source.
        ENDIF.
      CATCH zcx_qm_char_calculation INTO obj_calc_exception.
        APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-id = obj_calc_exception->if_t100_message~t100key-msgid.
        <wa_messages>-number = obj_calc_exception->if_t100_message~t100key-msgno.
        <wa_messages>-message_v1 = obj_calc_exception->if_t100_message~t100key-attr1.
        <wa_messages>-message_v2 = obj_calc_exception->if_t100_message~t100key-attr2.
        <wa_messages>-message_v3 = obj_calc_exception->if_t100_message~t100key-attr3.
        <wa_messages>-message_v4 = obj_calc_exception->if_t100_message~t100key-attr4.
        UNASSIGN <wa_messages>.
    ENDTRY.
  ENDLOOP.

  FREE obj_calculation.
ENDMETHOD.


  METHOD _fill_key_structure.
    FIELD-SYMBOLS: <wa_key_structure> TYPE any,
                   <lv_field> TYPE any.

    ASSIGN co_key_structure->* TO <wa_key_structure>.

    ASSIGN COMPONENT 'USERD1AKT' OF STRUCTURE <wa_key_structure> TO <lv_field>.
    IF sy-subrc IS INITIAL.
      <lv_field> = is_header_data-date.
    ENDIF.

    ASSIGN COMPONENT 'USERT1AKT' OF STRUCTURE <wa_key_structure> TO <lv_field>.
    IF sy-subrc IS INITIAL.
      <lv_field> = is_header_data-time.
    ENDIF.

    ASSIGN COMPONENT 'USERN2AKT' OF STRUCTURE <wa_key_structure> TO <lv_field>.
    IF sy-subrc IS INITIAL.
      <lv_field> = is_header_data-linie.
    ENDIF.

    ASSIGN COMPONENT 'USERC2AKT' OF STRUCTURE <wa_key_structure> TO <lv_field>.
    IF sy-subrc IS INITIAL.
      <lv_field> = is_header_data-sample_type.
    ENDIF.
  ENDMETHOD.                    "_fill_key_structure


METHOD _get_additional_header_data.
  DATA wa_qals TYPE qals.

  FIELD-SYMBOLS: <wa_qals> TYPE qals,
                 <wa_qapp> TYPE qapp.

* Get maintain type
  cs_data_to_maintain-slwid = zcl_qm_lab_bms_util=>get_maintenance_type( iv_insplot  = cs_data_to_maintain-insplot
                                                                         iv_inspoper = cs_data_to_maintain-inspoper ).

  IF cs_data_to_maintain-slwid = 'LAGQM01'.
* Read physical sample number
    cs_data_to_maintain-phynr = zcl_qm_lab_bms_util=>get_physical_sample( iv_insplot = cs_data_to_maintain-insplot ).
  ENDIF.

  READ TABLE me->at_qals_buffer
  ASSIGNING <wa_qals>
  WITH KEY prueflos = cs_data_to_maintain-insplot.

  IF sy-subrc IS NOT INITIAL.
    SELECT SINGLE *
    FROM qals
    INTO wa_qals
    WHERE prueflos = cs_data_to_maintain-insplot.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    APPEND wa_qals TO me->at_qals_buffer ASSIGNING <wa_qals>.
  ENDIF.

  SELECT SINGLE aplzl
  INTO cs_data_to_maintain-aplzl
  FROM afvc
  WHERE aufpl = <wa_qals>-aufpl
    AND vornr = cs_data_to_maintain-inspoper.
ENDMETHOD.


  METHOD _get_additional_values_data.
    DATA lt_qasr TYPE SORTED TABLE OF qasr WITH UNIQUE DEFAULT KEY.

    FIELD-SYMBOLS: <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_qasr> TYPE qasr.

* Get qasr values
    SELECT *
    INTO TABLE lt_qasr
    FROM qasr
    WHERE prueflos = cs_data_to_maintain-insplot
      AND vorglfnr = cs_data_to_maintain-aplzl
      AND probenr = cs_data_to_maintain-inspsample.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    LOOP AT cs_data_to_maintain-values ASSIGNING <wa_values>.
      READ TABLE lt_qasr
      ASSIGNING <wa_qasr>
      WITH KEY merknr = <wa_values>-inspchar.

      IF sy-subrc IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      <wa_values>-zquantity = <wa_qasr>-zquantity.
      <wa_values>-ztemperature = <wa_qasr>-ztemperature.
      <wa_values>-ztime = <wa_qasr>-ztime.
    ENDLOOP.

    FREE lt_qasr.
  ENDMETHOD.                    "_get_existing_sample_values


  METHOD _get_char_requirements.
    DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.
    DATA wa_char_requirements_ext TYPE zqm_s_laboratories_charrequ.

    FIELD-SYMBOLS: <wa_char_requirements_ext> TYPE zqm_s_laboratories_charrequ,
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
*         CHAR_FILTER_NO         = '1   '
*         CHAR_FILTER_TCODE      = 'QE11'
*         MAX_INSPPOINTS         = 100
*         INSPPOINT_FROM         = 0
        TABLES
          char_requirements      = lt_char_requirements.

      IF sy-subrc IS NOT INITIAL.
        RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
          EXPORTING
            textid = zcx_qm_lab_bms_exceptions=>no_char_found.
      ENDIF.

      LOOP AT lt_char_requirements ASSIGNING <wa_char_requirements>.
        wa_char_requirements_ext-insplot  = <wa_char_requirements>-insplot.
        wa_char_requirements_ext-inspoper = <wa_char_requirements>-inspoper.
        wa_char_requirements_ext-inspchar = <wa_char_requirements>-inspchar.

        IF <wa_char_requirements>-psel_set1 IS NOT INITIAL.
          wa_char_requirements_ext-fieldname = 'CODE1'.
          wa_char_requirements_ext-code_grp_fieldname = 'CODE_GRP1'.
          wa_char_requirements_ext-sel_set = <wa_char_requirements>-sel_set1.
          wa_char_requirements_ext-sel_set_p = <wa_char_requirements>-psel_set1.
          wa_char_requirements_ext-cat_type = <wa_char_requirements>-cat_type1.

          wa_char_requirements_ext-code_group = _get_code_group( iv_sel_set      = <wa_char_requirements>-sel_set1
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
      rs_char_requirements = <wa_char_requirements_ext>.
    ELSE.
      RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
        EXPORTING
          textid = zcx_qm_lab_bms_exceptions=>no_char_found.
    ENDIF.

    FREE: lt_char_requirements.
  ENDMETHOD.                    "_get_char_requirements


  METHOD _get_code_group.
* Get catalog from database
    SELECT SINGLE codegruppe
    FROM qpac
    INTO rv_code_group
    WHERE werks = iv_plant
      AND katalogart = iv_catalog_type
      AND auswahlmge = iv_sel_set
      AND gueltigab <= sy-datum.
  ENDMETHOD.                    "_get_code_group


  METHOD _get_existing_sample_values.
    DATA: lt_inspection_points TYPE STANDARD TABLE OF bapi2045l4,
          lt_sample_results TYPE STANDARD TABLE OF bapi2045d3.
    DATA lt_operations_mapping TYPE zqm_t_lab_bms_inspop_mapping.
    DATA lv_where_clause TYPE string.

    CONSTANTS: co_numbers(13) TYPE c VALUE ' 1234567890,.'.

    FIELD-SYMBOLS: <wa_sample_results> TYPE bapi2045d3,
                   <wa_inspection_points> TYPE bapi2045l4,
                   <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <lv_value_to> TYPE any,
                   <lv_value_from> TYPE any,
                   <wa_operations_mapping> TYPE zqm_s_lab_bms_inspop_mapping.

* Find inspection points with sample results
    CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
      EXPORTING
        insplot             = cs_data_to_maintain-insplot
        inspoper            = cs_data_to_maintain-inspoper
        read_insppoints     = abap_true
        read_sample_results = abap_true
        char_filter_no      = '1   '
        char_filter_tcode   = 'QE11'
        max_insppoints      = 300
        insppoint_from      = 0
      TABLES
        insppoints          = lt_inspection_points
        sample_results      = lt_sample_results.

* Get operations mapping
    lt_operations_mapping = zcl_qm_lab_bms_customizing=>get_insp_operation_mapping( iv_ident_key = cs_data_to_maintain-ident_key ).

* Build where clause with operations mapping
    LOOP AT lt_operations_mapping ASSIGNING <wa_operations_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_insp_point.
      IF lv_where_clause IS NOT INITIAL.
        lv_where_clause = |{ lv_where_clause } AND|.
      ENDIF.

      lv_where_clause = |{ lv_where_clause } { <wa_operations_mapping>-target_field } = cs_data_to_maintain-{ <wa_operations_mapping>-source_field }|.
    ENDLOOP.

    LOOP AT lt_inspection_points ASSIGNING <wa_inspection_points> WHERE (lv_where_clause).
      cs_data_to_maintain-inspsample = <wa_inspection_points>-insppoint.

      LOOP AT cs_data_to_maintain-values ASSIGNING <wa_values>.
        READ TABLE lt_sample_results
        ASSIGNING <wa_sample_results>
        WITH KEY inspchar = <wa_values>-inspchar
                 inspsample = <wa_inspection_points>-insppoint.

        IF sy-subrc IS INITIAL.
          ASSIGN <wa_values>-value->* TO <lv_value_to>.

          IF <wa_values>-value_fieldname = 'MEAN_VALUE'.
            ASSIGN COMPONENT 'ORIGINAL_INPUT' OF STRUCTURE <wa_sample_results> TO <lv_value_from>.
          ELSE.
            ASSIGN COMPONENT <wa_values>-value_fieldname OF STRUCTURE <wa_sample_results> TO <lv_value_from>.
          ENDIF.

          IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
            <lv_value_to> = <lv_value_from>.
          ENDIF.
          UNASSIGN: <lv_value_to>, <lv_value_from>.

          LOOP AT lt_operations_mapping ASSIGNING <wa_operations_mapping> WHERE field_type = zcl_qm_lab_bms_customizing=>ac_field_type_sample.
            ASSIGN COMPONENT <wa_operations_mapping>-target_field OF STRUCTURE <wa_sample_results> TO <lv_value_from>.
            ASSIGN COMPONENT <wa_operations_mapping>-source_field OF STRUCTURE <wa_values> TO <lv_value_to>.
            IF <lv_value_to> IS ASSIGNED AND <lv_value_from> IS ASSIGNED.
              <lv_value_to> = <lv_value_from>.
            ENDIF.
            UNASSIGN: <lv_value_to>, <lv_value_from>.
          ENDLOOP.
        ENDIF.
      ENDLOOP.

      EXIT.
    ENDLOOP.

    CLEAR lv_where_clause.
    FREE: lt_inspection_points, lt_sample_results, lt_operations_mapping.
  ENDMETHOD.                    "_get_existing_sample_values


  METHOD _lock.
    DATA: lv_insplot TYPE qenqavo-prueflos,
          lv_inspoper TYPE qenqavo-vornr.

    lv_insplot = iv_insplot.
    lv_inspoper = iv_inspoper.

    CALL FUNCTION 'ENQUEUE_EQAVO'
      EXPORTING
        mode_qenqavo   = 'E'
        mandant        = sy-mandt
        prueflos       = lv_insplot
        vornr          = lv_inspoper
        x_prueflos     = ' '
        x_vornr        = ' '
        _scope         = '2'
        _wait          = ' '
        _collect       = ' '
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.

    IF sy-subrc IS NOT INITIAL.
      ev_already_locked = abap_true.
      ev_lock_user = sy-msgv1.
    ENDIF.

    CLEAR: lv_inspoper, lv_insplot.
  ENDMETHOD.                    "_lock


  METHOD _save_additional_values_data.
    FIELD-SYMBOLS: <wa_values> TYPE zqm_s_lab_bms_measure_data,
                   <wa_messages> TYPE bapiret2.

    LOOP AT is_data_to_maintain-values ASSIGNING <wa_values>.
      UPDATE qasr
      SET zquantity    = <wa_values>-zquantity
          ztime        = <wa_values>-ztime
          ztemperature = <wa_values>-ztemperature
      WHERE prueflos = is_data_to_maintain-insplot
        AND vorglfnr = is_data_to_maintain-aplzl
        AND merknr = <wa_values>-inspchar
        AND probenr = is_data_to_maintain-inspsample.

      IF sy-subrc IS NOT INITIAL.
        APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
        <wa_messages>-id = 'ZQM_LABORATORIES_BMS'.
        <wa_messages>-number = 023.
        <wa_messages>-type = 'E'.
        <wa_messages>-message_v1 = is_data_to_maintain-insplot.
        <wa_messages>-message_v2 = is_data_to_maintain-inspoper.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDMETHOD.                    "_save_existing_sample_values


  METHOD _unlock.
    DATA: lv_insplot TYPE qenqavo-prueflos,
          lv_inspoper TYPE qenqavo-vornr.

    lv_insplot = iv_insplot.
    lv_inspoper = iv_inspoper.

    CALL FUNCTION 'DEQUEUE_EQAVO'
      EXPORTING
        mode_qenqavo = 'E'
        mandant      = sy-mandt
        prueflos     = lv_insplot
        vornr        = lv_inspoper
        x_prueflos   = ' '
        x_vornr      = ' '
        _scope       = '3'
        _synchron    = ' '
        _collect     = ' '.

    CLEAR: lv_inspoper, lv_insplot.
  ENDMETHOD.                    "_unlock


  METHOD _write_application_log.
    DATA wa_bal_s_log TYPE bal_s_log.
    DATA wa_msg TYPE bal_s_msg.
    DATA lv_log_handle TYPE balloghndl.
    DATA lt_log_handles TYPE bal_t_logh.

    CONSTANTS: co_bal_object TYPE balobj_d VALUE 'ZQM_BMS',
               co_bal_subobject TYPE balsubobj VALUE 'ZQM_BMS_LAB'.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    wa_bal_s_log-object = co_bal_object.
    wa_bal_s_log-subobject = co_bal_subobject.
    wa_bal_s_log-extnumber = |{ iv_insplot } { iv_inspoper }|.

* Create application log
    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = wa_bal_s_log
      IMPORTING
        e_log_handle = lv_log_handle.

    IF is_message IS NOT INITIAL.
      IF is_message-id IS NOT INITIAL.
        wa_msg-msgty = is_message-type.
        wa_msg-msgid = is_message-id.
        wa_msg-msgno = is_message-number.
        wa_msg-msgv1 = is_message-message_v1.
        wa_msg-msgv2 = is_message-message_v2.
        wa_msg-msgv3 = is_message-message_v3.
        wa_msg-msgv4 = is_message-message_v4.

        CALL FUNCTION 'BAL_LOG_MSG_ADD'
          EXPORTING
            i_log_handle = lv_log_handle
            i_s_msg      = wa_msg.
      ELSE.
        CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
          EXPORTING
            i_log_handle     = lv_log_handle
            i_msgty          = is_message-type
            i_text           = is_message-message
          EXCEPTIONS
            log_not_found    = 1
            msg_inconsistent = 2
            log_is_full      = 3
            OTHERS           = 4.
      ENDIF.

      CLEAR wa_msg.
    ENDIF.

    LOOP AT it_messages ASSIGNING <wa_messages>.
      IF <wa_messages>-id IS NOT INITIAL.
        wa_msg-msgty = <wa_messages>-type.
        wa_msg-msgid = <wa_messages>-id.
        wa_msg-msgno = <wa_messages>-number.
        wa_msg-msgv1 = <wa_messages>-message_v1.
        wa_msg-msgv2 = <wa_messages>-message_v2.
        wa_msg-msgv3 = <wa_messages>-message_v3.
        wa_msg-msgv4 = <wa_messages>-message_v4.

        CALL FUNCTION 'BAL_LOG_MSG_ADD'
          EXPORTING
            i_log_handle = lv_log_handle
            i_s_msg      = wa_msg.
      ELSE.
        CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
          EXPORTING
            i_log_handle     = lv_log_handle
            i_msgty          = <wa_messages>-type
            i_text           = <wa_messages>-message
          EXCEPTIONS
            log_not_found    = 1
            msg_inconsistent = 2
            log_is_full      = 3
            OTHERS           = 4.
      ENDIF.

      CLEAR: wa_msg.
    ENDLOOP.

    APPEND lv_log_handle TO lt_log_handles.

* Save application log
    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_t_log_handle = lt_log_handles.

    CLEAR: wa_msg, lv_log_handle, wa_bal_s_log.
    FREE: lt_log_handles.
  ENDMETHOD.                    "_write_application_log
ENDCLASS.
