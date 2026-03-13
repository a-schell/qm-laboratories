*&---------------------------------------------------------------------*
*& Report  ZQM_BMS_MAINTAIN_INSPLOT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zqm_bms_maintain_insplot.

TABLES: zbms_cu_linie.         "für select-options
TABLES: zbms_cu_werk.

DATA: gt_prodauf TYPE TABLE OF zbms_prodauf.
DATA: gt_cu_linie         TYPE HASHED TABLE OF zbms_cu_linie
                          WITH UNIQUE KEY linienr.
DATA: gv_only_deleted TYPE abap_bool.

CONSTANTS: gc_paendterm TYPE qprende VALUE '20991231'.
CONSTANTS: gc_paendzeit TYPE qendezeit VALUE '235959'.


SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME.
PARAMETERS pa_werks TYPE zbms_karde-werks OBLIGATORY.
SELECT-OPTIONS: so_linie FOR zbms_cu_linie-linienr.
SELECTION-SCREEN SKIP 1.
PARAMETERS pa_run AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK a.

AT SELECTION-SCREEN.

START-OF-SELECTION.

  IF pa_run = 'X'.
* Process deleted entries first (some inspection lot might need to be deleted)
    gv_only_deleted = abap_true.
    PERFORM get_prodauf_data USING gv_only_deleted.
    PERFORM check_inspection_lot.

* Process active entries
    gv_only_deleted = abap_false.
    PERFORM get_prodauf_data USING gv_only_deleted.
    PERFORM check_inspection_lot.
  ENDIF.

END-OF-SELECTION.


*&---------------------------------------------------------------------*
*&      Form  GET_PRODAUF_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_prodauf_data USING value(gv_only_deleted).
  FREE gt_prodauf.
  FREE gt_cu_linie.

  DATA: lv_cond(72) TYPE c.
  DATA: lt_cond LIKE TABLE OF lv_cond.

  DATA: ls_cu_linie         LIKE LINE OF gt_cu_linie.
  DATA: lt_prodauf TYPE TABLE OF zbms_prodauf.
  DATA: ls_prodauf TYPE zbms_prodauf.

  SELECT * FROM zbms_cu_linie INTO TABLE gt_cu_linie
*  WHERE werks   IN s_werks.
  BYPASSING BUFFER
  WHERE werks = pa_werks AND linienr IN so_linie.


  LOOP AT gt_cu_linie INTO ls_cu_linie.

    FREE lt_cond.
    CONCATENATE 'werks = ''' ls_cu_linie-werks '''' INTO lv_cond.
    APPEND lv_cond TO lt_cond.
    CONCATENATE 'AND linienr = ''' ls_cu_linie-linienr '''' INTO lv_cond.
    APPEND lv_cond TO lt_cond.
    lv_cond = 'AND prodvariant NOT LIKE ''9%'''.
    APPEND lv_cond TO lt_cond.
    IF gv_only_deleted = abap_true.
      lv_cond = 'AND xloevm = ''X'''.
    ELSE.
      lv_cond = 'AND xloevm <> ''X'''.
    ENDIF.
    APPEND lv_cond TO lt_cond.

    SELECT * FROM zbms_prodauf
    INTO TABLE lt_prodauf
    UP TO 1 ROWS
    BYPASSING BUFFER
    WHERE (lt_cond)
    ORDER BY beg_praufdat DESCENDING beg_praufzet DESCENDING.

*    SELECT * FROM zbms_prodauf
*    INTO TABLE lt_prodauf
*    UP TO 1 ROWS
*    WHERE werks = ls_cu_linie-werks AND
*       linienr = ls_cu_linie-linienr AND
*       prodvariant NOT LIKE '9%'
*    ORDER BY beg_praufdat DESCENDING beg_praufzet DESCENDING.

    IF sy-subrc = 0.
      LOOP AT lt_prodauf INTO ls_prodauf.
        INSERT ls_prodauf INTO TABLE gt_prodauf.
      ENDLOOP.
    ENDIF.

    FREE lt_prodauf.
  ENDLOOP.

