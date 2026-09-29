*&---------------------------------------------------------------------*
*& Report ZQM_LAB_TEST_DEVICE_IMPORTER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zqm_lab_test_device_importer.

INCLUDE zqm_lab_test_device_imp_top.
INCLUDE zqm_lab_test_device_imp_sel.

START-OF-SELECTION.
  FREE: lt_insplot_list_buffer, lt_qals_buffer, lt_operations_buffer.

* Create new transfer object
  CREATE OBJECT obj_transfer.
  IF p_debug = abap_true.
    WRITE: / |Started new session with GUID { obj_transfer->get_session_guid( ) } in plant { p_plant }|.
  ENDIF.

  IF p_opt1 = abap_true.
    PERFORM load_plant_settings.
    PERFORM load_files.
    PERFORM extract_file_data.
  ENDIF.

  IF p_test = abap_false.
    PERFORM create_inspection_operations.
    PERFORM archive_files.
    PERFORM archive_data.
  ENDIF.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  load_plant_settings
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_plant_settings.
  DATA obj_settings TYPE REF TO zcl_qm_lab_device_customizing.
  DATA obj_exception TYPE REF TO zcx_qm_lab_device_exceptions.
  DATA lv_message TYPE string.

  TRY.
      CREATE OBJECT obj_settings.
      wa_plant_settings = obj_settings->get_plant_settings( iv_plant = p_plant ).
    CATCH zcx_qm_lab_device_exceptions INTO obj_exception.
      lv_message = obj_exception->get_text( ).
      MESSAGE lv_message TYPE 'E'.

      CLEAR lv_message.
      FREE obj_exception.
  ENDTRY.

  FREE obj_settings.
ENDFORM.                    "load_plant_settings

*&---------------------------------------------------------------------*
*&      Form  load_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_files.
  TRY.
      lt_files = zcl_qm_lab_file_handler=>get_files_from_appl_sever( iv_dir_name = wa_plant_settings-folder_path ).

      IF s_files[] IS NOT INITIAL.
        LOOP AT lt_files ASSIGNING <wa_files>.
          IF <wa_files>-name NOT IN s_files.
            DELETE TABLE lt_files
            FROM <wa_files>.
          ENDIF.
        ENDLOOP.
      ENDIF.
    CATCH zcx_qm_lab_import_exceptions.
      MESSAGE TEXT-e01 TYPE 'E'.
  ENDTRY.
ENDFORM.                    "load_files

*&---------------------------------------------------------------------*
*&      Form  delete_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM delete_files.
  DATA lv_filepath TYPE string.

  LOOP AT lt_files ASSIGNING <wa_files>.
    lv_filepath = |{ wa_plant_settings-folder_path }{ <wa_files>-name }|.

    DELETE DATASET lv_filepath.

    CLEAR lv_filepath.
  ENDLOOP.
ENDFORM.                    "delete_files

*&---------------------------------------------------------------------*
*&      Form  archive_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM archive_files.
  DATA lv_filename TYPE eps2filnam.
  DATA lv_filepath TYPE string.

  LOOP AT lt_files ASSIGNING <wa_files>.
    lv_filename = <wa_files>-name.

    CALL METHOD zcl_qm_lab_device_transfer=>copy_files_local
      EXPORTING
        im_source_file           = lv_filename
        im_source_directory      = CONV #( wa_plant_settings-folder_path )
        im_target_file           = lv_filename
        im_target_directory      = CONV #( wa_plant_settings-archive_path )
      EXCEPTIONS
        open_input_file_failed   = 1
        open_output_file_failed  = 2
        write_block_failed       = 3
        read_block_failed        = 4
        close_output_file_failed = 5
        OTHERS                   = 6.

    lv_filepath = |{ wa_plant_settings-folder_path }{ <wa_files>-name }|.
    DELETE DATASET lv_filepath.
    CLEAR: lv_filename, lv_filepath.
  ENDLOOP.
ENDFORM.                    "archive_files

*&---------------------------------------------------------------------*
*&      Form  extract_file_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM extract_file_data.
  DATA lv_filepath TYPE string.
  DATA lv_dataset TYPE string.
  DATA wa_transfer TYPE zqm_s_lab_device_store_data.
  DATA lv_device_number TYPE zqm_testing_device_number.
  DATA obj_id_finder TYPE REF TO zcl_qm_lab_device_id_finder.
  DATA obj_number_finder TYPE REF TO zcl_qm_lab_device_nr_finder.

  CREATE OBJECT obj_id_finder.
  CREATE OBJECT obj_number_finder.

* Extract data from file and store them temporary in a transfer table
  LOOP AT lt_files ASSIGNING <wa_files> WHERE size > 0.
    lv_filepath = |{ wa_plant_settings-folder_path }{ <wa_files>-name }|.

    OPEN DATASET lv_filepath FOR INPUT IN TEXT MODE ENCODING NON-UNICODE WITH SMART LINEFEED.

    IF sy-subrc IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    DO.
      TRY.
          READ DATASET lv_filepath INTO lv_dataset.
        CATCH cx_sy_conversion_codepage.
          CONTINUE.
      ENDTRY.

      IF sy-subrc IS NOT INITIAL.
        EXIT.
      ENDIF.

      TRY.
          wa_transfer-device_id = obj_id_finder->find( iv_filename = <wa_files>-name
                                                       iv_raw_data = lv_dataset ).

          wa_transfer-device_number = obj_number_finder->find( iv_device_id = wa_transfer-device_id
                                                               iv_filename  = <wa_files>-name
                                                               iv_raw_data  = lv_dataset ).
        CATCH zcx_qm_lab_device_exceptions.
          CONTINUE.
      ENDTRY.

      wa_transfer-filename = <wa_files>-name.
      wa_transfer-raw_data = lv_dataset.

      IF p_test = abap_false.
        obj_transfer->store_data(
          iv_werks = p_plant
          is_data = wa_transfer
        ).
      ENDIF.

      CLEAR: wa_transfer, lv_dataset.
    ENDDO.

    CLOSE DATASET lv_filepath.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

    CLEAR lv_filepath.
  ENDLOOP.

  FREE: obj_id_finder, obj_number_finder.
