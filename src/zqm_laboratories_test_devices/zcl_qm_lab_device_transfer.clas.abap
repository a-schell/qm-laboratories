class ZCL_QM_LAB_DEVICE_TRANSFER definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods DELETE_STORED_DATA
    importing
      !IV_DATASET_GUID type SYSUUID_C32 optional
      !IV_COMMIT type ABAP_BOOL default ABAP_FALSE
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  class-methods DELETE_STORED_DATA_FOR_SESSION
    importing
      !IV_SESSION_GUID type SYSUUID_C32
      !IV_DATASET_GUID type SYSUUID_C32 optional
      !IV_COMMIT type ABAP_BOOL default ABAP_FALSE
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods GET_SESSION_GUID
    returning
      value(RV_SESSION_GUID) type SYSUUID_C32
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods GET_STORED_DATA
    importing
      !IV_WERKS type WERKS_D
    returning
      value(RT_DATA) type ZQM_T_LAB_DEVICE_READ_DATA
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  class-methods GET_STORED_DATA_FOR_SESSION
    importing
      !IV_WERKS type WERKS_D
      !IV_SESSION_GUID type SYSUUID_C32
    returning
      value(RT_DATA) type ZQM_T_LAB_DEVICE_READ_DATA
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods SET_STATUS
    importing
      !IV_WERKS type WERKS_D
      !IV_SESSION_GUID type SYSUUID_C32
      !IV_DATASET_GUID type SYSUUID_C32
      !IV_STATUS type ZQM_DATASET_STATUS
      !IV_PRUEFLOS type QPLOS optional
      !IV_COMMIT type ABAP_BOOL default ABAP_FALSE
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods STORE_DATA
    importing
      !IV_WERKS type WERKS_D
      !IS_DATA type ZQM_S_LAB_DEVICE_STORE_DATA
      !IV_COMMIT type ABAP_BOOL default ABAP_FALSE
    returning
      value(RV_DATASET_GUID) type SYSUUID_C32
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
  methods ARCHIVE_DATA
    importing
      !IV_WERKS type WERKS_D .
  class-methods GET_STORED_DATA_BY_STATUS
    importing
      !IV_WERKS type WERKS_D
      !IV_STATUS type ZQM_DEV_TRANSFER-STATUS
    returning
      value(RT_DATA) type ZQM_T_LAB_DEVICE_READ_DATA .
  class-methods COPY_FILES_LOCAL
    importing
      !IM_SOURCE_FILE type EPS2FILNAM
      !IM_SOURCE_DIRECTORY type EPS2PATH
      !IM_TARGET_FILE type EPS2FILNAM
      !IM_TARGET_DIRECTORY type EPS2PATH
      !IM_OVERWRITE_MODE type EPSOVRWRI default SPACE
    exporting
      !EX_FILE_SIZE type EPSFILSIZ
    exceptions
      OPEN_INPUT_FILE_FAILED
      OPEN_OUTPUT_FILE_FAILED
      WRITE_BLOCK_FAILED
      READ_BLOCK_FAILED
      CLOSE_OUTPUT_FILE_FAILED .
protected section.
private section.

  data AV_SESSION_GUID type SYSUUID_C32 .

  methods _CREATE_GUID
    returning
      value(RV_GUID) type SYSUUID_C32
    raising
      ZCX_QM_LAB_DEVICE_EXCEPTIONS .
ENDCLASS.



CLASS ZCL_QM_LAB_DEVICE_TRANSFER IMPLEMENTATION.


  METHOD archive_data.
    DATA: lt_zqm_dev_transfer TYPE TABLE OF zqm_dev_transfer,
          ls_zqm_dev_transfer TYPE zqm_dev_transfer.

    CONSTANTS: co_status_success TYPE zqm_dataset_status VALUE 2,
               co_status_bedap   TYPE zqm_dataset_status VALUE 3.

    SELECT * FROM zqm_dev_transfer INTO TABLE lt_zqm_dev_transfer
      WHERE werks = iv_werks
        AND ( status = co_status_success OR status = co_status_bedap ).

    LOOP AT lt_zqm_dev_transfer INTO ls_zqm_dev_transfer.
      INSERT INTO zqm_dev_tran_arc VALUES ls_zqm_dev_transfer.
      " Delete the data in the source table.
      IF sy-subrc = 0.
        DELETE FROM zqm_dev_transfer WHERE
          werks        = ls_zqm_dev_transfer-werks AND
          session_guid = ls_zqm_dev_transfer-session_guid AND
          dataset_guid = ls_zqm_dev_transfer-dataset_guid AND
          status = ls_zqm_dev_transfer-status.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