ENDFORM.                    " GET_PRODAUF_DATA
*&---------------------------------------------------------------------*
*&      Form  CHECK_INSPECTION_LOT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_inspection_lot .

  DATA: ls_prodauf TYPE zbms_prodauf.
  DATA: lt_qals TYPE TABLE OF qals.
  DATA: ls_qals TYPE qals.
  DATA: lx_tabix TYPE sy-tabix.

  DATA: ls_insplot_stats  TYPE bapi2045ss.
  DATA: lt_insplot_stats  TYPE TABLE OF bapi2045ss.
  DATA: ls_insplot_statu  TYPE bapi2045us.
  DATA: lt_insplot_statu  TYPE TABLE OF bapi2045us.
  DATA: ls_bapi2045la     TYPE bapi2045la.
  DATA: lv_zbms_end_praufdat TYPE zbms_end_praufdat.
  DATA: lv_zbms_end_praufzet TYPE zbms_end_praufzet.

  DATA: lv_prueflose_cnt TYPE i.
  DATA: lv_debug_txt TYPE string.
  DATA: lv_debug TYPE abap_bool VALUE abap_false.

  " FIELD-SYMBOLS: <wa_prodauf> TYPE zbms_prodauf.

  LOOP AT gt_prodauf INTO ls_prodauf.
    SHIFT ls_prodauf-umreif LEFT DELETING LEADING space.
    SHIFT ls_prodauf-umreif LEFT DELETING LEADING '0'.
    SHIFT ls_prodauf-umreif RIGHT DELETING TRAILING space.


    " Check if there is a inspection lot aktive (EndDate & Endtime > BegDate & Begintime) / LINIE / WERKS /PRODTYP
    SELECT * FROM qals INTO TABLE lt_qals BYPASSING BUFFER WHERE
        werk = ls_prodauf-werks AND
        art = 'ZLAG-01' AND
        ( paendterm > ls_prodauf-beg_praufdat OR ( paendterm = ls_prodauf-beg_praufdat AND paendzeit >= ls_prodauf-beg_praufzet ) ) AND
        zzlinienr = ls_prodauf-linienr
""                                    ZZBMS_MATERIALNR = ls_prodauf-bmsmatnr AND
""                                    ZZBMS_FARBE = ls_prodauf-farbe AND
 ""                                   ZZBMS_UMREIFUNG_CHAR1 = ls_prodauf-umreif AND
""                                    ZZBMS_AVIVAGE = ls_prodauf-avivage AND
""                                    ZZBMS_LEN_PTYPE_STELLE18 = ls_prodauf-len_ptype_s18 AND
""                                    ZZBMS_LEN_PTYPE_STELLE19 = ls_prodauf-len_ptype_s19 AND
""                                    ZZBMS_LEN_PTYPE_STELLE20 = ls_prodauf-len_ptype_s20 AND
""                                    ZZBMS_MATERIAL_VARIANTE_PROD = ls_prodauf-matvariant
     .

    " Calculate End-Date and End-Time for Qualitätsmeldung
    IF ls_prodauf-beg_praufzet = '000000'.
      lv_zbms_end_praufzet = gc_paendzeit.
      lv_zbms_end_praufdat = ls_prodauf-beg_praufdat - 1.
    ELSE.
      lv_zbms_end_praufdat = ls_prodauf-beg_praufdat.
      lv_zbms_end_praufzet = ls_prodauf-beg_praufzet - 1.
    ENDIF.

    "##########################################################################################################
    " Active Inspection lot exists not canceled
    IF sy-subrc = 0.

      " Stornierte Prüflose entfernen
      LOOP AT lt_qals INTO ls_qals.
        lx_tabix = sy-tabix.
        " Get Inspection lot status
        ls_bapi2045la-langu = sy-langu.

        CLEAR:  lt_insplot_stats,
                ls_insplot_stats.

        CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
          EXPORTING
            number        = ls_qals-prueflos
            language      = ls_bapi2045la
          TABLES
            system_status = lt_insplot_stats
            user_status   = lt_insplot_statu.

        LOOP AT lt_insplot_stats INTO ls_insplot_stats.
          IF ls_insplot_stats-sys_status = 'I0224' OR ls_insplot_stats-sys_status = 'I0232'.
            DELETE lt_qals INDEX lx_tabix.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDLOOP.

