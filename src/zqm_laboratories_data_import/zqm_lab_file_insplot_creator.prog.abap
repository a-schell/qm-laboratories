REPORT zqm_lab_file_insplot_creator.

DATA lt_files TYPE zqm_lab_t_file_list.
DATA lv_filename TYPE zqm_filename.
DATA wa_application_settings TYPE zqm_lab_s_import_settings.

FIELD-SYMBOLS: <wa_files> TYPE zqm_lab_s_file_list,
               <wa_messages> TYPE bapiret2.

SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME.
SELECT-OPTIONS: s_files FOR lv_filename.
SELECTION-SCREEN: END OF BLOCK a.
SELECTION-SCREEN SKIP 1.
PARAMETERS pa_exec AS CHECKBOX DEFAULT ''.

START-OF-SELECTION.
  IF pa_exec = ''.
    WRITE: / 'PA_EXEC = <BLANK>  Therefore do not Execute Program run' COLOR COL_GROUP.
    RETURN.  "<------------------- exit point
  ENDIF.
  PERFORM load_application_settings.
  PERFORM load_files.
  PERFORM create_inspection_lots.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  load_plant_settings
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_application_settings.
  DATA obj_settings TYPE REF TO zcl_qm_lab_import_settings.
  DATA obj_exception TYPE REF TO zcx_qm_lab_import_exceptions.
  DATA lv_message TYPE string.

  TRY.
      CREATE OBJECT obj_settings.
      wa_application_settings = obj_settings->get_application_settings( iv_application = zcl_qm_lab_import_settings=>ac_appl_create_insplot_file ).
    CATCH zcx_qm_lab_import_exceptions INTO obj_exception.
      lv_message = obj_exception->get_text( ).
      MESSAGE lv_message TYPE 'E'.

      CLEAR lv_message.
      FREE obj_exception.
  ENDTRY.

  FREE obj_settings.
ENDFORM.                    "load_plant_settings

*&---------------------------------------------------------------------*
*&      Form  create_inspection_lots
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_inspection_lots.
  DATA obj_insplot_maintain TYPE REF TO zcl_qm_lab_insplot_maintain.
  DATA obj_exceptions TYPE REF TO zcx_qm_lab_import_exceptions.
  DATA: lt_filedata TYPE zqm_lab_t_field_value,
        wa_filedata TYPE zqm_lab_s_field_value.
  DATA lt_dataset TYPE string_table.
  DATA lv_filename TYPE epsfilnam.
  DATA lv_filepath TYPE string.
  DATA lv_dataset TYPE string.
  DATA lt_messages TYPE bapiret2_t.
  DATA lv_plant TYPE werks_d.
  DATA lv_insplot_number TYPE qplos.

  FIELD-SYMBOLS: <wa_dataset> TYPE string,
                 <lv_field_to> TYPE any,
                 <lv_class_attribute> TYPE any.

* Create inspection lot handler
  CREATE OBJECT obj_insplot_maintain
    EXPORTING
      iv_application = zcl_qm_lab_import_settings=>ac_appl_create_insplot_file.

* Extract inspection lot data from external file
  LOOP AT lt_files ASSIGNING <wa_files>.
    CLEAR: lv_filepath, lv_dataset, lt_messages, lv_insplot_number.
    FREE: lt_filedata, lt_dataset.

    lv_filename = <wa_files>-name.

    IF <wa_files>-size > 0.
      lv_filepath = |{ wa_application_settings-folder_path }{ <wa_files>-name }|.

      OPEN DATASET lv_filepath FOR INPUT IN TEXT MODE ENCODING NON-UNICODE WITH SMART LINEFEED.

      IF sy-subrc IS INITIAL.
        DO.
          CLEAR wa_filedata.

          TRY.
              READ DATASET lv_filepath INTO lv_dataset.

              IF lv_dataset CP '.*'.
                CONTINUE.
              ENDIF.
            CATCH cx_sy_conversion_codepage.
              CONTINUE.
          ENDTRY.

          IF sy-subrc IS NOT INITIAL.
            EXIT.
          ENDIF.

          SPLIT lv_dataset AT ':' INTO TABLE lt_dataset.

          LOOP AT lt_dataset ASSIGNING <wa_dataset>.
            ASSIGN COMPONENT sy-tabix OF STRUCTURE wa_filedata TO <lv_field_to>.
            IF sy-subrc IS NOT INITIAL.
              EXIT.
            ENDIF.

            <lv_field_to> = <wa_dataset>.
          ENDLOOP.

          FREE lt_dataset.

          INSERT wa_filedata INTO TABLE lt_filedata.
        ENDDO.

* Get plant
        CLEAR lv_plant.

        PERFORM get_plant_for_line USING lt_filedata
                                   CHANGING lv_plant.

