*&---------------------------------------------------------------------*
*& Report  ZQM_LAB_BMS_INTERFACE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zqm_lab_bms_interface.

TABLES: qasr, qals.

TYPES: BEGIN OF ts_qasr,
         prueflos                 TYPE qplos,
         vorglfnr                 TYPE qlfnkn,
         merknr                   TYPE qmerknrp,
         probenr                  TYPE qstipronr,
         vornr                    TYPE vornr,
         slwbez                   TYPE qslwbez,
         werk                     TYPE werks_d,
         zzbms_zublasende_linienr TYPE zbms_zublasende_linienr,   "neu seit Juni 2021
         erstelldat               TYPE qdatumerst,
         zeiterstl                TYPE qzeiterstl,
         aenderdat                TYPE qdatumaend,
         zeitaend                 TYPE qzeitaend,
         katalgart1               TYPE qkatausw,
         code1                    TYPE qcode,
         version1                 TYPE qversnr,
         katalgart2               TYPE qkatausw,
         code2                    TYPE qcode,
         version2                 TYPE qversnr,
         katalgart3               TYPE qkatausw,
         code3                    TYPE qcode,
         version3                 TYPE qversnr,
         katalgart4               TYPE qkatausw,
         code4                    TYPE qcode,
         version4                 TYPE qversnr,
         katalgart5               TYPE qkatausw,
         code5                    TYPE qcode,
         version5                 TYPE qversnr,
         original_input           TYPE qoriginal_input,
         nok_status               TYPE zqm_stichprobenstatusnok,
         ok_datum                 TYPE sydatum,
         ok_zeit                  TYPE syuzeit,
       END OF ts_qasr.

TYPES: BEGIN OF ts_parname_count,
         werks    TYPE zbms_werks_d,
         prueflos TYPE qplos,
         ballennr TYPE zbms_ballennr,
         pargrp   TYPE zbms_interface_paramgrp,
         parname  TYPE zbms_ddic_feldname,
         count    TYPE i,
       END OF ts_parname_count.

TYPES: tt_qasr     TYPE SORTED TABLE OF ts_qasr WITH UNIQUE KEY prueflos vorglfnr merknr probenr,
       tt_transfer TYPE STANDARD TABLE OF zbms_if_ilabcrqm.

DATA: lt_qasr      TYPE tt_qasr,
      lt_qasr_bale TYPE tt_qasr.
DATA: ra_date TYPE RANGE OF sy-datum,
      ra_time TYPE RANGE OF sy-uzeit.
DATA: lv_running_date TYPE dats,
      lv_running_time TYPE time.
DATA: lv_last_date TYPE dats,
      lv_last_time TYPE time.
DATA lt_transfer_output TYPE tt_transfer.
DATA lt_parameter_mapping_buffer TYPE SORTED TABLE OF zbms_if_mappqm WITH UNIQUE KEY mandt werks mkmnr.
DATA lt_condense_values TYPE SORTED TABLE OF zqm_s_lab_bms_condense_values WITH UNIQUE DEFAULT KEY.
DATA lt_char_requirements TYPE STANDARD TABLE OF bapi2045d1.

CONSTANTS: co_datatype_numeric    TYPE zbms_interface_datentyp VALUE 'N',
           co_datatype_char       TYPE zbms_interface_datentyp VALUE 'Z',
           co_db_operation_insert TYPE string VALUE 'INSERT',
           co_db_operation_update TYPE string VALUE 'UPDATE',
           co_db_operation_delete TYPE string VALUE 'DELETE'.

FIELD-SYMBOLS: <wa_date> LIKE LINE OF ra_date,
               <wa_time> LIKE LINE OF ra_time,
               <wa_qasr> TYPE ts_qasr.

SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME.
PARAMETERS: p_test AS CHECKBOX.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: p_werks TYPE qals-werk OBLIGATORY.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: p_opt1 RADIOBUTTON GROUP a DEFAULT 'X'.
PARAMETERS: p_opt2 RADIOBUTTON GROUP a.
SELECT-OPTIONS: s_pruef FOR qasr-prueflos.
SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: s_date FOR sy-datum.
SELECT-OPTIONS: s_time FOR sy-uzeit.
SELECTION-SCREEN: END OF BLOCK a.

AT SELECTION-SCREEN.
  IF p_opt2 = abap_true.
    IF s_date[] IS INITIAL.
      MESSAGE TEXT-m01 TYPE 'E'.
    ENDIF.
  ENDIF.

