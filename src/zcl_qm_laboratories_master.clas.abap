class ZCL_QM_LABORATORIES_MASTER definition
  public
  final
  create public .

public section.

  interfaces ZIF_QM_LABORATORIES_MASTER .
protected section.
private section.

  types:
    tt_insppoints TYPE STANDARD TABLE OF bapi2045l4 .

  methods _FILL_INITIAL_DATA
    importing
      !IV_DATE type DATS
      !IV_TIME type SY-UZEIT
      !IS_OVERVIEW_DATA type ZQM_S_LABORATORIES_OVERVIEW
    changing
      !CS_DATA type ANY
    raising
      ZCX_QM_LABORATORIES .
  methods _GET_EXISTING_SAMPLE_RESULT
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IS_DATA type ANY
    exporting
      value(ET_SAMPLE_RESULTS) type RPLM_TT_BAPI2045D3
      value(ET_INSPECTION_POINTS) type TT_INSPPOINTS
    raising
      ZCX_QM_LABORATORIES .
  methods _GET_PLANTEXT
    importing
      !IV_PLNNR type PLNNR
      !IV_PLNAL type PLNAL
    returning
      value(RV_TEXT) type PLANTEXT .
ENDCLASS.



CLASS ZCL_QM_LABORATORIES_MASTER IMPLEMENTATION.


METHOD zif_qm_laboratories_master~get_data_object.
  DATA obj_table TYPE REF TO cl_abap_tabledescr.
  DATA: wa_operation TYPE bapi2045l2,
        wa_insppoint_requirements TYPE bapi2045d5.
  DATA lt_key_components TYPE zcl_qm_laboratories_util=>tt_components.
  DATA lt_components TYPE abap_component_tab.
  DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.
  DATA lv_fieldname TYPE fieldname.

  FIELD-SYMBOLS: <wa_key_components> TYPE zcl_qm_laboratories_util=>ts_components,
                 <wa_components> TYPE abap_componentdescr,
                 <wa_field_texts> TYPE zqm_s_laboratories_field_head,
                 <wa_char_requirements> TYPE bapi2045d1.

* Get inspeaction point requirement
  CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
    EXPORTING
      insplot                = iv_insplot
      inspoper               = iv_inspoper
      read_char_requirements = abap_true
    IMPORTING
      operation              = wa_operation
      insppoint_requirements = wa_insppoint_requirements
    TABLES
      char_requirements      = lt_char_requirements.

  ev_ident_key = wa_insppoint_requirements-ident_key.

* Get key components
  lt_key_components = zcl_qm_laboratories_util=>get_keyfields_components( iv_ident_key = ev_ident_key ).

  LOOP AT lt_key_components ASSIGNING <wa_key_components>.
    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    MOVE-CORRESPONDING <wa_key_components> TO <wa_components>.
    UNASSIGN <wa_components>.

    APPEND INITIAL LINE TO et_field_texts ASSIGNING <wa_field_texts>.
    <wa_field_texts>-fieldname = <wa_key_components>-name.
    <wa_field_texts>-text = <wa_key_components>-fieldtext.
    UNASSIGN <wa_field_texts>.
  ENDLOOP.

  IF lt_components[] IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_laboratories
      EXPORTING
        textid = zcx_qm_laboratories=>no_table_fields.
  ENDIF.

* Add chars to structure
  LOOP AT lt_char_requirements ASSIGNING <wa_char_requirements>.
    lv_fieldname = |INSP_{ <wa_char_requirements>-inspchar }|.

    APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
    <wa_components>-name = lv_fieldname.
    <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).

    APPEND INITIAL LINE TO et_field_texts ASSIGNING <wa_field_texts>.
    <wa_field_texts>-fieldname = lv_fieldname.
    <wa_field_texts>-text = <wa_char_requirements>-char_descr.
    UNASSIGN <wa_field_texts>.

    IF <wa_char_requirements>-sel_set1 IS NOT INITIAL.
      APPEND LINES OF zcl_qm_laboratories_util=>get_field_values( iv_fieldname  = lv_fieldname
                                                                  iv_werk       = wa_operation-plant
                                                                  iv_katalogart = <wa_char_requirements>-cat_type1
                                                                  iv_auswahlmge = <wa_char_requirements>-sel_set1 ) TO et_field_values.
    ENDIF.

    CLEAR: lv_fieldname.
  ENDLOOP.

