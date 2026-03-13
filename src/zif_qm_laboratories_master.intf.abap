interface ZIF_QM_LABORATORIES_MASTER
  public .


  methods GET_DATA_OBJECT
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
    exporting
      value(EO_DATA_OBJECT) type ref to DATA
      !ET_FIELD_TEXTS type ZQM_T_LABORATORIES_FIELD_HEAD
      !EO_STRUCTURE_DESCR type ref to CL_ABAP_STRUCTDESCR
      !EV_IDENT_KEY type QSLWBEZ
      !ET_FIELD_VALUES type ZQM_T_LABORATORIES_DD_VALUES
    raising
      ZCX_QM_LABORATORIES .
  methods GET_INIT_LIST_EDIT_DATA
    importing
      !IV_INSPLOT type QIBPLOSNR
      !IV_INSPOPER type QIBPVORNR
      !IV_SELECTED_DATE type DATS
      !IV_SELECTED_TIME type SY-UZEIT
      !IT_OVERVIEW_DATA type ZQM_T_LABORATORIES_OVERVIEW
    changing
      !CT_DATA_TABLE type STANDARD TABLE
    raising
      ZCX_QM_LABORATORIES .
  methods GET_OVERVIEW_DATA
    importing
      !IV_WERK type WERKS_D
    returning
      value(RT_DATA) type ZQM_T_LABORATORIES_OVERVIEW
    raising
      ZCX_QM_LABORATORIES .
  methods SAVE_INSPECTION_MULTI
    importing
      !IO_DATA type ref to DATA
    returning
      value(RT_MESSAGES) type BAPIRET2_T
    raising
      ZCX_QM_LABORATORIES .
endinterface.