METHOD constructor.
  super->constructor( ).

  me->av_session_guid = me->_create_guid( ).
ENDMETHOD.


  METHOD copy_files_local.
    " copy from cl_cts_language_file_io=>copy_files_local with other input parameter length
    DATA: lv_source_file_path   TYPE trfile,
          lv_source_file_size   TYPE epsfilsiz,
          lv_target_file_path   TYPE trfile,
          lv_target_file_size   TYPE epsfilsiz,
          lv_target_file_exists TYPE c.

    DATA: lv_overwrite TYPE c.

    DATA: lv_eof_reached   TYPE c,
          lv_buffer(20480),
          lv_buflen        TYPE i.

* check existence and file size of the source file
    CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
      EXPORTING
        iv_long_file_name      = im_source_file
        iv_long_dir_name       = im_source_directory
      IMPORTING
        file_size              = lv_source_file_size
      EXCEPTIONS
        read_directory_failed  = 1
        read_attributes_failed = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      RAISE open_input_file_failed.
    ENDIF.


* check existence and file size of the target file
    CLEAR lv_target_file_exists.
    CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
      EXPORTING
        iv_long_file_name      = im_target_file
        iv_long_dir_name       = im_target_directory
      IMPORTING
        file_size              = lv_target_file_size
      EXCEPTIONS
        read_directory_failed  = 1
        read_attributes_failed = 2
        OTHERS                 = 3.

    CASE sy-subrc.
      WHEN 0.
        lv_target_file_exists = 'X'.
      WHEN 1.
        RAISE open_output_file_failed.
      WHEN 2.
        lv_overwrite = 'X'.
      WHEN 3.
        RAISE open_output_file_failed.
    ENDCASE.


* depending on overwrite mode: copy files
    CASE im_overwrite_mode.
      WHEN space.
        IF lv_target_file_exists = 'X' AND
           lv_target_file_size > 0.
          CLEAR lv_overwrite.
        ELSE.
          lv_overwrite = 'X'.
        ENDIF.
      WHEN 'S'.
        IF lv_target_file_exists = 'X' AND
           lv_target_file_size = lv_source_file_size.
          CLEAR lv_overwrite.
        ELSE.
          lv_overwrite = 'X'.
        ENDIF.
      WHEN 'F'.
        lv_overwrite = 'X'.
      WHEN OTHERS.
        CLEAR lv_overwrite.
    ENDCASE.

    IF lv_overwrite <> 'X'.
      ex_file_size = lv_source_file_size.
      EXIT.
    ENDIF.

* build full file path
    CALL 'BUILD_DS_SPEC' ID 'FILENAME' FIELD im_source_file
                         ID 'PATH'     FIELD im_source_directory
                         ID 'RESULT'   FIELD lv_source_file_path.

    CALL 'BUILD_DS_SPEC' ID 'FILENAME' FIELD im_target_file
                         ID 'PATH'     FIELD im_target_directory
                         ID 'RESULT'   FIELD lv_target_file_path.

* source file and target file are the same:
* nothing to do.
    IF lv_source_file_path = lv_target_file_path.
      ex_file_size = lv_source_file_size.
      EXIT.
    ENDIF.

* delete old target file
    IF lv_target_file_exists = 'X'.
      DELETE DATASET lv_target_file_path.
    ENDIF.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        text = lv_target_file_path.


* open source and target files and start copying
    OPEN DATASET lv_source_file_path FOR INPUT IN BINARY MODE.
    IF sy-subrc NE 0.
      RAISE open_input_file_failed.
    ENDIF.

    OPEN DATASET lv_target_file_path FOR OUTPUT IN BINARY MODE.
    IF sy-subrc NE 0.
      RAISE open_output_file_failed.
    ENDIF.

    CLEAR lv_eof_reached.

    DO.
      CLEAR lv_buffer.

      READ DATASET lv_source_file_path
              INTO lv_buffer LENGTH lv_buflen.

      IF sy-subrc = 4.
        lv_eof_reached = 'X'.
      ELSEIF sy-subrc > 4.
        RAISE read_block_failed.
      ENDIF.

      TRANSFER lv_buffer TO lv_target_file_path
        LENGTH lv_buflen.

      IF sy-subrc NE 0.
        RAISE write_block_failed.
      ENDIF.

      IF lv_eof_reached = 'X'.  EXIT.  ENDIF.
    ENDDO.

    CLOSE DATASET lv_source_file_path.
    CLOSE DATASET lv_target_file_path.
    IF sy-subrc <> 0.
      RAISE close_output_file_failed.
    ENDIF.

    ex_file_size = lv_source_file_size.

  ENDMETHOD.