* check all inspection lots if product aftrag was deleted - in this case delete inspection lot too
      LOOP AT lt_qals INTO ls_qals.
        IF ls_qals-zzlinienr = ls_prodauf-linienr.
          DATA: tmp_t_prodaufnr TYPE TABLE OF zbms_prodaufnr.
          DATA: tmp_umreif TYPE zbms_umreifung.

          CONCATENATE ' ' ls_qals-zzbms_umreifung_char1 INTO tmp_umreif RESPECTING BLANKS.

          SELECT prodaufnr FROM zbms_prodauf INTO TABLE tmp_t_prodaufnr BYPASSING BUFFER WHERE werks = ls_prodauf-werks AND linienr = ls_qals-zzlinienr AND
          beg_praufdat = ls_qals-pastrterm AND beg_praufzet = ls_qals-pastrzeit AND
          bmsmatnr = ls_qals-zzbms_materialnr AND farbe = ls_qals-zzbms_farbe AND umreif = tmp_umreif AND avivage = ls_qals-zzbms_avivage AND
          len_ptype_s18 = ls_qals-zzbms_len_ptype_stelle18 AND len_ptype_s19 = ls_qals-zzbms_len_ptype_stelle19 AND len_ptype_s20 = ls_qals-zzbms_len_ptype_stelle20 AND
          prodvariant = ls_qals-zzbms_material_variante_prod AND
          xloevm = 'X'.

          IF lines( tmp_t_prodaufnr ) > 0.
            IF lv_debug = abap_true.
              MESSAGE 'Ein gelöschter ProduktAuftrag für eine aktive Prüflose ist gefunden worden. Die Prüflose wird storniert.' TYPE 'I'.
            ENDIF.
            PERFORM cancel_insplot USING ls_qals.
            DELETE TABLE lt_qals FROM ls_qals.
          ENDIF.

        ENDIF.
      ENDLOOP.

      LOOP AT lt_qals INTO ls_qals.
        lx_tabix = sy-tabix.
        " Check Liniennumber
        IF ls_qals-zzlinienr = ls_prodauf-linienr AND ls_prodauf-xloevm <> 'X'.

          IF lv_debug = abap_true.
            CONCATENATE ls_prodauf-linienr ' ' ls_prodauf-werks ' ls_prodauf-BEG_PRAUFDAT: ' ls_prodauf-beg_praufdat ', ls_prodauf-BEG_PRAUFDAT: ' ls_prodauf-beg_praufdat ', ls_prodauf-BEG_PRAUFZET: ' ls_prodauf-beg_praufzet
            ', ls_qals-paendterm: ' ls_qals-paendterm ', ls_qals-paendzeit: ' ls_qals-paendzeit INTO lv_debug_txt RESPECTING BLANKS.
            MESSAGE lv_debug_txt TYPE 'I'.
          ENDIF.

          "1) Active Insp.Lots Check Startdatum (Prodauf) <= Endedatum (Qals)
          IF ( ls_prodauf-beg_praufdat < ls_qals-paendterm ) OR ( ls_prodauf-beg_praufdat = ls_qals-paendterm AND ls_prodauf-beg_praufzet <= ls_qals-paendzeit ).
            IF ( ls_prodauf-beg_praufdat > ls_qals-pastrterm ) OR ( ls_prodauf-beg_praufdat = ls_qals-pastrterm AND ls_prodauf-beg_praufzet > ls_qals-pastrzeit ).
              ls_qals-paendterm = lv_zbms_end_praufdat.
              ls_qals-paendzeit = lv_zbms_end_praufzet.

              " 1. End current Qualitätsmeldung by setting the end date: lv_ZBMS_END_PRAUFDAT lv_ZBMS_END_PRAUFZET
              IF lv_debug = abap_true.
                MESSAGE 'Perform chg_insplot (disable current)' TYPE 'I'.
              ENDIF.
              MESSAGE i051(zqm) WITH ls_qals-prueflos.
              PERFORM chg_insplot USING ls_qals.

              " 2. Create new Qualitätsmeldung with start date: ls_prodauf-beg_praufdat ls_prodauf-beg_praufzet, end date: gv_paendterm gv_PAENDZEIT
              IF lv_debug = abap_true.
                MESSAGE 'Create new inspection lot' TYPE 'I'.
              ENDIF.
              PERFORM cre_insplot USING ls_prodauf.
              lv_prueflose_cnt = lv_prueflose_cnt + 1.

              " if the Qualitätsmeldung starts and ends in the future - delete it
              " in case when datetime is the same do nothing
            ELSEIF ( ls_prodauf-beg_praufdat < ls_qals-pastrterm ) OR ( ls_prodauf-beg_praufdat = ls_qals-pastrterm AND ls_prodauf-beg_praufzet < ls_qals-pastrzeit ).
              IF lv_debug = abap_true.
                MESSAGE 'Deleting inspecion log in the future' TYPE 'I'.
              ENDIF.
              MESSAGE i051(zqm) WITH ls_qals-prueflos.
              PERFORM cancel_insplot USING ls_qals.
            ENDIF.
            "2) Insp.Lots Check Startdatum (Prodauf) > Endedatum (Qals)
          ELSE.
            " 1. Create new Qualitätsmeldung with start date: ls_prodauf-beg_praufdat ls_prodauf-beg_praufzet end date: gv_paendterm gv_PAENDZEIT
            IF lv_debug = abap_true.
              MESSAGE 'Create new inspection lot (no active lots before end date)' TYPE 'I'.
            ENDIF.
            PERFORM cre_insplot USING ls_prodauf.
            lv_prueflose_cnt = lv_prueflose_cnt + 1.
          ENDIF.
        ENDIF.
      ENDLOOP.

      IF lt_qals IS INITIAL AND ls_prodauf-xloevm <> 'X'.
        " Create new inspection lot.
        IF lv_debug = abap_true.
          MESSAGE 'Create new inspection lot (no active not deleted lots exist)' TYPE 'I'.
        ENDIF.
        PERFORM cre_insplot USING ls_prodauf.
        lv_prueflose_cnt = lv_prueflose_cnt + 1.
      ENDIF.
    ELSE.
      IF ls_prodauf-xloevm <> 'X'.
        IF lv_debug = abap_true.
          CLEAR lv_debug_txt.
          CONCATENATE 'Create new inspection lot (no active lots exist). Aufnr: ' ls_prodauf-prodaufnr ', linienr: ' ls_prodauf-linienr ', werk: ' ls_prodauf-werks ', ls_prodauf-BEG_PRAUFDAT: ' ls_prodauf-beg_praufdat
          ', ls_prodauf-BEG_ZET: ' ls_prodauf-beg_praufzet INTO lv_debug_txt RESPECTING BLANKS.
          MESSAGE lv_debug_txt TYPE 'I'.
        ENDIF.

        PERFORM cre_insplot USING ls_prodauf.
        lv_prueflose_cnt = lv_prueflose_cnt + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF lv_prueflose_cnt IS NOT INITIAL.
    MESSAGE i025(zqm) WITH lv_prueflose_cnt.
  ENDIF.
