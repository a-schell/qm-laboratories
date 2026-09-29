**&---------------------------------------------------------------------*
*& Report  ZQM_LIST_OVERVIEW
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Artelsmair, art@informatics.at
*& DATE: 10.05.2017
*&---------------------------------------------------------------------*

REPORT zqm_list_overview.

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.
  PUBLIC SECTION.
    METHODS:
      on_double_click FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.                    "lcl_handle_events DEFINITION

TYPES: BEGIN OF ls_crhd,
        objty TYPE cr_objty,
        objid TYPE cr_objid,
        objid_hy TYPE cr_objid,
       END OF ls_crhd.

TYPES: BEGIN OF ls_qapp_key,
        prueflos TYPE qplos,
        vorglfnr TYPE qlfnkn,
       END OF ls_qapp_key.

DATA wa_qasr TYPE qasr.
DATA wa_workplaces TYPE zqmuserworkplace.
DATA wa_qmel TYPE qmel.
DATA lv_linie TYPE zqm_linie.
DATA lv_prod_type TYPE zbms_materialnr.
DATA lv_probenart TYPE zprobeart.
DATA lv_bale TYPE qusrchar18.
DATA lt_zzpspel TYPE SORTED TABLE OF ps_psp_ele WITH NON-UNIQUE KEY table_line.
DATA lt_qapp TYPE TABLE OF qapp.
DATA: lt_output_data TYPE TABLE OF zqm_pruefloslist,
      wa_output_data TYPE zqm_pruefloslist.
DATA lt_requirements_alv TYPE TABLE OF bapi2045d1.
DATA ra_pspel TYPE RANGE OF qmel-zzpspel.
DATA ra_workplace TYPE RANGE OF zqmuserworkplace-workplace.
DATA ra_plnr TYPE RANGE OF qmel-prueflos.

DATA obj_alv_data_object TYPE REF TO data.
DATA obj_event_handler TYPE REF TO lcl_handle_events.



FIELD-SYMBOLS: <wa_zzpspel> TYPE ps_psp_ele,
               <wa_pspel> LIKE LINE OF ra_pspel,
               <wa_workplace> LIKE LINE OF ra_workplace,
               <wa_plnr> LIKE LINE OF ra_plnr,
               <wa_qapp> TYPE qapp.

SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME.
"SELECT-OPTIONS: s_datum FOR wa_qasr-erstelldat OBLIGATORY.
SELECT-OPTIONS: s_datum FOR wa_qasr-erstelldat.
SELECT-OPTIONS: s_uhr FOR wa_qasr-pruefzeitv.
SELECT-OPTIONS: s_labor FOR wa_workplaces-workplace MATCHCODE OBJECT zqm_wlab.
SELECT-OPTIONS: s_group FOR wa_workplaces-workplace MATCHCODE OBJECT zqm_wgroup.
SELECT-OPTIONS: s_workp FOR wa_workplaces-workplace MATCHCODE OBJECT zqm_wplace.
SELECT-OPTIONS: s_meld FOR wa_qmel-qmnum.
SELECT-OPTIONS: s_plnr FOR wa_qmel-prueflos.
SELECT-OPTIONS: s_linie FOR lv_linie.
SELECT-OPTIONS: s_art FOR lv_probenart.
SELECT-OPTIONS: s_bale FOR lv_bale.
SELECT-OPTIONS: s_prodt FOR lv_prod_type.
SELECT-OPTIONS  s_pspel FOR wa_qmel-zzpspel.
PARAMETERS: p_date TYPE flag,
            p_empty TYPE flag DEFAULT 'X'.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: p_ok RADIOBUTTON GROUP b DEFAULT 'X',
            p_notok RADIOBUTTON GROUP b.
SELECTION-SCREEN: END OF BLOCK a.

INITIALIZATION.
  "  CLEAR s_datum.
  "  s_datum-sign   = 'I'.
  "  s_datum-option = 'EQ'.
  "  s_datum-low    = sy-datum - 1.
  "  APPEND s_datum.

AT SELECTION-SCREEN ON s_meld.
  PERFORM fill_psp_elements.

