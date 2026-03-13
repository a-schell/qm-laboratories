class ZCL_QM_LAB_DEVICE_CUSTOMIZING definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods GET_BEDAP_CODE_MAPPING
    importing
      !IV_BEDAP_CODE type ZQM_BEDAP_CODE
    returning
      value(RS_MAPPING) type ZQM_S_LAB_DEVICE_BEDAP_MAPPING
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods GET_DEVICE_SETTINGS
    importing
      !IV_DEVICE_ID type ZQM_TESTING_DEVICE_ID
    returning
      value(RS_SETTINGS) type ZQM_S_LAB_DEVICE_SETTINGS
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods GET_PLANT_SETTINGS
    importing
      !IV_PLANT type WERKS_D
    returning
      value(RS_SETTINGS) type ZQM_S_LAB_DEVICE_PLANT_SETTING
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
protected section.
private section.

  class-data AT_DEVICE_SETTINGS_BUFFER type ZQM_T_LAB_DEVICE_SETTINGS .
ENDCLASS.



CLASS ZCL_QM_LAB_DEVICE_CUSTOMIZING IMPLEMENTATION.


METHOD constructor.
  super->constructor( ).
ENDMETHOD.


METHOD get_bedap_code_mapping.
* Get bedap mapping from database table
  SELECT SINGLE bedap
                mkmnr
  INTO rs_mapping
  FROM zqm_dev_bedapmap
  WHERE bedap = iv_bedap_code.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid        = zcx_qm_lab_device_exceptions=>no_bedap_mapping_found
        av_bedap_code = iv_bedap_code.
  ENDIF.
ENDMETHOD.


METHOD get_device_settings.
* Read data from buffer
  READ TABLE at_device_settings_buffer
  INTO rs_settings
  WITH KEY device_id = iv_device_id.

  IF sy-subrc IS INITIAL.
    RETURN.
  ENDIF.

* Get device id setting from database
  SELECT SINGLE device_id
                target_structure
                mapping_class
                inspector_code
  FROM zqm_dev_settings
  INTO rs_settings
  WHERE device_id = iv_device_id.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid = zcx_qm_lab_device_exceptions=>no_device_settings_found.
  ENDIF.

  INSERT rs_settings INTO TABLE at_device_settings_buffer.
ENDMETHOD.


METHOD get_plant_settings.
* Read plant settings for customizing table
  SELECT SINGLE plant,
                folder_path,
                archive_path
           INTO @rs_settings
           FROM zqm_dev_plant
          WHERE plant = @iv_plant
            AND sysid = @sy-sysid.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid   = zcx_qm_lab_device_exceptions=>no_settings_for_plant
        av_plant = iv_plant.
  ENDIF.
ENDMETHOD.
ENDCLASS.
