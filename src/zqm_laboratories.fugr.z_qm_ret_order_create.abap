FUNCTION z_qm_ret_order_create.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"     VALUE(I_CUSTOMIZING) LIKE  V_TQ85 STRUCTURE  V_TQ85
*"  EXPORTING
*"     VALUE(E_QNQMAMA0) LIKE  QNQMAMA0 STRUCTURE  QNQMAMA0
*"  TABLES
*"      TI_IVIQMFE STRUCTURE  WQMFE
*"      TI_IVIQMUR STRUCTURE  WQMUR
*"      TI_IVIQMSM STRUCTURE  WQMSM
*"      TI_IVIQMMA STRUCTURE  WQMMA
*"      TI_IHPA STRUCTURE  IHPA
*"      TE_LINES STRUCTURE  TLINE OPTIONAL
*"  EXCEPTIONS
*"      ACTION_STOPPED
*"----------------------------------------------------------------------
  DATA lt_qmcrm_memory TYPE TABLE OF zzqmcrm.
  DATA lt_qmcrm TYPE SORTED TABLE OF zzqmcrm WITH UNIQUE KEY faknr ballen_id.
  DATA lt_faknr TYPE SORTED TABLE OF vbeln_vf WITH UNIQUE KEY table_line.
  DATA lv_itm_numb TYPE vbap-posnr.
  DATA: lv_vbeln TYPE vbeln,
        lv_matnr TYPE matnr,
        lv_vkorg TYPE vkorg,
        lv_vtweg TYPE vtweg,
        lv_spart TYPE spart,
        lv_vkbur TYPE vkbur,
        lv_kunag TYPE kunag.
  DATA wa_vbak TYPE bapisdhd1.
  DATA lt_vbap TYPE TABLE OF bapisditm.
  DATA lt_vbep TYPE TABLE OF bapischdl.
  DATA lt_vbpa TYPE TABLE OF bapiparnr.

  DATA lt_vbapx TYPE TABLE OF bapisditmx.
  DATA lt_cond  TYPE TABLE OF bapicond.
  DATA lt_return TYPE bapiret2_t.
  DATA: wa_role_a TYPE borident,
        wa_role_b TYPE borident.
  DATA lv_count TYPE i.
  DATA wa_vbco3 TYPE vbco3.
  DATA wa_vbdkr TYPE vbdkr.
  DATA lt_vbdpr TYPE STANDARD TABLE OF vbdpr.
  DATA wa_komk TYPE komk.
  DATA wa_komp TYPE komp.
  DATA lt_komv TYPE STANDARD TABLE OF komv.
  DATA lt_komvd TYPE STANDARD TABLE OF komvd.
  DATA lt_knvv TYPE TABLE OF knvv.
  DATA ls_knvv TYPE knvv.
  DATA: lv_vkgrp TYPE vkgrp.
  DATA: lv_vstel TYPE likp-vstel.
  DATA: lv_werks TYPE lips-werks.
  DATA: wa_bapisdls TYPE bapisdls.

  TYPES: BEGIN OF ls_vbrp,              "215684 - 16.01.2026 - SR-858787
           vbeln TYPE vbeln_vf,
           posnr TYPE posnr_vf,
           vgbel TYPE vgbel,
           vgpos TYPE vgpos,
         END OF ls_vbrp.
  DATA: lt_vbrp TYPE SORTED TABLE OF ls_vbrp WITH UNIQUE KEY vbeln posnr.   "215684 - 16.01.2026 - SR-858787
  DATA ls_vbrp2 TYPE ls_vbrp. "215684 - 16.01.2026 - SR-858787

TYPES: BEGIN OF ty_kbetr,
        kbetr TYPE kbetr,
       END OF ty_kbetr.
  DATA: lt_kbetr Type table of ty_kbetr,
        ls_kbetr TYPE ty_kbetr.


