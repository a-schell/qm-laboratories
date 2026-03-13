FUNCTION zqm_act_insplot_chg_status.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(INSPLOT) TYPE  QALS
*"     VALUE(INSPLOT_NEW) TYPE  QALS OPTIONAL
*"     VALUE(STATUS) TYPE  ZQM_INSPLOT_STATUS OPTIONAL
*"     VALUE(DIALOG) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     REFERENCE(EX_INSPLOT) TYPE  ZQM_ACT_INSPLOT_TT
*"  EXCEPTIONS
*"      ERROR_STATUS
*"      ERROR_DELETE
*"      ERROR_INSERT
*"      ERROR_SATZ_DA
*"      ABBRUCH_USER
*"      ERROR_DATA
*"      ERROR_UEBERSCHNEIDUNG
*"      ERROR_UNSOLVEABLE
*"----------------------------------------------------------------------


exit.

* ------------------------------------------------------------------- *
  IF insplot IS INITIAL.
    RAISE error_status.
  ENDIF.

* ------------------------------------------------------------------- *
  DATA:  lt_zqm_act_insplot  TYPE STANDARD TABLE OF  zqm_act_insplot,
* ---
         ls_zqm_act_insplot  TYPE  zqm_act_insplot,
         lv_status           TYPE  zqm_insplot_status,
         lv_ueberschneidung  TYPE  flag,
         lv_temp             TYPE  flag,
         lv_startx           TYPE  flag,
         lv_endx             TYPE  flag,

* ---
         timest_neu_von      TYPE  timestamp,
         timest_neu_bis      TYPE  timestamp,
         timest_db_von       TYPE  timestamp,
         timest_db_bis       TYPE  timestamp,
         tz                  TYPE  tzonref-tzone.
  DATA: lv_antwort TYPE char1.


  CLEAR: lt_zqm_act_insplot[],
         ls_zqm_act_insplot,
         lv_status,
         lv_ueberschneidung.


* ------------------------------------------------------------------- *
* ---> Status = D aktuellen Prüflos Beenden
  IF status = 'D'.

    SELECT SINGLE * FROM zqm_act_insplot INTO ls_zqm_act_insplot
                   WHERE  werks        =  insplot-werk
                     AND  bms_linienr  =  insplot-zzlinienr
*                     AND  status       =  'A'
                     AND  pastrterm    =  insplot-pastrterm
                     AND  pastrzeit    =  insplot-pastrzeit
                     AND  paendterm    =  insplot-paendterm
                     AND  paendzeit    =  insplot-paendzeit.
*                     AND  prueflos     =  insplot-prueflos.

* ---> daten gefunden
    IF sy-subrc = 0.
* ---> alten Satz Löschen
      DELETE  zqm_act_insplot  FROM ls_zqm_act_insplot.
      IF sy-subrc = 4.
*        RAISE error_delete.
      ENDIF.

* ---> neue Daten versorgen
      ls_zqm_act_insplot-status = 'D'.
      ls_zqm_act_insplot-paendterm = sy-datum.
      ls_zqm_act_insplot-paendzeit = sy-uzeit.
      ls_zqm_act_insplot-mandt = insplot-mandant.
      ls_zqm_act_insplot-werks = insplot-werk.

* ---> neuen 'Beendeten' Satz Schreiben
      INSERT INTO zqm_act_insplot VALUES ls_zqm_act_insplot.

      IF sy-subrc = 4.
*        RAISE error_insert.
      ENDIF.
    ELSE.
      RAISE error_data.
    ENDIF.
    EXIT.
  ELSE.
* !!!    RAISE ERROR_DATA.
  ENDIF.

* ------------------------------------------------------------------- *
  SELECT * FROM zqm_act_insplot INTO TABLE lt_zqm_act_insplot
                 WHERE  werks        =  insplot-werk
                   AND  bms_linienr  =  insplot-zzlinienr.
