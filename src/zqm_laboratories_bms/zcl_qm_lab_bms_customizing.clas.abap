class ZCL_QM_LAB_BMS_CUSTOMIZING definition
  public
  final
  create public .

public section.

  constants AC_FIELD_TYPE_INSP_POINT type ZQM_FIELD_TYPE value 'I'. "#EC NOTEXT
  constants AC_FIELD_TYPE_SAMPLE type ZQM_FIELD_TYPE value 'S'. "#EC NOTEXT

  class-methods GET_ALV_COLUM_CUSTOMIZING
    importing
      !IV_ALV_TYPE type ZQM_ALV_TYPE
      !IV_TCODE type TCODE default SY-TCODE
      !IV_SPRAS type SPRAS default SY-LANGU
    returning
      value(RT_CUSTOMIZING) type ZQM_T_LAB_BMS_ALV_CUSTOMIZING
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_INSP_OPERATION_MAPPING
    importing
      !IV_IDENT_KEY type QSLWBEZ
    returning
      value(RT_MAPPING) type ZQM_T_LAB_BMS_INSPOP_MAPPING
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
protected section.
private section.

  class-data AT_OPERATIONS_MAPPING type ZQM_T_LAB_BMS_INSPOP_MAPPING .
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_CUSTOMIZING IMPLEMENTATION.


METHOD get_alv_colum_customizing.
* Search data for transaction
  SELECT a~alv_type
         a~fieldname
         b~text30
         a~editable
         a~dropdown_enabled
         a~custom_column_header
         a~outputlen
         a~ref_field
         a~ref_table
         a~field_position
         a~group_values
  INTO TABLE rt_customizing
  FROM zqmalvcust AS a
  JOIN zqmalvcustt AS b
    ON a~alv_type = b~alv_type AND
       a~tcode = b~tcode AND
       a~fieldname = b~fieldname
  WHERE a~alv_type = iv_alv_type
    AND a~tcode = iv_tcode
    AND a~active = abap_true
    AND b~spras = iv_spras.

  IF sy-subrc IS NOT INITIAL.
* Search again without transaction code
    SELECT a~alv_type
           a~fieldname
           b~text30
           a~editable
           a~dropdown_enabled
           a~custom_column_header
           a~outputlen
           a~ref_field
           a~ref_table
           a~field_position
    INTO TABLE rt_customizing
    FROM zqmalvcust AS a
    JOIN zqmalvcustt AS b
      ON a~alv_type = b~alv_type AND
         a~tcode = b~tcode AND
         a~fieldname = b~fieldname
    WHERE a~alv_type = iv_alv_type
      AND a~tcode = ''
      AND a~active = abap_true
      AND b~spras = iv_spras.
  ENDIF.
ENDMETHOD.


METHOD get_insp_operation_mapping.
* Try to find values in buffer table
  rt_mapping[] = at_operations_mapping[].

  DELETE rt_mapping
  WHERE ident_key <> iv_ident_key.

  IF rt_mapping[] IS INITIAL.
* No data found in buffer table. Search database
    SELECT source_field
           target_field
           ident_key
           field_type
    FROM zqminspopflgmap
    INTO TABLE rt_mapping
    WHERE ident_key = iv_ident_key
      AND active = abap_true.

    APPEND LINES OF rt_mapping TO at_operations_mapping.
  ENDIF.
ENDMETHOD.
ENDCLASS.