*215684 - 16.01.2026 - SR-858787: Lesen Zertifikat und Faser Projekt
  DATA: lv_mvgr2 TYPE mvgr2,
        lv_mvgr4 TYPE mvgr4,
        lv_kvgr4 TYPE kvgr4.


  FIELD-SYMBOLS: <wa_qmcrm>  LIKE LINE OF lt_qmcrm,
                 <wa_faknr>  LIKE LINE OF lt_faknr,
                 <wa_vbap>   LIKE LINE OF lt_vbap,
                 <wa_knvv>   LIKE LINE OF lt_knvv,
                 <wa_vbapx>  LIKE LINE OF lt_vbapx,
                 <wa_vbep>   LIKE LINE OF lt_vbep,
                 <wa_vbdpr>  LIKE LINE OF lt_vbdpr,
                 <wa_cond>   LIKE LINE OF lt_cond,
                 <wa_return> LIKE LINE OF lt_return,
                 <wa_vbpa>   LIKE LINE OF lt_vbpa,
                 <wa_komv>   LIKE LINE OF lt_komv.

  CONSTANTS: co_mem_id_0505        TYPE char40 VALUE 'GT_PROBES_0505',
             co_mem_id_0505_reread TYPE char40 VALUE 'GV_REREAD_PROBES_0505',
             co_doc_type           TYPE auart VALUE 'ZFRE'.

  IMPORT gt_qmcrm_0505 TO lt_qmcrm_memory FROM MEMORY ID co_mem_id_0505.
  FREE MEMORY ID co_mem_id_0505.

  READ TABLE lt_qmcrm_memory
  WITH KEY returnbail = 'T'
  TRANSPORTING NO FIELDS.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e100(zqm).
    RETURN.
  ENDIF.


  CALL FUNCTION 'RV_PRICE_PRINT_REFRESH'
    TABLES
      tkomv = lt_komv.

  lt_qmcrm[] = lt_qmcrm_memory[].

  DELETE lt_qmcrm
  WHERE returnbail <> 'T' OR  retourenauftrag IS NOT INITIAL OR retourenauftrag <> ''.

  LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
    READ TABLE lt_faknr
    WITH KEY table_line = <wa_qmcrm>-faknr
    TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      INSERT <wa_qmcrm>-faknr INTO TABLE lt_faknr.
    ENDIF.
  ENDLOOP.

*215684 - 16.01.2026 - SR-858787: Nachziehen Logik aus Z_QM_CREDIT_MEMO_CREATE für Referenz Positionssnummer
  CLEAR: lt_vbrp.
  SELECT vbrp~vbeln
         vbrp~posnr
         vbrp~vgbel
         vbrp~vgpos
  FROM vbrp
  INNER JOIN lips
  ON lips~vbeln = vbrp~vgbel AND
     lips~posnr = vbrp~vgpos
  INTO TABLE lt_vbrp
  FOR ALL ENTRIES IN lt_qmcrm
  WHERE lips~vbeln = lt_qmcrm-vbeln
    AND lips~charg = ''.

*215684 - 16.01.2026 - SR-858787: Nachziehen Logik aus Z_QM_CREDIT_MEMO_CREATE für Referenz Positionssnummer - ENDE



  LOOP AT lt_faknr ASSIGNING <wa_faknr>.
    FREE: lt_vbap, lt_vbep, lt_vbpa, lt_vbapx, lt_return, lt_vbdpr, lt_komv, lt_komvd.
    CLEAR: lv_itm_numb, lv_vkorg, lv_vtweg, lv_spart, wa_vbak, wa_vbdkr, wa_komk.

    SELECT SINGLE vkorg
                  vtweg
                  spart
    FROM vbrk INTO (lv_vkorg, lv_vtweg, lv_spart)
    WHERE vbeln = <wa_faknr>.

    IF sy-subrc IS NOT INITIAL.
