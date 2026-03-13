class ZCL_QM_LABORATORIES_GUI definition
  public
  final
  create public .

public section.

  interfaces ZIF_QM_LABORATORIES_GUI .
protected section.
private section.

  methods _GET_FIELDCATALOG_BY_NAME
    importing
      !IV_STRUCTURE_NAME type DD02L-TABNAME
    returning
      value(RT_FIELDCATALOG) type LVC_T_FCAT
    raising
      ZCX_QM_LABORATORIES .
  methods _GET_FIELDCATALOG_BY_STUCT
    importing
      !IO_STRUCTURE_DESCR type ref to CL_ABAP_STRUCTDESCR
    returning
      value(RT_FIELDCATALOG) type LVC_T_FCAT
    raising
      ZCX_QM_LABORATORIES .
ENDCLASS.



CLASS ZCL_QM_LABORATORIES_GUI IMPLEMENTATION.


METHOD zif_qm_laboratories_gui~get_alv_fieldcatalog.
  IF iv_structure_name IS SUPPLIED.
    rt_fieldcatalog = me->_get_fieldcatalog_by_name( iv_structure_name = iv_structure_name ).
  ELSEIF io_structure_descr IS SUPPLIED.
    rt_fieldcatalog = me->_get_fieldcatalog_by_stuct( io_structure_descr = io_structure_descr ).
  ENDIF.
ENDMETHOD.


METHOD zif_qm_laboratories_gui~get_dynamic_dynpro_fields.
  DATA wa_insppoint_requirements TYPE bapi2045d5.
  DATA lt_key_components TYPE zcl_qm_laboratories_util=>tt_components.
  DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.
  DATA: lt_dynpro_fields TYPE rsdsfields_t,
        lt_dynpro_fields_text TYPE wcb_rsdstexts_tab.
  DATA wa_restriction TYPE sscr_restrict_ds.

  FIELD-SYMBOLS: <wa_dynpro_fields> TYPE rsdsfields,
                 <wa_key_components> TYPE zcl_qm_laboratories_util=>ts_components,
                 <wa_opt_list> TYPE sscr_opt_list,
                 <wa_ass_ds> TYPE sscr_ass_ds.

* Get inspeaction point requirement
  CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
    EXPORTING
      insplot                = iv_insplot
      inspoper               = iv_inspoper
    IMPORTING
      insppoint_requirements = wa_insppoint_requirements
    TABLES
      char_requirements      = lt_char_requirements.

* Get key components
  lt_key_components = zcl_qm_laboratories_util=>get_keyfields_components( iv_ident_key = wa_insppoint_requirements-ident_key ).

* Build dynpro fields
  LOOP AT lt_key_components ASSIGNING <wa_key_components>.
    APPEND INITIAL LINE TO lt_dynpro_fields ASSIGNING <wa_dynpro_fields>.
    <wa_dynpro_fields>-tablename = 'BAPI2045L4'.
    <wa_dynpro_fields>-fieldname = <wa_key_components>-name.
    UNASSIGN <wa_dynpro_fields>.
  ENDLOOP.

  APPEND INITIAL LINE TO wa_restriction-opt_list_tab ASSIGNING <wa_opt_list>.
  <wa_opt_list>-name = 'EQ'.
  <wa_opt_list>-options-eq = abap_true.
  UNASSIGN <wa_opt_list>.

  APPEND INITIAL LINE TO wa_restriction-ass_tab ASSIGNING <wa_ass_ds>.
  <wa_ass_ds>-kind = 'A'.
  <wa_ass_ds>-sg_addy = 'N'.
  <wa_ass_ds>-sg_main = 'I'.
  UNASSIGN <wa_ass_ds>.

  CALL FUNCTION 'FREE_SELECTIONS_INIT'
    EXPORTING
      kind                     = 'F'
      restriction              = wa_restriction
    IMPORTING
      selection_id             = ev_selection_id
    TABLES
      fields_tab               = lt_dynpro_fields
      field_texts              = lt_dynpro_fields_text
    EXCEPTIONS
      fields_incomplete        = 01
      fields_no_join           = 02
      field_not_found          = 03
      no_tables                = 04
      table_not_found          = 05
      expression_not_supported = 06
      incorrect_expression     = 07
      illegal_kind             = 08
      area_not_found           = 09
      inconsistent_area        = 10
      kind_f_no_fields_left    = 11
      kind_f_no_fields         = 12
      too_many_fields          = 13
      dup_field                = 14
      field_no_type            = 15
      field_ill_type           = 16
      dup_event_field          = 17
      node_not_in_ldb          = 18
      area_no_field            = 19
      OTHERS                   = 20.

  et_fields = lt_dynpro_fields.

  CLEAR: wa_insppoint_requirements, wa_restriction.
  FREE: lt_key_components, lt_char_requirements, lt_dynpro_fields, lt_dynpro_fields_text.
ENDMETHOD.


METHOD zif_qm_laboratories_gui~get_dynmaic_dynpro_field_val.
  CALL FUNCTION 'FREE_SELECTIONS_DIALOG'
    EXPORTING
      selection_id    = iv_selection_id
      start_row       = 1
      start_col       = 1
      no_intervals    = 'X'
      tree_visible    = space
      as_subscreen    = 'X'
      no_frame        = 'X'
    IMPORTING
      field_ranges    = rt_values
    TABLES
      fields_tab      = it_dynpro_fields
    EXCEPTIONS
      internal_error  = 1
      no_action       = 2
      selid_not_found = 3
      illegal_status  = 4
      OTHERS          = 5.
ENDMETHOD.