*                   AND  status       =  'A'.

  IF sy-subrc = 4.
    lv_ueberschneidung = abap_false.
  ENDIF.

  LOOP AT lt_zqm_act_insplot INTO ls_zqm_act_insplot.

    IF ls_zqm_act_insplot-pastrterm = insplot-pastrterm AND
       ls_zqm_act_insplot-paendterm = insplot-paendterm AND
       ls_zqm_act_insplot-pastrzeit = insplot-pastrzeit AND
       ls_zqm_act_insplot-paendzeit = insplot-paendzeit.
* ---> genau der gleiche satz ist schon vorhanden - Update
      MOVE-CORRESPONDING insplot TO ls_zqm_act_insplot.
      ls_zqm_act_insplot-mandt          =  insplot-mandant.
      ls_zqm_act_insplot-werks          =  insplot-werk.
      ls_zqm_act_insplot-ktextlos       =  insplot-ktextlos.

      ls_zqm_act_insplot-bms_linienr    =  insplot-zzlinienr.
      ls_zqm_act_insplot-farbe          =  insplot-zzbms_farbe.
      ls_zqm_act_insplot-bmsmatnr       =  insplot-zzbms_materialnr.
      ls_zqm_act_insplot-umreif         =  insplot-zzbms_umreifung_char1.
      ls_zqm_act_insplot-avivage        =  insplot-zzbms_avivage.
      ls_zqm_act_insplot-len_ptype_s18  =  insplot-zzbms_len_ptype_stelle18.
      ls_zqm_act_insplot-len_ptype_s19  =  insplot-zzbms_len_ptype_stelle19.
      ls_zqm_act_insplot-len_ptype_s20  =  insplot-zzbms_len_ptype_stelle20.
      ls_zqm_act_insplot-prodvariant    =  insplot-zzbms_material_variante_prod.
      CONCATENATE ls_zqm_act_insplot-bmsmatnr
                  ls_zqm_act_insplot-umreif
                  ls_zqm_act_insplot-avivage
                  ls_zqm_act_insplot-len_ptype_s18
                  ls_zqm_act_insplot-len_ptype_s19
                  ls_zqm_act_insplot-len_ptype_s20
             INTO ls_zqm_act_insplot-len_ptype_24.

      ls_zqm_act_insplot-aedat        =  sy-datum.
      ls_zqm_act_insplot-aezet        =  sy-uzeit.
      ls_zqm_act_insplot-aenam        =  sy-uname.
      MODIFY zqm_act_insplot FROM ls_zqm_act_insplot.
      IF sy-subrc <> 0.
*    MESSAGE i403(zqm).
        sy-msgid = 'ZQM'.
        sy-msgno = '404'.
        RAISE error_satz_da.
      ENDIF.
      RETURN.
    ENDIF.


    IF ls_zqm_act_insplot-pastrzeit IS INITIAL.
      ls_zqm_act_insplot-pastrzeit = '000001'.
      lv_startx = abap_true.
    ENDIF.
    IF ls_zqm_act_insplot-paendzeit IS INITIAL.
      ls_zqm_act_insplot-paendzeit = '235959'.
      lv_endx = abap_true.
    ENDIF.

* ------------------------------------------------------------------- *
* ---> das funktioniert nur mit einem Timestamp
    CONVERT DATE             insplot-pastrterm
            TIME             insplot-pastrzeit
            INTO TIME STAMP  timest_neu_von
            TIME ZONE        tz.

    CONVERT DATE             insplot-paendterm
            TIME             insplot-paendzeit
            INTO TIME STAMP  timest_neu_bis
            TIME ZONE        tz.


    CONVERT DATE             ls_zqm_act_insplot-pastrterm
            TIME             ls_zqm_act_insplot-pastrzeit
            INTO TIME STAMP  timest_db_von
            TIME ZONE        tz.

    CONVERT DATE             ls_zqm_act_insplot-paendterm
            TIME             ls_zqm_act_insplot-paendzeit
            INTO TIME STAMP  timest_db_bis
            TIME ZONE        tz.