START-OF-SELECTION.
  " Semaphor
  IF sy-batch = abap_true.
    DATA(lv_semaphore_set) = zcl_bms_semaphore=>get_instance(
                               iv_process = zif_bms_semaphore=>process-labor
                               iv_werks   = p_werks
                               iv_uname   = sy-uname
                               iv_ttl     = 1800
                             )->aquire( ).

    IF lv_semaphore_set <> abap_true.
      MESSAGE 'Semaphor is busy' TYPE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

  " for testing
  WAIT UP TO 30 SECONDS.

  IF p_opt1 = abap_true.
    PERFORM set_selection_date.
  ENDIF.

  PERFORM do_transfer.

  IF p_test = abap_false AND p_opt1 = abap_true.
    PERFORM track_run.
  ENDIF.

  PERFORM show_log USING lt_transfer_output.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  set_selection_date
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_selection_date.
  DATA obj_program_tracker TYPE REF TO zif_qm_lab_bms_program_runs.

  CLEAR: lv_last_date, lv_last_time.
  FREE: ra_date, ra_time.

  obj_program_tracker = zcl_qm_lab_bms_factory=>get_program_run_tracker( ).

  TRY.
      obj_program_tracker->get_last_run( EXPORTING iv_werks     = p_werks
                                                   iv_report    = sy-repid
                                         IMPORTING ev_last_date = lv_last_date
                                                   ev_last_time = lv_last_time ).

      IF lv_last_date <> sy-datum.
        APPEND INITIAL LINE TO ra_date ASSIGNING <wa_date>.
        <wa_date>-sign = 'I'.
        <wa_date>-option = 'BT'.
        <wa_date>-low = lv_last_date.
        <wa_date>-high = sy-datum.
        UNASSIGN <wa_date>.
      ELSE.
        APPEND INITIAL LINE TO ra_date ASSIGNING <wa_date>.
        <wa_date>-sign = 'I'.
        <wa_date>-option = 'EQ'.
        <wa_date>-low = sy-datum.
        UNASSIGN <wa_date>.
      ENDIF.
    CATCH zcx_qm_lab_bms_exceptions.
* Report is running first time so current date/time is taken
      APPEND INITIAL LINE TO ra_date ASSIGNING <wa_date>.
      <wa_date>-sign = 'I'.
      <wa_date>-option = 'EQ'.
      <wa_date>-low = sy-datum.
      UNASSIGN <wa_date>.

      APPEND INITIAL LINE TO ra_time ASSIGNING <wa_time>.
      <wa_time>-sign = 'I'.
      <wa_time>-option = 'GE'.
      <wa_time>-low = sy-uzeit.
      UNASSIGN <wa_time>.
  ENDTRY.

  lv_running_date = sy-datum.
  lv_running_time = sy-uzeit.

  FREE obj_program_tracker.
ENDFORM.                    "set_selection_date

*&---------------------------------------------------------------------*
*&      Form  do_transfer
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM do_transfer.
  DATA: lt_transfer TYPE STANDARD TABLE OF zbms_if_ilabcrqm,
        wa_transfer TYPE zbms_if_ilabcrqm.

  PERFORM get_data.

* Transfer non Z02 inspection lots
  PERFORM transfer_data USING lt_qasr
                        CHANGING lt_transfer.

  IF p_test = abap_false AND lt_transfer[] IS NOT INITIAL.
    PERFORM save_data USING lt_transfer.
  ENDIF.

  APPEND LINES OF lt_transfer[] TO lt_transfer_output[].
  FREE lt_transfer.

* Transfer Z02 inspection lots
  PERFORM transfer_data USING lt_qasr_bale
                        CHANGING lt_transfer.

  IF lt_transfer[] IS NOT INITIAL.
    PERFORM condense_data USING lt_qasr_bale
                          CHANGING lt_transfer.

    IF p_test = abap_false.
      PERFORM save_data USING lt_transfer.
    ENDIF.
  ENDIF.

  APPEND LINES OF lt_transfer[] TO lt_transfer_output[].
  FREE lt_transfer.
ENDFORM.                    "do_transfer

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_data.
  DATA lt_qasr_tmp TYPE STANDARD TABLE OF ts_qasr.

  FREE lt_qasr.

  IF p_opt2 = abap_true.
    APPEND LINES OF s_date[] TO ra_date.
    APPEND LINES OF s_time[] TO ra_time.
  ENDIF.

  SELECT a~prueflos
         a~vorglfnr
         a~merknr
         a~probenr
         c~vornr
         b~slwbez
         b~werk
         b~zzbms_zublasende_linienr   "neu seit Juni 2021
         a~erstelldat
         a~zeiterstl
         a~aenderdat
         a~zeitaend
         a~katalgart1
         a~code1
         a~version1
         a~katalgart2
         a~code2
         a~version2
         a~katalgart3
         a~code3
         a~version3
         a~katalgart4
         a~code4
         a~version4
         a~katalgart5
         a~code5
         a~version5
         a~original_input
         a~nok_status
         a~ok_datum
         a~ok_zeit
    INTO TABLE lt_qasr
    FROM qasr AS a
    INNER JOIN qals AS b
    ON b~prueflos = a~prueflos
    INNER JOIN afvc AS c
    ON c~aufpl = b~aufpl AND
       c~aplzl = a~vorglfnr
    WHERE ( ( a~erstelldat IN ra_date AND
              a~zeiterstl IN ra_time ) OR
            ( a~aenderdat IN ra_date AND
              a~zeitaend IN ra_time ) OR
            ( a~ok_datum IN ra_date AND
              a~ok_zeit IN ra_time ) )
       AND a~prueflos IN s_pruef
       AND b~werk = p_werks.

  IF p_opt1 = abap_true.
    LOOP AT lt_qasr ASSIGNING <wa_qasr>.
      IF <wa_qasr>-ok_datum IS NOT INITIAL.
