interface ZIF_QM_LAB_BMS_PROGRAM_RUNS
  public .


  methods GET_LAST_RUN
    importing
      !IV_WERKS type WERKS_D
      !IV_REPORT type PROGRAM
    exporting
      !EV_LAST_DATE type DATS
      !EV_LAST_TIME type TIME
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_RUNS
    importing
      !IV_WERKS type WERKS_D
      !IV_REPORT type PROGRAM
      !IV_MAX_HITS type INT4 default 100
    returning
      value(RT_RUNS) type ZQM_T_LAB_BMS_PROGRAM_RUNS
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SET_RUN
    importing
      !IV_WERKS type WERKS_D
      !IV_REPORT type PROGRAM
      !IV_DATE type DATS optional
      !IV_TIME type TIME optional
      !IV_COMMIT type ABAP_BOOL default ABAP_FALSE
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
endinterface.
