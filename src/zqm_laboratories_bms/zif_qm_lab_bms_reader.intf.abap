interface ZIF_QM_LAB_BMS_READER
  public .


  methods SEARCH
    importing
      !IV_WERK type WERKS_D
      !IO_WORKING_GROUP type ref to DATA optional
      !IO_LINES type ref to DATA optional
      !IV_SAMPLE_TYPE type ZBMS_ENTNAHME_PROBENART default 'N'
      !IV_DATE type DATS
      !IV_TIME type UZEIT
    returning
      value(RT_RESULT) type ZQM_T_LAB_BMS_SEARCH_RESULT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SEARCH_BY_BALLEN_ID
    importing
      !IV_WERK type WERKS_D
      !IV_BALLEN_ID type ZBMS_BALLENID
      !IO_WORKING_GROUP type ref to DATA optional
      !IV_SAMPLE_TYPE type ZBMS_ENTNAHME_PROBENART default 'N'
      !IV_DATE type DATS
      !IV_TIME type UZEIT
    returning
      value(RT_RESULT) type ZQM_T_LAB_BMS_SEARCH_RESULT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SEARCH_BY_INSPLOT
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IO_WORKING_GROUP type ref to DATA optional
      !IV_SAMPLE_TYPE type ZBMS_ENTNAHME_PROBENART default 'N'
      !IV_DATE type DATS
      !IV_TIME type UZEIT
    returning
      value(RT_RESULT) type ZQM_T_LAB_BMS_SEARCH_RESULT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  type-pools ABAP .
  methods SEARCH_BY_INSPLOT_BALLEN_ID
    importing
      !IV_WERK type WERKS_D
      !IV_BALLEN_ID type ZBMS_BALLENID
      !IO_WORKING_GROUP type ref to DATA optional
      !IO_LINES type ref to DATA optional
      !IV_SAMPLE_TYPE type ZBMS_ENTNAHME_PROBENART default 'N'
      !IV_DATE type DATS
      !IV_TIME type UZEIT
      !IV_INCLUDE_DATE type ABAP_BOOL
    returning
      value(RT_RESULT) type ZQM_T_LAB_BMS_SEARCH_RESULT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SEARCH_BY_PHYSICAL_SAMPLE
    importing
      !IV_PHYNR type QPHYSPRNR
      !IO_WORKING_GROUP type ref to DATA optional
      !IV_DATE type DATS
      !IV_TIME type UZEIT
    returning
      value(RT_RESULT) type ZQM_T_LAB_BMS_SEARCH_RESULT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
endinterface.
