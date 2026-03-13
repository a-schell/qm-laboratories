**&---------------------------------------------------------------------*
*& Report  ZQMLIST_PRUEFLOS
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Artelsmair, art@informatics.at
*& DATE: 16.02.2017
*& AUTHOR: Klaus Stranzinger: Erstselektion von DB nun mittels Join
*&         neuer Sel-Param PA_WERKS
*& DATE: 02.04.2021
*&---------------------------------------------------------------------*

REPORT zqm_list_prueflos_details.



DATA: lt_qasr TYPE TABLE OF qasr.
DATA: ls_qasr TYPE qasr.
DATA: lt_qapp TYPE TABLE OF qapp.
DATA: ls_qapp TYPE qapp.
DATA: lt_qapp_u TYPE TABLE OF qapp. "Jeder Vorgang nur einmal
DATA: ls_qapp_u TYPE qapp.
DATA: lt_split    TYPE TABLE OF char40.

DATA: bdcdata_wa TYPE bdcdata.
DATA: bdcdata_tab TYPE TABLE OF bdcdata.

DATA: lt_qmel TYPE TABLE OF qmel.
DATA: ls_qmel TYPE qmel.
DATA: lt_zqmprobes TYPE TABLE OF zqmprobes.
DATA: ls_zqmprobes TYPE zqmprobes.
DATA: ls_qals TYPE qals.

DATA: ls_qpmt TYPE qpmt.
DATA: lv_status TYPE xfeld.
DATA: ls_vorgangdata TYPE qapo.
DATA: lv_vorgang TYPE qvornr.
DATA: lv_vorglfnr LIKE qapp-vorglfnr.
DATA: lv_probenr LIKE qapp-probenr.

DATA: lt_vorgaenge TYPE TABLE OF bapi2045l2.
DATA: ls_vorgang TYPE bapi2045l2.
DATA: lt_merkmal TYPE TABLE OF bapi2045d3.
DATA: ls_merkmal TYPE bapi2045d3.
DATA: lt_merkmal2 TYPE TABLE OF bapi2045d3.
DATA: ls_vorgang_info TYPE bapi2045l2.
DATA: lt_requirements TYPE TABLE OF bapi2045d1.
DATA: ls_requirements TYPE  bapi2045d1.
DATA: lv_linie TYPE zqm_linie.
DATA: lv_prod_type TYPE zbms_materialnr.
DATA: lv_probenart TYPE zprobeart.
DATA: ls_workplaces TYPE zqmuserworkplace.
DATA: lt_bapi2045d4 TYPE TABLE OF bapi2045d4.
DATA: lt_bapi2045d2 TYPE TABLE OF bapi2045d2.
DATA: ls_bapi2045d2 TYPE bapi2045d2.
DATA: lv_lines TYPE i.
DATA: lv_dec TYPE i.
DATA: lv_ergebnis(30) TYPE c.
DATA: lv_ergdec(30) TYPE c.

*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver DEFINITION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.

  PUBLIC SECTION.
    METHODS:

    handle_double_click
        FOR EVENT double_click OF cl_gui_alv_grid
            IMPORTING e_row e_column,

    handle_detail_click
        FOR EVENT before_user_command OF cl_gui_alv_grid
            IMPORTING e_ucomm,

    handle_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
            IMPORTING e_row_id e_column_id es_row_no.

  PRIVATE SECTION.

ENDCLASS.                    "lcl_event_receiver DEFINITION



DATA: ls_alvdata TYPE zqm_pruefloslist.
DATA: ls_alvdata2 TYPE zqm_pruefloslist.
DATA: lt_alvdata TYPE TABLE OF zqm_pruefloslist.
DATA: lt_alvdata_old TYPE TABLE OF zqm_pruefloslist.
DATA: ls_alvdata_old TYPE zqm_pruefloslist.
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv.

DATA:
   l_scroll_row_no   TYPE lvc_s_roid,
   l_scroll_row_info TYPE lvc_s_row,
   l_scroll_col_info TYPE lvc_s_col,
   l_cell_row_no TYPE lvc_s_roid,
   l_cell_row_id TYPE lvc_s_row,
   l_cell_col_id TYPE lvc_s_col,

   mt_sel_cells TYPE lvc_t_ceno,
   mt_sel_rows  TYPE lvc_t_row.


DATA: lv_changed TYPE char1.

DATA: excl_tb TYPE ui_functions.
DATA: grid TYPE          REF TO cl_gui_alv_grid,
      g_custom_container TYPE REF TO cl_gui_custom_container,
      event_receiver     TYPE REF TO lcl_event_receiver,
      fcat               TYPE lvc_t_fcat WITH HEADER LINE,
      variant            TYPE disvariant.
DATA: i_soft         TYPE xfeld VALUE 'X'.
DATA: i_set_current  TYPE xfeld VALUE 'X'.
DATA: i_set_selected TYPE xfeld VALUE ''.
DATA : it_return1 LIKE ddshretval OCCURS 0 WITH HEADER LINE,
       it_return2 LIKE ddshretval OCCURS 0 WITH HEADER LINE.

DATA: lt_labor LIKE TABLE OF ls_qmel-zzarbpl.

DATA: lt_inspoint TYPE TABLE OF bapi2045l4.
DATA: ls_inspoint TYPE bapi2045l4.
DATA: lv_returncode(1) TYPE c.
DATA lv_bale TYPE qusrchar18.
DATA lt_qpmt_tab TYPE TABLE OF qpmt.
DATA lt_bapiret  TYPE TABLE OF bapiret2.

