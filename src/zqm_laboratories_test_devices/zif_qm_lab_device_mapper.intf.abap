interface ZIF_QM_LAB_DEVICE_MAPPER
  public .


  methods MAP
    importing
      !IS_TRANSFER_DATA type ZQM_S_LAB_DEVICE_READ_DATA
      !IS_DEVICE_SETTINGS type ZQM_S_LAB_DEVICE_SETTINGS
    exporting
      !ES_MAPPED_DATA type ANY
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
endinterface.