ENDFORM.                    " CHECK_INSPECTION_LOT


*"      "--------------------------------------------------------------------------------------
*"      " Inspection lot workarea
*
*"      " 1.) Step check nothing changed
*"      loop AT lt_qals INTO ls_qals.
*"        lx_tabix = sy-tabix.
*"        if ls_qals-pastrterm = ls_prodauf-beg_praufdat
*"           AND ls_qals-pastrzeit = ls_prodauf-beg_praufzet
*"           AND ls_qals-paendterm = gv_paendterm
*"           AND ls_qals-paendzeit = gv_PAENDZEIT
*"           AND ls_qals-werk = ls_prodauf-werks
*"           AND ls_qals-ART = 'ZLAG-01'
*"           AND ls_qals-zzlinienr = ls_prodauf-linienr
*"           AND ls_qals-zzbms_materialnr = ls_prodauf-bmsmatnr
*"           AND ls_qals-ZZBMS_FARBE = ls_prodauf-farbe
*"           AND ls_qals-ZZBMS_UMREIFUNG_CHAR1 = ls_prodauf-umreif+1(1)
*"           AND ls_qals-ZZBMS_AVIVAGE = ls_prodauf-avivage
*"           AND ls_qals-ZZBMS_LEN_PTYPE_STELLE18 = ls_prodauf-len_ptype_s18
*"           AND ls_qals-ZZBMS_LEN_PTYPE_STELLE19 = ls_prodauf-len_ptype_s19
*"           AND ls_qals-ZZBMS_LEN_PTYPE_STELLE20 = ls_prodauf-len_ptype_s20
*"           AND ls_qals-ZZBMS_MATERIAL_VARIANTE_PROD = LS_PRODAUF-PRODVARIANT.
*"          " Delete inspection lot from Working Table
*"          DELETE gt_prodauf INDEX lx_tabix.
*"        endif.
*"      endloop.
*
*"      " 2.) Step Startdate/time and Enddate/time are in the future and Qals-Zfields are the same
*"      loop AT lt_qals INTO ls_qals.
*"        lx_tabix = sy-tabix.
*"        if ls_qals-pastrterm > ls_prodauf-beg_praufdat
*"          AND ls_qals-pastrzeit > ls_prodauf-beg_praufzet
*"          AND ls_qals-paendterm > ls_prodauf-beg_praufdat
*"          AND ls_qals-paendzeit > ls_prodauf-beg_praufzet
*"          AND ls_qals-werk = ls_prodauf-werks
*"          AND ls_qals-ART = 'ZLAG-01'
*"          AND ls_qals-zzlinienr = ls_prodauf-linienr
*"          AND ls_qals-zzbms_materialnr = ls_prodauf-bmsmatnr
*"          AND ls_qals-ZZBMS_FARBE = ls_prodauf-farbe
*"          AND ls_qals-ZZBMS_UMREIFUNG_CHAR1 = ls_prodauf-umreif+1(1)
*"          AND ls_qals-ZZBMS_AVIVAGE = ls_prodauf-avivage
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE18 = ls_prodauf-len_ptype_s18
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE19 = ls_prodauf-len_ptype_s19
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE20 = ls_prodauf-len_ptype_s20
*"          AND ls_qals-ZZBMS_MATERIAL_VARIANTE_PROD = ls_prodauf-prodvariant.
*"          " set startdate/time and Enddate/time
*"          ls_qals-pastrterm = ls_prodauf-beg_praufdat.
*"          ls_qals-pastrzeit = ls_prodauf-beg_praufzet.
*"          ls_qals-paendterm = gv_paendterm.
*"          ls_qals-paendzeit = gv_PAENDZEIT.
*
*"          if p_test <> 'X'.
*"            " Change Inspection lot
*"            PERFORM chg_insplot USING ls_qals.
*"          else.
*"            " output
*"          endif.
*
*"          DELETE gt_prodauf INDEX lx_tabix.
*"        endif.
*"      endloop.
*
*"      " 3.) Step Startdate/time and Enddate/time are in the future and Qals-Zfields are NOT!!! the same
*"      loop AT lt_qals INTO ls_qals.
*"        lx_tabix = sy-tabix.
*"        if ls_qals-pastrterm > ls_prodauf-beg_praufdat
*"          AND ls_qals-pastrzeit > ls_prodauf-beg_praufzet
*"          AND ls_qals-paendterm > ls_prodauf-beg_praufdat
*"          AND ls_qals-paendzeit > ls_prodauf-beg_praufzet
*"          AND ls_qals-werk = ls_prodauf-werks
*"          AND ls_qals-ART = 'ZLAG-01'
*"          AND ls_qals-zzlinienr = ls_prodauf-linienr
*"          AND ls_qals-zzbms_materialnr <> ls_prodauf-bmsmatnr
*"          AND ls_qals-ZZBMS_FARBE <> ls_prodauf-farbe
*"          AND ls_qals-ZZBMS_UMREIFUNG_CHAR1 <> ls_prodauf-umreif+1(1)
*"          AND ls_qals-ZZBMS_AVIVAGE <> ls_prodauf-avivage
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE18 <> ls_prodauf-len_ptype_s18
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE19 <> ls_prodauf-len_ptype_s19
*"          AND ls_qals-ZZBMS_LEN_PTYPE_STELLE20 <> ls_prodauf-len_ptype_s20
*"          AND ls_qals-ZZBMS_MATERIAL_VARIANTE_PROD <> ls_prodauf-prodvariant.
*
*"          if p_test <> 'X'.
*"            " Cancel Inspection lot
*"            PERFORM cancel_insplot USING ls_qals.
*"            " Create new inspection lot.
*"            PERFORM cre_insplot
*"                        USING
*"                           ls_prodauf.
*"          else.
*"            " output
*"          endif.
*
*"          DELETE gt_prodauf INDEX lx_tabix.
*"        endif.
*"      endloop.
*
*
*
*
*"      " 3.) Step Startdate/time in the past and Enddate/time in the future
*
*
*
*
*
*
"*         if ls_qals-pastrterm > lv_ZBMS_END_PRAUFDAT AND pastrzeit > lv_ZBMS_END_PRAUFZET .
*        " Change Inspection lot
*        if p_test <> 'X'.
*          ls_qals-pastrterm = '30121990'.
*          ls_qals-pastrzeit = '000001'.
*          ls_qals-paendterm = '31121990'.
*          ls_qals-paendzeit = '000001'.
*
*          PERFORM chg_insplot USING ls_qals.
*        endif.
*
*        DELETE gt_prodauf INDEX lx_tabix.
*      endloop.
*      " Folge inspection lot exists.
*      loop AT lt_qals INTO ls_qals WHERE WERK = ls_prodauf-werks AND ART = 'ZLAG-01' AND PAENDTERM >= ls_prodauf-beg_praufdat AND PAENDZEIT >= ls_prodauf-beg_praufzet AND ZZLINIENR = ls_prodauf-linienr AND
*                                         ZZBMS_MATERIALNR = ls_prodauf-bmsmatnr AND ZZBMS_FARBE = ls_prodauf-farbe AND ZZBMS_UMREIFUNG_CHAR1 = ls_prodauf-umreif AND ZZBMS_AVIVAGE = ls_prodauf-avivage AND
*                                         ZZBMS_LEN_PTYPE_STELLE18 = ls_prodauf-len_ptype_s18 AND ZZBMS_LEN_PTYPE_STELLE19 = ls_prodauf-len_ptype_s19 AND ZZBMS_LEN_PTYPE_STELLE20 = ls_prodauf-len_ptype_s20 AND
*                                         ZZBMS_MATERIAL_VARIANTE_PROD = ls_prodauf-matvariant.
*
*
*
*        DELETE gt_prodauf INDEX lx_tabix.
*      endloop.