METHOD zif_qm_laboratories_gui~prepare_fieldcat_for_overview.
  FIELD-SYMBOLS <wa_fieldcatalog> TYPE lvc_s_fcat.

  LOOP AT ct_fieldcatalog ASSIGNING <wa_fieldcatalog>.
    IF <wa_fieldcatalog>-fieldname <> 'VORKTXT' AND <wa_fieldcatalog>-fieldname <> 'INSPLOT'.
      CONTINUE.
    ENDIF.

    CASE <wa_fieldcatalog>-fieldname.
      WHEN 'VORKTXT'.
        <wa_fieldcatalog>-emphasize = 'C411'.
      WHEN 'INSPLOT'.
        <wa_fieldcatalog>-emphasize = 'C211'.
    ENDCASE.
  ENDLOOP.
ENDMETHOD.


METHOD zif_qm_laboratories_gui~prepare_fieldcat_for_tab_edit.
  DATA obj_settings TYPE REF TO zcl_qm_laboratories_settings.
  DATA lt_references TYPE zqm_t_laboratories_references.
  DATA lv_count TYPE i.

  FIELD-SYMBOLS: <wa_field_texts> TYPE zqm_s_laboratories_field_head,
                 <wa_fieldcatalog> TYPE lvc_s_fcat,
                 <wa_references> TYPE zqm_s_laboratories_references,
                 <wa_dd_alv_values> TYPE lvc_s_drop,
                 <wa_dd_values> TYPE zqm_s_laboratories_dd_values,
                 <wa_dd_alv_alias_values> TYPE lvc_s_dral.

  CREATE OBJECT obj_settings.

* Load reference settings
  lt_references = obj_settings->get_field_references( iv_ident_key = iv_ident_key ).

  LOOP AT ct_fieldcatalog ASSIGNING <wa_fieldcatalog>.
* Add text to fieldcatalog
    READ TABLE it_field_texts
    ASSIGNING <wa_field_texts>
    WITH KEY fieldname = <wa_fieldcatalog>-fieldname.

    IF sy-subrc IS INITIAL AND <wa_field_texts>-text IS NOT INITIAL.
      <wa_fieldcatalog>-coltext = <wa_field_texts>-text.
    ENDIF.

    IF <wa_fieldcatalog>-fieldname = 'INSPOPER'.
      DELETE TABLE ct_fieldcatalog
      FROM <wa_fieldcatalog>.

      CONTINUE.
    ELSEIF <wa_fieldcatalog>-fieldname <> 'INSPLOT' AND <wa_fieldcatalog>-fieldname <> 'USERN2'.
      <wa_fieldcatalog>-edit = abap_true.
    ENDIF.

    READ TABLE lt_references
    ASSIGNING <wa_references>
    WITH KEY fieldname = <wa_fieldcatalog>-fieldname.

    IF sy-subrc IS INITIAL.
      <wa_fieldcatalog>-ref_table = <wa_references>-ref_table.
      <wa_fieldcatalog>-ref_field = <wa_references>-ref_field.
    ENDIF.

    READ TABLE it_dd_values
    WITH KEY fieldname = <wa_fieldcatalog>-fieldname
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS INITIAL.
      lv_count = lv_count + 1.

      <wa_fieldcatalog>-drdn_hndl = lv_count.
      <wa_fieldcatalog>-drdn_alias = abap_true.
      <wa_fieldcatalog>-checktable = '!'.

      LOOP AT it_dd_values ASSIGNING <wa_dd_values> WHERE fieldname = <wa_fieldcatalog>-fieldname.
        APPEND INITIAL LINE TO et_dd_alv_values ASSIGNING <wa_dd_alv_values>.
        <wa_dd_alv_values>-handle = lv_count.
        <wa_dd_alv_values>-value = <wa_dd_values>-key.
        UNASSIGN <wa_dd_alv_values>.

        APPEND INITIAL LINE TO et_dd_alv_alias_values ASSIGNING <wa_dd_alv_alias_values>.
        <wa_dd_alv_alias_values>-handle = lv_count.
        <wa_dd_alv_alias_values>-int_value = <wa_dd_values>-key.
        <wa_dd_alv_alias_values>-value = <wa_dd_values>-value.
        UNASSIGN <wa_dd_alv_alias_values>.
      ENDLOOP.
    ENDIF.

    UNASSIGN: <wa_field_texts>, <wa_references>.
  ENDLOOP.

  CLEAR lv_count.
  FREE lt_references.
  FREE obj_settings.
ENDMETHOD.


METHOD _get_fieldcatalog_by_name.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = iv_structure_name
    CHANGING
      ct_fieldcat            = rt_fieldcatalog
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_laboratories
      EXPORTING
        textid = zcx_qm_laboratories=>fieldcatalog_error.
  ENDIF.
ENDMETHOD.


METHOD _get_fieldcatalog_by_stuct.
  DATA lt_components TYPE abap_compdescr_tab.

  FIELD-SYMBOLS: <wa_fieldcatalog> TYPE lvc_s_fcat,
                 <wa_components> TYPE abap_compdescr.

  lt_components[] = io_structure_descr->components[].

  LOOP AT lt_components ASSIGNING <wa_components>.
    APPEND INITIAL LINE TO rt_fieldcatalog ASSIGNING <wa_fieldcatalog>.
    <wa_fieldcatalog>-fieldname = <wa_components>-name.
    <wa_fieldcatalog>-inttype = <wa_components>-type_kind.
    <wa_fieldcatalog>-intlen = <wa_components>-length.
    <wa_fieldcatalog>-decimals = <wa_components>-decimals.
    UNASSIGN <wa_fieldcatalog>.
  ENDLOOP.

  FREE lt_components.
ENDMETHOD.
ENDCLASS.