*            alt
*          /-----------/
*                 /------------/
*                      neu
    IF ( timest_neu_von BETWEEN timest_db_von AND timest_db_bis ) AND
       timest_neu_bis NOT BETWEEN timest_db_von AND timest_db_bis.
      lv_temp = abap_true.
    ENDIF.

*         alt
*       /--------/
*   /------/
*     neu
    IF ( timest_neu_bis BETWEEN timest_db_von AND timest_db_bis ) AND
        timest_neu_von NOT BETWEEN timest_db_von AND timest_db_bis.
      "Meldung ausgeben: Überlappung Vorhanden, bitte manuell Pflegen!
      IF dialog = abap_false.
        ex_insplot = lt_zqm_act_insplot[].
*        MOVE-CORRESPONDING ls_zqm_act_insplot TO ex_insplot.
*        MOVE: ls_zqm_act_insplot-werks TO ex_insplot-werk,
*              ls_zqm_act_insplot-bms_linienr TO ex_insplot-zzlinienr.
        RAISE error_unsolveable.
      ENDIF.
      MESSAGE i406(zqm).
      RAISE abbruch_user.

    ENDIF.

*                 alt
*    /------------------------------/
*         /------/
*           neu
    IF ( timest_neu_von BETWEEN timest_db_von AND timest_db_bis ) AND
        timest_neu_bis BETWEEN timest_db_von AND timest_db_bis.
      "Meldung ausgeben: Überlappung Vorhanden, bitte manuell Pflegen!
      IF dialog = abap_false.
        ex_insplot = lt_zqm_act_insplot[].
*        MOVE-CORRESPONDING ls_zqm_act_insplot TO ex_insplot.
*        MOVE: ls_zqm_act_insplot-werks TO ex_insplot-werk,
*              ls_zqm_act_insplot-bms_linienr TO ex_insplot-zzlinienr.
        RAISE error_unsolveable.
      ENDIF.
      MESSAGE i406(zqm).
      RAISE abbruch_user.
    ENDIF.

*           alt
*        /-------/
*    /-------------------/
*             neu
    IF ( timest_db_von BETWEEN timest_neu_von AND timest_neu_bis ) AND
      timest_db_bis BETWEEN timest_neu_von AND timest_neu_bis.
      "Meldung ausgeben: Überlappung Vorhanden, bitte manuell Pflegen!
      IF dialog = abap_false.
        ex_insplot = lt_zqm_act_insplot[].
*        MOVE-CORRESPONDING ls_zqm_act_insplot TO ex_insplot.
*        MOVE: ls_zqm_act_insplot-werks TO ex_insplot-werk,
*              ls_zqm_act_insplot-bms_linienr TO ex_insplot-zzlinienr.
        RAISE error_unsolveable.
      ENDIF.
      MESSAGE i406(zqm).
      RAISE abbruch_user.
    ENDIF.

    IF lv_startx EQ abap_true.
      CLEAR: ls_zqm_act_insplot-pastrzeit.
    ENDIF.
    IF lv_endx EQ abap_true.
      CLEAR: ls_zqm_act_insplot-paendzeit.
    ENDIF.

    IF lv_temp EQ abap_false.
      DELETE TABLE lt_zqm_act_insplot FROM ls_zqm_act_insplot.
    ENDIF.

    IF lv_temp EQ abap_true.
      lv_ueberschneidung = abap_true.
    ENDIF.
    CLEAR: lv_temp.
    CLEAR: lv_startx.
    CLEAR: lv_endx.
  ENDLOOP.