*&---------------------------------------------------------------------*
*&      Form  CHG_INSPLOT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM chg_insplot USING wa_qals TYPE qals.
  DATA: ls_qals_out TYPE qals.
  DATA: ls_rmqed TYPE rmqed.
  DATA: lv_prueflos TYPE qplos.
  DATA: lv_subrc LIKE sy-subrc.


  ls_rmqed-dbs_steuer  = '02'.
  ls_rmqed-dbs_flag    = 'X'.
  ls_rmqed-dbs_edunk   = 'X'.
  ls_rmqed-dbs_fdunk   = 'X'.
  ls_rmqed-dbs_noerr   = 'X'.
  ls_rmqed-dbs_nowrn   = 'X'.
  ls_rmqed-dbs_noauf   = 'X'.
  ls_rmqed-dbs_planzuo = 'X'.
  ls_rmqed-dbs_subrc   = 'X'.

  CALL FUNCTION 'QPL1_INSPECTION_LOT_CREATE'
    EXPORTING
      qals_imp   = wa_qals
      rmqed_imp  = ls_rmqed
    IMPORTING
      e_prueflos = lv_prueflos
      e_qals     = ls_qals_out
      subrc      = lv_subrc.
  IF lv_subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e029(zqm) RAISING error.

  ELSE.
    CALL FUNCTION 'QPL1_UPDATE_MEMORY'
      EXPORTING
        i_qals  = ls_qals_out
        i_updkz = 'U'
        i_rmqed = ls_rmqed.
  ENDIF.

  CALL FUNCTION 'QPL1_INSPECTION_LOTS_POSTING'.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  IF sy-subrc IS INITIAL.
    WAIT UP TO 5 SECONDS.
    MESSAGE i004(zqm_prlos_msg) WITH lv_prueflos RAISING error.
  ENDIF.

  WAIT UP TO 15 SECONDS.
  "END Change