START-OF-SELECTION.
  PERFORM read_data.
  PERFORM build_alv_data_object.
  PERFORM fill_alv_data_object.
  PERFORM init_alv.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  fill_psp_elements
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_psp_elements.
  FREE ra_pspel.
  APPEND LINES OF s_pspel TO ra_pspel.
  CHECK NOT s_meld-low IS INITIAL.

  SELECT zzpspel
  FROM qmel
  INTO TABLE lt_zzpspel
  WHERE qmnum IN s_meld.

  DELETE lt_zzpspel WHERE table_line = ''.
  DELETE ADJACENT DUPLICATES FROM lt_zzpspel.

  LOOP AT lt_zzpspel ASSIGNING <wa_zzpspel>.
    APPEND INITIAL LINE TO ra_pspel ASSIGNING <wa_pspel>.
    <wa_pspel>-sign = 'I'.
    <wa_pspel>-option = 'EQ'.
    <wa_pspel>-low = <wa_zzpspel>.
  ENDLOOP.

  SORT ra_pspel.
  DELETE ADJACENT DUPLICATES FROM ra_pspel.

  FREE lt_zzpspel.
ENDFORM.                    "fill_psp_elements

*&---------------------------------------------------------------------*
*&      Form  read_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM read_data.
  DATA lt_qasr TYPE SORTED TABLE OF qasr WITH UNIQUE KEY prueflos vorglfnr merknr probenr.
  DATA lt_requirements TYPE TABLE OF bapi2045d1.
  DATA wa_last_qapp_key TYPE ls_qapp_key.
  DATA wa_qals TYPE qals.
  DATA wa_zqmprobes TYPE zqmprobes.
  DATA lv_vorgang TYPE qvornr.
  DATA wa_vorgang_info TYPE bapi2045l2.
  DATA lv_dec TYPE i.
  DATA lv_arbpl TYPE rcr01-arbpl.
  DATA lv_arbid TYPE qapo-arbid.

  FIELD-SYMBOLS: <wa_qasr> TYPE qasr,
                 <wa_requirements> TYPE bapi2045d1.

  FREE: lt_qapp, lt_output_data.

  IF s_meld IS NOT INITIAL OR s_pspel IS NOT INITIAL.
    PERFORM fill_prueflos_range.
  ENDIF.

  IF ( s_meld IS NOT INITIAL AND ra_plnr IS NOT INITIAL ) OR s_meld IS INITIAL.
* Create workplace selection range
    PERFORM fill_workplace_range.
  ENDIF.

  IF p_date = abap_true.
    SELECT * FROM qapp
    INTO TABLE lt_qapp
    WHERE ersteldat IN s_datum
      AND prueflos IN s_plnr
      AND erstelzeit IN s_uhr
    ORDER BY prueflos DESCENDING.
  ELSE.
    SELECT * FROM qapp
    INTO TABLE lt_qapp
    WHERE userd1 IN s_datum
      AND prueflos IN s_plnr
      AND usert1 IN s_uhr
    ORDER BY prueflos DESCENDING.
  ENDIF.

  DELETE lt_qapp
  WHERE usert1 NOT IN s_uhr
    OR usern2 NOT IN s_linie
    OR userc2 NOT IN s_art
    OR userc1 NOT IN s_bale.

  SORT lt_qapp BY prueflos vorglfnr probenr.
  DELETE ADJACENT DUPLICATES FROM lt_qapp COMPARING prueflos vorglfnr probenr.

  LOOP AT lt_qapp ASSIGNING <wa_qapp>.
    CLEAR wa_output_data.

* Fetch additional data
    IF wa_last_qapp_key-prueflos <> <wa_qapp>-prueflos OR wa_last_qapp_key-vorglfnr <> <wa_qapp>-vorglfnr.
      CLEAR: wa_qals, wa_zqmprobes, wa_qmel, lv_vorgang, wa_vorgang_info, lv_arbid, lv_arbpl.
      FREE: lt_requirements, lt_qasr.