ENDFORM.                    "extract_file_data

*&---------------------------------------------------------------------*
*&      Form  create_inspection_operations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_inspection_operations.
  DATA lt_transfer_data TYPE zqm_t_lab_device_read_data.
  DATA lt_filenames TYPE string_table.
  DATA lt_converted_data TYPE ty_t_converted_data.
  DATA wa_device_settings TYPE zqm_s_lab_device_settings.
  DATA lv_insplot TYPE qibplosnr.
  DATA wa_removed_converted_data TYPE ty_s_converted_data.

  FIELD-SYMBOLS: <wa_filenames>        TYPE string,
                 <wa_transfer_data>    TYPE zqm_s_lab_device_read_data,
                 <wa_converted_data>   TYPE ty_s_converted_data,
                 <wa_target_structure> TYPE any.

  IF p_opt1 = abap_true.
* Get stored transfer data for this session
    lt_transfer_data = obj_transfer->get_stored_data(
      iv_werks = p_plant
    ).
  ELSEIF p_opt2 = abap_true.
* Load data from older session
    lt_transfer_data = zcl_qm_lab_device_transfer=>get_stored_data_for_session(
      iv_werks        = p_plant
      iv_session_guid = p_sess
    ).
  ELSEIF p_opt3 = abap_true.
* Load data from status
    lt_transfer_data = zcl_qm_lab_device_transfer=>get_stored_data_by_status(
      iv_werks  = p_plant
      iv_status = p_stat
    ).
  ELSE.
    RETURN.
  ENDIF.

* Extract filenames
  PERFORM extract_filenames USING lt_transfer_data
                            CHANGING lt_filenames.

  LOOP AT lt_filenames ASSIGNING <wa_filenames>.
    IF p_debug = abap_true.
      WRITE: /  |-----------------------------------------------------------|.
      WRITE: /4 |{ lines( lt_transfer_data ) } entries loaded from the file:|.
      WRITE: /8 |{ <wa_filenames> }|.
    ENDIF.

    FREE lt_converted_data.
    PERFORM convert_data USING <wa_filenames>
                               lt_transfer_data
                         CHANGING lt_converted_data
                                  wa_device_settings.
    IF p_debug = abap_true.
      WRITE: /4 |Number of entries after convertion: { lines( lt_converted_data ) }|.
    ENDIF.

* Set inspector
    PERFORM set_inspector USING wa_device_settings
                          CHANGING lt_converted_data
                                   wa_removed_converted_data.
    IF p_debug = abap_true.
      WRITE: /4 |Number of entries after set inspector: { lines( lt_converted_data ) }|.
    ENDIF.

    IF wa_removed_converted_data IS NOT INITIAL.
* Get transfer data
      READ TABLE lt_transfer_data
      ASSIGNING <wa_transfer_data>
      WITH KEY session_guid = wa_removed_converted_data-session_guid
               dataset_guid = wa_removed_converted_data-dataset_guid.

      <wa_transfer_data>-status = co_status_success.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.

      UNASSIGN <wa_transfer_data>.
      CLEAR wa_removed_converted_data.
    ENDIF.

    IF p_debug = abap_true.
      WRITE: /.
    ENDIF.

* Set values
    PERFORM set_insplot_value CHANGING lt_converted_data
                                       lt_transfer_data.

    IF p_debug = abap_true.
      WRITE: /.
      WRITE: /4 |set_insplot_value summary for transfer_data (+converted_data):|.
      LOOP AT lt_transfer_data ASSIGNING <wa_transfer_data>.
        WRITE: /8 |{ <wa_transfer_data>-dataset_guid } status: { <wa_transfer_data>-status }|.
        WRITE: /8 |Lot: {
          VALUE #( lt_converted_data[ session_guid = <wa_transfer_data>-session_guid
                   dataset_guid = <wa_transfer_data>-dataset_guid ]-insplot OPTIONAL )
        } Oper: {
          VALUE #( lt_converted_data[ session_guid = <wa_transfer_data>-session_guid
                   dataset_guid = <wa_transfer_data>-dataset_guid ]-inspoper OPTIONAL )
        } Point: {
          VALUE #( lt_converted_data[ session_guid = <wa_transfer_data>-session_guid
                   dataset_guid = <wa_transfer_data>-dataset_guid ]-insppoint OPTIONAL )
        }|.
        WRITE: /.
      ENDLOOP.
    ENDIF.

    CLEAR wa_device_settings.
  ENDLOOP.

  FREE: lt_transfer_data, lt_filenames.
ENDFORM.                    "create_inspection_operations