* Check if check value was changed with BMS report since last run. If yes, the entry can stay in the table
        IF ( <wa_qasr>-ok_datum = lv_last_date AND <wa_qasr>-ok_zeit > lv_last_time ) OR <wa_qasr>-ok_datum > lv_last_date.
          CONTINUE.
        ENDIF.
      ENDIF.

      IF <wa_qasr>-aenderdat IS NOT INITIAL.
        IF ( <wa_qasr>-aenderdat = lv_last_date AND <wa_qasr>-zeitaend > lv_last_time ) OR <wa_qasr>-aenderdat > lv_last_date.
          CONTINUE.
        ELSE.
* If change date exist no need to check creation date
          DELETE TABLE lt_qasr FROM <wa_qasr>.
          CONTINUE.
        ENDIF.
      ENDIF.

      IF <wa_qasr>-erstelldat <= lv_last_date AND <wa_qasr>-zeiterstl < lv_last_time.
        DELETE TABLE lt_qasr FROM <wa_qasr>.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDIF.

  LOOP AT lt_qasr ASSIGNING <wa_qasr> WHERE werk = '1106'
                                        AND slwbez = 'Z02'.
    SELECT a~prueflos
           a~vorglfnr
           a~merknr
           a~probenr
           c~vornr
           b~slwbez
           b~werk
           b~zzbms_zublasende_linienr   "neu seit Juni 2021: Info: bei 1106 eh' immer leer !
           a~erstelldat
           a~zeiterstl
           a~aenderdat
           a~zeitaend
           a~katalgart1
           a~code1
           a~version1
           a~katalgart2
           a~code2
           a~version2
           a~katalgart3
           a~code3
           a~version3
           a~katalgart4
           a~code4
           a~version4
           a~katalgart5
           a~code5
           a~version5
           a~original_input
           a~nok_status
           a~ok_datum
           a~ok_zeit
      INTO TABLE lt_qasr_tmp
      FROM qasr AS a
      INNER JOIN qals AS b
      ON b~prueflos = a~prueflos
      INNER JOIN afvc AS c
      ON c~aufpl = b~aufpl AND
         c~aplzl = a~vorglfnr
      WHERE a~prueflos = <wa_qasr>-prueflos.

    INSERT LINES OF lt_qasr_tmp INTO TABLE lt_qasr_bale.

    DELETE lt_qasr
    WHERE prueflos = <wa_qasr>-prueflos.

    FREE lt_qasr_tmp.
  ENDLOOP.
ENDFORM.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  transfer_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM transfer_data USING it_data TYPE tt_qasr
                   CHANGING ct_transfer TYPE tt_transfer.

  DATA: lv_prueflos TYPE qplos,
        lv_vorglfnr TYPE qlfnkn.
  DATA: wa_operation              TYPE bapi2045l2,
        wa_insppoint_requirements TYPE bapi2045d5.
  DATA: lt_char_requirements_tmp TYPE STANDARD TABLE OF bapi2045d1,
        lt_insppoints            TYPE STANDARD TABLE OF bapi2045l4.
  DATA wa_parameter_mapping TYPE zbms_if_mappqm.
  DATA lv_value TYPE string.
  DATA: lv_datetime_dataset TYPE integer64,
        lv_datetime_last    TYPE integer64.
  DATA wa_message TYPE bapiret2.
  DATA lv_htype TYPE dd01v-datatype.
  DATA lv_balenum TYPE p.
  DATA lv_check_error TYPE abap_bool.

  FIELD-SYMBOLS: <wa_transfer>          TYPE zbms_if_ilabcrqm,
                 <wa_char_requirements> TYPE bapi2045d1,
                 <wa_insppoints>        TYPE bapi2045l4,
                 <wa_data>              TYPE ts_qasr.

  CONSTANTS co_numeric TYPE string VALUE '0123456789.'.

  IF lv_last_date IS NOT INITIAL.
    lv_datetime_last = |{ lv_last_date }{ lv_last_time }|.
  ENDIF.

  LOOP AT it_data ASSIGNING <wa_data>.
    IF lv_prueflos <> <wa_data>-prueflos OR lv_vorglfnr <> <wa_data>-vorglfnr.
      lv_prueflos = <wa_data>-prueflos.
      lv_vorglfnr = <wa_data>-vorglfnr.

      READ TABLE lt_char_requirements
      WITH KEY insplot = <wa_data>-prueflos
               inspoper = <wa_data>-vornr
      TRANSPORTING NO FIELDS.

      IF sy-subrc IS NOT INITIAL.
        CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
          EXPORTING
            insplot                = <wa_data>-prueflos
            inspoper               = <wa_data>-vornr
            read_char_requirements = abap_true
            read_insppoints        = abap_true
            max_insppoints         = 5000
          IMPORTING
            operation              = wa_operation
            insppoint_requirements = wa_insppoint_requirements
          TABLES
            char_requirements      = lt_char_requirements_tmp
            insppoints             = lt_insppoints.

        APPEND LINES OF lt_char_requirements_tmp[] TO lt_char_requirements[].
        FREE lt_char_requirements_tmp.
      ENDIF.
    ENDIF.