* Create data object
  eo_structure_descr = cl_abap_structdescr=>create( lt_components ).
  obj_table ?= cl_abap_tabledescr=>create( p_line_type = eo_structure_descr ).
  CREATE DATA eo_data_object TYPE HANDLE obj_table.

  FREE: lt_char_requirements, lt_key_components.
  CLEAR: wa_insppoint_requirements, wa_operation.
  FREE: obj_table.
ENDMETHOD.


METHOD zif_qm_laboratories_master~get_init_list_edit_data.
  DATA lt_overview_data TYPE zqm_t_laboratories_overview.
  DATA: lt_inspection_points TYPE tt_insppoints,
        lt_sample_results TYPE rplm_tt_bapi2045d3.
  DATA lv_fieldname TYPE string.
  DATA wa_char_requirements TYPE zqm_s_laboratories_charrequ.

  FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
                 <wa_data> TYPE any,
                 <lv_field> TYPE any,
                 <lv_field_from> TYPE any,
                 <wa_overview_data> TYPE zqm_s_laboratories_overview,
                 <wa_sample_results> TYPE bapi2045d3,
                 <wa_inspection_points> TYPE bapi2045l4.

  lt_overview_data = it_overview_data.

  DELETE lt_overview_data
  WHERE inspoper <> iv_inspoper.

  ASSIGN ct_data_table TO <lt_data>.

  LOOP AT lt_overview_data ASSIGNING <wa_overview_data>.
    APPEND INITIAL LINE TO <lt_data> ASSIGNING <wa_data>.
    me->_fill_initial_data( EXPORTING iv_date = iv_selected_date
                                      iv_time = iv_selected_time
                                      is_overview_data = <wa_overview_data>
                            CHANGING cs_data = <wa_data> ).

    me->_get_existing_sample_result( EXPORTING iv_insplot  = <wa_overview_data>-insplot
                                               iv_inspoper = <wa_overview_data>-inspoper
                                               is_data     = <wa_data>
                                     IMPORTING et_sample_results    = lt_sample_results
                                               et_inspection_points = lt_inspection_points  ).

    IF lt_sample_results[] IS NOT INITIAL.
      SORT lt_sample_results BY insplot inspoper inspchar inspsample.

      LOOP AT lt_inspection_points ASSIGNING <wa_inspection_points>.
        IF sy-tabix > 1.
          APPEND INITIAL LINE TO <lt_data> ASSIGNING <wa_data>.
          me->_fill_initial_data( EXPORTING iv_date = iv_selected_date
                                            iv_time = iv_selected_time
                                            is_overview_data = <wa_overview_data>
                                  CHANGING cs_data = <wa_data> ).

          MOVE-CORRESPONDING <wa_inspection_points> TO <wa_data>.
        ENDIF.

        LOOP AT lt_sample_results ASSIGNING <wa_sample_results> WHERE insplot  = <wa_inspection_points>-insplot
                                                                  AND inspoper = <wa_inspection_points>-inspoper
                                                                  AND inspsample = <wa_inspection_points>-insppoint.

* Create inspection point fieldname
          lv_fieldname = |INSP_{ <wa_sample_results>-inspchar }|.

          ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_data> TO <lv_field>.
          IF sy-subrc IS INITIAL.