*     MESSAGE e102(zqm).
      MESSAGE e098(zqm) DISPLAY LIKE 'I'.
      CONTINUE.
    ENDIF.

    wa_vbak-sales_org = lv_vkorg.
    wa_vbak-distr_chan = lv_vtweg.
    wa_vbak-division = lv_spart.
    wa_vbak-doc_type = co_doc_type.
    wa_vbak-ord_reason = ''.
    wa_vbak-notif_no = i_viqmel-qmnum.

    wa_vbco3-vbeln = <wa_faknr>.
    wa_vbco3-mandt = sy-mandt.

    CALL FUNCTION 'RV_BILLING_PRINT_VIEW'
      EXPORTING
        comwa                        = wa_vbco3
      IMPORTING
        kopf                         = wa_vbdkr
      TABLES
        pos                          = lt_vbdpr
      EXCEPTIONS
        terms_of_payment_not_in_t052 = 1
        OTHERS                       = 2.

    IF sy-subrc IS INITIAL.
      MOVE-CORRESPONDING wa_vbdkr TO wa_komk.
      wa_komk-kappl = 'V'.

      CALL FUNCTION 'RV_PRICE_PRINT_REFRESH'
        TABLES
          tkomv = lt_komv.

      CALL FUNCTION 'RV_PRICE_PRINT_ITEM'
        EXPORTING
          comm_head_i = wa_komk
          comm_item_i = wa_komp
        IMPORTING
          comm_head_e = wa_komk
          comm_item_e = wa_komp
        TABLES
          tkomv       = lt_komv
          tkomvd      = lt_komvd.
    ENDIF.

*215684 - 12.11.2024 - SR-768237 - Bugfix: Erstellen pro Rechnungsposition eine Retourenposition (notwendig aufgrund möglicher unterschiedlicher Preise)
*folgende 3 Zeilen runterkopiert in Loop
*    lv_itm_numb = lv_itm_numb + 10.
*    APPEND INITIAL LINE TO lt_vbap ASSIGNING <wa_vbap>.
*    APPEND INITIAL LINE TO lt_vbapx ASSIGNING <wa_vbapx>.

*####################################### - evt wieder ausbauen
*Check ob es Preisinformationen gibt
    READ TABLE lt_vbdpr
    ASSIGNING <wa_vbdpr>
    WITH KEY vbeln_vl = <wa_qmcrm>-vbeln.

    IF sy-subrc IS NOT INITIAL.
      MESSAGE e075(zqm) WITH <wa_qmcrm>-vbeln <wa_faknr>.
      RETURN.
    ENDIF.
*Abfrage ob mehrere Retouren Positionen auf Basis der Ursprungsrechnung angelegt werden müssen
IF lines( lt_vbdpr ) > 1.   " mehr als ein Eintrag vorhanden
*check ob es unterschiedliche Preise gibt bei den Positionen
  CLEAR: lt_kbetr, ls_kbetr.
      LOOP AT lt_vbdpr ASSIGNING <wa_vbdpr>.

      READ TABLE lt_komv
      ASSIGNING <wa_komv>
      WITH KEY kposn = <wa_vbdpr>-posnr
               kschl = 'ZFPW'.
      ls_kbetr-kbetr = <wa_komv>-kbetr.
      APPEND ls_kbetr TO lt_kbetr.
      CLEAR: ls_kbetr.
      ENDLOOP.
ENDIF.
*in lt_kbetr sind alle Preise der Rechnungspositionen vorhanden - nun: Vergleich ob es Abweichungen gibt:
IF lt_kbetr[] IS NOT INITIAL.
  DATA: ls_first TYPE ty_kbetr,
        ls_last type ty_kbetr.

  SORT lt_kbetr BY kbetr.

  READ TABLE lt_kbetr INDEX 1 INTO ls_first.
  READ TABLE lt_kbetr INDEX lines( lt_kbetr ) INTO ls_last.

 IF ls_first-kbetr <> ls_last-kbetr.
   IF sy-langu = 'D'.
     MESSAGE 'Achtung! In der Ursprungsrechnung gibt es unterschiedliche Preise! Auf die richtige Aufteilung achten!' TYPE 'I'.
   ELSE.
     MESSAGE 'ATTENTION! There are different prices in the original invoice! Please take care in the return order!' TYPE 'I'.
   ENDIF.
 ENDIF.