*&---------------------------------------------------------------------*
*&      Form  set_inspector
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IS_DEVICE_SETTINGS  text
*      -->CT_CONVERTED_DATA   text
*      -->OF                  text
*      -->LS_CONVERTED_DATA   text
*----------------------------------------------------------------------*
FORM set_inspector USING is_device_settings TYPE zqm_s_lab_device_settings
                   CHANGING ct_converted_data TYPE ty_t_converted_data
                            cs_removed_dataset TYPE ty_s_converted_data.

  DATA lv_inspector TYPE qinspector.

  FIELD-SYMBOLS: <wa_converted_data> TYPE ty_s_converted_data,
                 <wa_data_structure> TYPE any,
                 <lv_bedap_code>     TYPE any,
                 <lv_value>          TYPE any.

* Find inspector
  LOOP AT ct_converted_data ASSIGNING <wa_converted_data>.
    ASSIGN <wa_converted_data>-data->* TO <wa_data_structure>.
    IF sy-subrc IS INITIAL.
      ASSIGN COMPONENT 'BEDAP_CODE' OF STRUCTURE <wa_data_structure> TO <lv_bedap_code>.
      IF sy-subrc IS INITIAL AND <lv_bedap_code> = is_device_settings-inspector_code.
        ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa_data_structure> TO <lv_value>.
        IF sy-subrc IS INITIAL.
* Store inspectro code and delete dataset
          IF p_debug = abap_true.
            WRITE: / |set_inspector removing { <wa_converted_data>-dataset_guid }|.
          ENDIF.
          lv_inspector = <lv_value>.
          cs_removed_dataset = <wa_converted_data>.
          DELETE TABLE ct_converted_data FROM <wa_converted_data>.
          EXIT.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

* Set inspector
  LOOP AT ct_converted_data ASSIGNING <wa_converted_data>.
    <wa_converted_data>-inspector = lv_inspector.
  ENDLOOP.

  CLEAR lv_inspector.
ENDFORM.                    "set_inspector

*&---------------------------------------------------------------------*
*&      Form  extract_filenames
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_TRANSFER_DATA  text
*      -->CT_FILENAMES      text
*----------------------------------------------------------------------*
FORM extract_filenames USING it_transfer_data TYPE zqm_t_lab_device_read_data
                       CHANGING ct_filenames TYPE string_table.

  FIELD-SYMBOLS <wa_transfer_data> TYPE zqm_s_lab_device_read_data.

  LOOP AT it_transfer_data ASSIGNING <wa_transfer_data>.
    APPEND <wa_transfer_data>-filename TO ct_filenames.
  ENDLOOP.

  SORT ct_filenames BY table_line.
  DELETE ADJACENT DUPLICATES FROM ct_filenames COMPARING table_line.
ENDFORM.                    "extract_filenames

*&---------------------------------------------------------------------*
*&      Form  find_inspection_lot
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->WA_TARGET_STRUCTURE  text
*----------------------------------------------------------------------*
FORM find_inspection_lot USING is_target_structure TYPE any
                               iv_plant            TYPE werks_d
                      CHANGING cv_insplot          TYPE qibplosnr.

  DATA: wa_general               TYPE bapi2045d_il0,
        wa_task_list             TYPE bapi2045d_il1,
        wa_customer_include_data TYPE bapi2045ci,
        lt_system_status         TYPE STANDARD TABLE OF bapi2045ss,
        lt_user_status           TYPE STANDARD TABLE OF bapi2045us,
        ls_insplot_return        TYPE bapireturn1.

  FIELD-SYMBOLS: <lv_date>  TYPE any,
                 <lv_time>  TYPE any,
                 <lv_linie> TYPE any.

  CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
             co_storno   TYPE j_istat VALUE 'I0224'.

* Set field symbols
  UNASSIGN: <lv_date>, <lv_time>, <lv_linie>.
  ASSIGN COMPONENT 'DATE ' OF STRUCTURE is_target_structure TO <lv_date>.
  ASSIGN COMPONENT 'TIME'  OF STRUCTURE is_target_structure TO <lv_time>.
  ASSIGN COMPONENT 'LINIE' OF STRUCTURE is_target_structure TO <lv_linie>.

  IF <lv_date> IS NOT ASSIGNED OR <lv_time> IS NOT ASSIGNED OR <lv_linie> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  IF lt_insplot_list_buffer[] IS INITIAL.
    CLEAR: ls_insplot_return.

* Get inspection lots
    CALL FUNCTION 'BAPI_INSPLOT_GETLIST'
      EXPORTING
        plant           = p_plant
        max_rows        = 9999
        status_created  = 'X'
        status_released = 'X'
        status_ud       = ' '
        creat_dat       = CONV qdatumerst( sy-datum - 360 )
        selection_id    = ' '
      IMPORTING
        return          = ls_insplot_return
      TABLES
        insplot_list    = lt_insplot_list_buffer.

    DELETE lt_insplot_list_buffer WHERE insppoints = abap_false.

    IF lines( lt_insplot_list_buffer ) > 0.
      SELECT FROM qals
          FIELDS prueflos, werk, zzlinienr
          FOR ALL ENTRIES IN @lt_insplot_list_buffer
          WHERE  prueflos = @lt_insplot_list_buffer-insplot
          INTO CORRESPONDING FIELDS OF TABLE @lt_qals_buffer.
    ENDIF.

    IF p_debug = abap_true.
      PERFORM write_bapiret USING 'BAPI_INSPLOT_GETLIST' ls_insplot_return.
      WRITE: /8 |{  lines( lt_qals_buffer ) } inspection lots found in plant { p_plant } |.
    ENDIF.
  ENDIF.

  "LOOP AT lt_insplot_list_buffer ASSIGNING <wa_insplot_list> WHERE insppoints = abap_true.
  LOOP AT lt_qals_buffer ASSIGNING FIELD-SYMBOL(<wa_qals>) WHERE zzlinienr = <lv_linie>.
    FREE: lt_system_status, lt_user_status.
    CLEAR: ls_insplot_return.