FIELD-SYMBOLS: <wa_qpmt> TYPE qpmt.
PARAMETERS: pa_werk TYPE qals-werk OBLIGATORY MEMORY ID wrk. "neu seit 2.April 2021
"SELECT-OPTIONS: p_datum FOR ls_qasr-erstelldat OBLIGATORY.
SELECT-OPTIONS: p_datum FOR ls_qasr-erstelldat.
SELECT-OPTIONS: p_uhr FOR ls_qasr-pruefzeitv.
SELECT-OPTIONS: p_labor FOR ls_workplaces-workplace MATCHCODE OBJECT zqm_workplace.
SELECT-OPTIONS: p_arbpl FOR ls_workplaces-workplace MATCHCODE OBJECT zqm_workplace.
SELECT-OPTIONS: p_plnr FOR ls_qmel-prueflos.
SELECT-OPTIONS: p_linie FOR lv_linie.
SELECT-OPTIONS: p_art FOR lv_probenart.
SELECT-OPTIONS: p_prodt FOR lv_prod_type.
SELECT-OPTIONS: p_bale FOR lv_bale.

SELECT-OPTIONS: s_meld  FOR ls_qmel-qmnum.
SELECT-OPTIONS  s_pspel FOR ls_qmel-zzpspel.

PARAMETERS:
p_date TYPE flag.


INITIALIZATION.
  "CLEAR p_datum.
  "p_datum-sign   = 'I'.
  "p_datum-option = 'EQ'.
  "p_datum-low    = sy-datum - 1.
  "APPEND p_datum.

* =================================================================== *
AT SELECTION-SCREEN ON s_meld.
* ------------------------------------------------------------------- *
  CHECK NOT s_meld-low IS INITIAL.
  s_pspel-sign = 'I'.
  s_pspel-option = 'EQ'.
  SELECT zzpspel FROM qmel INTO s_pspel-low
    WHERE qmnum IN s_meld
      AND zzpspel <> ''.
    APPEND s_pspel.
  ENDSELECT.

  DELETE ADJACENT DUPLICATES FROM s_pspel.
* ------------------------------------------------------------------- *

  p_plnr-sign = 'I'.
  p_plnr-option = 'EQ'.
  SELECT prueflos FROM zqmprobes INTO p_plnr-low
         WHERE qmnum IN s_meld.
    APPEND p_plnr.
  ENDSELECT.
  DELETE ADJACENT DUPLICATES FROM p_plnr.
* =================================================================== *

* =================================================================== *
AT SELECTION-SCREEN ON s_pspel.
* ------------------------------------------------------------------- *
  CHECK NOT s_pspel-low IS INITIAL.
  s_meld-sign = 'I'.
  s_meld-option = 'EQ'.
  SELECT qmnum FROM qmel INTO s_meld-low
    WHERE zzpspel IN s_pspel.
    APPEND s_meld.
  ENDSELECT.

  DELETE ADJACENT DUPLICATES FROM s_meld.
* ------------------------------------------------------------------- *

  p_plnr-sign = 'I'.
  p_plnr-option = 'EQ'.
  SELECT prueflos FROM zqmprobes INTO p_plnr-low
         WHERE qmnum IN s_meld.
    APPEND p_plnr.
  ENDSELECT.
  DELETE ADJACENT DUPLICATES FROM p_plnr.
* =================================================================== *




***********************************************************************
START-OF-SELECTION.

  zcl_bms_zbaloggac002=>write_log_zzprogrammlog2(
      EXPORTING
        i_syrepid = sy-repid
        i_syuname = sy-uname
        i_sydatum = sy-datum
        i_syzeit  = sy-uzeit ).

  PERFORM daten_lesen.
  PERFORM alv_erzeugen.

*&---------------------------------------------------------------------*
*&      Form  daten_lesen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM daten_lesen.

* Stichprobenergebnisse mit Datum selektieren
  IF p_date IS NOT INITIAL.
    CLEAR lt_qapp.
    SELECT prueflos ppsortkey phynr probenr vorglfnr userc1 userc2 userd1 usert1 usern2 vorglfnr
      FROM qapp
      INTO CORRESPONDING FIELDS OF TABLE lt_qapp
      WHERE ersteldat  IN p_datum
        AND prueflos   IN p_plnr
        AND erstelzeit IN p_uhr.

  ELSE.
*   neu seit 2.4.2021 Klaus Stranzinger:
*   Erstselektion von DB nun mittels Join
    CLEAR lt_qapp.
    SELECT pp~prueflos pp~ppsortkey pp~phynr pp~probenr pp~vorglfnr
           pp~userc1 pp~userc2 pp~userd1 pp~usert1 pp~usern2 pp~vorglfnr
      INTO CORRESPONDING FIELDS OF TABLE lt_qapp
      FROM qapp AS pp INNER JOIN qals AS ls
        ON pp~prueflos =  ls~prueflos
     WHERE pp~userd1   IN p_datum
       AND pp~prueflos IN p_plnr
       AND pp~usert1   IN p_uhr
       AND ls~werk             =  pa_werk
       AND ls~zzbms_materialnr IN p_prodt   "wird nun hier schon bei Erstselektion abgegrenzt
       AND ls~zzlinienr        IN p_linie.  "wird nun hier schon bei Erstselektion abgegrenzt

**  Alter Code
    DATA  l_alter_code TYPE flag.
    l_alter_code = ''.
    IF l_alter_code = 'X'.
      CLEAR lt_qapp.
      SELECT prueflos ppsortkey phynr probenr vorglfnr userc1 userc2 userd1 usert1 usern2 vorglfnr
        FROM qapp
        INTO CORRESPONDING FIELDS OF TABLE lt_qapp
        WHERE userd1   IN p_datum
          AND prueflos IN p_plnr
          AND usert1   IN p_uhr.
    ENDIF.
  ENDIF.

  IF p_bale[] IS NOT INITIAL.
    DELETE lt_qapp
    WHERE userc1 NOT IN p_bale.
  ENDIF.

*  LT_QAPP_U = LT_QAPP.
  SORT lt_qapp BY prueflos vorglfnr probenr.
  DELETE ADJACENT DUPLICATES FROM lt_qapp COMPARING prueflos vorglfnr probenr.

  LOOP AT lt_qapp INTO ls_qapp.