ENDIF.

*####################################### - evt wieder ausbauen


      lv_itm_numb = lv_itm_numb + 10.
      APPEND INITIAL LINE TO lt_vbap ASSIGNING <wa_vbap>.
      APPEND INITIAL LINE TO lt_vbapx ASSIGNING <wa_vbapx>.

    LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm> WHERE faknr = <wa_faknr>.

*13.01.2026: Überarbeitung im Zuge vom Lesen des Zertifiakts und Faser Projekts aus VBRP - Hinzufügen von Positionsnummer in VBRP ansonsten ersten Eintrag wählen (wie bisher)
      CLEAR: ls_vbrp2, lv_vkgrp, lv_vkbur.
      LOOP AT lt_vbrp INTO ls_vbrp2 WHERE vbeln = <wa_qmcrm>-faknr.      "finden d. richtigen Positionsnummer zur aktuellen Rechnung
        EXIT.
      ENDLOOP.

      IF ls_vbrp2 IS NOT INITIAL.        "wenn Positionsnummer gefunden wurde
        SELECT SINGLE vkgrp
                      vkbur
          FROM vbrp INTO (lv_vkgrp, lv_vkbur)
          WHERE vbeln = <wa_qmcrm>-faknr
          AND posnr = ls_vbrp2-posnr.
        IF lv_vkgrp IS INITIAL.         "probiere ohne Positionsnummer wenn aus Select zuvor nichts gefunden wurde
          SELECT SINGLE vkgrp
                        vkbur
          FROM vbrp INTO (lv_vkgrp, lv_vkbur)
          WHERE vbeln = <wa_qmcrm>-faknr.
        ENDIF.
      ELSE.                             "sonst wie bisher - erster Eintrag (wie zuvor) - lesen ohne Positionsnummer
        SELECT SINGLE vkgrp
                 vkbur
     FROM vbrp INTO (lv_vkgrp, lv_vkbur)
     WHERE vbeln = <wa_qmcrm>-faknr.
      ENDIF.

      wa_vbak-sales_grp = lv_vkgrp.
      wa_vbak-sales_off = lv_vkbur.

*215684 - 16.01.2026 - SR-858787: Lesen Zertifikat und Faser Projekt
*KVGR4 = Faser Projekt Kopf; MVGR2 = Faser Projekt Position; MVGR4 = Zertifikat
      CLEAR: lv_kvgr4, lv_mvgr2, lv_mvgr4.
      IF ls_vbrp2 IS NOT INITIAL.        "wenn Positionsnummer gefunden wurde
        SELECT SINGLE kvgr4 mvgr2 mvgr4 FROM vbrp INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr AND posnr = ls_vbrp2-posnr.
        IF lv_mvgr2 IS INITIAL.         "probiere ohne Positionsnummer wenn aus Select zuvor nichts gefunden wurde
          SELECT SINGLE kvgr4 mvgr2 mvgr4 FROM vbrp INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr.
        ENDIF.
      ELSE.                              "sonst erster Eintrag - lesen ohne Positionsnummer
        SELECT SINGLE kvgr4 mvgr2 mvgr4 FROM vbrp INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr.
      ENDIF.

      wa_vbak-cust_grp4 = lv_kvgr4.       "215684 - 16.01.2026 - SR-858787




      <wa_vbap>-material = <wa_qmcrm>-matnr.
      "<wa_vbap>-batch = <wa_qmcrm>-ballen_id.
      <wa_vbap>-target_qty =  <wa_vbap>-target_qty + <wa_qmcrm>-weight.
      <wa_vbapx>-target_qty = 'X'.
      <wa_vbap>-target_qu = 'K13'.
      <wa_vbapx>-target_qu = 'X'.
      <wa_vbap>-plant = <wa_qmcrm>-werks.
      <wa_vbapx>-plant = 'X'.
      <wa_vbap>-itm_number = lv_itm_numb.