* Add general parameters
    APPEND INITIAL LINE TO ct_transfer ASSIGNING <wa_transfer>.
    <wa_transfer>-werks = wa_operation-plant.
    <wa_transfer>-credat = <wa_data>-erstelldat.
    <wa_transfer>-crezet = <wa_data>-zeiterstl.
    <wa_transfer>-prueflos = <wa_data>-prueflos.
    <wa_transfer>-vorglfnr = <wa_data>-vorglfnr.
    <wa_transfer>-merknr = <wa_data>-merknr.
    <wa_transfer>-probenr = <wa_data>-probenr.

    lv_datetime_dataset = |{ <wa_data>-erstelldat }{ <wa_data>-zeiterstl } |.

    IF <wa_data>-nok_status = abap_true.
      <wa_transfer>-db_operation = co_db_operation_delete.
    ELSEIF lv_datetime_dataset > lv_datetime_last.
      <wa_transfer>-db_operation = co_db_operation_insert.
    ELSE.
      IF <wa_data>-aenderdat IS INITIAL.
        <wa_transfer>-db_operation = co_db_operation_insert.
      ELSE.
        <wa_transfer>-db_operation = co_db_operation_update.
      ENDIF.
    ENDIF.

* Add inspection lot data
    READ TABLE lt_insppoints
    ASSIGNING <wa_insppoints>
    WITH KEY insppoint = <wa_data>-probenr.

    IF sy-subrc IS NOT INITIAL.
      DELETE TABLE ct_transfer
      FROM <wa_transfer>.

      CONTINUE.
    ENDIF.

*   >>>> Begin Ticket SR-621435 BMS: New Sampling type BM  Benchmarking
    IF <wa_insppoints>-userc2 = 'BM'.
*     QM Data assigned to BMS Sampling type 'BM' shall remain only in QM, and not be transfered to BMS
      DELETE TABLE ct_transfer FROM <wa_transfer>.
      CONTINUE.
    ENDIF.
*   <<<< ENDE Ticket SR-621435

    <wa_transfer>-probenart = <wa_insppoints>-userc2.
    <wa_transfer>-linienr = <wa_insppoints>-usern2.
    IF <wa_transfer>-werks = zcl_bms_const=>c_werks_1101.  "neu seit Juni 2021
      <wa_transfer>-zublaslinienr = <wa_data>-zzbms_zublasende_linienr.
*     wenn (Zublasende)linie Kennzeichen = '08': Prod.Linie mit '05' überschreiben
      IF <wa_transfer>-zublaslinienr = '08'.
        <wa_transfer>-linienr = '05'.    "'08' -> '05'
      ENDIF.
    ENDIF.

* Bale number handling L340002008 => 000200 (Change LAGAHW)
    IF <wa_data>-slwbez = 'Z02' AND strlen( <wa_insppoints>-userc1 ) >= 18.
      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = <wa_insppoints>-userc1+12(6)
        IMPORTING
          htype     = lv_htype.

      IF lv_htype = 'NUMC'.
        CALL FUNCTION 'MOVE_CHAR_TO_NUM'
          EXPORTING
            chr             = <wa_insppoints>-userc1+12(6)
          IMPORTING
            num             = lv_balenum
          EXCEPTIONS
            convt_no_number = 1
            convt_overflow  = 2
            OTHERS          = 3.

        IF sy-subrc IS INITIAL.
          <wa_transfer>-ballennr = lv_balenum.
        ENDIF.
      ENDIF.
    ENDIF.

    <wa_transfer>-entnadat = <wa_insppoints>-userd1.
    <wa_transfer>-entnazet = <wa_insppoints>-usert1.

* Add char data
    READ TABLE lt_char_requirements
    ASSIGNING <wa_char_requirements>
    WITH KEY insplot = <wa_data>-prueflos
             inspoper = <wa_data>-vornr
             inspchar = <wa_data>-merknr.

    IF <wa_char_requirements>-char_type = '01'.
      <wa_transfer>-parwert = <wa_data>-original_input.
      <wa_transfer>-datentyp = co_datatype_numeric.
    ELSE.
      <wa_transfer>-parwert = <wa_data>-code1.
      <wa_transfer>-datentyp = co_datatype_char.
    ENDIF.

* Add parameter data
    PERFORM get_parameter_mapping USING <wa_char_requirements>-mstr_char
                                        wa_operation-plant
                                        <wa_char_requirements>-vmstr_char
                                 CHANGING wa_parameter_mapping.

    IF wa_parameter_mapping IS INITIAL.
      wa_message-type = 'E'.
      wa_message-message = TEXT-m02.

      PERFORM write_application_log USING <wa_transfer>
                                          wa_message.

      DELETE TABLE ct_transfer
      FROM <wa_transfer>.

      UNASSIGN: <wa_transfer>, <wa_insppoints>, <wa_char_requirements>.
      CLEAR wa_message.

      CONTINUE.
    ENDIF.

    <wa_transfer>-parname = wa_parameter_mapping-parname.
    <wa_transfer>-pargrp = wa_parameter_mapping-pargrp.

    PERFORM check_data USING <wa_transfer>
                             <wa_data>-slwbez
                       CHANGING lv_check_error.

    IF lv_check_error = abap_true.
      DELETE TABLE ct_transfer
      FROM <wa_transfer>.

      CONTINUE.
    ENDIF.

    CLEAR wa_parameter_mapping.
    UNASSIGN: <wa_transfer>, <wa_insppoints>, <wa_char_requirements>.
  ENDLOOP.

  FREE: lt_insppoints.
  CLEAR: lv_prueflos, lv_vorglfnr, wa_operation, wa_insppoint_requirements,
         lv_datetime_last, lv_datetime_dataset.
