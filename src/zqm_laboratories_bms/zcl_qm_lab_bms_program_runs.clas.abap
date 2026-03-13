class ZCL_QM_LAB_BMS_PROGRAM_RUNS definition
  public
  final
  create public .

public section.

  interfaces ZIF_QM_LAB_BMS_PROGRAM_RUNS .

  methods CONSTRUCTOR .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LAB_BMS_PROGRAM_RUNS IMPLEMENTATION.


method CONSTRUCTOR.
endmethod.


METHOD zif_qm_lab_bms_program_runs~get_last_run.
  DATA lt_data TYPE SORTED TABLE OF zqmbms_prog_runs WITH UNIQUE DEFAULT KEY.

  FIELD-SYMBOLS <wa_data> TYPE zqmbms_prog_runs.

* Get last runs
  SELECT mandt
         werk
         report
         run_count
         last_date
         last_time
  INTO TABLE lt_data
  FROM zqmbms_prog_runs
  UP TO 1 ROWS
  WHERE werk   = iv_werks
    AND report = iv_report
  ORDER BY run_count DESCENDING.

  IF lt_data[] IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_bms_exceptions
      EXPORTING
        textid       = zcx_qm_lab_bms_exceptions=>no_last_run_found
        av_report_id = iv_report.
  ENDIF.

  READ TABLE lt_data
  ASSIGNING <wa_data>
  INDEX 1.

  ev_last_date = <wa_data>-last_date.
  ev_last_time = <wa_data>-last_time.

  FREE lt_data.
ENDMETHOD.


METHOD zif_qm_lab_bms_program_runs~get_runs.
* Get last runs
  SELECT werk
         report
         run_count
         last_date
         last_time
  INTO TABLE rt_runs
  FROM zqmbms_prog_runs
  UP TO iv_max_hits ROWS
  WHERE werk   = iv_werks
    AND report = iv_report
  ORDER BY last_date DESCENDING
           last_time DESCENDING.
ENDMETHOD.


METHOD zif_qm_lab_bms_program_runs~set_run.
  DATA: lt_data TYPE SORTED TABLE OF zqmbms_prog_runs WITH UNIQUE DEFAULT KEY,
        wa_data TYPE zqmbms_prog_runs.
  DATA lv_run_count TYPE int4.

  FIELD-SYMBOLS <wa_data> TYPE zqmbms_prog_runs.

* Get last runs
  SELECT mandt
         werk
         report
         run_count
         last_date
         last_time
  INTO TABLE lt_data
  FROM zqmbms_prog_runs
  UP TO 1 ROWS
  WHERE werk   = iv_werks
    AND report = iv_report
  ORDER BY run_count DESCENDING.

  IF lt_data[] IS INITIAL.
    lv_run_count = 1.
  ELSE.
    READ TABLE lt_data
    ASSIGNING <wa_data>
    INDEX 1.

    lv_run_count = <wa_data>-run_count + 1.
  ENDIF.

* Set data for insert
  wa_data-werk      = iv_werks.
  wa_data-report    = iv_report.
  wa_data-run_count = lv_run_count.

  IF iv_date IS INITIAL.
    wa_data-last_date = sy-datum.
  ELSE.
    wa_data-last_date = iv_date.
  ENDIF.

  IF iv_time IS INITIAL.
    wa_data-last_time = sy-uzeit.
  ELSE.
    wa_data-last_time = iv_time.
  ENDIF.

* Insert data into database
  INSERT INTO zqmbms_prog_runs VALUES wa_data.

  IF iv_commit = abap_true.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDIF.

  CLEAR: lv_run_count, wa_data.
  FREE lt_data.
ENDMETHOD.
ENDCLASS.
