class ZCL_QM_CHAR_CALCULATION definition
  public
  final
  create public .

public section.

  constants AC_VT_WERKS type ZQM_CALC_VALUE_TYPE value 1. "#EC NOTEXT

  methods CALCULATE
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
      !IT_SOURCE_CHARS type ZQM_T_CALCULATION_SOURCE
    returning
      value(RV_CALCULATED_VALUE) type STRING
    raising
      ZCX_QM_CHAR_CALCULATION .
  methods CONSTRUCTOR
    raising
      ZCX_QM_CHAR_CALCULATION .
  methods GET_SOURCE_CHARS
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
    returning
      value(RT_CHARS) type ZQM_T_QMERKNR
    raising
      ZCX_QM_CHAR_CALCULATION .
  type-pools ABAP .
  methods IS_CHAR_CALCULATED
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
    returning
      value(RV_IS_CALCULATED) type ABAP_BOOL
    raising
      ZCX_QM_CHAR_CALCULATION .
protected section.
private section.

  methods _GET_HEADER
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
    returning
      value(RS_HEADER) type ZQM_S_CALCULATION_HEADER
    raising
      ZCX_QM_CHAR_CALCULATION .
  methods _GET_ITEMS
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
    returning
      value(RT_ITEMS) type ZQM_T_CALCULATION_ITEMS
    raising
      ZCX_QM_CHAR_CALCULATION .
  methods _GET_PARAMETERS
    importing
      !IV_WERKS type WERKS_D
      !IV_MKMNR type QMERKNR
    returning
      value(RT_PARAMETERS) type ZQM_T_CALCULATION_PARAMETERS
    raising
      ZCX_QM_CHAR_CALCULATION .
ENDCLASS.



CLASS ZCL_QM_CHAR_CALCULATION IMPLEMENTATION.


METHOD calculate.
  DATA wa_calc_header TYPE zqm_s_calculation_header.
  DATA lt_calc_items TYPE zqm_t_calculation_items.
  DATA lt_calc_parameters TYPE zqm_t_calculation_parameters.
  DATA: lt_parameters TYPE abap_parmbind_tab,
        wa_parameters TYPE abap_parmbind.
  DATA obj_class_descr TYPE REF TO cl_abap_classdescr.
  DATA obj_param_type TYPE REF TO cl_abap_datadescr.
  DATA obj_root_exception TYPE REF TO cx_root.

  FIELD-SYMBOLS: <wa_calc_items> TYPE zqm_s_calculation_item,
                 <wa_calc_parameters> TYPE zqm_s_calculation_parameter,
                 <wa_source_chars> TYPE zqm_s_calculation_source,
                 <lv_value> TYPE any,
                 <wa_methods> TYPE abap_methdescr,
                 <wa_method_parameters> TYPE abap_parmdescr,
                 <wa_parameters> TYPE abap_parmbind.

  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

* Get settings
  wa_calc_header = me->_get_header( iv_werks = iv_werks
                                    iv_mkmnr = iv_mkmnr ).

  lt_calc_items = me->_get_items( iv_werks = iv_werks
                                  iv_mkmnr = iv_mkmnr ).

  TRY.
      lt_calc_parameters = me->_get_parameters( iv_werks = iv_werks
                                                iv_mkmnr = iv_mkmnr ).
    CATCH zcx_qm_char_calculation.