* Get detail
    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number                = <wa_qals>-prueflos
      IMPORTING
        general_data          = wa_general
        task_list_data        = wa_task_list
        customer_include_data = wa_customer_include_data
        return                = ls_insplot_return.

    IF p_debug = abap_true.
      PERFORM write_bapiret USING 'BAPI_INSPLOT_GETDETAIL' ls_insplot_return.
    ENDIF.

* Check data if inspection lot is relevant
    IF ( wa_general-inspection_starts_on_date > <lv_date> OR wa_general-inspection_ends_on_date < <lv_date> ) OR
       (
        ( wa_general-inspection_starts_on_date = <lv_date> AND wa_general-inspection_starts_at_time > <lv_time> )
          OR
        ( wa_general-inspection_ends_on_date = <lv_date> AND wa_general-inspection_ends_at_time < <lv_time> )
       ).
      CONTINUE.
    ENDIF.

* Check status
    CLEAR: ls_insplot_return.
    CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
      EXPORTING
        number        = <wa_qals>-prueflos
        language      = VALUE bapi2045la( langu = 'EN' )
      IMPORTING
        return        = ls_insplot_return
      TABLES
        system_status = lt_system_status
        user_status   = lt_user_status.

    IF p_debug = abap_true.
      PERFORM write_bapiret USING 'BAPI_INSPLOT_GETSTATUS' ls_insplot_return.
    ENDIF.

    DELETE lt_system_status WHERE sys_status <> co_decision
                              AND sys_status <> co_storno.

    IF lt_system_status[] IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    cv_insplot = <wa_qals>-prueflos.
    RETURN.

    CLEAR: wa_general, wa_task_list, wa_customer_include_data.
  ENDLOOP.

ENDFORM.                    "find_inspection_lot

*&---------------------------------------------------------------------*
*&      Form  set_insplot_value
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IV_INSPLOT           text
*      -->IS_TARGET_STRUCTURE  text
*----------------------------------------------------------------------*
FORM set_insplot_value CHANGING ct_converted_data TYPE ty_t_converted_data
                                ct_transfer_data TYPE zqm_t_lab_device_read_data.

  DATA: lv_insplot       TYPE qibplosnr,
        lv_last_insplot  TYPE qibplosnr,
        lv_last_inspoper TYPE qibpvornr.
  DATA lv_bedap_code TYPE zqm_bedap_code.
  DATA wa_bedap_mapping TYPE zqm_s_lab_device_bedap_mapping.
  DATA lv_status TYPE zqm_dataset_status.
  DATA lt_operations TYPE STANDARD TABLE OF bapi2045l2.
  DATA lt_char_requiremens TYPE STANDARD TABLE OF bapi2045d1.
  DATA: lt_sample_results          TYPE STANDARD TABLE OF bapi2045d3,
        lt_existing_sample_results TYPE STANDARD TABLE OF bapi2045d3,
        lt_sample_results_save     TYPE STANDARD TABLE OF bapi2045d3.
  DATA: lt_inspection_points      TYPE STANDARD TABLE OF bapi2045l4,
        lt_inspection_points_save TYPE STANDARD TABLE OF bapi2045l4.
  DATA: lt_return TYPE bapiret2_t,
        wa_return TYPE bapiret2.
  DATA lv_error TYPE abap_bool.
  DATA lv_no_operation TYPE abap_bool.
  DATA lv_temp_insppoint TYPE qibpppktnr VALUE 999000.

  FIELD-SYMBOLS: <wa_converted_data>          TYPE ty_s_converted_data,
                 <wa_transfer_data>           TYPE zqm_s_lab_device_read_data,
                 <wa_target_structure>        TYPE any,
                 <lv_bedap_code>              TYPE any,
                 <wa_operations>              TYPE bapi2045l2,
                 <wa_char_requirements>       TYPE bapi2045d1,
                 <wa_char_requirements_bedap> TYPE bapi2045d1,
                 <wa_sample_results>          TYPE bapi2045d3,
                 <wa_existing_sample_results> TYPE bapi2045d3,
                 <wa_inspection_points>       TYPE bapi2045l4,
                 <lv_linie>                   TYPE any,
                 <lv_date>                    TYPE any,
                 <lv_time>                    TYPE any,
                 <lv_value>                   TYPE any,
                 <lv_field_to>                TYPE any,
                 <lv_sample_type>             TYPE zbms_entnahme_probenart.

  CONSTANTS: co_normal_sample TYPE zbms_entnahme_probenart VALUE 'N',
             co_retest_sample TYPE zbms_entnahme_probenart VALUE 'RT'.