METHOD delete_stored_data.
  delete_stored_data_for_session( iv_session_guid = me->av_session_guid
                                  iv_dataset_guid = iv_dataset_guid
                                  iv_commit       = iv_commit ).
ENDMETHOD.


METHOD delete_stored_data_for_session.
  IF iv_dataset_guid IS INITIAL.
*  Delete session data
    DELETE FROM zqm_dev_transfer
    WHERE session_guid = iv_session_guid.
  ELSE.
*  Delete dataset data
    DELETE FROM zqm_dev_transfer
    WHERE session_guid = iv_session_guid
      AND dataset_guid = iv_dataset_guid.
  ENDIF.

  IF iv_commit = abap_true.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDIF.
ENDMETHOD.


METHOD get_session_guid.
  rv_session_guid = me->av_session_guid.
ENDMETHOD.


METHOD get_stored_data.

* Get stored data
  rt_data = get_stored_data_for_session(
    iv_werks        = iv_werks
    iv_session_guid = me->av_session_guid
  ).

ENDMETHOD.


  METHOD get_stored_data_by_status.

* Get stored data by status
    SELECT session_guid
           dataset_guid
           status
           device_id
           device_number
           raw_data
           filename
    FROM zqm_dev_transfer
    INTO TABLE rt_data
    WHERE werks = iv_werks
     AND status = iv_status.

  ENDMETHOD.


METHOD get_stored_data_for_session.

* Get stored data
  SELECT session_guid
         dataset_guid
         status
         device_id
         device_number
         raw_data
         filename
  FROM zqm_dev_transfer
       INTO TABLE rt_data
       WHERE werks = iv_werks
  AND session_guid = iv_session_guid.

ENDMETHOD.


METHOD set_status.
  IF iv_dataset_guid IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid = zcx_qm_lab_device_exceptions=>dataset_guid_is_missing.
  ENDIF.

* Update status in database
  IF iv_prueflos IS SUPPLIED.
    UPDATE zqm_dev_transfer
     SET
          status   = iv_status
          prueflos = iv_prueflos
          aenam    = sy-uname
          aedat    = sy-datum
          aezet    = sy-uzeit
    WHERE
          werks        = iv_werks AND
          session_guid = iv_session_guid AND
          dataset_guid = iv_dataset_guid.
  ELSE.
    UPDATE zqm_dev_transfer
     SET
         status = iv_status
         aenam  = sy-uname
         aedat  = sy-datum
         aezet  = sy-uzeit
    WHERE
          werks        = iv_werks AND
          session_guid = iv_session_guid AND
          dataset_guid = iv_dataset_guid.
  ENDIF.

  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
      EXPORTING
        textid = zcx_qm_lab_device_exceptions=>status_not_updated.
  ENDIF.

  IF iv_commit = abap_true.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDIF.
ENDMETHOD.


METHOD store_data.
  DATA wa_transfer_data TYPE zqm_dev_transfer.

  CONSTANTS: co_status_new TYPE zqm_dataset_status VALUE 1.

* Check data
  IF is_data-device_id IS INITIAL.
    RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions EXPORTING textid = zcx_qm_lab_device_exceptions=>device_id_is_missing.
  ENDIF.

  IF is_data-raw_data IS INITIAL.
    " RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions EXPORTING textid = zcx_qm_lab_device_exceptions=>no_data_submitted.
    " means just the empty line in the file - could be the file empty or just some empty line after or between the data
    " no need to raise exception - just safe to ignore the empty line
    RETURN.
  ENDIF.

* Fill db structure
  wa_transfer_data-werks = iv_werks.
  wa_transfer_data-session_guid = me->av_session_guid.
  rv_dataset_guid = wa_transfer_data-dataset_guid = me->_create_guid( ).
  wa_transfer_data-device_id = is_data-device_id.
  wa_transfer_data-device_number = is_data-device_number.
  wa_transfer_data-status = co_status_new.
  wa_transfer_data-filename = is_data-filename.
  wa_transfer_data-raw_data = is_data-raw_data.
  wa_transfer_data-ernam = sy-uname.
  wa_transfer_data-erdat = sy-datum.
  wa_transfer_data-erzet = sy-uzeit.

* Store data
  INSERT INTO zqm_dev_transfer VALUES wa_transfer_data.

  IF iv_commit = abap_true.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDIF.

  CLEAR wa_transfer_data.
ENDMETHOD.


METHOD _create_guid.
  rv_guid = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
ENDMETHOD.
ENDCLASS.