* Prüflos lesen
      SELECT SINGLE prueflos
                    zzbms_materialnr
                    aufpl
      INTO (wa_qals-prueflos, wa_qals-zzbms_materialnr, wa_qals-aufpl)
      FROM qals
      WHERE prueflos = <wa_qapp>-prueflos
        AND zzbms_materialnr IN s_prodt
        AND zzlinienr IN s_linie.

      IF sy-subrc IS NOT INITIAL.
        CONTINUE.
      ENDIF.

* Meldung lesen
      SELECT SINGLE qmnum
      FROM zqmprobes
      INTO wa_zqmprobes-qmnum
      WHERE prueflos = <wa_qapp>-prueflos.

      IF sy-subrc IS INITIAL.
        SELECT SINGLE qmtxt
                      zzpspel
        INTO (wa_qmel-qmtxt, wa_qmel-zzpspel)
        FROM qmel
        WHERE qmnum = wa_zqmprobes-qmnum
          AND zzpspel IN s_pspel.

        IF sy-subrc IS NOT INITIAL OR wa_qmel-zzarbpl NOT IN s_labor.
          CONTINUE.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'QIBP_GET_VORNR'
        EXPORTING
          i_insplot      = <wa_qapp>-prueflos
          i_inspoper_int = <wa_qapp>-vorglfnr
        IMPORTING
          e_inspoper     = lv_vorgang.

      IF lv_vorgang IS INITIAL.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                      = <wa_qapp>-prueflos
          inspoper                     = lv_vorgang
          read_insppoints              = ' '
          read_char_requirements       = 'X'
          read_char_results            = ' '
          read_sample_results          = ' '
          read_single_results          = ' '
          read_chars_with_classes      = ' '
          read_chars_without_recording = ' '
          res_org                      = ' '
          char_filter_no               = '1   '
          char_filter_tcode            = 'QE11'
          max_insppoints               = 100
          insppoint_from               = 0
          handheld_application         = ' '
          result_copy                  = ' '
        IMPORTING
          operation                    = wa_vorgang_info
        TABLES
          char_requirements            = lt_requirements.

      IF wa_vorgang_info-workcenter IS INITIAL.
* Try to read direct because of a buffer error in the above bapi module
        SELECT SINGLE arbid
        FROM afvc
        INTO lv_arbid
        WHERE aufpl = wa_qals-aufpl
          AND vornr = lv_vorgang.

        IF lv_arbid IS NOT INITIAL.
          CALL FUNCTION 'CR_WORKSTATION_READ'
            EXPORTING
              id        = lv_arbid
            IMPORTING
              arbpl     = lv_arbpl
            EXCEPTIONS
              not_found = 1.
        ENDIF.

        wa_vorgang_info-workcenter = lv_arbpl.
        CLEAR lv_arbpl.
      ENDIF.

      IF wa_vorgang_info-workcenter NOT IN ra_workplace.
        DELETE lt_qapp
        WHERE prueflos = <wa_qapp>-prueflos
          AND vorglfnr = <wa_qapp>-vorglfnr.

        CONTINUE.
      ENDIF.

      LOOP AT lt_requirements ASSIGNING <wa_requirements>.
        READ TABLE lt_requirements_alv
        WITH KEY insplot = <wa_requirements>-insplot
                 inspoper = <wa_requirements>-inspoper
                 inspchar = <wa_requirements>-inspchar
         TRANSPORTING NO FIELDS.

        IF sy-subrc IS NOT INITIAL.
          APPEND <wa_requirements> TO lt_requirements_alv.
        ENDIF.
      ENDLOOP.

      SELECT prueflos
             vorglfnr
             merknr
             probenr
             ok_benutzer
             ok_datum
             ok_zeit
             ok_status
             nok_status
             mittelwert
             code1
             mittelwni
             original_input
        FROM qasr
        INTO CORRESPONDING FIELDS OF TABLE lt_qasr
       WHERE prueflos = <wa_qapp>-prueflos
         AND vorglfnr = <wa_qapp>-vorglfnr.

      IF p_notok = abap_true.
        DELETE lt_qasr
        WHERE nok_status = ' '.
      ELSE.
        DELETE lt_qasr
        WHERE nok_status = 'X'.
      ENDIF.

      wa_last_qapp_key-prueflos = <wa_qapp>-prueflos.
      wa_last_qapp_key-vorglfnr = <wa_qapp>-vorglfnr.
    ENDIF.

    IF lt_qasr[] IS INITIAL.
      CONTINUE.
    ENDIF.

