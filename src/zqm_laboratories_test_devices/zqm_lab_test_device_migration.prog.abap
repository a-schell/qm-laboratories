*&---------------------------------------------------------------------*
*& Report ZQM_LAB_TEST_DEVICE_MIGRATION
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zqm_lab_test_device_migration.

*CONSTANTS: cv_data_regex TYPE string VALUE '.*(2023|2024|2025).+'.
*
*DATA: lv_status TYPE zqm_dataset_status.
*
*SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME TITLE TEXT-st1.
*PARAMETERS: p_migdat TYPE flag DEFAULT abap_false.
*PARAMETERS: p_migarc TYPE flag DEFAULT abap_false.
*SELECT-OPTIONS: so_stat FOR lv_status.
*SELECTION-SCREEN: END OF BLOCK a.
*
*SELECTION-SCREEN: BEGIN OF BLOCK b WITH FRAME TITLE TEXT-st2.
*PARAMETERS: p_deldto TYPE flag DEFAULT abap_false.
*SELECTION-SCREEN: END OF BLOCK b.
*
*SELECTION-SCREEN: BEGIN OF BLOCK c WITH FRAME TITLE TEXT-st3.
*PARAMETERS: p_movdat TYPE flag DEFAULT abap_false.
*SELECTION-SCREEN: END OF BLOCK c.
*
*SELECTION-SCREEN: BEGIN OF BLOCK d WITH FRAME TITLE TEXT-st4.
*PARAMETERS: p_deltmp TYPE flag DEFAULT abap_false.
*SELECTION-SCREEN: END OF BLOCK d.
*
*SELECTION-SCREEN SKIP 1.
*PARAMETERS: p_delete TYPE flag DEFAULT abap_false.
*SELECTION-SCREEN SKIP 1.
*PARAMETERS: p_tregex TYPE flag DEFAULT abap_false.
*
*
*START-OF-SELECTION.
*
*  IF p_migdat = abap_true.
*    PERFORM migrate_data_table USING 'zqm_dev_transfer' 'zqm_dev_transf_2'.
*  ENDIF.
*
*  IF p_migarc = abap_true.
*    PERFORM migrate_data_table USING 'zqm_dev_tran_arc' 'zqm_dev_tran_a_2'.
*  ENDIF.
*
*  IF p_deldto = abap_true.
*    PERFORM delete_original_data_table.
*  ENDIF.
*
*  IF p_movdat = abap_true.
*    PERFORM move_migrated_to_original_data.
*  ENDIF.
*
*  IF p_delete = abap_true.
*    PERFORM delete_migrated_table.
*  ENDIF.
*
*  IF p_tregex = abap_true.
*    PERFORM test_regular_expression.
*  ENDIF.
*
*
*FORM migrate_data_table USING iv_table_orig TYPE tabname
*                              iv_table_dest TYPE tabname.
*
*  " transfer and archive table have the same structure
*  DATA: lt_data_orig TYPE STANDARD TABLE OF zqm_dev_transfer WITH DEFAULT KEY.
*  DATA: lt_data_dest TYPE STANDARD TABLE OF zqm_dev_transf_2 WITH DEFAULT KEY.
*
*  SELECT * FROM (iv_table_orig)
*   WHERE status IN @so_stat
*   INTO CORRESPONDING FIELDS OF TABLE @lt_data_orig.
*
*  IF sy-subrc = 0.
*    LOOP AT lt_data_orig ASSIGNING FIELD-SYMBOL(<fs_data_orig>).
*      IF matches( val = <fs_data_orig>-filename case = abap_false regex = cv_data_regex ).
*        APPEND VALUE #( BASE CORRESPONDING #( <fs_data_orig> )
*          werks = COND #(
*              WHEN find( val = <fs_data_orig>-filename regex = 'TIP-.+' ) = -1
*              THEN '1101'
*              ELSE '1106' )
*        ) TO lt_data_dest.
*      ENDIF.
*    ENDLOOP.
*
*    IF lines( lt_data_dest ) > 0.
*      INSERT (iv_table_dest) FROM TABLE lt_data_dest.
*    ENDIF.
*  ENDIF.
*
*ENDFORM.
*
*
*FORM delete_original_data_table.
*
*  DELETE FROM zqm_dev_transfer.
*  DELETE FROM zqm_dev_tran_arc.
*
*ENDFORM.
*
*
*FORM move_migrated_to_original_data.
*
*  INSERT zqm_dev_transfer FROM ( SELECT * FROM zqm_dev_transf_2 ).
*  INSERT zqm_dev_tran_arc FROM ( SELECT * FROM zqm_dev_tran_a_2 ).
*
*ENDFORM.
*
*
*FORM delete_migrated_table.
*
*  DELETE FROM zqm_dev_transf_2.
*  WRITE: / |Deleted {  sy-dbcnt } entries from zqm_dev_transf_2|.
*
*  DELETE FROM zqm_dev_tran_a_2.
*  WRITE: / |Deleted {  sy-dbcnt } entries from zqm_dev_tran_a_2|.
*
*ENDFORM.
*
*
*FORM test_regular_expression.
*
*  PERFORM process_regular_expression USING 'TIP-20231007_140031_con_N-Q154F001+Q154F117-10071624.pvs'.
*  PERFORM process_regular_expression USING 'Kond_202202080915.dat'.
*  PERFORM process_regular_expression USING 'TIP-20231202_060030_con_N-Q154F001+Q154F117-12021033.pvs'.
*  PERFORM process_regular_expression USING '20210925_060071_N_09250815.pro'.
*  PERFORM process_regular_expression USING 'Kond_202112140651.dat'.
*  PERFORM process_regular_expression USING 'Kond_202112140628.dat'.
*
*ENDFORM.
*
*FORM process_regular_expression USING iv_text TYPE string.
*
*  DATA: matcher TYPE REF TO cl_abap_matcher,
*        match   TYPE c LENGTH 1.
*
*  matcher = cl_abap_matcher=>create(
*    pattern     = cv_data_regex
*    ignore_case = abap_true
*    text        = iv_text
*  ).
*
*  match = matcher->match( ).
*
*  WRITE: / |Text { iv_text } matched against { cv_data_regex }: { match }|.
*
*ENDFORM.