* Build inspection lot data
  LOOP AT ct_converted_data ASSIGNING <wa_converted_data>.
    IF p_debug = abap_true.
      WRITE: /.
      WRITE: / |Processing converted entry as { sy-uname } in { p_plant }|.
      WRITE: /4 |{ <wa_converted_data>-session_guid } { <wa_converted_data>-dataset_guid }|.
    ENDIF.

    CLEAR lv_status.
    ASSIGN <wa_converted_data>-data->* TO <wa_target_structure>.

* Get transfer data
    READ TABLE ct_transfer_data
    ASSIGNING <wa_transfer_data>
    WITH KEY session_guid = <wa_converted_data>-session_guid
             dataset_guid = <wa_converted_data>-dataset_guid.

    IF <lv_sample_type> IS NOT ASSIGNED.
      IF <wa_transfer_data>-filename CP '*_RT_*' OR <wa_transfer_data>-filename CP '*_RT-*'.
        ASSIGN co_retest_sample TO <lv_sample_type>.
      ELSE.
        ASSIGN co_normal_sample TO <lv_sample_type>.
      ENDIF.
    ENDIF.

* Find inspection lot
    CLEAR lv_insplot.
    PERFORM find_inspection_lot USING <wa_target_structure>
                                      p_plant
                                CHANGING lv_insplot.
    IF p_debug = abap_true.
      ASSIGN COMPONENT 'BEDAP_CODE' OF STRUCTURE <wa_target_structure> TO <lv_bedap_code>.
      ASSIGN COMPONENT 'LINIE' OF STRUCTURE <wa_target_structure> TO <lv_linie>.
      ASSIGN COMPONENT 'DATE' OF STRUCTURE <wa_target_structure> TO <lv_date>.
      ASSIGN COMPONENT 'TIME' OF STRUCTURE <wa_target_structure> TO <lv_time>.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa_target_structure> TO <lv_value>.
      WRITE: /4 |{ <lv_linie> } { <lv_date> } { <lv_time> } { <lv_value> } { <lv_bedap_code> }|.
      WRITE: /4 |Finding inspection lot: { lv_insplot }|.
    ENDIF.

    IF lv_insplot IS INITIAL.
      IF p_debug = abap_true.
        WRITE: /4 |No inspection lot found for: { p_plant }|.
      ENDIF.

      <wa_transfer_data>-status = co_status_no_insplot.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.

      CONTINUE.
    ENDIF.

* Get bedap mapping
    ASSIGN COMPONENT 'BEDAP_CODE' OF STRUCTURE <wa_target_structure> TO <lv_bedap_code>.
    lv_bedap_code = <lv_bedap_code>.

    CLEAR: wa_bedap_mapping, lv_status.
    PERFORM get_bedap_mapping USING lv_bedap_code
                              CHANGING wa_bedap_mapping
                                       lv_status.

    IF lv_status = co_status_bedap.
      IF p_debug = abap_true.
        WRITE: /4 |No BEDAP mapping found.|.
      ENDIF.

      <wa_transfer_data>-status = co_status_bedap.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.

      CONTINUE.
    ENDIF.

* Get inspection lot operations
    FREE lt_operations.
    PERFORM get_operations USING lv_insplot
                           CHANGING lt_operations.

    IF lt_operations[] IS INITIAL.
      IF p_debug = abap_true.
        WRITE: /4 |No Operations found.|.
      ENDIF.

* No operation found.
      <wa_transfer_data>-status = co_status_no_operation_char.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.

      CONTINUE.
    ENDIF.

    lv_no_operation = abap_true.

* Try to find inspection lot operation which includes the required characteristics
    LOOP AT lt_operations ASSIGNING <wa_operations>.
      UNASSIGN <wa_char_requirements_bedap>.
      FREE lt_char_requiremens.

      READ TABLE lt_char_requiremens_buffer
      ASSIGNING <wa_char_requirements_bedap>
      WITH KEY insplot = <wa_operations>-insplot
               inspoper = <wa_operations>-inspoper
               mstr_char = wa_bedap_mapping-mkmnr.

      IF sy-subrc IS NOT INITIAL.
        CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
          EXPORTING
            insplot                = <wa_operations>-insplot
            inspoper               = <wa_operations>-inspoper
            read_char_requirements = abap_true
          TABLES
            char_requirements      = lt_char_requiremens.

        READ TABLE lt_char_requiremens
        ASSIGNING <wa_char_requirements_bedap>
        WITH KEY mstr_char = wa_bedap_mapping-mkmnr.

        IF sy-subrc IS NOT INITIAL.
          CONTINUE.
        ENDIF.

        lv_no_operation = abap_false.

        INSERT LINES OF lt_char_requiremens INTO TABLE lt_char_requiremens_buffer.
      ELSE.
        lv_no_operation = abap_false.
      ENDIF.

* Assign field symbol
      ASSIGN COMPONENT 'LINIE' OF STRUCTURE <wa_target_structure> TO <lv_linie>.
      ASSIGN COMPONENT 'DATE' OF STRUCTURE <wa_target_structure> TO <lv_date>.
      ASSIGN COMPONENT 'TIME' OF STRUCTURE <wa_target_structure> TO <lv_time>.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <wa_target_structure> TO <lv_value>.

      IF lv_last_insplot <> <wa_operations>-insplot OR lv_last_inspoper <> <wa_operations>-inspoper.
        FREE: lt_existing_sample_results, lt_inspection_points.

