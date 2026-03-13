*----------------------------------------------------------------------*
*       INTERFACE ZIF_QM_LAB_BMS_RUNTIME
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
interface ZIF_QM_LAB_BMS_RUNTIME
  public .


  methods CHECK_DATA
    importing
      !IV_DATA_TYPE type CHAR1
      !IT_MODIFIED_CELLS type LVC_T_MODI
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
      !IO_DATA_OBJECT type ref to DATA
    returning
      value(RT_MESSAGES) type BAPIRET2_T
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods DISPOSE
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  type-pools ABAP .
  methods GET_DATA_FOR_MAINTAIN
    importing
      !IT_HEAD_DATA type ZQM_T_LAB_BMS_HEAD_DATA
      !IV_IS_LINE_REQUIRED type ABAP_BOOL default ABAP_TRUE
    returning
      value(RT_DATA) type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_HISTORICAL_SAMPLE_VALUES
    importing
      !IT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA
      !IV_BALLENNR type ZBMS_BALLENID optional
      !IV_MAX_HITS type INT4 default 3
    returning
      value(RT_HISTORICAL_DATA) type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods IS_MULTI_MAINTAINABLE
    importing
      !IS_MAINTAIN_DATA type ZQM_S_LAB_BMS_MAINTAIN_DATA
    returning
      value(RV_IS_MULTI) type ABAP_BOOL
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SAVE_DATA
    exporting
      value(ET_MESSAGES) type BAPIRET2_T
    changing
      !CT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SAVE_TIME_REPORTING
    importing
      !IT_DATA type ZQM_T_LAB_BMS_TIME_REP_DATA
    returning
      value(RT_MESSAGES) type BAPIRET2_T
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SHOW_TIME_REPORTING
    importing
      !IV_INSPLOT type QIBPLOSNR
    returning
      value(RT_MESSAGES) type BAPIRET2_T
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
endinterface.