*      <wa_vbapx>-itm_number = 'X'.   "215684 - 12.11.2024 - falsch von LAGAHW? - siehe nächste Zeile
      <wa_vbapx>-itm_number =  lv_itm_numb.
      <wa_vbap>-prc_group2 = lv_mvgr2.     "215684 - 16.01.2026 - SR-858787
      <wa_vbap>-prc_group4 = lv_mvgr4.     "215684 - 16.01.2026 - SR-858787
      <wa_vbapx>-prc_group2 = 'X'.    "215684 - 16.01.2026 - SR-858787
      <wa_vbapx>-prc_group4 = 'X'.    "215684 - 16.01.2026 - SR-858787



*215684 - 05.10.2022 - Erweiterung laut Anfoderung von Kastinger/Neudorfer - Anfang: Versandstelle aus Ursprungslieferung ziehen im Zuge des Customer Complaint Projekts
      CLEAR: lv_vstel, lv_werks.
      SELECT SINGLE vstel FROM likp WHERE vbeln = @<wa_qmcrm>-vbeln INTO @lv_vstel.
      SELECT SINGLE werks FROM lips WHERE vbeln = @<wa_qmcrm>-vbeln INTO @lv_werks.
      <wa_vbap>-ship_point = lv_vstel.
      <wa_vbapx>-ship_point = 'X'.
      <wa_vbap>-plant = lv_werks.
      <wa_vbapx>-plant = 'X'.
*215684 - Ende Versandstelle

      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input        = <wa_qmcrm>-matnr
        IMPORTING
          output       = <wa_vbap>-material
        EXCEPTIONS
          length_error = 1
          OTHERS       = 2.

      <wa_vbapx>-material = 'X'.

      SELECT parvw AS partn_role
             kunnr AS partn_numb
      FROM vbpa
      APPENDING CORRESPONDING FIELDS OF TABLE lt_vbpa
      WHERE vbeln = <wa_qmcrm>-vbeln
      AND ( parvw = 'WE' OR parvw = 'AG' ).

    ENDLOOP.

      APPEND INITIAL LINE TO lt_vbep ASSIGNING <wa_vbep>.
      <wa_vbep>-itm_number = <wa_vbap>-itm_number.
      <wa_vbep>-req_qty = <wa_vbap>-target_qty.


    READ TABLE lt_vbdpr
    ASSIGNING <wa_vbdpr>
    WITH KEY vbeln_vl = <wa_qmcrm>-vbeln.
*
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e075(zqm) WITH <wa_qmcrm>-vbeln <wa_faknr>.
      RETURN.
    ENDIF.

