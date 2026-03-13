*----------------------------------------------------------------------*
*       INTERFACE ZIF_QM_LAB_BMS_UI
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
interface ZIF_QM_LAB_BMS_UI
  public .


  methods CREATE_DYNAMIC_MULTI_COL_LABEL
    importing
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods FILL_MULTI_DO
    importing
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
    changing
      !CO_DATA_OBJECT type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods FILL_SINGLE_DO
    importing
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
    changing
      !CO_DATA_OBJECT type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_MULTI_COLUMN_LABLES
    returning
      value(RT_COLUMN_LABELS) type WDY_KEY_VALUE_LIST
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_MULTI_DO
    importing
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
    returning
      value(RO_DATA_OBJECT) type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_MULTI_FIELDCAT
    importing
      !IO_DATA_OBJECT type ref to DATA
    exporting
      value(ET_FIELD_GROUPS) type LVC_T_SGRP
      value(ET_FIELDCATALOG) type LVC_T_FCAT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_MULTI_FIRST_ENABLED_CELL
    importing
      !IO_DATA_OBJECT type ref to DATA
      !IT_FIELDCATALOG type LVC_T_FCAT
    exporting
      !ES_ROW_ID type LVC_S_ROW
      !ES_CELL_ID type LVC_S_COL
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_SINGLE_DO
    returning
      value(RO_DATA_OBJECT) type ref to DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_SINGLE_FIELDCAT
    importing
      !IO_DATA_OBJECT type ref to DATA
    exporting
      value(ET_FIELD_GROUPS) type LVC_T_SGRP
      value(ET_FIELDCATALOG) type LVC_T_FCAT
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods GET_SINGLE_FIRST_ENABLED_CELL
    importing
      !IO_DATA_OBJECT type ref to DATA
      !IT_FIELDCATALOG type LVC_T_FCAT
    exporting
      !ES_ROW_ID type LVC_S_ROW
      !ES_CELL_ID type LVC_S_COL
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SET_MULTI_DD
    importing
      !IO_DATA_OBJECT type ref to DATA
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
      !IO_GRID_INSTANCE type ref to CL_GUI_ALV_GRID
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods SET_SINGLE_DD
    importing
      !IO_DATA_OBJECT type ref to DATA
      !IT_MAINTAIN_DATA type ZQM_T_LAB_BMS_MAINTAIN_DATA
      !IO_GRID_INSTANCE type ref to CL_GUI_ALV_GRID
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods UPDATE_DTM_FROM_MULTI
    importing
      !IO_MULTI_MAINTAIN_DATA type ref to DATA
    changing
      !CT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
  methods UPDATE_DTM_FROM_SINGLE
    importing
      !IO_SINGLE_MAINTAIN_DATA type ref to DATA
    changing
      !CT_DATA_TO_MAINTAIN type ZQM_T_LAB_BMS_MAINTAIN_DATA
    raising
      ZCX_QM_LAB_BMS_EXCEPTIONS .
endinterface.