ENDFORM.                    "transfer_data

*&---------------------------------------------------------------------*
*&      Form  check_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_data USING is_transfer TYPE zbms_if_ilabcrqm
                      iv_slwbez TYPE qslwbez
                CHANGING cv_error TYPE abap_bool.

  DATA wa_message TYPE bapiret2.

  cv_error = abap_false.

  IF is_transfer-werks = '1106'.
    IF ( is_transfer-ballennr IS INITIAL AND iv_slwbez = 'Z02' ) OR is_transfer-probenart IS INITIAL OR is_transfer-entnadat IS INITIAL.
      wa_message-type = 'E'.
      wa_message-message = TEXT-m03.

      PERFORM write_application_log USING is_transfer
                                          wa_message.

      cv_error = abap_true.
    ENDIF.
  ENDIF.

ENDFORM.                    "check_data

*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM save_data USING it_transfer TYPE tt_transfer.
  DATA: lt_transfer_ready TYPE SORTED TABLE OF zbms_if_ilabcrqm WITH UNIQUE DEFAULT KEY,
        wa_transfer_ready TYPE zbms_if_ilabcrqm.
  DATA lt_transfer_temp TYPE SORTED TABLE OF zbms_if_ilabcrqm WITH UNIQUE DEFAULT KEY.
  DATA lv_counter TYPE i.

  FIELD-SYMBOLS: <wa_transfer>       TYPE zbms_if_ilabcrqm,
                 <wa_transfer_ready> TYPE zbms_if_ilabcrqm,
                 <wa_transfer_temp>  TYPE zbms_if_ilabcrqm.

  LOOP AT it_transfer ASSIGNING <wa_transfer>.
    CLEAR: lv_counter, wa_transfer_ready.
    FREE lt_transfer_temp.

    wa_transfer_ready = <wa_transfer>.

* Check if entry for date/time already exist in transfer ready table
    READ TABLE lt_transfer_ready
    TRANSPORTING NO FIELDS
    WITH KEY werks = <wa_transfer>-werks
             credat = <wa_transfer>-credat
             crezet = <wa_transfer>-crezet.

    IF sy-subrc IS INITIAL.
* Get highest counter
      LOOP AT lt_transfer_ready ASSIGNING <wa_transfer_ready> WHERE werks  = <wa_transfer>-werks
                                                                AND credat = <wa_transfer>-credat
                                                                AND crezet = <wa_transfer>-crezet.

        lv_counter = <wa_transfer_ready>-countr.
      ENDLOOP.

      wa_transfer_ready-countr = lv_counter + 1.
    ELSE.
      IF <wa_transfer>-werks = '1106' AND <wa_transfer>-ballennr IS NOT INITIAL.
* Existing datasets should be overwritten
        wa_transfer_ready-countr = 1.
      ELSE.
* Check if on database already a dataset exist for date/time combination
        SELECT *
        INTO TABLE lt_transfer_temp
        FROM zbms_if_ilabcrqm
        UP TO 1 ROWS
        WHERE werks = <wa_transfer>-werks
          AND credat = <wa_transfer>-credat
          AND crezet = <wa_transfer>-crezet
        ORDER BY countr DESCENDING.

        IF sy-subrc IS INITIAL.
          READ TABLE lt_transfer_temp
          ASSIGNING <wa_transfer_temp>
          INDEX 1.

          wa_transfer_ready-countr = <wa_transfer_temp>-countr + 1.
        ELSE.
          wa_transfer_ready-countr = 1.
        ENDIF.
      ENDIF.
    ENDIF.

    IF wa_transfer_ready IS NOT INITIAL.
      INSERT wa_transfer_ready INTO TABLE lt_transfer_ready.
    ENDIF.
  ENDLOOP.

  IF lt_transfer_ready[] IS NOT INITIAL.
    MODIFY zbms_if_ilabcrqm FROM TABLE lt_transfer_ready.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  ENDIF.
ENDFORM.                    "save_data