**215684 - 12.11.2024 - SR-768237: neue Logik: Preise finden aufgrund von Bugfix (pro Rechnungsposition eine Retourenposition) --> doch nur mehr 1 Position anlegen!
*UNASSIGN: <wa_komv>.
*    CLEAR: lv_itm_numb.
*    LOOP AT lt_vbdpr ASSIGNING <wa_vbdpr>.
*
*      READ TABLE lt_komv
*      ASSIGNING <wa_komv>
*      WITH KEY kposn = <wa_vbdpr>-posnr
*               kschl = 'ZFPW'.
*
*      IF sy-subrc = 0.
*        lv_itm_numb = lv_itm_numb + 10.     "falls Positionssnummer im Retourenauftrag nicht gleich Rechnungsposition ist (soll eines nach dem anderen abarbeiten)
*
*        LOOP AT lt_vbap ASSIGNING <wa_vbap> WHERE itm_number = lv_itm_numb.
*          APPEND INITIAL LINE TO lt_cond ASSIGNING <wa_cond>.
*          <wa_cond>-itm_number = <wa_vbap>-itm_number.
*          <wa_cond>-cond_type = <wa_komv>-kschl.
*          <wa_cond>-condchaman = 'X'.
*          "<wa_cond>-COND_VALUE = <wa_komv>-kwert.
*          <wa_cond>-cond_value = <wa_komv>-kbetr.
*          <wa_cond>-currency = <wa_komv>-waers.
*          <wa_cond>-cond_unit = <wa_komv>-kmein.
*          <wa_cond>-cond_p_unt = <wa_komv>-kpein.
*        ENDLOOP.
*
*      ENDIF.
*    ENDLOOP.




    READ TABLE lt_komv
    ASSIGNING <wa_komv>
    WITH KEY kposn = <wa_vbdpr>-posnr
             kschl = 'ZFPW'.

    IF sy-subrc IS INITIAL.
      APPEND INITIAL LINE TO lt_cond ASSIGNING <wa_cond>.
      <wa_cond>-itm_number = <wa_vbap>-itm_number.
      <wa_cond>-cond_type = <wa_komv>-kschl.
      <wa_cond>-condchaman = 'X'.
      "<wa_cond>-COND_VALUE = <wa_komv>-kwert.
      <wa_cond>-cond_value = <wa_komv>-kbetr.
      <wa_cond>-currency = <wa_komv>-waers.
      <wa_cond>-cond_unit = <wa_komv>-kmein.
      <wa_cond>-cond_p_unt = <wa_komv>-kpein.

      UNASSIGN <wa_komv>.
    ENDIF.



    IF wa_vbak IS NOT INITIAL AND lt_vbap[] IS NOT INITIAL.
      SORT lt_vbpa BY partn_role partn_numb.
      DELETE ADJACENT DUPLICATES FROM lt_vbpa COMPARING partn_role partn_numb.

      READ TABLE lt_vbpa
      ASSIGNING <wa_vbpa>
      WITH KEY partn_role = 'AG'.

      SELECT SINGLE *
      FROM knvv
      INTO ls_knvv
      WHERE vkorg = wa_vbak-sales_org
        AND vtweg = wa_vbak-distr_chan
        AND spart = wa_vbak-division
        AND kunnr = <wa_vbpa>-partn_numb.

*215684 - 08.09.2022 - Customer Complaint: Verkäufergruppe + -büro aus der Ursprungsrechnung und nicht vom Kundenstamm ziehen
*13.01.2026: wurde verschoben in LOOP von lt_zqmcrm
*      SELECT SINGLE VKGRP
*                    VKBUR
*        FROM vbrp INTO (lv_vkgrp, lv_vkbur)
*        WHERE vbeln = <wa_faknr>.
*
*      wa_vbak-sales_grp = lv_vkgrp.
*      wa_vbak-sales_off = lv_vkbur.




**      wa_vbak-sales_grp = ls_knvv-vkgrp.
**      wa_vbak-sales_off = ls_knvv-vkbur.
*215684 - 08.09.2022 - Customer Complaint: Verkäufergruppe + -büro aus der Ursprungsrechnung und nicht vom Kundenstamm ziehen


      UNASSIGN <wa_vbpa>.

*215684 - 27.01.2023 - SR-643223: Einbau Logic Switch damit ein Konditionssatz mit dem zuvor ermittelten Preis aus der Ursprungsfaktura überschrieben wird
*zuvor hat es immer eine Fehlermeldung gegeben und der Beleg konnte nicht angelegt werden, da ZFPW 2 x existierte (1x durch Konditionssatz und 1x hier bei der Übergabe)
      wa_bapisdls-cond_handl = 'X'.


      CALL FUNCTION 'BAPI_CUSTOMERRETURN_CREATE'
        EXPORTING
          return_header_in     = wa_vbak
          logic_switch         = wa_bapisdls
        IMPORTING
          salesdocument        = lv_vbeln
        TABLES
          return               = lt_return
          return_items_in      = lt_vbap
          return_items_inx     = lt_vbapx
          return_conditions_in = lt_cond
          return_partners      = lt_vbpa
          return_schedules_in  = lt_vbep.

      DELETE lt_return
      WHERE type <> 'E' AND
            type <> 'A'.