* Get char requirments
            wa_char_requirements = zcl_qm_laboratories_util=>get_char_requirements( iv_insplot  = iv_insplot
                                                                                    iv_inspoper = iv_inspoper
                                                                                    iv_inspchar = <wa_sample_results>-inspchar ).

            ASSIGN COMPONENT wa_char_requirements-fieldname OF STRUCTURE <wa_sample_results> TO <lv_field_from>.
            IF sy-subrc IS INITIAL.
              <lv_field> = <lv_field_from>.
            ENDIF.

            UNASSIGN <lv_field_from>.
          ENDIF.

          UNASSIGN: <lv_field>.
          CLEAR: lv_fieldname, wa_char_requirements.
        ENDLOOP.
      ENDLOOP.
    ENDIF.

    FREE: lt_sample_results, lt_inspection_points.
  ENDLOOP.

  SORT <lt_data>.

  FREE lt_overview_data.
ENDMETHOD.


METHOD zif_qm_laboratories_master~get_overview_data.
  DATA lt_insplot_list TYPE STANDARD TABLE OF bapi2045l1.
  DATA: wa_general TYPE bapi2045d_il0,
        wa_task_list TYPE bapi2045d_il1.
  DATA lt_operations TYPE STANDARD TABLE OF bapi2045l2.
  DATA wa_insppoint_requirements TYPE bapi2045d5.
  DATA wa_return TYPE bapiret2.
  DATA wa_language TYPE bapi2045la.
  DATA: lt_system_status TYPE STANDARD TABLE OF bapi2045ss,
        lt_user_status TYPE STANDARD TABLE OF bapi2045us.
  DATA lt_inspoints TYPE STANDARD TABLE OF bapi2045l4.
  DATA wa_qals TYPE qals.

  FIELD-SYMBOLS: <wa_insplot_list> TYPE bapi2045l1,
                 <wa_data> TYPE zqm_s_laboratories_overview,
                 <wa_operations> TYPE bapi2045l2,
                 <wa_system_status> TYPE bapi2045ss.

  CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
             co_storno TYPE j_istat VALUE 'I0224'.

  CALL FUNCTION 'BAPI_INSPLOT_GETLIST'
    EXPORTING
      plant           = iv_werk
      max_rows        = 9999
      status_created  = 'X'
      status_released = 'X'
      status_ud       = ' '
      selection_id    = ' '
    TABLES
      insplot_list    = lt_insplot_list.

  LOOP AT lt_insplot_list ASSIGNING <wa_insplot_list> WHERE insppoints = abap_true.
    FREE: lt_system_status, lt_user_status.
    CLEAR wa_language.
    wa_language-langu = 'EN'.

* Check status
    CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
      EXPORTING
        number        = <wa_insplot_list>-insplot
        language      = wa_language
      TABLES
        system_status = lt_system_status
        user_status   = lt_user_status.

    DELETE lt_system_status WHERE sys_status <> co_decision
                              AND sys_status <> co_storno.

    IF lt_system_status[] IS NOT INITIAL.
      CONTINUE.
    ENDIF.

* Get detail
    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number         = <wa_insplot_list>-insplot
      IMPORTING
        general_data   = wa_general
        task_list_data = wa_task_list.

* Get operations
    CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
      EXPORTING
        number        = <wa_insplot_list>-insplot
      TABLES
        inspoper_list = lt_operations.

    LOOP AT lt_operations ASSIGNING <wa_operations>.
      CALL FUNCTION 'QPSE_LOT_READ'
        EXPORTING
          i_prueflos = <wa_operations>-insplot
        IMPORTING
          e_qals     = wa_qals.

      IF wa_qals-slwbez IS INITIAL.
        CONTINUE.
      ENDIF.

* Get operation detail
      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                = <wa_operations>-insplot
          inspoper               = <wa_operations>-inspoper
        IMPORTING
          insppoint_requirements = wa_insppoint_requirements
          return                 = wa_return.

      IF wa_insppoint_requirements IS NOT INITIAL.
        APPEND INITIAL LINE TO rt_data ASSIGNING <wa_data>.
        <wa_data>-insplot = <wa_insplot_list>-insplot.
        <wa_data>-inspoper = <wa_operations>-inspoper.
        <wa_data>-vorktxt = <wa_operations>-txt_oper.