*&---------------------------------------------------------------------*
*&      Form  condense_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->CT_TRANSFER_DATA  text
*      -->OF                text
*      -->ZBMS_IF_ILABCRQM  text
*----------------------------------------------------------------------*
FORM condense_data USING it_qasr TYPE tt_qasr
                    CHANGING ct_transfer_data TYPE tt_transfer.

  DATA obj_value TYPE REF TO data.
  DATA lt_transfer_condense TYPE STANDARD TABLE OF zbms_if_ilabcrqm.
  DATA: lt_counter TYPE SORTED TABLE OF ts_parname_count WITH UNIQUE KEY werks prueflos ballennr pargrp parname,
        wa_counter TYPE ts_parname_count.
  DATA: lv_insplot  TYPE bapi2045l2-insplot,
        lv_inspoper TYPE bapi2045l2-inspoper.
  DATA lt_transfer_tmp TYPE tt_transfer.
  DATA lv_value TYPE p DECIMALS 8.

  FIELD-SYMBOLS: <wa_transfer_data>     TYPE zbms_if_ilabcrqm,
                 <wa_transfer_condense> TYPE zbms_if_ilabcrqm,
                 <wa_counter>           TYPE ts_parname_count,
                 <wa_parameter_mapping> TYPE zbms_if_mappqm,
                 <wa_char_requirements> TYPE bapi2045d1,
                 <lv_value>             TYPE any,
                 <wa_qasr>              TYPE ts_qasr.

  LOOP AT ct_transfer_data ASSIGNING <wa_transfer_data> WHERE ballennr IS NOT INITIAL.
    CLEAR lv_value.

    IF <wa_transfer_data>-datentyp = co_datatype_numeric.
      lv_value = <wa_transfer_data>-parwert.

      IF lv_value = '0.00000000'.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF <wa_transfer_data>-db_operation = co_db_operation_delete.
      lt_transfer_tmp[] = ct_transfer_data[].

      DELETE lt_transfer_tmp
      WHERE ( werks    <> <wa_transfer_data>-werks OR
              prueflos <> <wa_transfer_data>-prueflos OR
              ballennr <> <wa_transfer_data>-ballennr OR
              parname  <> <wa_transfer_data>-parname OR
              pargrp   <> <wa_transfer_data>-pargrp )
          OR db_operation = co_db_operation_delete.

      IF lt_transfer_tmp[] IS NOT INITIAL.
        FREE lt_transfer_tmp.
        CONTINUE.
      ENDIF.
    ENDIF.

    READ TABLE lt_transfer_condense
    ASSIGNING <wa_transfer_condense>
    WITH KEY werks    = <wa_transfer_data>-werks
             prueflos = <wa_transfer_data>-prueflos
             ballennr = <wa_transfer_data>-ballennr
             parname  = <wa_transfer_data>-parname
             pargrp   = <wa_transfer_data>-pargrp.

    IF sy-subrc IS NOT INITIAL.
      APPEND <wa_transfer_data> TO lt_transfer_condense.

      MOVE-CORRESPONDING <wa_transfer_data> TO wa_counter.
      wa_counter-count = 1.
      INSERT wa_counter INTO TABLE lt_counter.
    ELSE.
      READ TABLE lt_counter
      ASSIGNING <wa_counter>
      WITH KEY werks = <wa_transfer_data>-werks
               prueflos = <wa_transfer_data>-prueflos
               ballennr = <wa_transfer_data>-ballennr
               parname  = <wa_transfer_data>-parname
               pargrp   = <wa_transfer_data>-pargrp.

      <wa_counter>-count = <wa_counter>-count + 1.
      UNASSIGN <wa_counter>.

      IF <wa_transfer_data>-datentyp = co_datatype_numeric.
        <wa_transfer_condense>-parwert = ( <wa_transfer_condense>-parwert + <wa_transfer_data>-parwert ).
      ELSE.
        PERFORM set_condense_catalog_value USING <wa_transfer_data>
                                           CHANGING <wa_transfer_condense>.
      ENDIF.

* Set CRDAT and CRTIME
      IF <wa_transfer_condense>-credat > <wa_transfer_data>-credat.
        <wa_transfer_condense>-credat = <wa_transfer_data>-credat.
        <wa_transfer_condense>-crezet = <wa_transfer_data>-crezet.
        <wa_transfer_condense>-entnadat = <wa_transfer_data>-entnadat.
        <wa_transfer_condense>-entnazet = <wa_transfer_data>-entnazet.
        <wa_transfer_condense>-probenr = <wa_transfer_data>-probenr.
      ELSEIF <wa_transfer_condense>-credat = <wa_transfer_data>-credat AND <wa_transfer_condense>-crezet > <wa_transfer_data>-crezet.
        <wa_transfer_condense>-crezet = <wa_transfer_data>-crezet.
        <wa_transfer_condense>-entnadat = <wa_transfer_data>-entnadat.
        <wa_transfer_condense>-entnazet = <wa_transfer_data>-entnazet.
        <wa_transfer_condense>-probenr = <wa_transfer_data>-probenr.
      ENDIF.

* Set db operation
      IF <wa_transfer_condense>-db_operation = co_db_operation_delete AND <wa_transfer_data>-db_operation <> co_db_operation_insert.
        <wa_transfer_condense>-db_operation = <wa_transfer_data>-db_operation.
      ELSEIF <wa_transfer_condense>-db_operation = co_db_operation_insert AND <wa_transfer_data>-db_operation = co_db_operation_update.
        <wa_transfer_condense>-db_operation = co_db_operation_update.
      ENDIF.
    ENDIF.
  ENDLOOP.

  FREE ct_transfer_data.

* Delete all datasets which are not part of the delta
  DELETE lt_transfer_condense
  WHERE ( credat NOT IN ra_date )
     OR ( credat IN ra_date AND
          crezet NOT IN ra_time ).