* Start to fill output data
    CLEAR wa_output_data.
    wa_output_data-prueflos = <wa_qapp>-prueflos.
    wa_output_data-pruefpunkt = <wa_qapp>-ppsortkey.
    wa_output_data-phyprob = <wa_qapp>-phynr.
    wa_output_data-prob = <wa_qapp>-probenr.
    wa_output_data-knoten = <wa_qapp>-vorglfnr.
    wa_output_data-probenart = <wa_qapp>-userc2.
    wa_output_data-ballennummer = <wa_qapp>-userc1.
    wa_output_data-date = <wa_qapp>-userd1.
    wa_output_data-time = <wa_qapp>-usert1.
    wa_output_data-line = <wa_qapp>-usern2.
    wa_output_data-prod_typ = wa_qals-zzbms_materialnr.
    wa_output_data-num = wa_zqmprobes-qmnum.
    wa_output_data-meldungtext = wa_qmel-qmtxt.
    wa_output_data-zzpspel = wa_qmel-zzpspel.
    wa_output_data-vornr = lv_vorgang.
    wa_output_data-prueflostext = wa_vorgang_info-txt_oper.

    IF wa_vorgang_info-workcenter IS INITIAL.
      SELECT SINGLE arbpl
      FROM crhd AS a
      INNER JOIN plpo AS b
      ON a~objid = b~arbid
      INTO wa_output_data-arbpl
      WHERE b~plnty = wa_qals-plnty
        AND b~plnnr = wa_qals-plnnr
        AND b~plnkn = <wa_qapp>-vorglfnr.
    ELSE.
      wa_output_data-arbpl = wa_vorgang_info-workcenter.
    ENDIF.

    LOOP AT lt_qasr ASSIGNING <wa_qasr> WHERE probenr = <wa_qapp>-probenr.
      CLEAR: wa_output_data-stammpruefmerkmal, wa_output_data-merkmaltxt, wa_output_data-ergebnis,
             wa_output_data-wert, wa_output_data-sample, wa_output_data-merkmal, wa_output_data-aenderer,
             wa_output_data-datum, wa_output_data-zeit, wa_output_data-ok, wa_output_data-nicht_ok,
             wa_output_data-mittelwert, wa_output_data-stellen, wa_output_data-mittelwni, wa_output_data-qualitativ.

      READ TABLE lt_requirements
      WITH KEY inspchar = <wa_qasr>-merknr
      ASSIGNING <wa_requirements>.

      IF sy-subrc IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      wa_output_data-stammpruefmerkmal = <wa_requirements>-mstr_char.
      wa_output_data-merkmaltxt = <wa_requirements>-char_descr.

      IF <wa_requirements>-char_type = '02'.
        wa_output_data-ergebnis = <wa_qasr>-code1.
        wa_output_data-wert = <wa_qasr>-code1.
      ELSE.
        CLEAR lv_dec.
        wa_output_data-wert = <wa_qasr>-original_input.

        IF <wa_qasr>-original_input IS NOT INITIAL.
          IF <wa_requirements>-dec_places > 0.
            CALL FUNCTION 'CONVERT_STRING_TO_INTEGER'
              EXPORTING
                p_string      = <wa_requirements>-dec_places
              IMPORTING
                p_int         = lv_dec
              EXCEPTIONS
                overflow      = 1
                invalid_chars = 2
                OTHERS        = 3.
          ELSE.
            lv_dec = -2.
          ENDIF.

          CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
            EXPORTING
              i_float        = <wa_qasr>-mittelwert
              i_dec          = 0
              i_decimals     = lv_dec
            IMPORTING
              e_string       = wa_output_data-ergebnis
            EXCEPTIONS
              number_too_big = 1
              OTHERS         = 2.

          IF lv_dec < 0.
            lv_dec = 0.
          ENDIF.
        ENDIF.
      ENDIF.

      wa_output_data-sample = <wa_qasr>-probenr.
      wa_output_data-merkmal = <wa_qasr>-merknr.
      wa_output_data-aenderer = <wa_qasr>-ok_benutzer.
      wa_output_data-datum = <wa_qasr>-ok_datum.
      wa_output_data-zeit = <wa_qasr>-ok_zeit.
      wa_output_data-ok = <wa_qasr>-ok_status.
      wa_output_data-nicht_ok = <wa_qasr>-nok_status.
      wa_output_data-mittelwert = <wa_qasr>-mittelwert.
      wa_output_data-stellen = lv_dec.
      wa_output_data-mittelwni = <wa_qasr>-mittelwni.

      IF wa_output_data-mittelwni IS NOT INITIAL AND wa_output_data-mittelwert IS INITIAL.
        wa_output_data-wert = '0'.
      ENDIF.

      IF <wa_qasr>-code1 IS NOT INITIAL.
        wa_output_data-qualitativ = 'X'.
      ENDIF.

      APPEND wa_output_data TO lt_output_data.
    ENDLOOP.
  ENDLOOP.

  SORT lt_output_data BY num prueflos pruefpunkt.
  DELETE ADJACENT DUPLICATES FROM lt_output_data.

  CLEAR: wa_qals, wa_zqmprobes, wa_qmel, lv_vorgang, wa_vorgang_info, wa_last_qapp_key.
  FREE: lt_requirements, lt_qasr.
