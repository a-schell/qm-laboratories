*----------------------------------------------------------------------*
*       CLASS ZCL_QM_LAB_BMS_READER DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zcl_qm_lab_bms_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_qm_lab_bms_reader .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_READER IMPLEMENTATION.


  METHOD zif_qm_lab_bms_reader~search.
    DATA: ra_lines      TYPE RANGE OF zbms_linienr,
          ra_workcenter TYPE RANGE OF qprplatz.
    DATA lt_insplot_list TYPE STANDARD TABLE OF bapi2045l1.
    DATA: lt_system_status TYPE STANDARD TABLE OF bapi2045ss,
          lt_user_status   TYPE STANDARD TABLE OF bapi2045us.
    DATA wa_language TYPE bapi2045la.
    DATA lt_operations TYPE STANDARD TABLE OF bapi2045l2.
    DATA wa_qals TYPE qals.
    DATA wa_insppoint_requirements TYPE bapi2045d5.
    DATA wa_return TYPE bapiret2.
    DATA wa_result TYPE zqm_s_lab_bms_search_result.
    DATA lv_creat_dat TYPE qdatumerst.
    DATA wa_operation TYPE bapi2045l2.

    DATA: wa_general               TYPE bapi2045d_il0,
          wa_task_list             TYPE bapi2045d_il1,
          wa_customer_include_data TYPE bapi2045ci.

    CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
               co_storno   TYPE j_istat VALUE 'I0224'.

    FIELD-SYMBOLS: <lt_lines>        TYPE ANY TABLE,
                   <lt_workcenter>   TYPE ANY TABLE,
                   <wa_insplot_list> TYPE bapi2045l1,
                   <wa_operations>   TYPE bapi2045l2.

* Fill ranges
    IF io_lines IS BOUND.
      ASSIGN io_lines->* TO <lt_lines>.
      APPEND LINES OF <lt_lines> TO ra_lines.
    ENDIF.

    IF io_working_group IS BOUND.
      ASSIGN io_working_group->* TO <lt_workcenter>.
      APPEND LINES OF <lt_workcenter> TO ra_workcenter.
    ENDIF.

    lv_creat_dat = sy-datum - 365.

* Get inspection lots
    CALL FUNCTION 'BAPI_INSPLOT_GETLIST'
      EXPORTING
        plant           = iv_werk
        max_rows        = 9999
        status_created  = 'X'
        status_released = 'X'
        status_ud       = ' '
        creat_dat       = lv_creat_dat
        selection_id    = ' '
      TABLES
        insplot_list    = lt_insplot_list.

    LOOP AT lt_insplot_list ASSIGNING <wa_insplot_list> WHERE insppoints = abap_true.
      FREE: lt_system_status, lt_user_status, lt_operations.
      CLEAR: wa_language, wa_general, wa_task_list.

* Get detail
      CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
        EXPORTING
          number                = <wa_insplot_list>-insplot
        IMPORTING
          general_data          = wa_general
          task_list_data        = wa_task_list
          customer_include_data = wa_customer_include_data.

* Check date
      IF wa_customer_include_data-zzlinienr NOT IN ra_lines OR
         ( wa_general-inspection_starts_on_date > iv_date OR wa_general-inspection_ends_on_date < iv_date ) OR
         ( ( wa_general-inspection_starts_on_date = iv_date AND wa_general-inspection_starts_at_time > iv_time ) OR ( wa_general-inspection_ends_on_date = iv_date AND wa_general-inspection_ends_at_time < iv_time ) ).

        CONTINUE.
      ENDIF.

* Set language to english
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

* Get operations
      CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
        EXPORTING
          number        = <wa_insplot_list>-insplot
        TABLES
          inspoper_list = lt_operations.

      LOOP AT lt_operations ASSIGNING <wa_operations> WHERE workcenter IN ra_workcenter.
        CLEAR: wa_qals, wa_insppoint_requirements, wa_return.

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
            operation              = wa_operation
            insppoint_requirements = wa_insppoint_requirements
            return                 = wa_return.

        wa_result-insplot = <wa_insplot_list>-insplot.
        wa_result-inspoper = <wa_operations>-inspoper.
        wa_result-date = iv_date.
        wa_result-time = iv_time.
        wa_result-sample_type = iv_sample_type.
        wa_result-txt_oper = <wa_operations>-txt_oper.
        wa_result-ident_key = wa_insppoint_requirements-ident_key.
        wa_result-plant = wa_general-plant.
        wa_result-linie = zcl_qm_lab_bms_util=>get_line( iv_insplot = <wa_insplot_list>-insplot ).

        INSERT wa_result INTO TABLE rt_result.
        CLEAR wa_result.
      ENDLOOP.
    ENDLOOP.

    CLEAR: wa_general, wa_insppoint_requirements, wa_customer_include_data.
    FREE: ra_lines, lt_insplot_list, ra_workcenter.
  ENDMETHOD.                    "zif_qm_lab_bms_reader~search


  METHOD zif_qm_lab_bms_reader~search_by_ballen_id.
    DATA wa_ball TYPE zbms_ball.
    DATA: lv_linienr TYPE zbms_linienr,
          lv_ballennr TYPE zbms_ballennr.
    DATA ra_lines TYPE RANGE OF zbms_linienr.
    DATA obj_lines TYPE REF TO data.

    FIELD-SYMBOLS: <wa_lines> LIKE LINE OF ra_lines,
                   <wa_result> TYPE zqm_s_lab_bms_search_result.

