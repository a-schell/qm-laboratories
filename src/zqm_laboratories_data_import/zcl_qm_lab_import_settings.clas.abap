*----------------------------------------------------------------------*
*       CLASS zcl_qm_lab_import_settings DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zcl_qm_lab_import_settings DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS ac_appl_create_insplot_file TYPE zqm_import_appplication VALUE 1. "#EC NOTEXT
    CONSTANTS ac_appl_measuring_dev_import TYPE zqm_import_appplication VALUE 2. "#EC NOTEXT

    METHODS constructor.

    METHODS get_application_settings
    IMPORTING !iv_application TYPE zqm_import_appplication
    RETURNING value(rs_settings) TYPE zqm_lab_s_import_settings
    RAISING zcx_qm_lab_import_exceptions.

    METHODS get_field_mappings
    IMPORTING !iv_plant TYPE werks_d
              !iv_application TYPE zqm_import_appplication
    RETURNING value(rt_mappings) TYPE zqm_lab_t_field_mappings
    RAISING zcx_qm_lab_import_exceptions.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_QM_LAB_IMPORT_SETTINGS IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.                    "constructor


  METHOD get_application_settings.
* Check import parameters
    IF iv_application IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_import_exceptions
        EXPORTING
          textid = zcx_qm_lab_import_exceptions=>no_application_submitted.
    ENDIF.

* Select application settings from database
    SELECT SINGLE application
                  folder_path
                  archive_path
                  error_archive_path
    FROM zqm_impapplsett
    INTO rs_settings
    WHERE application = iv_application.
  ENDMETHOD.                    "get_appl_settings


  METHOD get_field_mappings.
* Check import parameters
    IF iv_plant IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_import_exceptions
        EXPORTING
          textid = zcx_qm_lab_import_exceptions=>no_plant_submitted.
    ENDIF.

    IF iv_application IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_import_exceptions
        EXPORTING
          textid = zcx_qm_lab_import_exceptions=>no_application_submitted.
    ENDIF.

* Select field mappings
    SELECT plant
           application
           source_field
           target_field
    FROM zqm_impfldmap
    INTO TABLE rt_mappings
    WHERE plant = iv_plant
      AND application = iv_application.
  ENDMETHOD.                    "get_field_mappings
ENDCLASS.