* Get existing sample results
        CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
          EXPORTING
            insplot             = <wa_operations>-insplot
            inspoper            = <wa_operations>-inspoper
            read_insppoints     = abap_true
            read_sample_results = abap_true
            max_insppoints      = 2000
          TABLES
            insppoints          = lt_inspection_points
            sample_results      = lt_existing_sample_results.

        lv_last_insplot = <wa_operations>-insplot.
        lv_last_inspoper = <wa_operations>-inspoper.
      ENDIF.

* Try to find an existing inspection point. Otherwise create one
      READ TABLE lt_inspection_points
      ASSIGNING <wa_inspection_points>
      WITH KEY userd1 = <lv_date>
               usert1 = <lv_time>
               usern2 = <lv_linie>
               userc2 = <lv_sample_type>.

      IF sy-subrc IS NOT INITIAL.
        APPEND INITIAL LINE TO lt_inspection_points_save ASSIGNING <wa_inspection_points>.
        <wa_inspection_points>-insplot = <wa_operations>-insplot.
        <wa_inspection_points>-inspoper = <wa_operations>-inspoper.
        <wa_inspection_points>-insppoint = lv_temp_insppoint.
        <wa_inspection_points>-userd1 = <lv_date>.
        <wa_inspection_points>-usert1 = <lv_time>.
        <wa_inspection_points>-userc2 = <lv_sample_type>.
        <wa_inspection_points>-usern2 = <lv_linie>.

* Add new inspection point also to existing ones for later reads
        APPEND <wa_inspection_points> TO lt_inspection_points.

        lv_temp_insppoint = lv_temp_insppoint + 1.
      ELSE.
        READ TABLE lt_inspection_points_save
        WITH KEY insplot = <wa_inspection_points>-insplot
                 inspoper = <wa_inspection_points>-inspoper
                 insppoint = <wa_inspection_points>-insppoint
        TRANSPORTING NO FIELDS.

        IF sy-subrc IS NOT INITIAL.
          APPEND <wa_inspection_points> TO lt_inspection_points_save.
        ENDIF.

        LOOP AT lt_existing_sample_results ASSIGNING <wa_existing_sample_results> WHERE insplot = <wa_operations>-insplot
                                                                                    AND inspoper = <wa_operations>-inspoper
                                                                                    AND inspsample = <wa_inspection_points>-insppoint.

          READ TABLE lt_sample_results
          WITH KEY insplot = <wa_existing_sample_results>-insplot
                   inspoper = <wa_existing_sample_results>-inspoper
                   inspchar = <wa_existing_sample_results>-inspchar
                   inspsample = <wa_existing_sample_results>-inspsample
          TRANSPORTING NO FIELDS.

          IF sy-subrc IS NOT INITIAL.
            APPEND <wa_existing_sample_results> TO lt_sample_results.
          ENDIF.
        ENDLOOP.
      ENDIF.

* Try to find sample result
      READ TABLE lt_sample_results
      ASSIGNING <wa_sample_results>
      WITH KEY insplot = <wa_operations>-insplot
               inspoper = <wa_char_requirements_bedap>-inspoper
               inspchar = <wa_char_requirements_bedap>-inspchar
               inspsample = <wa_inspection_points>-insppoint.

      IF sy-subrc IS NOT INITIAL.
        LOOP AT lt_char_requiremens_buffer ASSIGNING <wa_char_requirements> WHERE insplot = <wa_char_requirements_bedap>-insplot
                                                                              AND inspoper = <wa_char_requirements_bedap>-inspoper.
* Create sample result
          APPEND INITIAL LINE TO lt_sample_results ASSIGNING <wa_sample_results>.
          <wa_sample_results>-insplot = <wa_operations>-insplot.
          <wa_sample_results>-inspoper = <wa_operations>-inspoper.
          <wa_sample_results>-inspchar = <wa_char_requirements>-inspchar.
          <wa_sample_results>-inspsample = <wa_inspection_points>-insppoint.
          <wa_sample_results>-inspector = <wa_converted_data>-inspector.
          <wa_sample_results>-remark = <wa_converted_data>-device_number.
        ENDLOOP.

        READ TABLE lt_sample_results
        ASSIGNING <wa_sample_results>
        WITH KEY insplot = <wa_operations>-insplot
                 inspoper = <wa_char_requirements_bedap>-inspoper
                 inspchar = <wa_char_requirements_bedap>-inspchar
                 inspsample = <wa_inspection_points>-insppoint.
      ENDIF.

      IF <wa_sample_results> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

* Set value.
      IF <wa_char_requirements_bedap>-cat_type1 IS NOT INITIAL.
* Catalog value
        <wa_sample_results>-code_grp1 = zcl_qm_lab_bms_util=>get_code_group( iv_sel_set      = <wa_char_requirements_bedap>-sel_set1
                                                                             iv_plant        = <wa_char_requirements_bedap>-psel_set1
                                                                             iv_catalog_type = <wa_char_requirements_bedap>-cat_type1 ).

        <wa_sample_results>-code1 = <lv_value>.
      ELSE.
* Single value
        <wa_sample_results>-mean_value = <lv_value>.
      ENDIF.

* Clear existing original input
      CLEAR: <wa_sample_results>-original_input.