*        <wa_data>-linie =
        <wa_data>-ktext = me->_get_plantext( iv_plnnr = wa_task_list-task_list_number
                                             iv_plnal = wa_task_list-task_list_counter ).
      ENDIF.

      UNASSIGN <wa_data>.
    ENDLOOP.

    FREE: lt_operations.
    CLEAR: wa_general, wa_task_list.
  ENDLOOP.

  DELETE rt_data
  WHERE linie IS INITIAL.

  FREE lt_insplot_list.
ENDMETHOD.


METHOD zif_qm_laboratories_master~save_inspection_multi.
  DATA lt_components TYPE abap_component_tab.
  DATA wa_insp_point TYPE bapi2045l4.
  DATA lt_inspection_chars TYPE zqm_t_laboratories_inspchars.
  DATA lt_sample_results TYPE STANDARD TABLE OF bapi2045d3.
  DATA wa_return TYPE bapiret2.
  DATA lv_index TYPE i.
  DATA wa_char_requirements TYPE zqm_s_laboratories_charrequ.

  FIELD-SYMBOLS: <lt_data> TYPE ANY TABLE,
                 <wa_data> TYPE any,
                 <lv_insplot> TYPE any,
                 <lv_inspoper> TYPE any,
                 <lv_value> TYPE any,
                 <lv_field_to> TYPE any,
                 <wa_inspection_chars> TYPE zqm_s_laboratories_inspchars,
                 <wa_sample_results> TYPE bapi2045d3.

  ASSIGN io_data->* TO <lt_data>.

* Get structure components and extract inspection points
  lt_components = zcl_qm_laboratories_util=>get_table_components( it_data = <lt_data> ).
  lt_inspection_chars = zcl_qm_laboratories_util=>extract_inspchars( it_components = lt_components ).

  LOOP AT <lt_data> ASSIGNING <wa_data>.
    lv_index = lv_index + 1.

* Assign key fields
    ASSIGN COMPONENT 'INSPLOT' OF STRUCTURE <wa_data> TO <lv_insplot>.
    ASSIGN COMPONENT 'INSPOPER' OF STRUCTURE <wa_data> TO <lv_inspoper>.

* Move values
    MOVE-CORRESPONDING <wa_data> TO wa_insp_point.

    LOOP AT lt_inspection_chars ASSIGNING <wa_inspection_chars>.
* Get char requirments
      wa_char_requirements = zcl_qm_laboratories_util=>get_char_requirements( iv_insplot  = <lv_insplot>
                                                                              iv_inspoper = <lv_inspoper>
                                                                              iv_inspchar = <wa_inspection_chars>-inspchars ).

* Set sample value
      ASSIGN COMPONENT <wa_inspection_chars>-fieldname OF STRUCTURE <wa_data> TO <lv_value>.
      IF sy-subrc IS INITIAL AND <lv_value> IS NOT INITIAL.
        APPEND INITIAL LINE TO lt_sample_results ASSIGNING <wa_sample_results>.
        <wa_sample_results>-insplot = <lv_insplot>.
        <wa_sample_results>-inspoper = <lv_inspoper>.
        <wa_sample_results>-inspchar = <wa_inspection_chars>-inspchars.

        ASSIGN COMPONENT wa_char_requirements-fieldname OF STRUCTURE <wa_sample_results> TO <lv_field_to>.
        IF sy-subrc IS INITIAL.
          <lv_field_to> = <lv_value>.

          IF wa_char_requirements-code_grp_fieldname IS NOT INITIAL.
            ASSIGN COMPONENT wa_char_requirements-code_grp_fieldname OF STRUCTURE <wa_sample_results> TO <lv_field_to>.
            IF sy-subrc IS INITIAL.
              <lv_field_to> = wa_char_requirements-code_group.
            ENDIF.
          ENDIF.
        ENDIF.

        UNASSIGN <wa_sample_results>.
      ENDIF.

      UNASSIGN: <lv_value>, <lv_field_to>.
    ENDLOOP.