*  PERFORM validate_insplot USING lv_prueflos.

ENDFORM.                    " CHG_INSPLOT

*&---------------------------------------------------------------------*
*&      Form  CHG_INSPLOT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_insplot USING ls_prodauf TYPE zbms_prodauf.
  DATA: ls_qals TYPE qals.
  DATA: ls_qals_out TYPE qals.
  DATA: ls_rmqed TYPE rmqed.
  DATA: ls_zbms_material_sz TYPE zbms_material_sz.
  DATA: lv_prueflos TYPE qplos.
  DATA: lv_plnnr TYPE plnnr.
  DATA: ls_plko TYPE plko.
  DATA: lv_subrc LIKE sy-subrc.


  "Stammdaten aus BMS Materialstamm SZ lesen
  SELECT SINGLE * FROM zbms_material_sz INTO ls_zbms_material_sz BYPASSING BUFFER WHERE werks = ls_prodauf-werks
                            AND bmsmatnr = ls_prodauf-bmsmatnr
                            AND farbe = ls_prodauf-farbe
                            AND umreif = ls_prodauf-umreif+1(1)
                            AND avivage = ls_prodauf-avivage
                            AND len_ptype_s18 = ls_prodauf-len_ptype_s18
                            AND len_ptype_s19 = ls_prodauf-len_ptype_s19
                            AND len_ptype_s20 = ls_prodauf-len_ptype_s20
                            AND prodvariant = ls_prodauf-prodvariant
                            AND xloevm <> 'X'.

  "BEGIN ANLEGEN

  "ls_qals-ktextlos   = 'Fiori Prüflos'.
  ls_qals-matnr      = '000000000071006536'.
  ls_qals-art        = 'ZLAG-01'.
  ls_qals-herkunft   = '89'.
  ls_qals-losmenge   = 100000.
  ls_qals-mengeneinh = 'K13'.
  ls_qals-stat13     = ' '.
  ls_qals-stat07     = 'X'.
  ls_qals-werk       = ls_prodauf-werks.

  SELECT SINGLE * FROM plko INTO ls_plko BYPASSING BUFFER WHERE plnnr EQ ls_zbms_material_sz-plnnr
                                           AND statu = '4'
                                           AND werks = ls_prodauf-werks
                                           AND loekz <> 'X'.