* Call middle value
  LOOP AT lt_transfer_condense ASSIGNING <wa_transfer_condense> WHERE datentyp = co_datatype_numeric.
    READ TABLE lt_counter
    ASSIGNING <wa_counter>
    WITH KEY werks = <wa_transfer_condense>-werks
             prueflos = <wa_transfer_condense>-prueflos
             ballennr = <wa_transfer_condense>-ballennr
             parname  = <wa_transfer_condense>-parname
             pargrp   = <wa_transfer_condense>-pargrp.

    IF sy-subrc IS INITIAL.
* Get parameter mapping
      READ TABLE lt_parameter_mapping_buffer
      ASSIGNING <wa_parameter_mapping>
      WITH KEY werks   = <wa_transfer_condense>-werks
               parname = <wa_transfer_condense>-parname.

      READ TABLE lt_char_requirements
      ASSIGNING <wa_char_requirements>
      WITH KEY mstr_char = <wa_parameter_mapping>-mkmnr.

      IF sy-subrc IS INITIAL.
        CREATE DATA obj_value TYPE p DECIMALS <wa_char_requirements>-dec_places.
        ASSIGN obj_value->* TO <lv_value>.

        <lv_value> = <wa_transfer_condense>-parwert / <wa_counter>-count.
        <wa_transfer_condense>-parwert = <lv_value>.
      ENDIF.

      UNASSIGN: <lv_value>, <wa_parameter_mapping>.
      CLEAR: lv_insplot, lv_inspoper.
      FREE obj_value.
    ELSE.
      CLEAR <wa_transfer_condense>-parwert.
    ENDIF.

    UNASSIGN <wa_counter>.
  ENDLOOP.

  APPEND LINES OF lt_transfer_condense TO ct_transfer_data.
  SORT ct_transfer_data BY prueflos vorglfnr merknr.

  FREE: lt_transfer_condense, lt_counter.
ENDFORM.                    "condense_data

*&---------------------------------------------------------------------*
*&      Form  track_run
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM track_run.
  DATA obj_program_tracker TYPE REF TO zif_qm_lab_bms_program_runs.

  obj_program_tracker = zcl_qm_lab_bms_factory=>get_program_run_tracker( ).

  obj_program_tracker->set_run( EXPORTING iv_werks  = p_werks
                                          iv_report = sy-repid
                                          iv_date   = lv_running_date
                                          iv_time   = lv_running_time ).

  FREE obj_program_tracker.
ENDFORM.                    "track_run

*&---------------------------------------------------------------------*
*&      Form  get_parameter_mapping
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LV_MASTER_CHAR  text
*      -->CS_MAPPING      text
*----------------------------------------------------------------------*
FORM get_parameter_mapping USING lv_master_char TYPE qmstr_char
                                 lv_werk TYPE werks_d
                                 lv_version TYPE qversnrmk
                           CHANGING cs_mapping TYPE zbms_if_mappqm.

  DATA lt_mapping_temp TYPE STANDARD TABLE OF zbms_if_mappqm.

* Try to find values in buffer table
  READ TABLE lt_parameter_mapping_buffer
  INTO cs_mapping
  WITH KEY werks = lv_werk
           mkmnr = lv_master_char
           version = lv_version.

  IF sy-subrc IS INITIAL.
    RETURN.
  ENDIF.

* Select mapping from database and add to buffer
  SELECT SINGLE *
  FROM zbms_if_mappqm
  INTO cs_mapping
  WHERE werks = lv_werk
    AND mkmnr = lv_master_char
    AND version = lv_version.

  IF sy-subrc IS INITIAL.
    INSERT cs_mapping INTO TABLE lt_parameter_mapping_buffer.
  ELSE.
* Try to find value wihtout version restriction
    SELECT *
    FROM zbms_if_mappqm
    INTO TABLE lt_mapping_temp
    UP TO 1 ROWS
    WHERE werks = lv_werk
      AND mkmnr = lv_master_char
    ORDER BY version DESCENDING.

    IF sy-subrc IS INITIAL.
      READ TABLE lt_mapping_temp
      INTO cs_mapping
      INDEX 1.

      FREE lt_mapping_temp.
    ENDIF.
  ENDIF.
ENDFORM.                    "get_parameter_mapping

*&---------------------------------------------------------------------*
*&      Form  set_condense_catalog_value
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IS_NEW_TRANSFER_DATA       text
*      -->CS_EXISTING_TRANSFER_DATA  text
*----------------------------------------------------------------------*
FORM set_condense_catalog_value USING is_new_transfer_data TYPE zbms_if_ilabcrqm
                                CHANGING cs_existing_transfer_data TYPE zbms_if_ilabcrqm.

  DATA wa_message TYPE bapiret2.

  FIELD-SYMBOLS: <wa_condense_values_new>      TYPE zqm_s_lab_bms_condense_values,
                 <wa_condense_values_existing> TYPE zqm_s_lab_bms_condense_values,
                 <wa_parameter_mapping>        TYPE zbms_if_mappqm.

  IF lt_condense_values[] IS INITIAL.
* Fill buffer
    SELECT werks
           mkmnr
           value
           condense_order
    FROM zqmcondense
    INTO TABLE lt_condense_values.
  ENDIF.

  IF lt_condense_values[] IS NOT INITIAL.