* Save data
    CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
      EXPORTING
        insplot              = <lv_insplot>
        inspoper             = <lv_inspoper>
        insppointdata        = wa_insp_point
        handheld_application = ' '
      IMPORTING
        return               = wa_return
      TABLES
        sample_results       = lt_sample_results.

    wa_return-row = lv_index.
    IF wa_return-type = 'E' OR wa_return-type = 'A'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    ENDIF.

    FREE: lt_sample_results, wa_return, wa_insp_point.
    UNASSIGN: <lv_insplot>, <lv_inspoper>.
  ENDLOOP.

  CLEAR lv_index.
  FREE: lt_components, lt_inspection_chars.
ENDMETHOD.


METHOD _fill_initial_data.
  FIELD-SYMBOLS: <wa_data> TYPE any,
                 <lv_field> TYPE any.

  ASSIGN cs_data TO <wa_data>.
  MOVE-CORRESPONDING is_overview_data TO <wa_data>.

  ASSIGN COMPONENT 'USERD1' OF STRUCTURE <wa_data> TO <lv_field>.
  IF sy-subrc IS INITIAL.
    <lv_field> = iv_date.
  ENDIF.

  ASSIGN COMPONENT 'USERT1' OF STRUCTURE <wa_data> TO <lv_field>.
  IF sy-subrc IS INITIAL.
    <lv_field> = iv_time.
  ENDIF.

  ASSIGN COMPONENT 'USERN2' OF STRUCTURE <wa_data> TO <lv_field>.
  IF sy-subrc IS INITIAL.
    <lv_field> = is_overview_data-linie.
  ENDIF.

  ASSIGN COMPONENT 'USERC2' OF STRUCTURE <wa_data> TO <lv_field>.
  IF sy-subrc IS INITIAL.
    <lv_field> = 'N'.
  ENDIF.
ENDMETHOD.


METHOD _get_existing_sample_result.
  DATA: lt_inspection_points TYPE STANDARD TABLE OF bapi2045l4,
        lt_sample_results TYPE STANDARD TABLE OF bapi2045d3.
  DATA lv_where TYPE string.

  FIELD-SYMBOLS: <wa_inspection_points> TYPE bapi2045l4,
                 <wa_sample_results> TYPE bapi2045d3.

* Find inspection points with sample results
  CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
    EXPORTING
      insplot             = iv_insplot
      inspoper            = iv_inspoper
      read_insppoints     = abap_true
      read_sample_results = abap_true
      char_filter_no      = '1   '
      char_filter_tcode   = 'QE11'
      max_insppoints      = 100
      insppoint_from      = 0
    TABLES
      insppoints          = lt_inspection_points
      sample_results      = lt_sample_results.

* Get where clause
  lv_where = zcl_qm_laboratories_util=>create_sample_result_clause( is_data = is_data ).

  LOOP AT lt_inspection_points ASSIGNING <wa_inspection_points> WHERE (lv_where).
    LOOP AT lt_sample_results ASSIGNING <wa_sample_results> WHERE insplot = <wa_inspection_points>-insplot
                                                              AND inspoper = <wa_inspection_points>-inspoper
                                                              AND inspsample = <wa_inspection_points>-insppoint.

      APPEND <wa_sample_results> TO et_sample_results.
    ENDLOOP.

    IF sy-subrc IS INITIAL.
      APPEND <wa_inspection_points> TO et_inspection_points.
    ENDIF.
  ENDLOOP.

  CLEAR lv_where.
  FREE: lt_inspection_points, lt_sample_results.
ENDMETHOD.


METHOD _get_plantext.
  SELECT SINGLE ktext
  FROM plko
  INTO rv_text
  WHERE plnnr = iv_plnnr
    AND plnal = iv_plnal.
ENDMETHOD.
ENDCLASS.
