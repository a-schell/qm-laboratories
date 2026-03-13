class ZCL_QM_LAB_DEVICE_ID_FINDER definition
  public
  final
  create public .

public section.

  constants AC_STAINING type ZQM_TESTING_DEVICE_ID value 1. "#EC NOTEXT
  constants AC_CONDITIONING type ZQM_TESTING_DEVICE_ID value 2. "#EC NOTEXT
  constants AC_FIBRES type ZQM_TESTING_DEVICE_ID value 3. "#EC NOTEXT
  constants AC_DIMENSION type ZQM_TESTING_DEVICE_ID value 4. "#EC NOTEXT

  methods CONSTRUCTOR .
  methods FIND
    importing
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_ID) type ZQM_TESTING_DEVICE_ID
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
protected section.
private section.

  methods _ANALYZE_FOR_CONDITIONING
    importing
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_ID) type ZQM_TESTING_DEVICE_ID
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods _ANALYZE_FOR_DIMENSION
    importing
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_ID) type ZQM_TESTING_DEVICE_ID
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods _ANALYZE_FOR_FIBRES
    importing
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_ID) type ZQM_TESTING_DEVICE_ID
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods _ANALYZE_FOR_STAINING
    importing
      !IV_FILENAME type ZQM_FILENAME
      !IV_RAW_DATA type ZQM_RAW_FILE_DATA
    returning
      value(RV_DEVICE_ID) type ZQM_TESTING_DEVICE_ID
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
ENDCLASS.



CLASS ZCL_QM_LAB_DEVICE_ID_FINDER IMPLEMENTATION.


METHOD constructor.
  super->constructor( ).
ENDMETHOD.


METHOD find.
  DATA lv_method TYPE string.
  DATA lv_count TYPE i.

  DO 4 TIMES.
    lv_count = lv_count + 1.

    CASE lv_count.
      WHEN 1.
        lv_method = '_ANALYZE_FOR_CONDITIONING'.
      WHEN 2.
        lv_method = '_ANALYZE_FOR_DIMENSION'.
      WHEN 3.
        lv_method = '_ANALYZE_FOR_STAINING'.
      WHEN 4.
        lv_method = '_ANALYZE_FOR_FIBRES'.
    ENDCASE.

    CALL METHOD me->(lv_method)
      EXPORTING
        iv_filename  = iv_filename
        iv_raw_data  = iv_raw_data
      RECEIVING
        rv_device_id = rv_device_id.

    IF rv_device_id IS NOT INITIAL.
      RETURN.
    ENDIF.

    CLEAR lv_method.
  ENDDO.

  IF rv_device_id IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid = zcx_qm_lab_device_exceptions=>could_not_determine_device_id.
  ENDIF.

  CLEAR lv_count.
ENDMETHOD.


METHOD _analyze_for_conditioning.
  IF iv_filename CP 'Kond_*.dat'.
    rv_device_id = ac_conditioning.
  ENDIF.
ENDMETHOD.


METHOD _analyze_for_dimension.
  IF iv_raw_data CP 'WATE*'.
    rv_device_id = ac_dimension.
  ENDIF.
ENDMETHOD.


METHOD _analyze_for_fibres.
  IF iv_filename CP 'FLF-*.pvs' OR iv_filename CP 'FLL-*.pvs' OR iv_filename CP 'TIP-*.pvs'.
    rv_device_id = ac_fibres.
  ENDIF.
ENDMETHOD.


METHOD _analyze_for_staining.
  DATA: lv_filename TYPE string,
        lv_file_extension TYPE string.

  SPLIT iv_filename AT '.' INTO lv_filename lv_file_extension.

  IF lv_file_extension = 'p10'.
    rv_device_id = ac_staining.
  ENDIF.

  CLEAR: lv_file_extension, lv_filename.
ENDMETHOD.
ENDCLASS.