ENDFORM.                    "read_data

*&---------------------------------------------------------------------*
*&      Form  fill_prueflos_range
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_prueflos_range.
  DATA lt_qplos TYPE TABLE OF qplos.

  FIELD-SYMBOLS <wa_qplos> TYPE qplos.

  SELECT a~prueflos
  FROM zqmprobes AS a
  INNER JOIN qmel AS b
  ON a~qmnum = b~qmnum
  INTO TABLE lt_qplos
  WHERE a~qmnum IN s_meld
    AND b~zzpspel IN s_pspel.

  DELETE lt_qplos WHERE table_line = ''.

  LOOP AT lt_qplos ASSIGNING <wa_qplos>.
    APPEND INITIAL LINE TO ra_plnr ASSIGNING <wa_plnr>.
    <wa_plnr>-sign = 'I'.
    <wa_plnr>-option = 'EQ'.
    <wa_plnr>-low = <wa_qplos>.
    UNASSIGN <wa_plnr>.
  ENDLOOP.

  FREE lt_qplos.
ENDFORM.                    "fill_prueflos_range

*&---------------------------------------------------------------------*
*&      Form  fill_workplace_range
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_workplace_range.
  DATA lt_crhd TYPE SORTED TABLE OF ls_crhd WITH UNIQUE KEY objty objid.
  DATA lt_crhs TYPE STANDARD TABLE OF crhs.
  DATA lv_arbpl TYPE rcr01-arbpl.
  DATA lv_count TYPE i.

  FIELD-SYMBOLS: <wa_crhd> TYPE ls_crhd,
                 <wa_crhs> TYPE crhs,
                 <lt_range> TYPE STANDARD TABLE.

  FREE ra_workplace.
  APPEND LINES OF s_workp TO ra_workplace.

  DO 2 TIMES.
    lv_count = lv_count + 1.

    CASE lv_count.
      WHEN 1.
        ASSIGN s_labor[] TO <lt_range>.
      WHEN 2.
        ASSIGN s_group[] TO <lt_range>.
    ENDCASE.

    IF <lt_range>[] IS NOT INITIAL.
      APPEND LINES OF <lt_range> TO ra_workplace.
      SORT ra_workplace.
      DELETE ADJACENT DUPLICATES FROM ra_workplace.