* Prüflosdaten nur eimal lesen.
    ls_alvdata-prueflos     = ls_qapp-prueflos.
    ls_alvdata-pruefpunkt   = ls_qapp-ppsortkey.
    ls_alvdata-phyprob      = ls_qapp-phynr.
    ls_alvdata-prob         = ls_qapp-probenr.
    ls_alvdata-knoten       = ls_qapp-vorglfnr.
    ls_alvdata-probenart    = ls_qapp-userc2.
    ls_alvdata-ballennummer = ls_qapp-userc1.
    ls_alvdata-date         = ls_qapp-userd1.
    ls_alvdata-time         = ls_qapp-usert1.
    ls_alvdata-line         = ls_qapp-usern2.

    IF NOT lv_vorglfnr      = ls_qapp-vorglfnr.
      CLEAR ls_zqmprobes.



* Prüflos lesen
      CLEAR ls_qals.
      SELECT SINGLE zzbms_materialnr plnty plnnr
        FROM qals
        INTO CORRESPONDING FIELDS OF ls_qals
        WHERE prueflos          = ls_qapp-prueflos
          AND zzbms_materialnr IN p_prodt
          AND zzlinienr        IN p_linie.
      IF NOT sy-subrc = 0.
        CONTINUE.
      ENDIF.


* Meldung lesen.
      SELECT SINGLE * FROM zqmprobes INTO ls_zqmprobes
        WHERE prueflos = ls_qapp-prueflos.
      IF sy-subrc = 0.


        CLEAR ls_qmel.
        SELECT SINGLE qmtxt
          FROM qmel
          INTO CORRESPONDING FIELDS OF ls_qmel
          WHERE qmnum = ls_zqmprobes-qmnum.
        IF sy-subrc = 0.

          IF ls_qmel-zzarbpl NOT IN p_labor.
            CONTINUE.
          ENDIF.

        ENDIF.
      ENDIF.

    ENDIF.
    ls_alvdata-prod_typ    = ls_qals-zzbms_materialnr.
    ls_alvdata-num         = ls_zqmprobes-qmnum.
    ls_alvdata-meldungtext = ls_qmel-qmtxt.

*    IF NOT LV_PROBENR = LS_QAPP-PROBENR.
    IF NOT ls_qapp-vorglfnr = lv_vorglfnr.
      CLEAR lt_merkmal.

      CALL FUNCTION 'QIBP_GET_VORNR'
        EXPORTING
          i_insplot      = ls_qapp-prueflos
          i_inspoper_int = ls_qapp-vorglfnr
        IMPORTING
          e_inspoper     = lv_vorgang.

      IF lv_vorgang IS NOT INITIAL.

        ls_alvdata-vornr = lv_vorgang.


        DATA: lt_bapi2045d4 TYPE TABLE OF bapi2045d4.
        DATA: lt_bapi2045d2 TYPE TABLE OF bapi2045d2.

* Merkmale zum Vorgang, Vorgang info lesen, mit FUB da Texte dabei...
        CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
          EXPORTING
            insplot                      = ls_qapp-prueflos
            inspoper                     = lv_vorgang
*           READ_INSPPOINTS              = 'X'
            read_char_requirements       = 'X'
*           READ_CHAR_RESULTS            = 'X'
*           READ_SAMPLE_RESULTS          = 'X'
*           READ_SINGLE_RESULTS          = 'X'
*           READ_CHARS_WITH_CLASSES      = 'X'
*           READ_CHARS_WITHOUT_RECORDING = 'X'
*           RES_ORG                      = ' '
*           CHAR_FILTER_NO               = '1   '
*           CHAR_FILTER_TCODE            = 'QE11'
*           MAX_INSPPOINTS               = 100
*           INSPPOINT_FROM               = 0
*           HANDHELD_APPLICATION         = ' '
*           RESULT_COPY                  = ' '
          IMPORTING
            operation                    = ls_vorgang_info
*           INSPPOINT_REQUIREMENTS       =
*           RETURN                       =
          TABLES
            insppoints                   = lt_inspoint
            char_requirements            = lt_requirements
            char_results                 = lt_bapi2045d2
            sample_results               = lt_merkmal
            single_results               = lt_bapi2045d4.

        READ TABLE lt_inspoint INDEX 3 INTO ls_inspoint.


*        IF LS_VORGANG_INFO-WORKCENTER IN P_ARBPL.
*
*        ELSE.
*          CONTINUE.
*        ENDIF.
      ENDIF.
    ENDIF.

