*----------------------------------------------------------------------*
*       CLASS ZCL_QM_LABORATORIES_UTIL DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class ZCL_QM_LABORATORIES_UTIL definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF  ts_components.
            INCLUDE TYPE abap_componentdescr.
    TYPES: fieldtext TYPE string.
    TYPES:   END OF ts_components .
  types:
    tt_components TYPE STANDARD TABLE OF ts_components WITH KEY name .

  class-methods CREATE_SAMPLE_RESULT_CLAUSE
    importing
      !IS_DATA type ANY
    returning
      value(RV_WHERE) type STRING
    raising
      ZCX_QM_LABORATORIES .
  type-pools ABAP .
  class-methods EXTRACT_INSPCHARS
    importing
      !IT_COMPONENTS type ABAP_COMPONENT_TAB
    returning
      value(RT_INSPCHARS) type ZQM_T_LABORATORIES_INSPCHARS
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_CHAR_REQUIREMENTS
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IV_INSPCHAR type QIBPMERKNR
    returning
      value(RS_CHAR_REQUIREMENTS) type ZQM_S_LABORATORIES_CHARREQU
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_CODE_GROUP
    importing
      !IV_SEL_SET type QSEL_SET
      !IV_PLANT type QSEL_SET_P
      !IV_CATALOG_TYPE type QCAT_TYPE
    returning
      value(RV_CODE_GROUP) type QCODEGRP
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_FIELD_VALUES
    importing
      !IV_FIELDNAME type FIELDNAME
      !IV_WERK type WERKS_D
      !IV_KATALOGART type QKATART
      !IV_AUSWAHLMGE type QAUSWAHLMG
    returning
      value(RT_FIELD_VALUES) type ZQM_T_LABORATORIES_DD_VALUES
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_IDENT_KEY
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    returning
      value(RV_IDENT_KEY) type QSLWBEZ
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_KEYFIELDS_COMPONENTS
    importing
      !IV_IDENT_KEY type QSLWBEZ
    returning
      value(RT_COMPONENTS) type TT_COMPONENTS
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_TABLE_COMPONENTS
    importing
      !IT_DATA type ANY TABLE
    returning
      value(RT_COMPONENTS) type ABAP_COMPONENT_TAB
    raising
      ZCX_QM_LABORATORIES .
protected section.
private section.

  class-data AT_CHAR_REQUIREMENTS type ZQM_T_LABORATORIES_CHARREQU .
ENDCLASS.



CLASS ZCL_QM_LABORATORIES_UTIL IMPLEMENTATION.


METHOD create_sample_result_clause.
  DATA obj_struct TYPE REF TO cl_abap_structdescr.
  DATA lt_components TYPE abap_component_tab.

  FIELD-SYMBOLS: <wa_data> TYPE any,
                 <lv_field> TYPE any,
                 <wa_components> TYPE abap_componentdescr.

  ASSIGN is_data TO <wa_data>.

* Get fields of structure to determine user fields
  obj_struct ?= cl_abap_structdescr=>describe_by_data( p_data = <wa_data> ).
  lt_components = obj_struct->get_components( ).

  DELETE lt_components
  WHERE name NP 'USER*'.

  LOOP AT lt_components ASSIGNING <wa_components>.
    IF <wa_components>-name = 'USERC2'.
      CONTINUE.
    ENDIF.

    IF sy-tabix > 1.
      rv_where = |{ rv_where } and |.
    ENDIF.

    ASSIGN COMPONENT <wa_components>-name OF STRUCTURE <wa_data> TO <lv_field>.

    rv_where = |{ rv_where } { <wa_components>-name } = '{ <lv_field> }'|.

    UNASSIGN <lv_field>.
  ENDLOOP.

  FREE lt_components.
  FREE: obj_struct.
ENDMETHOD.


METHOD extract_inspchars.
  DATA wa_inspchars TYPE zqm_s_laboratories_inspchars.
  DATA lv_inspchars TYPE string.

  FIELD-SYMBOLS <wa_components> TYPE abap_componentdescr.

  CONSTANTS co_prefix TYPE string VALUE 'INSP_*'.

  LOOP AT it_components ASSIGNING <wa_components> WHERE name CP co_prefix.
    lv_inspchars = <wa_components>-name.
    REPLACE FIRST OCCURRENCE OF co_prefix IN lv_inspchars WITH space.
    CONDENSE lv_inspchars.

    wa_inspchars-fieldname = <wa_components>-name.
    wa_inspchars-inspchars = lv_inspchars.
    INSERT wa_inspchars INTO TABLE rt_inspchars.

    CLEAR: wa_inspchars, lv_inspchars.
  ENDLOOP.
ENDMETHOD.


METHOD get_char_requirements.
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
    rs_char_requirements = <wa_char_requirements_ext>.
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


METHOD get_field_values.
  DATA wa_field_values TYPE zqm_s_laboratories_dd_values.
  DATA lt_qpct TYPE STANDARD TABLE OF qpct.
  DATA lv_langu TYPE langu.

  FIELD-SYMBOLS <wa_qpct> TYPE qpct.

  DO 2 TIMES.
    IF sy-index = 1.
      lv_langu = sy-langu.
    ELSE.
      lv_langu = 'EN'.
    ENDIF.