** ---> Fällt der NEUE Satz in den Zeitraum eines ALTEN ein ?
*  IF timest_neu_von BETWEEN timest_db_von AND timest_db_bis OR
*     timest_neu_bis BETWEEN timest_db_von AND timest_db_bis.
*    lv_ueberschneidung = abap_true.
*  ENDIF.
*
** ---> Fällt der ALTE Satz in den Zeitraum des NEUEN  ein ?
*  IF timest_db_von BETWEEN timest_neu_von AND timest_neu_bis OR
*     timest_db_bis BETWEEN timest_neu_von AND timest_neu_bis.
*    lv_ueberschneidung = abap_true.
*  ENDIF.
** ------------------------------------------------------------------- *





  IF  lv_ueberschneidung = abap_true.

* popup
    IF dialog = abap_false.
      ex_insplot = lt_zqm_act_insplot[].
*      MOVE-CORRESPONDING ls_zqm_act_insplot TO ex_insplot.
*      MOVE: ls_zqm_act_insplot-werks TO ex_insplot-werk,
*            ls_zqm_act_insplot-bms_linienr TO ex_insplot-zzlinienr.
      RAISE error_ueberschneidung.
    ENDIF.


    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
*       TITLEBAR                    = ' '
*       DIAGNOSE_OBJECT             = ' '
        text_question               = 'Soll das Prüflos beendet und ein neues angelegt werden?'(003)
        text_button_1               = 'Ja'(004)
*       ICON_BUTTON_1               = ' '
        text_button_2               = 'Nein'(005)
*       ICON_BUTTON_2               = ' '
*       DEFAULT_BUTTON              = '1'
*       DISPLAY_CANCEL_BUTTON       = 'X'
*       USERDEFINED_F1_HELP         = ' '
*       START_COLUMN                = 25
*       START_ROW                   = 6
*       POPUP_TYPE                  =
*       IV_QUICKINFO_BUTTON_1       = ' '
*       IV_QUICKINFO_BUTTON_2       = ' '
     IMPORTING
       answer                      = lv_antwort
*     TABLES
*       PARAMETER                   =
     EXCEPTIONS
       text_not_found              = 1
       OTHERS                      = 2
              .
    IF lv_antwort <> '1'.
*      exit.
      RAISE abbruch_user.
    ENDIF.
* ---> alten satz Löschen
    LOOP AT lt_zqm_act_insplot INTO ls_zqm_act_insplot.
      DELETE  zqm_act_insplot  FROM ls_zqm_act_insplot.
      IF sy-subrc = 4.
        RAISE error_delete.
      ENDIF.

* ------------------------------------------------------------------- *
* ---> alten Satz mit neuem Ende Datum/Zeit schreiben
      ls_zqm_act_insplot-status     =  'E'.
      ls_zqm_act_insplot-paendterm  =  insplot-pastrterm.
      ls_zqm_act_insplot-paendzeit  =  insplot-pastrzeit - 1.
      INSERT INTO zqm_act_insplot VALUES ls_zqm_act_insplot.
      IF sy-subrc = 4.
* ---> sollte der satz schon da sein muss es trotzdem weiter gehen !
*      RAISE error_insert.
      ENDIF.