* Split ball id
    lv_linienr = iv_ballen_id+1(2).
    lv_ballennr = iv_ballen_id+3(6).

* Get ball data
    zcl_bms_bale_util=>search_bale_bynr( EXPORTING i_werks    = iv_werk
                                                   i_linienr  = lv_linienr
                                                   i_ballennr = lv_ballennr
                                         IMPORTING es_ball = wa_ball ).

    IF wa_ball IS INITIAL OR wa_ball-linienr IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ra_lines ASSIGNING <wa_lines>.
    <wa_lines>-sign = 'I'.
    <wa_lines>-option = 'EQ'.
    <wa_lines>-low = wa_ball-linienr.
    UNASSIGN <wa_lines>.

    GET REFERENCE OF ra_lines INTO obj_lines.

* Find data
    rt_result = me->zif_qm_lab_bms_reader~search( iv_werk          = iv_werk
                                                  io_lines         = obj_lines
                                                  io_working_group = io_working_group
                                                  iv_sample_type   = iv_sample_type
                                                  iv_date          = wa_ball-end_pdat
                                                  iv_time          = wa_ball-end_pzet ).

    LOOP AT rt_result ASSIGNING <wa_result>.
      <wa_result>-ballennr = wa_ball-ballennr.
    ENDLOOP.

    FREE: obj_lines.
    FREE: ra_lines.
    CLEAR: wa_ball, lv_linienr, lv_ballennr.
  ENDMETHOD.                    "zif_qm_lab_bms_reader~search_by_ballen_id


  METHOD zif_qm_lab_bms_reader~search_by_insplot.
    DATA: wa_general               TYPE bapi2045d_il0,
          wa_task_list             TYPE bapi2045d_il1,
          wa_customer_include_data TYPE bapi2045ci.
    DATA wa_language TYPE bapi2045la.
    DATA: lt_system_status TYPE STANDARD TABLE OF bapi2045ss,
          lt_user_status   TYPE STANDARD TABLE OF bapi2045us.
    DATA lt_operations TYPE STANDARD TABLE OF bapi2045l2.
    DATA wa_return TYPE bapiret2.
    DATA wa_result TYPE zqm_s_lab_bms_search_result.
    DATA wa_insppoint_requirements TYPE bapi2045d5.
    DATA: ra_workcenter TYPE RANGE OF qprplatz.

    CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
               co_storno   TYPE j_istat VALUE 'I0224'.

    FIELD-SYMBOLS: <wa_operations> TYPE bapi2045l2,
                   <lt_workcenter> TYPE ANY TABLE.

* Fill ranges
    IF io_working_group IS BOUND.
      ASSIGN io_working_group->* TO <lt_workcenter>.
      APPEND LINES OF <lt_workcenter> TO ra_workcenter.
    ENDIF.

* Get detail
    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number                = iv_insplot
      IMPORTING
        general_data          = wa_general
        task_list_data        = wa_task_list
        customer_include_data = wa_customer_include_data.

    IF wa_general IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
        EXPORTING
          textid     = zcx_qm_lab_bms_exceptions=>inspplot_not_found
          a_inspplot = iv_insplot.
    ENDIF.

* Set language to english
    wa_language-langu = 'EN'.

* Check status
    CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
      EXPORTING
        number        = iv_insplot
        language      = wa_language
      TABLES
        system_status = lt_system_status
        user_status   = lt_user_status.

    DELETE lt_system_status WHERE sys_status <> co_decision
                              AND sys_status <> co_storno.

    IF lt_system_status[] IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
        EXPORTING
          textid     = zcx_qm_lab_bms_exceptions=>inspplot_closed
          a_inspplot = iv_insplot.
    ENDIF.