* Create inspection lot
        TRY.
            obj_insplot_maintain->create_from_field_value( EXPORTING iv_plant         = lv_plant
                                                                     it_fields_values = lt_filedata
                                                           IMPORTING ev_insplot_number = lv_insplot_number
                                                                     et_messages       = lt_messages ).

            PERFORM write_output USING lv_filename
                                       lt_messages.
          CATCH zcx_qm_lab_import_exceptions INTO obj_exceptions.
            APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
            <wa_messages>-id = obj_exceptions->if_t100_message~t100key-msgid.
            <wa_messages>-number = obj_exceptions->if_t100_message~t100key-msgno.
            <wa_messages>-type = 'E'.
            <wa_messages>-message = obj_exceptions->get_text( ).

            IF obj_exceptions->if_t100_message~t100key-attr1 IS NOT INITIAL.
              ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr1) TO <lv_class_attribute>.
              IF sy-subrc IS INITIAL.
                <wa_messages>-message_v1 = <lv_class_attribute>.
              ENDIF.
            ENDIF.

            IF obj_exceptions->if_t100_message~t100key-attr2 IS NOT INITIAL.
              ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr2) TO <lv_class_attribute>.
              IF sy-subrc IS INITIAL.
                <wa_messages>-message_v2 = <lv_class_attribute>.
              ENDIF.
            ENDIF.

            IF obj_exceptions->if_t100_message~t100key-attr3 IS NOT INITIAL.
              ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr3) TO <lv_class_attribute>.
              IF sy-subrc IS INITIAL.
                <wa_messages>-message_v3 = <lv_class_attribute>.
              ENDIF.
            ENDIF.

            IF obj_exceptions->if_t100_message~t100key-attr4 IS NOT INITIAL.
              ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr4) TO <lv_class_attribute>.
              IF sy-subrc IS INITIAL.
                <wa_messages>-message_v4 = <lv_class_attribute>.
              ENDIF.
            ENDIF.

            PERFORM write_output USING lv_filename
                                       lt_messages.
        ENDTRY.
      ENDIF.
    ENDIF.

* Delete all non error messages
    DELETE lt_messages
    WHERE type = 'S'
       OR type = 'W'.

    IF lt_messages[] IS INITIAL.
      PERFORM archive_file USING lv_filename
                                 abap_false.

      CONTINUE.
    ELSE.
      PERFORM archive_file USING lv_filename
                                 abap_true.

      CONTINUE.
    ENDIF.

    PERFORM delete_file USING lv_filename.
  ENDLOOP.

  FREE obj_insplot_maintain.
ENDFORM.                    "create_inspection_lots

*&---------------------------------------------------------------------*
*&      Form  load_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_files.
  TRY.
      lt_files = zcl_qm_lab_file_handler=>get_files_from_appl_sever( iv_dir_name = wa_application_settings-folder_path ).

      IF s_files[] IS NOT INITIAL.
        LOOP AT lt_files ASSIGNING <wa_files>.
          IF <wa_files>-name NOT IN s_files.
            DELETE TABLE lt_files
            FROM <wa_files>.
          ENDIF.
        ENDLOOP.
      ENDIF.
    CATCH zcx_qm_lab_import_exceptions.
      MESSAGE text-e01 TYPE 'E'.
  ENDTRY.
ENDFORM.                    "load_files

*&---------------------------------------------------------------------*
*&      Form  archive_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM archive_file USING iv_filename TYPE epsfilnam
                        iv_error TYPE abap_bool.
  DATA lv_target_directory TYPE epsdirnam.

  IF iv_error = abap_false.
    lv_target_directory = wa_application_settings-archive_path.
  ELSE.
    lv_target_directory = wa_application_settings-error_archive_path.
  ENDIF.

  IF lv_target_directory IS NOT INITIAL.
    CALL METHOD cl_cts_language_file_io=>copy_files_local
      EXPORTING
        im_source_file           = iv_filename
        im_source_directory      = wa_application_settings-folder_path
        im_target_file           = iv_filename
        im_target_directory      = lv_target_directory
      EXCEPTIONS
        open_input_file_failed   = 1
        open_output_file_failed  = 2
        write_block_failed       = 3
        read_block_failed        = 4
        close_output_file_failed = 5
        OTHERS                   = 6.
  ENDIF.

  PERFORM delete_file USING iv_filename.
ENDFORM.                    "archive_files

*&---------------------------------------------------------------------*
*&      Form  delete_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM delete_file USING iv_filename TYPE epsfilnam.
  DATA lv_filepath TYPE string.

  lv_filepath = |{ wa_application_settings-folder_path }{ iv_filename }|.
  DELETE DATASET lv_filepath.
  CLEAR lv_filepath.
ENDFORM.                    "delete_files

*&---------------------------------------------------------------------*
*&      Form  get_plant_for_line
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IT_FILE_DATA  text
*      -->CV_PLANT      text
*----------------------------------------------------------------------*
FORM get_plant_for_line USING it_filedata TYPE zqm_lab_t_field_value
                        CHANGING cv_plant TYPE werks_d.

  FIELD-SYMBOLS <wa_filedata> TYPE zqm_lab_s_field_value.

* Find line number
  READ TABLE it_filedata
  ASSIGNING <wa_filedata>
  WITH KEY fieldname = 'LINE_NO'.

  IF sy-subrc IS INITIAL.
    SELECT SINGLE werks
    INTO cv_plant
    FROM zbms_cu_linie
    WHERE linienr = <wa_filedata>-value.
  ENDIF.
ENDFORM.                    "get_plant_for_line

*&---------------------------------------------------------------------*
*&      Form  write_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IV_FILENAME  text
*      -->IT_MESSAGES  text
*----------------------------------------------------------------------*
FORM write_output USING iv_filename TYPE epsfilnam
                        it_messages TYPE bapiret2_t.

  DATA lv_message TYPE string.

  WRITE iv_filename.

  IF it_messages[] IS NOT INITIAL.
    LOOP AT it_messages ASSIGNING <wa_messages>.
      CLEAR lv_message.

      MESSAGE ID <wa_messages>-id TYPE <wa_messages>-type NUMBER <wa_messages>-number INTO lv_message
      WITH <wa_messages>-message_v1 <wa_messages>-message_v2 <wa_messages>-message_v3 <wa_messages>-message_v4.

      WRITE / lv_message.
    ENDLOOP.
  ENDIF.

  WRITE / '**************************************************'.
ENDFORM.                    "write_output