* ------------------------------------------------------------------- *
* ---> neuen Satz mit geänderten Start Datum/Zeit Speichern
      MOVE-CORRESPONDING insplot TO ls_zqm_act_insplot.
      ls_zqm_act_insplot-mandt          =  insplot-mandant.
      ls_zqm_act_insplot-werks          =  insplot-werk.
      ls_zqm_act_insplot-ktextlos       =  insplot-ktextlos.

      ls_zqm_act_insplot-bms_linienr    =  insplot-zzlinienr.
      ls_zqm_act_insplot-farbe          =  insplot-zzbms_farbe.
      ls_zqm_act_insplot-bmsmatnr       =  insplot-zzbms_materialnr.
      ls_zqm_act_insplot-umreif         =  insplot-zzbms_umreifung_char1.
      ls_zqm_act_insplot-avivage        =  insplot-zzbms_avivage.
      ls_zqm_act_insplot-len_ptype_s18  =  insplot-zzbms_len_ptype_stelle18.
      ls_zqm_act_insplot-len_ptype_s19  =  insplot-zzbms_len_ptype_stelle19.
      ls_zqm_act_insplot-len_ptype_s20  =  insplot-zzbms_len_ptype_stelle20.
      ls_zqm_act_insplot-prodvariant    =  insplot-zzbms_material_variante_prod.
      CONCATENATE ls_zqm_act_insplot-bmsmatnr
                  ls_zqm_act_insplot-umreif
                  ls_zqm_act_insplot-avivage
                  ls_zqm_act_insplot-len_ptype_s18
                  ls_zqm_act_insplot-len_ptype_s19
                  ls_zqm_act_insplot-len_ptype_s20
             INTO ls_zqm_act_insplot-len_ptype_24.

      ls_zqm_act_insplot-status       = 'A'.
      ls_zqm_act_insplot-aedat        =  sy-datum.
      ls_zqm_act_insplot-aezet        =  sy-uzeit.
      ls_zqm_act_insplot-aenam        =  sy-uname.
      INSERT INTO zqm_act_insplot VALUES ls_zqm_act_insplot.
      IF sy-subrc = 4.
        RAISE error_insert.
      ENDIF.
    ENDLOOP.

*    COMMIT WORK AND WAIT.
  ENDIF.


* ------------------------------------------------------------------- *
* ---> Satz noch nicht da oder keine überschneidung
  IF  lv_ueberschneidung = abap_false.
*    break: extjaw.
    MOVE-CORRESPONDING insplot TO ls_zqm_act_insplot.
    ls_zqm_act_insplot-mandt          =  insplot-mandant.
    ls_zqm_act_insplot-werks          =  insplot-werk.
    ls_zqm_act_insplot-ktextlos       =  insplot-ktextlos.

    ls_zqm_act_insplot-bms_linienr    =  insplot-zzlinienr.
    ls_zqm_act_insplot-farbe          =  insplot-zzbms_farbe.
    ls_zqm_act_insplot-bmsmatnr       =  insplot-zzbms_materialnr.
    ls_zqm_act_insplot-umreif         =  insplot-zzbms_umreifung_char1.
    ls_zqm_act_insplot-avivage        =  insplot-zzbms_avivage.
    ls_zqm_act_insplot-len_ptype_s18  =  insplot-zzbms_len_ptype_stelle18.
    ls_zqm_act_insplot-len_ptype_s19  =  insplot-zzbms_len_ptype_stelle19.
    ls_zqm_act_insplot-len_ptype_s20  =  insplot-zzbms_len_ptype_stelle20.
    ls_zqm_act_insplot-prodvariant    =  insplot-zzbms_material_variante_prod.
    CONCATENATE ls_zqm_act_insplot-bmsmatnr
                ls_zqm_act_insplot-umreif
                ls_zqm_act_insplot-avivage
                ls_zqm_act_insplot-len_ptype_s18
                ls_zqm_act_insplot-len_ptype_s19
                ls_zqm_act_insplot-len_ptype_s20
           INTO ls_zqm_act_insplot-len_ptype_24.

    ls_zqm_act_insplot-status       = 'A'.
    ls_zqm_act_insplot-erdat        = sy-datum.
    ls_zqm_act_insplot-erzet        = sy-uzeit.
    ls_zqm_act_insplot-ernam        = sy-uname.
    ls_zqm_act_insplot-aedat        =  sy-datum.
    ls_zqm_act_insplot-aezet        =  sy-uzeit.
    ls_zqm_act_insplot-aenam        =  sy-uname.

    INSERT INTO zqm_act_insplot VALUES ls_zqm_act_insplot.
    IF sy-subrc = 4.
      RAISE error_insert.
    ENDIF.

*    COMMIT WORK AND WAIT.

  ENDIF.



ENDFUNCTION.
