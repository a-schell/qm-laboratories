class ZCL_QM_LAB_BMS_FACTORY definition
  public
  final
  create public .

public section.

  class-methods GET_PROGRAM_RUN_TRACKER
    returning
      value(RO_INSTANCE) type ref to ZIF_QM_LAB_BMS_PROGRAM_RUNS
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_READER
    returning
      value(RO_READER) type ref to ZIF_QM_LAB_BMS_READER
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_RUNTIME
    returning
      value(RO_INSTANCE) type ref to ZIF_QM_LAB_BMS_RUNTIME
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  class-methods GET_UI_HELPER
    returning
      value(RO_INSTANCE) type ref to ZIF_QM_LAB_BMS_UI
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_FACTORY IMPLEMENTATION.


METHOD get_program_run_tracker.
* Create instance
  CREATE OBJECT ro_instance TYPE zcl_qm_lab_bms_program_runs.
ENDMETHOD.


METHOD get_reader.
* Create reader instance
  CREATE OBJECT ro_reader TYPE zcl_qm_lab_bms_reader.
ENDMETHOD.


METHOD get_runtime.
  TRY.
      CREATE OBJECT ro_instance TYPE zcl_qm_lab_bms_runtime.
    CATCH cx_root.
      RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
        EXPORTING
          textid = zcx_qm_lab_bms_exceptions=>error_runtime_instance.
  ENDTRY.
ENDMETHOD.


METHOD get_ui_helper.
* Create instance
  CREATE OBJECT ro_instance TYPE zcl_qm_lab_bms_ui.
ENDMETHOD.
ENDCLASS.