* Get operations
    CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
      EXPORTING
        number        = iv_insplot
      TABLES
        inspoper_list = lt_operations.

    LOOP AT lt_operations ASSIGNING <wa_operations> WHERE workcenter IN ra_workcenter.
* Get operation detail
      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                = <wa_operations>-insplot
          inspoper               = <wa_operations>-inspoper
        IMPORTING
          insppoint_requirements = wa_insppoint_requirements
          return                 = wa_return.

      wa_result-insplot = iv_insplot.
      wa_result-inspoper = <wa_operations>-inspoper.
      wa_result-date = iv_date.
      wa_result-time = iv_time.
      wa_result-sample_type = iv_sample_type.
      wa_result-txt_oper = <wa_operations>-txt_oper.
      wa_result-ident_key = wa_insppoint_requirements-ident_key.
      wa_result-plant = wa_general-plant.
      wa_result-linie = zcl_qm_lab_bms_util=>get_line( iv_insplot = iv_insplot ).

      INSERT wa_result INTO TABLE rt_result.
      CLEAR wa_result.
    ENDLOOP.

    CLEAR: wa_general, wa_task_list, wa_language, wa_customer_include_data.
    FREE: lt_system_status, lt_system_status, lt_operations, ra_workcenter.
  ENDMETHOD.                    "zif_qm_lab_bms_reader~search_by_insplot


  METHOD zif_qm_lab_bms_reader~search_by_insplot_ballen_id.
    DATA wa_qals TYPE qals.
    DATA ra_lines TYPE RANGE OF zbms_linienr.
    DATA lt_table_fields TYPE string_table.

    FIELD-SYMBOLS: <wa_result> TYPE zqm_s_lab_bms_search_result,
                   <ra_lines> TYPE STANDARD TABLE.

    IF io_lines IS BOUND.
      ASSIGN io_lines->* TO <ra_lines>.
      APPEND LINES OF <ra_lines> TO ra_lines.
    ENDIF.

    lt_table_fields = zcl_qm_lab_bms_util=>get_table_fields( iv_tabname = 'QALS' ).

    IF iv_include_date = abap_true.
* Find inspection lot by bale number
      SELECT (lt_table_fields)
      INTO wa_qals
      FROM qals
      WHERE werk = iv_werk
        AND zzlinienr IN ra_lines
        AND ( zzbms_ballennr_von <= iv_ballen_id AND
              zzbms_ballennr_bis >= iv_ballen_id )
        AND ( ( pastrterm < iv_date ) OR
              ( pastrterm = iv_date AND
                pastrzeit <= iv_time ) )
        AND ( ( paendterm > iv_date ) OR
              ( paendterm = iv_date AND
                paendzeit >= iv_time ) )
        ORDER BY prueflos.
        EXIT.
      ENDSELECT.
    ELSE.
      SELECT (lt_table_fields)
      INTO wa_qals
      FROM qals
      WHERE werk = iv_werk
      AND zzlinienr IN ra_lines
      AND ( zzbms_ballennr_von <= iv_ballen_id AND
            zzbms_ballennr_bis >= iv_ballen_id )
      ORDER BY prueflos.
        EXIT.
      ENDSELECT.
    ENDIF.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

* Search by insplot number
    rt_result = me->zif_qm_lab_bms_reader~search_by_insplot( iv_insplot       = wa_qals-prueflos
                                                             io_working_group = io_working_group
                                                             iv_sample_type   = iv_sample_type
                                                             iv_date          = iv_date
                                                             iv_time          = iv_time ).

    LOOP AT rt_result ASSIGNING <wa_result>.
      <wa_result>-ballennr = iv_ballen_id.
    ENDLOOP.

    FREE lt_table_fields.
    FREE ra_lines.
    CLEAR wa_qals.
  ENDMETHOD.                    "ZIF_QM_LAB_BMS_READER~SEARCH_BY_INSPLOT_BALLEN_ID


  METHOD zif_qm_lab_bms_reader~search_by_physical_sample.
    DATA lv_insplot TYPE qibplosnr.

* Find inspection lot by physical sample id
    SELECT SINGLE plos2
    FROM qprs
    INTO lv_insplot
    WHERE phynr = iv_phynr.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

* Get data from inspection lot
    rt_result = me->zif_qm_lab_bms_reader~search_by_insplot( iv_insplot       = lv_insplot
                                                             io_working_group = io_working_group
                                                             iv_date          = iv_date
                                                             iv_time          = iv_time ).

    CLEAR lv_insplot.
  ENDMETHOD.                    "zif_qm_lab_bms_reader~search_by_physical_sample
ENDCLASS.