* If nothing was found - return from function without error to allow other entries to be allocated
  IF sy-subrc <> 0.
    MESSAGE i011(zqm_prlos_msg) WITH ls_prodauf-prodaufnr.
    RETURN.
  ENDIF.


  ls_qals-selmatnr = ls_qals-matnr.
  ls_qals-selpplverw = ls_plko-verwe.
  ls_qals-selwerk = ls_plko-werks.
  ls_qals-zaehl1 = ls_plko-zaehl.

  ls_qals-ppkztlzu = '0'.

  ls_qals-zzlinienr  = ls_prodauf-linienr.
  ls_qals-zzbms_materialnr = ls_prodauf-bmsmatnr.
  ls_qals-zzbms_farbe       = ls_prodauf-farbe.
  ls_qals-zzbms_umreifung_char1      = ls_prodauf-umreif+1(1).
  ls_qals-zzbms_avivage     = ls_prodauf-avivage.
  ls_qals-zzbms_len_ptype_stelle18   = ls_prodauf-len_ptype_s18.
  ls_qals-zzbms_len_ptype_stelle19   = ls_prodauf-len_ptype_s18.
  ls_qals-zzbms_len_ptype_stelle20   = ls_prodauf-len_ptype_s18.
  ls_qals-zzbms_material_variante_prod = ls_prodauf-prodvariant.
  ls_qals-plnty      = ls_plko-plnty.
  ls_qals-plnnr      = ls_plko-plnnr.
  ls_qals-plnal      = ls_plko-plnal.
  ls_qals-pplverw    = ls_plko-verwe.
  ls_qals-zaehl      = ls_plko-zaehl.
  ls_qals-slwbez     = ls_plko-slwbez.
  ls_qals-pastrterm  = ls_prodauf-beg_praufdat.
  ls_qals-pastrzeit  = ls_prodauf-beg_praufzet.
  ls_qals-paendterm  = gc_paendterm.
  ls_qals-paendzeit  = gc_paendzeit.
  ls_qals-gueltigab  = ls_qals-pastrterm.

  ls_rmqed-dbs_steuer  = '01'.
  ls_rmqed-dbs_flag    = 'X'.
  ls_rmqed-dbs_edunk   = 'X'.
  ls_rmqed-dbs_fdunk   = 'X'.
  ls_rmqed-dbs_noerr   = 'X'.
  ls_rmqed-dbs_nowrn   = 'X'.
  ls_rmqed-dbs_noauf   = 'X'.
  ls_rmqed-dbs_planzuo = 'X'.
  ls_rmqed-dbs_subrc   = 'X'.

  CALL FUNCTION 'QPL1_INSPECTION_LOT_CREATE'
    EXPORTING
      qals_imp   = ls_qals
      rmqed_imp  = ls_rmqed
    IMPORTING
      e_prueflos = lv_prueflos
      e_qals     = ls_qals_out
      subrc      = lv_subrc.
  IF lv_subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e029(zqm) RAISING error.

  ELSE.
    CALL FUNCTION 'QPL1_UPDATE_MEMORY'
      EXPORTING
        i_qals  = ls_qals_out
        i_updkz = 'I'
        i_rmqed = ls_rmqed.
  ENDIF.

  CALL FUNCTION 'QPL1_INSPECTION_LOTS_POSTING'.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.


  WAIT UP TO 5 SECONDS.

*    cancel inspection plan if data no matches Stammdaten
  DATA: lv_validate_status TYPE abap_bool VALUE abap_false.
  PERFORM validate_insplot USING lv_prueflos CHANGING lv_validate_status.
  IF lv_validate_status = abap_false.
    DATA: ls_qals_remove TYPE qals.
    SELECT SINGLE * FROM qals INTO ls_qals_remove WHERE prueflos = lv_prueflos.
    IF sy-subrc = 0.
      MESSAGE i058(zqm) WITH ls_qals_remove-prueflos.
      PERFORM cancel_insplot USING ls_qals_remove.
      PERFORM send_notification USING ls_qals_remove-prueflos.
    ENDIF.
  ENDIF.

  WAIT UP TO 15 SECONDS.