* Update also existing sample results for later reads
      MODIFY TABLE lt_existing_sample_results FROM <wa_sample_results>.

      <wa_converted_data>-insplot = <wa_inspection_points>-insplot.
      <wa_converted_data>-inspoper = <wa_inspection_points>-inspoper.
      <wa_converted_data>-insppoint = <wa_inspection_points>-insppoint.

      EXIT.

      UNASSIGN: <lv_date>, <lv_time>, <lv_value>, <lv_linie>, <wa_sample_results>, <wa_inspection_points>,
                <wa_char_requirements_bedap>.
    ENDLOOP.

    IF lv_no_operation = abap_true.
* No operation found.
      <wa_transfer_data>-status = co_status_no_operation_char.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.
    ENDIF.

    CLEAR lv_insplot.
  ENDLOOP.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

* Store values
  LOOP AT lt_inspection_points_save ASSIGNING <wa_inspection_points>.
    lt_sample_results_save[] = lt_sample_results[].

    DELETE lt_sample_results_save
    WHERE insplot <> <wa_inspection_points>-insplot
       OR inspoper <> <wa_inspection_points>-inspoper
       OR inspsample <> <wa_inspection_points>-insppoint.

    IF lt_sample_results_save[] IS INITIAL.
      CONTINUE.
    ENDIF.

    IF <wa_inspection_points>-insppoint >= 999000.
* Remove temporary samplepoint
      CLEAR <wa_inspection_points>-insppoint.

      LOOP AT lt_sample_results_save ASSIGNING <wa_sample_results>.
        CLEAR <wa_sample_results>-inspsample.
      ENDLOOP.
    ENDIF.

* Save data
    CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
      EXPORTING
        insplot              = <wa_inspection_points>-insplot
        inspoper             = <wa_inspection_points>-inspoper
        insppointdata        = <wa_inspection_points>
        handheld_application = ' '
      IMPORTING
        return               = wa_return
      TABLES
        sample_results       = lt_sample_results_save
        returntable          = lt_return.

    IF wa_return-type = 'E' OR wa_return-type = 'A'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      lv_error = abap_true.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
      lv_error = abap_false.
    ENDIF.

    IF p_debug = abap_true.
      WRITE: /.
    ENDIF.
    LOOP AT ct_converted_data ASSIGNING <wa_converted_data> WHERE insplot = <wa_inspection_points>-insplot
                                                              AND inspoper = <wa_inspection_points>-inspoper
                                                              AND insppoint = <wa_inspection_points>-insppoint.
      READ TABLE ct_transfer_data
      ASSIGNING <wa_transfer_data>
      WITH KEY session_guid = <wa_converted_data>-session_guid
               dataset_guid = <wa_converted_data>-dataset_guid.

      IF lv_error = abap_true.
        <wa_transfer_data>-status = co_status_error.
      ELSE.
        <wa_transfer_data>-status = co_status_success.
      ENDIF.

      obj_transfer->set_status( iv_werks        = p_plant
                                iv_session_guid = <wa_transfer_data>-session_guid
                                iv_dataset_guid = <wa_transfer_data>-dataset_guid
                                iv_status       = <wa_transfer_data>-status
                                iv_prueflos     = <wa_inspection_points>-insplot
                                iv_commit       = abap_true ).
      IF p_debug = abap_true.
        WRITE: /4 |Set status: { <wa_transfer_data>-status }|.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

    FREE: lt_return, lt_sample_results_save.
    CLEAR: wa_return, lv_error.
  ENDLOOP.

  FREE: lt_inspection_points_save, lt_sample_results.
ENDFORM.                    "set_insplot_value

*&---------------------------------------------------------------------*
*&      Form  GET_DEVICE_SETTINGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IV_DEVICE_ID  text
*      -->CS_SETTINGS   text
*----------------------------------------------------------------------*
FORM get_device_settings USING iv_device_id TYPE zqm_testing_device_id
                         CHANGING cs_settings TYPE zqm_s_lab_device_settings.

  DATA obj_customizing TYPE REF TO zcl_qm_lab_device_customizing.

* Find settings in buffer table
  READ TABLE lt_device_settings_buffer
  INTO cs_settings
  WITH KEY device_id = iv_device_id.

  IF sy-subrc IS INITIAL.
    RETURN.
  ENDIF.

* Read settings from database and store in local buffer
  CREATE OBJECT obj_customizing.

  cs_settings = obj_customizing->get_device_settings( iv_device_id = iv_device_id ).
  INSERT cs_settings INTO TABLE lt_device_settings_buffer.

  FREE obj_customizing.
ENDFORM.                    "GET_DEVICE_SETTINGS

*&---------------------------------------------------------------------*
*&      Form  get_bedap_mapping
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->CT_MAPPING text
*----------------------------------------------------------------------*
FORM get_bedap_mapping USING iv_bedap_code TYPE zqm_bedap_code
                       CHANGING cs_mapping TYPE zqm_s_lab_device_bedap_mapping
                                cv_status TYPE zqm_dataset_status.

  DATA obj_customizing TYPE REF TO zcl_qm_lab_device_customizing.

* Try to find data in buffer
  READ TABLE lt_bedap_mapping_buffer
  INTO cs_mapping
  WITH KEY bedap = iv_bedap_code.

  IF sy-subrc IS INITIAL.
    RETURN.
  ENDIF.

  CREATE OBJECT obj_customizing.

  TRY.
      cs_mapping = obj_customizing->get_bedap_code_mapping( iv_bedap_code = iv_bedap_code ).
    CATCH zcx_qm_lab_device_exceptions.
      cv_status = co_status_bedap.
      RETURN.
  ENDTRY.

  INSERT cs_mapping INTO TABLE lt_bedap_mapping_buffer.

  FREE obj_customizing.