*    ENDIF.<
    ls_alvdata-prueflostext = ls_vorgang_info-txt_oper.
    IF ls_vorgang_info-workcenter IS INITIAL.
      SELECT SINGLE arbpl FROM crhd AS a
         INNER JOIN plpo AS b ON a~objid = b~arbid
               INTO ls_alvdata-arbpl
              WHERE b~plnty = ls_qals-plnty
                AND b~plnnr = ls_qals-plnnr
                AND b~plnkn = ls_qapp-vorglfnr.
    ELSE.
      ls_alvdata-arbpl = ls_vorgang_info-workcenter.
    ENDIF.

    CLEAR: ls_qasr.
    SELECT probenr pruefbemkt mittelwert code1 original_input merknr ok_benutzer ok_datum
           ok_zeit ok_status nok_status
      FROM qasr
      INTO CORRESPONDING FIELDS OF TABLE lt_qasr
     WHERE prueflos = ls_qapp-prueflos
       AND vorglfnr = ls_qapp-vorglfnr
       AND probenr  = ls_qapp-probenr.

    LOOP AT lt_qasr INTO ls_qasr.

      READ TABLE lt_requirements WITH KEY inspchar = ls_qasr-merknr INTO ls_requirements.

      ls_alvdata-stammpruefmerkmal = ls_requirements-mstr_char.
      " LAGAHW Change read description by SY-LANGU
      "ls_alvdata-merkmaltxt        = ls_requirements-char_descr.

      cl_qmip_master_inspchar=>read_mic( EXPORTING iv_werk           = ls_requirements-pmstr_char
                                                   iv_mkmnr          = ls_requirements-mstr_char
                                                   iv_version        = ls_requirements-vmstr_char
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
          ls_alvdata-merkmaltxt   = <wa_qpmt>-kurztext.
        ENDIF.
      ENDIF.






      IF ls_alvdata-time NOT IN p_uhr OR ls_alvdata-line NOT IN p_linie OR ls_alvdata-probenart NOT IN p_art
        OR ls_alvdata-prod_typ NOT IN p_prodt.
        CONTINUE.
      ENDIF.
      IF ls_qasr-code1 IS NOT INITIAL.
        ls_alvdata-ergebnis = ls_qasr-code1.
        ls_alvdata-wert = ls_qasr-code1.
      ELSE.
        ls_alvdata-wert = ls_qasr-original_input.
        CLEAR: lv_dec.
        CALL FUNCTION 'CONVERT_STRING_TO_INTEGER'
          EXPORTING
            p_string      = ls_requirements-dec_places
          IMPORTING
            p_int         = lv_dec
          EXCEPTIONS
            overflow      = 1
            invalid_chars = 2
            OTHERS        = 3.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
          EXPORTING
            i_float        = ls_qasr-mittelwert
*           I_DEC          = 0
            i_decimals     = lv_dec
          IMPORTING
            e_string       = ls_alvdata-ergebnis
*           E_FLOAT        =
*           E_DEC          =
*           E_DECIMALS     =
          EXCEPTIONS
            number_too_big = 1
            OTHERS         = 2.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.
        IF lv_dec = 0.
*          BREAK: <EXTJAW.
          CONSTANTS: sep VALUE ','.
          SPLIT ls_alvdata-ergebnis AT sep INTO lv_ergebnis lv_ergdec.
          IF lv_ergdec(1) >= 5.
            CLEAR: lv_ergebnis, lv_ergdec.
            ls_qasr-mittelwert = ls_qasr-mittelwert + 1.
            CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
              EXPORTING
                i_float        = ls_qasr-mittelwert
*               I_DEC          = 0
                i_decimals     = lv_dec
              IMPORTING
                e_string       = ls_alvdata-ergebnis
*               E_FLOAT        =
*               E_DEC          =
*               E_DECIMALS     =
              EXCEPTIONS
                number_too_big = 1
                OTHERS         = 2.

            SPLIT ls_alvdata-ergebnis AT sep INTO lv_ergebnis lv_ergdec.
          ENDIF.
          ls_alvdata-ergebnis = lv_ergebnis.
        ENDIF.
        IF ls_alvdata-ergebnis <> '0' AND ls_alvdata-ergebnis IS NOT INITIAL AND ls_alvdata-ergebnis <> '0,0' AND
          ls_alvdata-ergebnis <> '0,00' AND ls_alvdata-ergebnis <> '0,000' AND ls_alvdata-ergebnis <> '0,0000' AND
          ls_alvdata-ergebnis <> '0,00000' AND ls_alvdata-ergebnis <> '0,000000'.
          ls_alvdata-wert = ls_alvdata-ergebnis.
        ENDIF.
*        LS_ALVDATA-MITTELWERT = LS_QASR-MITTELWERT.
      ENDIF.
      ls_alvdata-sample     = ls_qasr-probenr.
      ls_alvdata-merkmal    = ls_qasr-merknr.
      ls_alvdata-aenderer   = ls_qasr-ok_benutzer.
      ls_alvdata-datum      = ls_qasr-ok_datum.
      ls_alvdata-zeit       = ls_qasr-ok_zeit.
      ls_alvdata-ok         = ls_qasr-ok_status.
      ls_alvdata-nicht_ok   = ls_qasr-nok_status.
      ls_alvdata-pruefbemkt = ls_qasr-pruefbemkt.

      IF ls_vorgang_info-workcenter IN p_arbpl.

      ELSE.
        CONTINUE.
      ENDIF.

      APPEND ls_alvdata TO lt_alvdata.
    ENDLOOP.
    lv_probenr = ls_qapp-probenr.
    lv_vorglfnr = ls_qapp-vorglfnr.

  ENDLOOP.

  CLEAR ls_alvdata.

  SORT lt_alvdata BY num prueflos phyprob date time.
  DELETE ADJACENT DUPLICATES FROM lt_alvdata.
  lt_alvdata_old = lt_alvdata.

ENDFORM.                    "daten_lesen

*&---------------------------------------------------------------------*
*&      Form  alv_erzeugen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_erzeugen.

  CALL SCREEN 100.

ENDFORM.                    "alv_erzeugen

*&---------------------------------------------------------------------*
*&      Form  update_checked
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM update_checked.
ENDFORM.                    "update_checked
*&---------------------------------------------------------------------*
*&      Module  INIT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init OUTPUT.

  SET PF-STATUS 'MAIN100'.

  IF g_custom_container IS INITIAL.

    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = 'CUST_CONTROL'.

    CREATE OBJECT grid
      EXPORTING
        i_parent = g_custom_container.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZQM_PRUEFLOSLIST'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = fcat[].

    LOOP AT fcat.

      CASE fcat-fieldname.
        WHEN 'OK'.
          fcat-scrtext_s = 'OK'.
          fcat-scrtext_m = 'OK'.
          fcat-scrtext_l = 'OK'.
          fcat-reptext   = 'OK'.
          fcat-checkbox = 'X'.
          fcat-edit = 'X'.
          fcat-hotspot     = 'X'.
          fcat-outputlen = 6.
        WHEN 'NICHT_OK'.
          IF sy-langu = 'D'.
            fcat-scrtext_s = 'Nicht OK'.
            fcat-scrtext_m = 'Nicht OK'.
            fcat-scrtext_l = 'Nicht OK'.
            fcat-reptext   = 'Nicht OK'.
          ELSE.
            fcat-scrtext_s = 'not OK'.
            fcat-scrtext_m = 'not OK'.
            fcat-scrtext_l = 'not OK'.
            fcat-reptext   = 'not OK'.
          ENDIF.
          fcat-checkbox = 'X'.
          fcat-edit = 'X'.
          fcat-hotspot     = 'X'.
          fcat-outputlen = 6.
        WHEN 'KNOTEN'.
          fcat-no_out = 'X'.
*        WHEN 'MERKMAL'.
*          fcat-no_out = 'X'.

        WHEN 'SAMPLE'.
          fcat-no_out = 'X'.
        WHEN 'ZEIT'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Zeit'.
            fcat-scrtext_s = 'Zeit'.
            fcat-scrtext_m = 'Zeit'.
            fcat-scrtext_l = 'Zeit'.
          ELSE.
            fcat-reptext = 'Time'.
            fcat-scrtext_s = 'Time'.
            fcat-scrtext_m = 'Time'.
            fcat-scrtext_l = 'Time'.
          ENDIF.
        WHEN 'DATUM'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Datum'.
            fcat-scrtext_s = 'Datum'.
            fcat-scrtext_m = 'Datum'.
            fcat-scrtext_l = 'Datum'.
          ELSE.
            fcat-reptext = 'Date'.
            fcat-scrtext_s = 'Date'.
            fcat-scrtext_m = 'Date'.
            fcat-scrtext_l = 'Date'.
          ENDIF.
        WHEN 'DATE'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Datum'.
            fcat-scrtext_s = 'Datum'.
            fcat-scrtext_m = 'Datum'..
            fcat-scrtext_l = 'Datum'.
          ELSE.
            fcat-reptext = 'Date'.
            fcat-scrtext_s = 'Date'.
            fcat-scrtext_m = 'Date'..
            fcat-scrtext_l = 'Date'.
          ENDIF.
        WHEN 'TIME'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Zeit'.
            fcat-scrtext_s = 'Zeit'.
            fcat-scrtext_m = 'Zeit'..
            fcat-scrtext_l = 'Zeit'.
          ELSE.
            fcat-reptext = 'Time'.
            fcat-scrtext_s = 'Time'.
            fcat-scrtext_m = 'Time'..
            fcat-scrtext_l = 'Time'.
          ENDIF.
        WHEN 'Line'.
          IF sy-langu = 'D'.
            fcat-scrtext_s = 'Linie'.
            fcat-scrtext_m = 'Linie'..
            fcat-scrtext_l = 'Linie'.
            fcat-lzero = 'X'.
          ELSE.
            fcat-scrtext_s = 'Line'.
            fcat-scrtext_m = 'Line'..
            fcat-scrtext_l = 'Line'.
            fcat-lzero = 'X'.
          ENDIF.
        WHEN 'BALLENNUMMER'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Ballennummer'.
            fcat-scrtext_s = 'Ballenr'.
            fcat-scrtext_m = 'Ballenr'.
            fcat-scrtext_l = 'Ballenr'.
          ELSE.
            fcat-reptext = 'Balenumber'.
            fcat-scrtext_s = 'Bale Nr'.
            fcat-scrtext_m = 'Bale Nr'.
            fcat-scrtext_l = 'Bale Nr'.
          ENDIF.
*          fcat-no_out = 'X'.
          fcat-no_zero = ''.
        WHEN 'PRUEFBEMKT'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Gerätenummer'.
            fcat-scrtext_s = 'Geräte Nr.'.
            fcat-scrtext_m = 'Gerätenummer'.
            fcat-scrtext_l = 'Gerätenummer'.
          ELSE.
            fcat-reptext = 'Devicenumber'.
            fcat-scrtext_s = 'Device no.'.
            fcat-scrtext_m = 'Devicenumber'.
            fcat-scrtext_l = 'Devicenumber'.
          ENDIF.
        WHEN 'PROBENART'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Probenart'.
            fcat-scrtext_s = 'Probenart'.
            fcat-scrtext_m = 'Probenart'.
            fcat-scrtext_l = 'Probenart'.
          ELSE.
            fcat-reptext = 'Sampletype'.
            fcat-scrtext_s = 'Sampletype'.
            fcat-scrtext_m = 'Sampletype'.
            fcat-scrtext_l = 'Sampletype'.
          ENDIF.
        WHEN 'ERGEBNIS'.
          IF sy-langu = 'D'.
            fcat-reptext = 'Ergebnis'.
            fcat-scrtext_s = 'Ergebnis'.
            fcat-scrtext_m = 'Ergebnis'.
            fcat-scrtext_l = 'Ergebnis'.
          ELSE.
            fcat-reptext = 'Result'.
            fcat-scrtext_s = 'Result'.
            fcat-scrtext_m = 'Result'.
            fcat-scrtext_l = 'Result'.
          ENDIF.
      ENDCASE.
      MODIFY fcat.
    ENDLOOP.

    APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_move_row TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_paste TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_cut TO excl_tb.
    APPEND cl_gui_alv_grid=>mc_fc_loc_append_row TO excl_tb.

    variant-report  = sy-repid.
    CALL METHOD grid->set_table_for_first_display
      EXPORTING
        i_structure_name     = 'ZQM_PRUEFLOSLIST'
        i_save               = 'A'
        is_variant           = variant
        it_toolbar_excluding = excl_tb
      CHANGING
        it_outtab            = lt_alvdata
        it_fieldcatalog      = fcat[].



    CREATE OBJECT event_receiver.
    SET HANDLER event_receiver->handle_double_click      FOR grid.
    SET HANDLER event_receiver->handle_detail_click      FOR grid.
    SET HANDLER event_receiver->handle_hotspot_click     FOR grid.

  ENDIF.

ENDMODULE.                 " INIT  OUTPUT


*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver IMPLEMENTATION.

  METHOD handle_double_click.

    CLEAR ls_alvdata.
    READ TABLE lt_alvdata INDEX e_row-index INTO ls_alvdata.

    DATA: ls_bapi2045d4 TYPE bapi2045d4.
    READ TABLE lt_bapi2045d4 INDEX 3 INTO ls_bapi2045d4.
    CLEAR lt_bapi2045d4.
    APPEND ls_bapi2045d4 TO lt_bapi2045d4.

    DATA: lt_bapiret2 TYPE TABLE OF bapiret2.
    DATA: ls_bapiret2 TYPE bapiret2.


    IF e_column = 'ERGEBNIS' AND ls_alvdata-prueflos IS NOT INITIAL AND ls_alvdata-vornr IS NOT INITIAL.

      CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
        EXPORTING
          insplot                      = ls_alvdata-prueflos
          inspoper                     = ls_alvdata-vornr
          read_insppoints              = 'X'
          read_char_requirements       = 'X'
          read_char_results            = 'X'
          read_sample_results          = 'X'
          read_single_results          = 'X'
*         READ_CHARS_WITH_CLASSES      = 'X'
*         READ_CHARS_WITHOUT_RECORDING = 'X'
*         RES_ORG                      = ' '
*         CHAR_FILTER_NO               = '1   '
*         CHAR_FILTER_TCODE            = 'QE11'
*         MAX_INSPPOINTS               = 100
*         INSPPOINT_FROM               = 0
*         HANDHELD_APPLICATION         = ' '
*         RESULT_COPY                  = ' '
        IMPORTING
          operation                    = ls_vorgang_info
*         INSPPOINT_REQUIREMENTS       =
*         RETURN                       =
        TABLES
          insppoints                   = lt_inspoint
          char_requirements            = lt_requirements
          char_results                 = lt_bapi2045d2
          sample_results               = lt_merkmal
          single_results               = lt_bapi2045d4.

      READ TABLE lt_inspoint INTO ls_inspoint WITH KEY insppoint = ls_alvdata-prob.


      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

      CLEAR ls_merkmal.
      LOOP AT lt_merkmal INTO ls_merkmal
        WHERE inspsample = ls_alvdata-sample
          AND inspchar   = ls_alvdata-merkmal.


        DATA:    lt_fields TYPE TABLE OF sval,
            ls_fields TYPE sval.

        CLEAR lt_fields.
        CLEAR ls_fields.

        ls_fields-tabname = 'QASR'.
        ls_fields-fieldname = 'ORIGINAL_INPUT'.
        ls_fields-value = ls_alvdata-ergebnis.

        APPEND ls_fields TO lt_fields.

        CALL FUNCTION 'POPUP_GET_VALUES'
          EXPORTING
*           NO_VALUE_CHECK  = ' '
            popup_title     = 'Messwertkorrektur'
*           START_COLUMN    = '5'
*           START_ROW       = '5'
          IMPORTING
            returncode      = lv_returncode
          TABLES
            fields          = lt_fields
          EXCEPTIONS
            error_in_fields = 1
            OTHERS          = 2.
        IF lv_returncode = 'A'.
          EXIT.
        ENDIF.

        READ TABLE lt_fields INDEX 1 INTO ls_fields.

        DATA:    ls_sample_results TYPE bapi2045d3.
        DATA: ls_inspection_points TYPE bapi2045l4.
        DATA: lt_inspection_points TYPE STANDARD TABLE OF bapi2045l4,
              lt_sample_results TYPE STANDARD TABLE OF bapi2045d3.

        ls_sample_results-insplot = ls_merkmal-insplot.
        ls_sample_results-insplot = ls_merkmal-insplot.
        ls_sample_results-inspoper = ls_merkmal-inspoper.
        ls_sample_results-inspchar = ls_merkmal-inspchar.
        ls_sample_results-inspsample =  ls_merkmal-inspsample.

        IF ls_merkmal-code1 IS NOT INITIAL.
          ls_sample_results-code1 = ls_fields-value.
          ls_sample_results-code_grp1 = ls_merkmal-code_grp1.
        ELSE.
          ls_sample_results-mean_value = ls_fields-value.
        ENDIF.
        APPEND ls_sample_results TO lt_sample_results.
        .

        CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
          EXPORTING
            insplot              = ls_merkmal-insplot
            inspoper             = ls_merkmal-inspoper
            insppointdata        = ls_inspoint
            handheld_application = ' '
          IMPORTING
            return               = ls_bapiret2
          TABLES
            sample_results       = lt_sample_results.

        IF ls_bapiret2-type = 'E' OR ls_bapiret2-type = 'A'.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
          MESSAGE ls_bapiret2-message TYPE 'S' DISPLAY LIKE 'E'.
*   Fehler beim Anlegen einer eindeutigen Aufgabenplannummer aus Nummernkreis

        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

          IF sy-subrc = 0.
            UPDATE qasr SET ok_benutzer = sy-uname ok_datum = sy-datum ok_zeit = sy-uzeit
              WHERE prueflos = ls_alvdata-prueflos AND vorglfnr = ls_alvdata-knoten AND merknr = ls_alvdata-merkmal AND  probenr = ls_alvdata-sample.
            COMMIT WORK.
            ls_alvdata-aenderer = sy-uname.
            ls_alvdata-datum = sy-datum.
            ls_alvdata-zeit = sy-uzeit.

          ENDIF.
        ENDIF.

      ENDLOOP.
      LOOP AT lt_alvdata INTO ls_alvdata2 WHERE prueflos = ls_alvdata-prueflos
        AND prob = ls_alvdata-prob AND vornr = ls_alvdata-vornr.
        ls_alvdata2 = ls_alvdata.
        MODIFY lt_alvdata FROM ls_alvdata2.
      ENDLOOP.

      CLEAR bdcdata_tab.


      CLEAR bdcdata_wa.
      bdcdata_wa-program = 'SAPMQEEA'.
      bdcdata_wa-dynpro = '0100'.
      bdcdata_wa-dynbegin = 'X'.
      APPEND bdcdata_wa TO bdcdata_tab.

*--->>
      CLEAR bdcdata_wa.
      bdcdata_wa-fnam = 'BDC_CURSOR'.
      bdcdata_wa-fval = 'QALS-PRUEFLOS'.
      APPEND bdcdata_wa TO bdcdata_tab.

      CLEAR bdcdata_wa.
      bdcdata_wa-fnam = 'QALS-PRUEFLOS'.
      bdcdata_wa-fval = ls_alvdata-prueflos.
      APPEND bdcdata_wa TO bdcdata_tab.

      CLEAR bdcdata_wa.
      bdcdata_wa-fnam = 'BDC_CURSOR'.
      bdcdata_wa-fval = 'QAQEE-VORNR'.
      APPEND bdcdata_wa TO bdcdata_tab.

      CLEAR bdcdata_wa.
      bdcdata_wa-fnam = 'QAQEE-VORNR'.
      bdcdata_wa-fval = ls_alvdata-vornr.
      APPEND bdcdata_wa TO bdcdata_tab.

      DATA: lv_time TYPE char8.

      DATA: g_output_time TYPE tims,
      g_hour(2)     TYPE n,
      g_minuts(2)   TYPE n,
      g_seconds(2)  TYPE n,
      c_code(2)     TYPE c.


      g_hour    = ls_alvdata-time(2).
      g_minuts  = ls_alvdata-time+2(2).
      g_seconds = ls_alvdata-time+4(2).

      CONCATENATE g_hour ':' g_minuts ':' g_seconds INTO lv_time.


      DATA: lv_date TYPE char10.

      DATA: lv_day(2)     TYPE n,
      lv_month(2)   TYPE n,
      lv_year(4)  TYPE n.


      lv_year    = ls_alvdata-date(4).
      lv_month  = ls_alvdata-date+4(2).
      lv_day = ls_alvdata-date+6(2).

      CONCATENATE lv_day '.' lv_month '.' lv_year INTO lv_date.
*
      IF ls_alvdata-phyprob IS NOT INITIAL.
        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-PHYNR'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-PHYNR'.
        bdcdata_wa-fval = ls_alvdata-phyprob.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERD1'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERD1'.
        bdcdata_wa-fval = lv_date.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERT1'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERT1'.
        bdcdata_wa-fval = lv_time.
        APPEND bdcdata_wa TO bdcdata_tab.

*        CALL TRANSACTION 'QE24' USING bdcdata_tab
*                             MODE 'A'
*                             UPDATE 'L'.


      ELSE.

        CLEAR bdcdata_wa.

        IF ls_alvdata-slwbez = 'Z02'.
          bdcdata_wa-fnam = 'BDC_CURSOR'.
          bdcdata_wa-fval = 'QAPPD-USERC1'.
          APPEND bdcdata_wa TO bdcdata_tab.

          CLEAR bdcdata_wa.
          bdcdata_wa-fnam = 'QAPPD-USERC1'.
          bdcdata_wa-fval = ls_alvdata-ballennummer.
          APPEND bdcdata_wa TO bdcdata_tab.

        ELSE.
          bdcdata_wa-fnam = 'BDC_CURSOR'.
          bdcdata_wa-fval = 'QAPPD-USERC1'.
          APPEND bdcdata_wa TO bdcdata_tab.


        ENDIF.

        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERC2'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERC2'.
        bdcdata_wa-fval = ls_alvdata-probenart.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.

        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERN2'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERN2'.
        bdcdata_wa-fval = ls_alvdata-line.
        APPEND bdcdata_wa TO bdcdata_tab.

        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERD1'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERD1'.
        bdcdata_wa-fval = lv_date.
        APPEND bdcdata_wa TO bdcdata_tab.

        bdcdata_wa-fnam = 'BDC_CURSOR'.
        bdcdata_wa-fval = 'QAPPD-USERT1'.
        APPEND bdcdata_wa TO bdcdata_tab.

        CLEAR bdcdata_wa.
        bdcdata_wa-fnam = 'QAPPD-USERT1'.
        bdcdata_wa-fval = lv_time.
        APPEND bdcdata_wa TO bdcdata_tab.



      ENDIF.


      CLEAR lt_alvdata.
      PERFORM daten_lesen.
      CALL METHOD grid->refresh_table_display.


    ENDIF.

*    READ TABLE lt_alvdata INDEX e_row-index INTO w_alv.
    CHECK: sy-subrc = 0.
*    SET PARAMETER ID 'IQM' FIELD w_alv-qmnum.
*    CALL TRANSACTION 'QM03' AND SKIP FIRST SCREEN.

  ENDMETHOD.                           "handle_double_click


  METHOD handle_detail_click.


  ENDMETHOD.                    "handle_detail_click


  METHOD handle_hotspot_click.
    IF e_column_id = 'OK' OR e_column_id = 'NICHT_OK'.
      READ TABLE lt_alvdata INTO ls_alvdata INDEX e_row_id.

* Haken-Handling nur OK oder Nicht_OK, nicht beide löschbar wenn bereits ein Wert in DB steht.
      IF e_column_id = 'OK' AND ls_alvdata-ok = ''.
        ls_alvdata-ok = 'X'.
        ls_alvdata-nicht_ok = ''.
        MODIFY lt_alvdata FROM ls_alvdata INDEX e_row_id.
      ELSEIF e_column_id = 'NICHT_OK' AND ls_alvdata-nicht_ok = ''.
        ls_alvdata-ok = ''.
        ls_alvdata-nicht_ok = 'X'.
        MODIFY lt_alvdata FROM ls_alvdata INDEX e_row_id.
      ELSEIF e_column_id = 'NICHT_OK' AND ls_alvdata-nicht_ok = 'X' OR e_column_id = 'OK' AND ls_alvdata-ok = 'X'.
        READ TABLE lt_alvdata_old INTO ls_alvdata_old INDEX e_row_id.
        IF ls_alvdata_old-nicht_ok = '' AND ls_alvdata_old-ok = ' '.
          ls_alvdata-ok = ''.
          ls_alvdata-nicht_ok = ''.

          MODIFY lt_alvdata FROM ls_alvdata INDEX e_row_id.
        ENDIF.
      ENDIF.


* Refresh fix..Scrollposition ALV halten.

      grid->get_scroll_info_via_id(
      IMPORTING
        es_row_no   = l_scroll_row_no
        es_row_info = l_scroll_row_info
        es_col_info = l_scroll_col_info
        ).

* Save info about last selected cell
      grid->get_current_cell(
        IMPORTING
*     e_row     =
*     e_value   =
*     e_col     =
          es_row_id = l_cell_row_id
          es_col_id = l_cell_col_id
          es_row_no = l_cell_row_no
      ).

* Save info about selected rows
      grid->get_selected_rows(
        IMPORTING
          et_index_rows = mt_sel_rows
      ).

* If no row is selected save info about selected cells
      IF mt_sel_rows[] IS INITIAL.
        grid->get_selected_cells_id(
          IMPORTING
            et_cells = mt_sel_cells
        ).
      ENDIF.

      grid->refresh_table_display( i_soft_refresh = i_soft ).

* Restore the saved selection
      IF mt_sel_cells[] IS NOT INITIAL.
        grid->set_selected_cells_id( it_cells = mt_sel_cells   ).
      ELSE.
        grid->set_selected_rows(
          it_index_rows            = mt_sel_rows
*       it_row_no                =
*       is_keep_other_selections =
        ).
      ENDIF.

      grid->set_scroll_info_via_id(
      is_row_info = l_scroll_row_info
      is_col_info = l_scroll_col_info
      is_row_no   = l_scroll_row_no
    ).

* Set focus on previously selected cell
      IF i_set_current = abap_true.
        grid->set_current_cell_via_id(
          is_row_id    = l_cell_row_id
          is_column_id = l_cell_col_id
          is_row_no    = l_cell_row_no ).
      ENDIF.


    ENDIF.

  ENDMETHOD.                    "handle_hotspot_click

ENDCLASS.                    "lcl_event_receiver IMPLEMENTATION


*&---------------------------------------------------------------------*
*&      Module  PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai INPUT.

*   to react on oi_custom_events:
  CALL METHOD cl_gui_cfw=>dispatch.
  CASE sy-ucomm.
    WHEN 'EXIT'.
      PERFORM exit_program.
    WHEN 'SAVE'.
      PERFORM save_status.
    WHEN OTHERS.
*     do nothing
  ENDCASE.

ENDMODULE.                 " PAI  INPUT
*&---------------------------------------------------------------------*
*&      Form  EXIT_PROGRAM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exit_program .
  CALL METHOD g_custom_container->free.
  CALL METHOD cl_gui_cfw=>flush.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDFORM.                    " EXIT_PROGRAM
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN100'.
  SET TITLEBAR 'MAIN100'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  SAVE_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_status .
  CLEAR ls_alvdata.
  CLEAR ls_alvdata_old.



  LOOP AT lt_alvdata INTO ls_alvdata.
    READ TABLE lt_alvdata_old WITH KEY prueflos = ls_alvdata-prueflos knoten = ls_alvdata-knoten merkmal = ls_alvdata-merkmal
        sample = ls_alvdata-sample INTO ls_alvdata_old.
* Etwas hat sich verändert
    IF ls_alvdata_old-ok NE ls_alvdata-ok  OR ls_alvdata_old-nicht_ok NE ls_alvdata-nicht_ok.
      UPDATE qasr SET ok_status = ls_alvdata-ok nok_status = ls_alvdata-nicht_ok ok_benutzer = sy-uname ok_datum = sy-datum ok_zeit = sy-uzeit
          WHERE prueflos = ls_alvdata-prueflos AND vorglfnr = ls_alvdata-knoten AND merknr = ls_alvdata-merkmal AND  probenr = ls_alvdata-sample.
      COMMIT WORK.
      ls_alvdata-aenderer = sy-uname.
      ls_alvdata-datum = sy-datum.
      ls_alvdata-zeit = sy-uzeit.

      MODIFY lt_alvdata FROM ls_alvdata.
    ENDIF.
  ENDLOOP.
  lt_alvdata_old = lt_alvdata.



  lt_alvdata_old = lt_alvdata.

* Refresh fix..Scrollposition ALV halten.

  grid->get_scroll_info_via_id(
  IMPORTING
    es_row_no   = l_scroll_row_no
    es_row_info = l_scroll_row_info
    es_col_info = l_scroll_col_info
    ).

* Save info about last selected cell
  grid->get_current_cell(
    IMPORTING
*     e_row     =
*     e_value   =
*     e_col     =
      es_row_id = l_cell_row_id
      es_col_id = l_cell_col_id
      es_row_no = l_cell_row_no
  ).

* Save info about selected rows
  grid->get_selected_rows(
    IMPORTING
      et_index_rows = mt_sel_rows
  ).

* If no row is selected save info about selected cells
  IF mt_sel_rows[] IS INITIAL.
    grid->get_selected_cells_id(
      IMPORTING
        et_cells = mt_sel_cells
    ).
  ENDIF.

  grid->refresh_table_display( i_soft_refresh = i_soft ).

* Restore the saved selection
  IF mt_sel_cells[] IS NOT INITIAL.
    grid->set_selected_cells_id( it_cells = mt_sel_cells   ).
  ELSE.
    grid->set_selected_rows(
      it_index_rows            = mt_sel_rows
*       it_row_no                =
*       is_keep_other_selections =
    ).
  ENDIF.

  grid->set_scroll_info_via_id(
  is_row_info = l_scroll_row_info
  is_col_info = l_scroll_col_info
  is_row_no   = l_scroll_row_no
).

* Set focus on previously selected cell
  IF i_set_current = abap_true.
    grid->set_current_cell_via_id(
      is_row_id    = l_cell_row_id
      is_column_id = l_cell_col_id
      is_row_no    = l_cell_row_no ).
  ENDIF.


ENDFORM.                    " SAVE_STATUS