* If no parameter customizing is found this is okay
  ENDTRY.

  IF wa_calc_header-class IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>no_class.
  ENDIF.

  obj_class_descr ?= cl_abap_classdescr=>describe_by_name( p_name = wa_calc_header-class ).

  READ TABLE obj_class_descr->methods
  ASSIGNING <wa_methods>
  WITH KEY name = wa_calc_header-method.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid      = zcx_qm_char_calculation=>method_not_found
        class_name  = wa_calc_header-class
        method_name = wa_calc_header-method.
  ENDIF.

  LOOP AT <wa_methods>-parameters ASSIGNING <wa_method_parameters>.
    obj_param_type ?= obj_class_descr->get_method_parameter_type( p_method_name    = <wa_methods>-name
                                                                  p_parameter_name = <wa_method_parameters>-name ).

    wa_parameters-name = <wa_method_parameters>-name.

    CASE <wa_method_parameters>-parm_kind.
      WHEN cl_abap_classdescr=>exporting.
        wa_parameters-kind = cl_abap_classdescr=>importing.
      WHEN cl_abap_classdescr=>importing.
        wa_parameters-kind = cl_abap_classdescr=>exporting.
    ENDCASE.

    CREATE DATA wa_parameters-value TYPE (obj_param_type->absolute_name).
    ASSIGN wa_parameters-value->* TO <lv_value>.

    IF <lv_value> IS ASSIGNED.
      READ TABLE lt_calc_items
      ASSIGNING <wa_calc_items>
      WITH KEY parameter_name = <wa_method_parameters>-name.

      IF sy-subrc IS INITIAL.
        READ TABLE it_source_chars
        ASSIGNING <wa_source_chars>
        WITH KEY mkmnr = <wa_calc_items>-calc_mkmnr.

        IF sy-subrc IS INITIAL.
          <lv_value> = <wa_source_chars>-value.
        ENDIF.
      ELSE.
        READ TABLE lt_calc_parameters
        ASSIGNING <wa_calc_parameters>
        WITH KEY parameter_name = <wa_method_parameters>-name.

        IF sy-subrc IS INITIAL.
          CASE <wa_calc_parameters>-value_type.
            WHEN ac_vt_werks.
              <lv_value> = iv_werks.
          ENDCASE.
        ENDIF.
      ENDIF.
    ENDIF.

    INSERT wa_parameters INTO TABLE lt_parameters.

    UNASSIGN <lv_value>.
    CLEAR wa_parameters.
    FREE obj_param_type.
  ENDLOOP.

  TRY.
      CALL METHOD (wa_calc_header-class)=>(wa_calc_header-method) PARAMETER-TABLE lt_parameters.
    CATCH cx_root INTO obj_root_exception.
      RAISE EXCEPTION TYPE zcx_qm_char_calculation
        EXPORTING
          textid     = zcx_qm_char_calculation=>class_exception
          error_text = obj_root_exception->get_text( ).

      FREE obj_root_exception.
  ENDTRY.

  READ TABLE lt_parameters
  ASSIGNING <wa_parameters>
  WITH KEY name = wa_calc_header-parameter_name.

  IF sy-subrc IS INITIAL.
    ASSIGN <wa_parameters>-value->* TO <lv_value>.
    rv_calculated_value = <lv_value>.
  ENDIF.

  FREE: obj_class_descr, obj_param_type.
  FREE: lt_calc_items, lt_calc_parameters, lt_parameters.
  CLEAR wa_calc_header.
ENDMETHOD.


method CONSTRUCTOR.
endmethod.


METHOD GET_SOURCE_CHARS.
  DATA lt_items TYPE zqm_t_calculation_items.

  FIELD-SYMBOLS <wa_items> TYPE zqm_s_calculation_item.

  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

  lt_items = me->_get_items( iv_mkmnr = iv_mkmnr
                             iv_werks = iv_werks ).

  LOOP AT lt_items ASSIGNING <wa_items>.
    INSERT <wa_items>-calc_mkmnr INTO TABLE rt_chars.
  ENDLOOP.

  FREE lt_items.
ENDMETHOD.


METHOD is_char_calculated.
  DATA lv_mkmnr TYPE qmerknr.

  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

* Check against header table if char is calculated
  SELECT SINGLE mkmnr
  FROM zqm_calc_h
  INTO lv_mkmnr
  WHERE werks = iv_werks
    AND mkmnr = iv_mkmnr.

  IF sy-subrc IS INITIAL.
    rv_is_calculated = abap_true.
  ELSE.
    rv_is_calculated = abap_false.
  ENDIF.

  CLEAR lv_mkmnr.
ENDMETHOD.


METHOD _get_header.
  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

  SELECT SINGLE werks
                mkmnr
                class
                method
                parameter_name
   INTO rs_header
   FROM zqm_calc_h
   WHERE werks = iv_werks
     AND mkmnr = iv_mkmnr.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>no_header_customizing.
  ENDIF.
ENDMETHOD.                    "_GET_HEADER


METHOD _get_items.
  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

* Select chars from database
  SELECT werks
         mkmnr
         calc_mkmnr
         parameter_name
  FROM zqm_calc_c
  INTO TABLE rt_items
  WHERE werks = iv_werks
    AND mkmnr = iv_mkmnr.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>no_items_customizing.
  ENDIF.
ENDMETHOD.


METHOD _get_parameters.
  IF iv_mkmnr IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>char_missing.
  ENDIF.

* Select chars from database
  SELECT werks
         mkmnr
         value_type
         parameter_name
  FROM zqm_calc_p
  INTO TABLE rt_parameters
  WHERE werks = iv_werks
    AND mkmnr = iv_mkmnr.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_char_calculation
      EXPORTING
        textid = zcx_qm_char_calculation=>no_param_customizing.
  ENDIF.
ENDMETHOD.
ENDCLASS.