ENDFORM.                    " CHG_INSPLOT
*&---------------------------------------------------------------------*
*&      Form  CANCEL_INSPLOT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_QALS  text
*----------------------------------------------------------------------*
FORM cancel_insplot  USING    p_ls_qals.
  DATA: lv_stafo LIKE qals-stafo.


  CALL FUNCTION 'QPL1_INSPECTION_LOT_CANCEL'
    EXPORTING
      i_qals             = p_ls_qals
      i_dialog           = ' '
      i_check_only       = ' '
    IMPORTING
      e_stafo            = lv_stafo
    EXCEPTIONS
      x_lot_not_canceled = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    "Implement suitable error handling here
  ENDIF.

  COMMIT WORK.

  WAIT UP TO 15 SECONDS.

ENDFORM.                    " CANCEL_INSPLOT


*&---------------------------------------------------------------------*
*&      Form  validate_insplot
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PRUEFLOS text
*----------------------------------------------------------------------*
FORM validate_insplot  USING    p_prueflos
                       CHANGING p_validate_status.

  DATA lv_plnnr TYPE plnnr.
  DATA lv_aufpl TYPE co_aufpl.

  DATA lv_total_prueflos TYPE i.
  DATA lv_total_stammdaten TYPE i.

  SELECT SINGLE plnnr aufpl FROM qals INTO (lv_plnnr, lv_aufpl) WHERE prueflos = p_prueflos.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e050(zqm) RAISING error.
    RETURN.
  ENDIF.

  SELECT COUNT(*) FROM afvc AS a INNER JOIN
  plmk AS p ON a~plnkn = p~plnkn INTO lv_total_stammdaten
  WHERE p~plnnr = lv_plnnr AND p~loekz <> 'X' AND a~plnnr = lv_plnnr AND a~aufpl = lv_aufpl.

  SELECT COUNT(*) FROM qamv INTO lv_total_prueflos WHERE prueflos = p_prueflos.

  IF lv_total_prueflos <> lv_total_stammdaten.
    MESSAGE i056(zqm) WITH p_prueflos lv_total_prueflos lv_total_stammdaten.
    p_validate_status = abap_false.
  ELSE.
    MESSAGE i057(zqm) WITH p_prueflos lv_total_prueflos lv_total_stammdaten.
    p_validate_status = abap_true.
  ENDIF.

ENDFORM.                    "check_insplot

*&---------------------------------------------------------------------*
*&      Form  send_notification
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PRUEFLOS text
*----------------------------------------------------------------------*
FORM send_notification USING lv_prueflos.
  DATA: lt_mailsubject     TYPE sodocchgi1.
  DATA: lt_mailrecipients  TYPE STANDARD TABLE OF somlrec90 WITH HEADER LINE.
  DATA: lt_mailtxt         TYPE STANDARD TABLE OF soli      WITH HEADER LINE.

  lt_mailrecipients-rec_type  = 'U'.
  lt_mailrecipients-receiver = 'a.shelkovich@lenzing.com'.
  APPEND lt_mailrecipients .
  CLEAR lt_mailrecipients .

  lt_mailsubject-obj_name = 'TEST'.
  lt_mailsubject-obj_langu = sy-langu.
  lt_mailsubject-obj_descr = 'Prüflos wurde falsch angelegt'.

  CONCATENATE `Prüflos ` lv_prueflos ` wurder falsch angelegt und wurde storniert.` INTO lt_mailtxt.
  APPEND lt_mailtxt. CLEAR lt_mailtxt.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
    EXPORTING
      document_data              = lt_mailsubject
    TABLES
      object_content             = lt_mailtxt
      receivers                  = lt_mailrecipients
    EXCEPTIONS
      too_many_receivers         = 1
      document_not_sent          = 2
      document_type_not_exist    = 3
      operation_no_authorization = 4
      parameter_error            = 5
      x_error                    = 6
      enqueue_error              = 7
      OTHERS                     = 8.
  IF sy-subrc EQ 0.
    COMMIT WORK.
*   Push mail out from SAP outbox
    SUBMIT rsconn01 WITH mode = 'INT' AND RETURN.
  ENDIF.
ENDFORM.                    "send_notification