ENDFORM.                    "get_bedap_mapping

*&---------------------------------------------------------------------*
*&      Form  get_operations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IV_INSPLOT     text
*      -->CT_OPERATIONS  text
*      -->BAPI2045L2     text
*----------------------------------------------------------------------*
FORM get_operations USING iv_insplot TYPE qibplosnr
                    CHANGING ct_operations TYPE ty_bapi2045l2.

  FIELD-SYMBOLS <wa_operations> TYPE bapi2045l2.

  READ TABLE lt_operations_buffer
  WITH KEY insplot = iv_insplot
  TRANSPORTING NO FIELDS.

  IF sy-subrc IS NOT INITIAL.
    CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
      EXPORTING
        number        = iv_insplot
      TABLES
        inspoper_list = ct_operations.

    INSERT LINES OF ct_operations INTO TABLE lt_operations_buffer.
  ELSE.
    LOOP AT lt_operations_buffer ASSIGNING <wa_operations> WHERE insplot = iv_insplot.
      APPEND <wa_operations> TO ct_operations.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "get_operations

*&---------------------------------------------------------------------*
*&      Form  convert_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_TRANSFER_DATA   text
*      -->CT_CONVERTED_DATA  text
*----------------------------------------------------------------------*
FORM convert_data USING iv_filename TYPE string
                        it_transfer_data TYPE zqm_t_lab_device_read_data
                  CHANGING ct_converted_data TYPE ty_t_converted_data
                           cs_device_settings TYPE zqm_s_lab_device_settings.

  DATA lt_transfer_data TYPE zqm_t_lab_device_read_data.
  DATA obj_data_mapper TYPE REF TO zif_qm_lab_device_mapper.

  FIELD-SYMBOLS: <wa_transfer_data>    TYPE zqm_s_lab_device_read_data,
                 <wa_converted_data>   TYPE ty_s_converted_data,
                 <wa_target_structure> TYPE any.

* Get datasets for current file
  lt_transfer_data[] = it_transfer_data[].
  DELETE lt_transfer_data WHERE filename <> iv_filename.

* Convert data
  LOOP AT lt_transfer_data ASSIGNING <wa_transfer_data>.
    APPEND INITIAL LINE TO ct_converted_data ASSIGNING <wa_converted_data>.
    <wa_converted_data>-session_guid = <wa_transfer_data>-session_guid.
    <wa_converted_data>-dataset_guid = <wa_transfer_data>-dataset_guid.
    <wa_converted_data>-device_number = <wa_transfer_data>-device_number.

    IF cs_device_settings IS INITIAL.
* Get device settings
      PERFORM get_device_settings USING <wa_transfer_data>-device_id
                                  CHANGING cs_device_settings.
    ENDIF.

* Create target structure object
    CREATE DATA <wa_converted_data>-data TYPE (cs_device_settings-target_structure).
    ASSIGN <wa_converted_data>-data->* TO <wa_target_structure>.

    IF cs_device_settings-mapping_class IS NOT INITIAL.
      CREATE OBJECT obj_data_mapper TYPE (cs_device_settings-mapping_class).

      IF obj_data_mapper IS BOUND.
* Use data mapper to move complex structure
        obj_data_mapper->map( EXPORTING is_transfer_data   = <wa_transfer_data>
                                        is_device_settings = cs_device_settings
                              IMPORTING es_mapped_data = <wa_target_structure> ).
      ENDIF.
    ELSE.
* Move raw values to structure
      MOVE <wa_transfer_data>-raw_data TO <wa_target_structure>.
    ENDIF.

    IF <wa_target_structure> IS INITIAL.
      IF p_debug = abap_true.
        WRITE: / |convert_data removing { <wa_transfer_data>-device_id } { <wa_transfer_data>-device_number }|.
        WRITE: / |{ <wa_transfer_data>-raw_data } from converted data|.
      ENDIF.
      DELETE TABLE ct_converted_data FROM <wa_converted_data>.
      CONTINUE.
    ENDIF.
  ENDLOOP.

  FREE lt_transfer_data.
  FREE obj_data_mapper.
ENDFORM.                    "convert_data
*&---------------------------------------------------------------------*
*&      Form  ARCHIVE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM archive_data .

  DATA obj_transfer TYPE REF TO zcl_qm_lab_device_transfer.

* Create new transfer object
  CREATE OBJECT obj_transfer.
  obj_transfer->archive_data( ).

ENDFORM.

FORM write_bapiret USING iv_bapi_name TYPE string
                         is_bapi_ret  TYPE bapireturn1.

  IF is_bapi_ret IS NOT INITIAL AND
     ( is_bapi_ret-type = 'E' OR is_bapi_ret-type = 'A' OR is_bapi_ret-type = 'X' ).
    WRITE: / |{ iv_bapi_name } { is_bapi_ret-type } { is_bapi_ret-id }-{ is_bapi_ret-number }: {
    is_bapi_ret-message
    } { is_bapi_ret-message_v1
    } { is_bapi_ret-message_v2
    } { is_bapi_ret-message_v3
    } { is_bapi_ret-message_v4 }|.
  ENDIF.

ENDFORM.
