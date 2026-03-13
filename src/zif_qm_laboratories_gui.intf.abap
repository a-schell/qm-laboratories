interface ZIF_QM_LABORATORIES_GUI
  public .


  methods GET_ALV_FIELDCATALOG
    importing
      !IV_STRUCTURE_NAME type DD02L-TABNAME optional
      !IO_STRUCTURE_DESCR type ref to CL_ABAP_STRUCTDESCR optional
    returning
      value(RT_FIELDCATALOG) type LVC_T_FCAT
    raising
      ZCX_QM_LABORATORIES .
  methods GET_DYNAMIC_DYNPRO_FIELDS
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    exporting
      !EV_SELECTION_ID type RSDYNSEL-SELID
      !ET_FIELDS type RSDSFIELDS_T
    raising
      ZCX_QM_LABORATORIES .
  type-pools RSDS .
  methods GET_DYNMAIC_DYNPRO_FIELD_VAL
    importing
      !IV_SELECTION_ID type RSDYNSEL-SELID
      !IT_DYNPRO_FIELDS type RSDSFIELDS_T
    returning
      value(RT_VALUES) type RSDS_TRANGE
    raising
      ZCX_QM_LABORATORIES .
  methods PREPARE_FIELDCAT_FOR_OVERVIEW
    changing
      !CT_FIELDCATALOG type LVC_T_FCAT
    raising
      ZCX_QM_LABORATORIES .
  methods PREPARE_FIELDCAT_FOR_TAB_EDIT
    importing
      !IT_FIELD_TEXTS type ZQM_T_LABORATORIES_FIELD_HEAD
      !IO_TABLE_STRUCTURE type ref to CL_ABAP_STRUCTDESCR
      !IV_IDENT_KEY type QSLWBEZ
      !IT_DD_VALUES type ZQM_T_LABORATORIES_DD_VALUES
    exporting
      !ET_DD_ALV_VALUES type LVC_T_DROP
      !ET_DD_ALV_ALIAS_VALUES type LVC_T_DRAL
    changing
      !CT_FIELDCATALOG type LVC_T_FCAT
    raising
      ZCX_QM_LABORATORIES .
endinterface.