*215684 - 26.09.2022 - Customer Complaint Projekt - wenn Fehler bei VKGRP, VKBUR, dann nimm aus Kundenstamm (Fehler ZSD118)
      LOOP AT lt_return ASSIGNING <wa_return> WHERE type = 'E' AND id = 'ZSD' AND number = '118'.
      ENDLOOP.
      IF sy-subrc = 0.
        CLEAR: lv_vkgrp, lv_vkbur, lt_return.
        wa_vbak-sales_grp = lv_vkgrp.
        wa_vbak-sales_off = lv_vkbur.


        CALL FUNCTION 'BAPI_CUSTOMERRETURN_CREATE'
          EXPORTING
            return_header_in     = wa_vbak
            logic_switch         = wa_bapisdls
          IMPORTING
            salesdocument        = lv_vbeln
          TABLES
            return               = lt_return
            return_items_in      = lt_vbap
            return_items_inx     = lt_vbapx
            return_conditions_in = lt_cond
            return_partners      = lt_vbpa
            return_schedules_in  = lt_vbep.
        DELETE lt_return
        WHERE type <> 'E' AND
              type <> 'A'.
        LOOP AT lt_return ASSIGNING <wa_return>.
          MESSAGE <wa_return>-message TYPE <wa_return>-type.
        ENDLOOP.
      ELSE.
        LOOP AT lt_return ASSIGNING <wa_return>.
          MESSAGE <wa_return>-message TYPE <wa_return>-type.
        ENDLOOP.
      ENDIF.

      IF lt_return[] IS INITIAL.
        LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm> WHERE faknr = <wa_faknr>.
          UPDATE zzqmcrm
          SET retourenauftrag = lv_vbeln
          WHERE ballen_id = <wa_qmcrm>-ballen_id
            AND werks = <wa_qmcrm>-werks.
        ENDLOOP.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.

        lv_count = lv_count + 1.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        CONTINUE.
      ENDIF.

      wa_role_a-objkey = i_viqmel-qmnum.
      wa_role_a-objtype = 'BUS2078'.
      wa_role_b-objkey = lv_vbeln.
      wa_role_b-objtype = 'BUS2102'.

      CALL FUNCTION 'QMLR_CREATE_DOCUMENT_FLOW'
        EXPORTING
          role_a  = wa_role_a
          role_b  = wa_role_b
          reltype = 'REFZ'
        EXCEPTIONS
          OTHERS  = 1.

      IF sy-subrc IS INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        MESSAGE e106(zqm).
      ENDIF.

*      IF <wa_faknr> IS ASSIGNED AND <wa_faknr> IS NOT INITIAL.
*        wa_role_a-objkey = i_viqmel-qmnum.
*        wa_role_a-objtype = 'BUS2078'.
*        wa_role_b-objkey = <wa_faknr>.
*        wa_role_b-objtype = 'BUS2037'.
*
*        CALL FUNCTION 'QMLR_CREATE_DOCUMENT_FLOW'
*          EXPORTING
*            role_a  = wa_role_a
*            role_b  = wa_role_b
*            reltype = 'REFZ'
*          EXCEPTIONS
*            OTHERS  = 1.
*      ENDIF.
*
*      IF sy-subrc IS INITIAL.
*        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*          EXPORTING
*            wait = 'X'.
*      ELSE.
*        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
*        MESSAGE e105(zqm).
*      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_count > 0.
    EXPORT lv_reread_data FROM abap_true TO MEMORY ID co_mem_id_0505_reread.
    MESSAGE s072(zqm) WITH lv_count.
  ENDIF.

  FREE: lt_faknr, lt_qmcrm, lt_qmcrm_memory.
ENDFUNCTION.
