*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_TEST_DEVICE_IMP_TOP
*&---------------------------------------------------------------------*

CONSTANTS: co_status_bedap             TYPE zqm_dataset_status VALUE 3,
           co_status_success           TYPE zqm_dataset_status VALUE 2,
           co_status_no_insplot        TYPE zqm_dataset_status VALUE 4,
           co_status_no_operation_char TYPE zqm_dataset_status VALUE 5,
           co_status_error             TYPE zqm_dataset_status VALUE 6,
           co_no_prueflos              TYPE qplos VALUE IS INITIAL,
           co_lock_retries             TYPE i VALUE 20,
           co_lock_wait_seconds        TYPE i VALUE 30.

TYPES: ty_bapi2045l2 TYPE STANDARD TABLE OF bapi2045l2.

TYPES: BEGIN OF ty_s_converted_data,
         session_guid  TYPE sysuuid_c32,
         dataset_guid  TYPE sysuuid_c32,
         insplot       TYPE qibplosnr,
         inspoper      TYPE qibpvornr,
         insppoint     TYPE qibpppktnr,
         inspector     TYPE qinspector,
         device_number TYPE zqm_testing_device_number,
         data          TYPE REF TO data,
       END OF ty_s_converted_data.
TYPES: ty_t_converted_data TYPE STANDARD TABLE OF ty_s_converted_data.

TYPES: BEGIN OF ty_qals,
         prueflos  TYPE qals-prueflos,
         werk      TYPE qals-werk,
         zzlinienr TYPE qals-zzlinienr.
TYPES: END OF ty_qals.

DATA: wa_plant_settings TYPE zqm_s_lab_device_plant_setting,
      obj_transfer TYPE REF TO zcl_qm_lab_device_transfer,
      lt_files TYPE zqm_lab_t_file_list,
      lv_filename TYPE zqm_filename,
      lv_plant_locked TYPE abap_bool.

DATA: lt_device_settings_buffer  TYPE SORTED TABLE OF zqm_s_lab_device_settings WITH UNIQUE KEY device_id,
      lt_bedap_mapping_buffer    TYPE zqm_t_lab_device_bedap_mapping,
      lt_operations_buffer       TYPE SORTED TABLE OF bapi2045l2 WITH NON-UNIQUE KEY insplot,
      lt_char_requiremens_buffer TYPE SORTED TABLE OF bapi2045d1 WITH UNIQUE KEY insplot inspoper mstr_char,
      lt_insplot_list_buffer     TYPE STANDARD TABLE OF bapi2045l1,
      lt_qals_buffer             TYPE SORTED TABLE OF ty_qals WITH NON-UNIQUE KEY zzlinienr.

FIELD-SYMBOLS <wa_files> TYPE zqm_lab_s_file_list.