* Get catalog values from database
    SELECT *
    FROM qpct AS a
    INNER JOIN qpac AS b
    ON b~katalogart = a~katalogart
    AND b~codegruppe = a~codegruppe
    AND b~code = a~code
    INTO CORRESPONDING FIELDS OF TABLE lt_qpct
    WHERE b~werks = IV_WERK
      AND b~katalogart = IV_KATALOGART
      AND b~auswahlmge = IV_AUSWAHLMGE
      AND b~gueltigab <= sy-datum
      AND a~sprache = lv_langu.

    IF sy-subrc IS INITIAL.
      EXIT.
    ENDIF.
  ENDDO.

  IF sy-subrc IS INITIAL.
    LOOP AT lt_qpct ASSIGNING <wa_qpct>.
      wa_field_values-fieldname = iv_fieldname.
      wa_field_values-key = <wa_qpct>-code.
      wa_field_values-value = <wa_qpct>-kurztext.
      INSERT wa_field_values INTO TABLE rt_field_values.
      CLEAR wa_field_values.
    ENDLOOP.

    READ TABLE rt_field_values
    WITH KEY key = ''
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      wa_field_values-fieldname = iv_fieldname.
      wa_field_values-key = ''.
      wa_field_values-value = ''.
      INSERT wa_field_values INTO rt_field_values INDEX 1.
      CLEAR wa_field_values.
    ENDIF.
  ENDIF.

  FREE lt_qpct.
  CLEAR: lv_langu, wa_field_values.
ENDMETHOD.


METHOD get_ident_key.
  DATA wa_insppoint_requirements TYPE bapi2045d5.

* Get inspeaction point requirement
  CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
    EXPORTING
      insplot                = iv_insplot
      inspoper               = iv_inspoper
    IMPORTING
      insppoint_requirements = wa_insppoint_requirements.

  rv_ident_key = wa_insppoint_requirements-ident_key.

  CLEAR wa_insppoint_requirements.
ENDMETHOD.


METHOD get_keyfields_components.
  DATA: wa_tq79 TYPE tq79,
        wa_tq79t TYPE tq79t.
  DATA lt_fields TYPE STANDARD TABLE OF ls_fields.
  DATA lv_fieldname TYPE string.
  DATA wa_dd04v TYPE dd04v.

  FIELD-SYMBOLS: <wa_fields> TYPE ls_fields,
                 <lv_field> TYPE any,
                 <wa_components> TYPE ts_components.

* Find inspection point key values
  SELECT SINGLE *
  INTO wa_tq79
  FROM tq79
  WHERE slwbez = iv_ident_key.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_laboratories
      EXPORTING
        textid = zcx_qm_laboratories=>insp_key_fields_not_found.
  ENDIF.

  SELECT SINGLE *
  INTO wa_tq79t
  FROM tq79t
  WHERE slwbez = iv_ident_key
    AND sprache = sy-langu.

  IF sy-subrc IS NOT INITIAL.
    SELECT SINGLE *
    INTO wa_tq79t
    FROM tq79t
    WHERE slwbez = iv_ident_key
      AND sprache = 'EN'.
  ENDIF.

  DO 6 TIMES.
    CASE sy-index.
      WHEN 1.
        ASSIGN COMPONENT 'USERC1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERC1SLW'.
      WHEN 2.
        ASSIGN COMPONENT 'USERC2AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERC2SLW'.
      WHEN 3.
        ASSIGN COMPONENT 'USERN1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERN1SLW'.
      WHEN 4.
        ASSIGN COMPONENT 'USERN2AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERN2SLW'.
      WHEN 5.
        ASSIGN COMPONENT 'USERD1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERD1SLW'.
      WHEN 6.
        ASSIGN COMPONENT 'USERT1AKT' OF STRUCTURE wa_tq79 TO <lv_field>.
        lv_fieldname = 'USERT1SLW'.
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

  CALL FUNCTION 'DDIF_DTEL_GET'
    EXPORTING
      name          = 'QIBPLOSNR'
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd04v_wa      = wa_dd04v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.

  APPEND INITIAL LINE TO rt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'INSPLOT'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPLOSNR' ).
  <wa_components>-fieldtext = wa_dd04v-ddtext.
  UNASSIGN <wa_components>.

  CALL FUNCTION 'DDIF_DTEL_GET'
    EXPORTING
      name          = 'QIBPVORNR'
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd04v_wa      = wa_dd04v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.

  APPEND INITIAL LINE TO rt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'INSPOPER'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QIBPVORNR' ).
  <wa_components>-fieldtext = wa_dd04v-ddtext.
  UNASSIGN <wa_components>.

  SORT lt_fields BY index.

  LOOP AT lt_fields ASSIGNING <wa_fields>.
    ASSIGN COMPONENT <wa_fields>-name OF STRUCTURE wa_tq79t TO <lv_field>.

    APPEND INITIAL LINE TO rt_components ASSIGNING <wa_components>.
    <wa_components>-name = <wa_fields>-name+0(6).
    <wa_components>-fieldtext = <lv_field>.

    IF <wa_components>-name CP 'USERC*'.
      <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_ENTNAHME_PROBENART' ).
    ELSEIF <wa_components>-name CP 'USERN*'.
      <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'INT4' ).
    ELSEIF <wa_components>-name CP 'USERD*'.
      <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'DATS' ).
    ELSEIF <wa_components>-name CP 'USERT*'.
      <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'UZEIT' ).
    ENDIF.

    UNASSIGN: <lv_field>, <wa_components>.
  ENDLOOP.

  CLEAR: wa_tq79, wa_tq79t, wa_dd04v.
ENDMETHOD.


METHOD get_table_components.
  DATA: obj_table_descr TYPE REF TO cl_abap_tabledescr,
        obj_struct_descr TYPE REF TO cl_abap_structdescr.

  obj_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = it_data ).
  obj_struct_descr ?= obj_table_descr->get_table_line_type( ).
  rt_components = obj_struct_descr->get_components( ).

  FREE: obj_table_descr, obj_struct_descr.
ENDMETHOD.
ENDCLASS.