* Get workplace id`s
      SELECT a~objty
             a~objid
             b~objid_hy
      FROM crhd AS a
      INNER JOIN crhs AS b
      ON a~objty = b~objty_ho AND
         a~objid = b~objid_ho
      INTO TABLE lt_crhd
      WHERE a~arbpl IN s_labor.

      LOOP AT lt_crhd ASSIGNING <wa_crhd>.
        FREE lt_crhs.

        CALL FUNCTION 'CR_HIERARCHY_FATHER_AND_SONS'
          EXPORTING
            objid_ho            = <wa_crhd>-objid
            objid_hy            = <wa_crhd>-objid_hy
          TABLES
            t_crhs              = lt_crhs
          EXCEPTIONS
            hierarchy_not_found = 1.

        LOOP AT lt_crhs ASSIGNING <wa_crhs>.
          CLEAR lv_arbpl.

          CALL FUNCTION 'CR_WORKSTATION_READ'
            EXPORTING
              id        = <wa_crhs>-objid_ho
            IMPORTING
              arbpl     = lv_arbpl
            EXCEPTIONS
              not_found = 1.

          APPEND INITIAL LINE TO ra_workplace ASSIGNING <wa_workplace>.
          <wa_workplace>-sign = 'I'.
          <wa_workplace>-option = 'EQ'.
          <wa_workplace>-low = lv_arbpl.
          UNASSIGN <wa_workplace>.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDDO.
ENDFORM.                    "fill_workplace_range

*&---------------------------------------------------------------------*
*&      Form  fill_alv_data_object
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_alv_data_object.
  DATA lv_fieldname TYPE string.

  FIELD-SYMBOLS: <lt_alv_data> TYPE STANDARD TABLE,
                 <wa_alv_data> TYPE any,
                 <wa_output_data> TYPE zqm_pruefloslist,
                 <lv_field> TYPE any.

  ASSIGN obj_alv_data_object->* TO <lt_alv_data>.

  LOOP AT lt_output_data ASSIGNING <wa_output_data>.
    CLEAR lv_fieldname.

    IF p_empty = abap_true AND <wa_output_data>-ergebnis IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE <lt_alv_data>
    ASSIGNING <wa_alv_data>
    WITH KEY ('PRUEFLOS') = <wa_output_data>-prueflos
             ('LINE') = <wa_output_data>-line
             ('PROBENART') = <wa_output_data>-probenart
             ('DATE') = <wa_output_data>-date
             ('TIME') = <wa_output_data>-time
             ('BALLENNUMMER') = <wa_output_data>-ballennummer.  "neu Mai 2026 Ticket SR-881777
*   Ticket SR-881777: es wurde bei RnD linie 33 immer nur der erste Record wo prüflos/line/probenart/date/time übereinstimmte übernommen

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO <lt_alv_data> ASSIGNING <wa_alv_data>.
      MOVE-CORRESPONDING <wa_output_data> TO <wa_alv_data>.
    ENDIF.

    lv_fieldname = |VALUE_{ <wa_output_data>-stammpruefmerkmal }|.

    ASSIGN COMPONENT lv_fieldname OF STRUCTURE <wa_alv_data> TO <lv_field>.
    IF sy-subrc IS INITIAL.
      <lv_field> = <wa_output_data>-ergebnis.
      UNASSIGN <lv_field>.
    ENDIF.
  ENDLOOP.

  SORT <lt_alv_data> BY ('LINE') ('DATE') ('TIME').
ENDFORM.                    "fill_alv_data_object

*&---------------------------------------------------------------------*
*&      Form  build_alv_data_object
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_data_object.
  DATA: obj_struct_descr TYPE REF TO cl_abap_structdescr,
        obj_table_descr TYPE REF TO cl_abap_tabledescr.
  DATA lt_components TYPE abap_component_tab.
  DATA lv_fieldname TYPE fieldname.

  FIELD-SYMBOLS: <wa_requirements_alv> TYPE bapi2045d1,
                 <wa_components> TYPE abap_componentdescr.

* Build components
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'NUM'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QMNUM' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'MELDUNGTEXT'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QMTXT' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'PRUEFLOS'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QPLOS' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'PRUEFPUNKT'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QPPSORTKEY' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'BALLENNUMMER'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QUSRCHAR18' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'LINE'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZQM_LINIE' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'PROBENART'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZPROBEART' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'DATE'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QUSRDATS' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'TIME'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'QUSRTIMS' ).
  APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
  <wa_components>-name = 'PROD_TYP'.
  <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'ZBMS_MATERIALNR' ).

  SORT lt_requirements_alv BY mstr_char.
  DELETE ADJACENT DUPLICATES FROM lt_requirements_alv COMPARING mstr_char.
  SORT lt_requirements_alv BY inspoper inspchar.

  LOOP AT lt_requirements_alv ASSIGNING <wa_requirements_alv>.
    lv_fieldname = |VALUE_{ <wa_requirements_alv>-mstr_char }|.

    READ TABLE lt_components
    WITH KEY name = lv_fieldname
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_components ASSIGNING <wa_components>.
      <wa_components>-name = lv_fieldname.
      <wa_components>-type ?= cl_abap_elemdescr=>describe_by_name( 'STRING' ).
    ENDIF.
  ENDLOOP.

* Create data object
  obj_struct_descr = cl_abap_structdescr=>create( lt_components ).
  obj_table_descr ?= cl_abap_tabledescr=>create( obj_struct_descr ).
  CREATE DATA obj_alv_data_object TYPE HANDLE obj_table_descr.

  FREE: obj_struct_descr, obj_table_descr.
ENDFORM.                    "build_alv_data_object

*&---------------------------------------------------------------------*
*&      Form  init_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_alv.
  DATA obj_alv TYPE REF TO cl_salv_table.
  DATA obj_events TYPE REF TO cl_salv_events_table.
  DATA lt_columns TYPE salv_t_column_ref.
  DATA: lv_fieldname_prefix TYPE string,
        lv_fieldname TYPE string.
  DATA: lv_long_text TYPE scrtext_l,
        lv_medium_text TYPE scrtext_m,
        lv_short_text TYPE scrtext_s.
  DATA lv_where TYPE string.
  DATA lv_long_text_hlp TYPE scrtext_l.
  DATA lt_qpmt_tab TYPE TABLE OF qpmt.
  DATA lt_bapiret  TYPE TABLE OF bapiret2.

  FIELD-SYMBOLS: <lt_alv_data> TYPE STANDARD TABLE,
                 <wa_alv_data> TYPE any,
                 <wa_columns> TYPE salv_s_column_ref,
                 <wa_requirements_alv> TYPE bapi2045d1,
                 <wa_qpmt> TYPE qpmt.

  ASSIGN obj_alv_data_object->* TO <lt_alv_data>.

* Create alv
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = obj_alv
                              CHANGING t_table = <lt_alv_data> ).

* Activate functions
      obj_alv->get_functions( )->set_all( abap_true ).
      obj_alv->get_layout( )->set_save_restriction( if_salv_c_layout=>restrict_none ).
      obj_alv->get_layout( )->set_key( VALUE salv_s_layout_key( report = sy-repid ) ).
      obj_alv->get_layout( )->set_default( abap_true ).

* Edit columns
      lt_columns = obj_alv->get_columns( )->get( ).

      LOOP AT lt_columns ASSIGNING <wa_columns>.
        IF <wa_columns>-columnname CP 'VALUE_*'.
          SPLIT <wa_columns>-columnname AT '_' INTO lv_fieldname_prefix lv_fieldname.

          READ TABLE lt_requirements_alv
          ASSIGNING <wa_requirements_alv>
          WITH KEY mstr_char = lv_fieldname.

          IF sy-subrc IS INITIAL.
            cl_qmip_master_inspchar=>read_mic( EXPORTING iv_werk           = <wa_requirements_alv>-pmstr_char
                                                         iv_mkmnr          = <wa_requirements_alv>-mstr_char
                                                         iv_version        = <wa_requirements_alv>-vmstr_char
                                               IMPORTING et_qpmt           = lt_qpmt_tab
                                                         et_return         = lt_bapiret ).

            READ TABLE lt_bapiret
            TRANSPORTING NO FIELDS
            WITH KEY type = 'E'.

            IF sy-subrc IS NOT INITIAL.
              READ TABLE lt_qpmt_tab
              ASSIGNING <wa_qpmt>
              WITH KEY sprache = sy-langu.

              IF sy-subrc IS INITIAL.
                <wa_requirements_alv>-char_descr = <wa_qpmt>-kurztext.
              ENDIF.
            ENDIF.

            FREE: lt_qpmt_tab, lt_bapiret.

            IF <wa_requirements_alv>-meas_unit IS INITIAL.
              lv_long_text_hlp = <wa_requirements_alv>-char_descr.
            ELSE.
              CONCATENATE <wa_requirements_alv>-char_descr ' [' <wa_requirements_alv>-meas_unit ']' INTO lv_long_text_hlp.
            ENDIF.
            lv_short_text = lv_medium_text = lv_long_text = lv_long_text_hlp.
            <wa_columns>-r_column->set_long_text( value = lv_long_text ).
            <wa_columns>-r_column->set_medium_text( value = lv_medium_text ).
            <wa_columns>-r_column->set_short_text( value = lv_short_text ).
          ENDIF.
        ELSEIF <wa_columns>-columnname = 'DATE'.
          lv_short_text = lv_medium_text = lv_long_text = text-t01.
          <wa_columns>-r_column->set_long_text( value = lv_long_text ).
          <wa_columns>-r_column->set_medium_text( value = lv_medium_text ).
          <wa_columns>-r_column->set_short_text( value = lv_short_text ).
        ELSEIF <wa_columns>-columnname = 'TIME'.
          lv_short_text = lv_medium_text = lv_long_text = text-t02.
          <wa_columns>-r_column->set_long_text( value = lv_long_text ).
          <wa_columns>-r_column->set_medium_text( value = lv_medium_text ).
          <wa_columns>-r_column->set_short_text( value = lv_short_text ).
        ELSEIF <wa_columns>-columnname = 'BALLENNUMMER'.
          lv_short_text = lv_medium_text = lv_long_text = text-t03.
          <wa_columns>-r_column->set_long_text( value = lv_long_text ).
          <wa_columns>-r_column->set_medium_text( value = lv_medium_text ).
          <wa_columns>-r_column->set_short_text( value = lv_short_text ).
        ELSEIF <wa_columns>-columnname = 'PROBENART'.
          lv_short_text = lv_medium_text = lv_long_text = text-t04.
          <wa_columns>-r_column->set_long_text( value = lv_long_text ).
          <wa_columns>-r_column->set_medium_text( value = lv_medium_text ).
          <wa_columns>-r_column->set_short_text( value = lv_short_text ).
        ENDIF.
      ENDLOOP.

* Register events
      CREATE OBJECT obj_event_handler.
      obj_events = obj_alv->get_event( ).
      SET HANDLER obj_event_handler->on_double_click FOR obj_events.

* Display table
      obj_alv->display( ).
    CATCH cx_salv_msg.
  ENDTRY.

  FREE lt_columns.
  FREE: obj_alv, obj_events.
ENDFORM.                    "init_alv

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.
  METHOD on_double_click.
    FIELD-SYMBOLS: <lt_alv_data> TYPE STANDARD TABLE,
                   <wa_alv_data> TYPE any,
                   <lv_field> TYPE any.

    ASSIGN obj_alv_data_object->* TO <lt_alv_data>.

    READ TABLE <lt_alv_data>
    ASSIGNING <wa_alv_data>
    INDEX row.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF column = 'NUM'.
      ASSIGN COMPONENT column OF STRUCTURE <wa_alv_data> TO <lv_field>.
      IF sy-subrc IS INITIAL AND <lv_field> IS NOT INITIAL.
        SET PARAMETER ID 'IQM' FIELD <lv_field>.
        CALL TRANSACTION 'QM03' AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.

    IF column = 'PRUEFLOS'.
      ASSIGN COMPONENT column OF STRUCTURE <wa_alv_data> TO <lv_field>.
      IF sy-subrc IS INITIAL AND <lv_field> IS NOT INITIAL.
        SET PARAMETER ID 'QLS' FIELD <lv_field>.
        CALL TRANSACTION 'QA03'   AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "on_double_click
ENDCLASS.                    "lcl_handle_events IMPLEMENTATION