* Get parameter mapping
    READ TABLE lt_parameter_mapping_buffer
    ASSIGNING <wa_parameter_mapping>
    WITH KEY werks   = cs_existing_transfer_data-werks
             parname = cs_existing_transfer_data-parname.

    IF <wa_parameter_mapping> IS ASSIGNED.
* Find new and existing values
      READ TABLE lt_condense_values
      ASSIGNING <wa_condense_values_new>
      WITH KEY werks = is_new_transfer_data-werks
               mkmnr = <wa_parameter_mapping>-mkmnr
               value = is_new_transfer_data-parwert.

      IF sy-subrc IS NOT INITIAL.
        wa_message-type = 'W'.
        wa_message-id = 'ZQM_LABORATORIES_BMS'.
        wa_message-number = 018.
        wa_message-message_v1 = <wa_parameter_mapping>-mkmnr.
        wa_message-message_v2 = is_new_transfer_data-werks.
        wa_message-message_v3 = is_new_transfer_data-parwert.

        PERFORM write_application_log USING is_new_transfer_data
                                            wa_message.

        CLEAR wa_message.
      ENDIF.

      READ TABLE lt_condense_values
      ASSIGNING <wa_condense_values_existing>
      WITH KEY werks = cs_existing_transfer_data-werks
               mkmnr = <wa_parameter_mapping>-mkmnr
               value = cs_existing_transfer_data-parwert.

      IF sy-subrc IS NOT INITIAL.
        wa_message-type = 'W'.
        wa_message-id = 'ZQM_LABORATORIES_BMS'.
        wa_message-number = 018.
        wa_message-message_v1 = <wa_parameter_mapping>-mkmnr.
        wa_message-message_v2 = cs_existing_transfer_data-werks.
        wa_message-message_v3 = cs_existing_transfer_data-parwert.

        PERFORM write_application_log USING is_new_transfer_data
                                            wa_message.

        CLEAR wa_message.
      ENDIF.

      IF <wa_condense_values_new> IS ASSIGNED AND <wa_condense_values_existing> IS ASSIGNED.
        IF <wa_condense_values_existing>-condense_order > <wa_condense_values_new>-condense_order.
          cs_existing_transfer_data-parwert = is_new_transfer_data-parwert.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    "set_condense_catalog_value

*&---------------------------------------------------------------------*
*&      Form  write_application_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IS_TRANSFER  text
*      -->IS_MESSAGE   text
*----------------------------------------------------------------------*
FORM write_application_log USING is_transfer TYPE zbms_if_ilabcrqm
                                 is_message TYPE bapiret2.


  DATA wa_bal_s_log TYPE bal_s_log.
  DATA wa_msg TYPE bal_s_msg.
  DATA lv_log_handle TYPE balloghndl.
  DATA lt_log_handles TYPE bal_t_logh.

  CONSTANTS: co_bal_object    TYPE balobj_d VALUE 'ZQM_BMS',
             co_bal_subobject TYPE balsubobj VALUE 'ZQM_BMS_INTERFACE'.

  FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

  wa_bal_s_log-object = co_bal_object.
  wa_bal_s_log-subobject = co_bal_subobject.
  wa_bal_s_log-extnumber = |{ is_transfer-prueflos } { is_transfer-vorglfnr }|.

* Create application log
  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log      = wa_bal_s_log
    IMPORTING
      e_log_handle = lv_log_handle.

  IF is_message-id IS NOT INITIAL.
    wa_msg-msgty = is_message-type.
    wa_msg-msgid = is_message-id.
    wa_msg-msgno = is_message-number.
    wa_msg-msgv1 = is_message-message_v1.
    wa_msg-msgv2 = is_message-message_v2.
    wa_msg-msgv3 = is_message-message_v3.
    wa_msg-msgv4 = is_message-message_v4.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = lv_log_handle
        i_s_msg      = wa_msg.
  ELSE.
    CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
      EXPORTING
        i_log_handle     = lv_log_handle
        i_msgty          = is_message-type
        i_text           = is_message-message
      EXCEPTIONS
        log_not_found    = 1
        msg_inconsistent = 2
        log_is_full      = 3
        OTHERS           = 4.
  ENDIF.

  CLEAR: wa_msg.

  APPEND lv_log_handle TO lt_log_handles.

* Save application log
  CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING
      i_t_log_handle = lt_log_handles.

  CLEAR: wa_msg, lv_log_handle, wa_bal_s_log.
  FREE: lt_log_handles.
ENDFORM.                    "write_application_log

*&---------------------------------------------------------------------*
*&      Form  show_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM show_log USING it_transfer TYPE tt_transfer.
  DATA obj_table TYPE REF TO cl_salv_table.
  DATA lv_header TYPE lvc_title.

* Create table
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = obj_table
                              CHANGING t_table = it_transfer ).

      IF p_test = abap_true.
        lv_header = TEXT-t01.
      ELSE.
        lv_header = TEXT-t02.
      ENDIF.

      obj_table->get_display_settings( )->set_list_header( lv_header ).

      obj_table->display( ).
    CATCH cx_salv_msg.
  ENDTRY.

  CLEAR lv_header.
  FREE obj_table.
ENDFORM.                    "show_log
