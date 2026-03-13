class ZCL_QM_LAB_DEVICE_NR_FINDER definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods FIND
    importing
      !IV_DEVICE_ID type ZQM_TESTING_DEVICE_ID
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_NUMBER) type ZQM_TESTING_DEVICE_NUMBER
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods _EXTRACT_FOR_FIBRES
    importing
      !IV_DEVICE_ID type ZQM_TESTING_DEVICE_ID
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_NUMBER) type ZQM_TESTING_DEVICE_NUMBER
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LAB_DEVICE_NR_FINDER IMPLEMENTATION.


METHOD constructor.
  super->constructor( ).
ENDMETHOD.


METHOD find.
* Call correct submethod
  CASE iv_device_id.
    WHEN zcl_qm_lab_device_id_finder=>ac_fibres.
      rv_device_number = me->_extract_for_fibres( iv_device_id = iv_device_id
                                                  iv_filename  = iv_filename
                                                  iv_raw_data  = iv_raw_data ).
  ENDCASE.
ENDMETHOD.


METHOD _extract_for_fibres.
  DATA: lt_split TYPE string_table,
        wa_split TYPE string.

  FIELD-SYMBOLS <wa_split> TYPE string.

  SPLIT iv_filename AT '_' INTO TABLE lt_split.

  READ TABLE lt_split
  INTO wa_split
  INDEX 4.

  IF sy-subrc IS INITIAL.
    FREE lt_split.
    SPLIT wa_split AT '-' INTO TABLE lt_split.

    READ TABLE lt_split
    ASSIGNING <wa_split>
    INDEX 2.

    IF sy-subrc IS INITIAL.
      rv_device_number = <wa_split>.
    ENDIF.
  ENDIF.

  CLEAR wa_split.
  FREE lt_split.
ENDMETHOD.
ENDCLASS.
