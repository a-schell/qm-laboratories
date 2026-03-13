FUNCTION z_qm_credit_memo_create.
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
TYPES: BEGIN OF ls_vbrp,
          vbeln TYPE vbeln_vf,
          posnr TYPE posnr_vf,
          vgbel TYPE vgbel,
          vgpos TYPE vgpos,
         END OF ls_vbrp.

  DATA lt_qmcrm TYPE STANDARD TABLE OF zzqmcrm.
  DATA: lv_vkorg TYPE vkorg,
        lv_vtweg TYPE vtweg,
        lv_spart TYPE spart.
  DATA lv_item_number TYPE vbap-posnr.
  DATA wa_order_header TYPE bapisdhd1.
  DATA lt_order_items TYPE STANDARD TABLE OF bapisditm.
  DATA lt_order_schedules TYPE STANDARD TABLE OF bapischdl.
  DATA lt_order_partners TYPE STANDARD TABLE OF bapiparnr.
  DATA lt_order_conditions TYPE STANDARD TABLE OF bapicond.
  DATA lv_vbeln TYPE vbeln.
  DATA lt_return TYPE bapiret2_t.
  DATA lv_error_occured TYPE abap_bool.
  DATA: wa_role_a TYPE borident,
        wa_role_b TYPE borident.
  DATA lt_vbrp TYPE SORTED TABLE OF ls_vbrp WITH UNIQUE KEY vbeln posnr.
  DATA ls_vbrp2 type ls_vbrp.         "215684 - 13.01.2026
  DATA wa_vbco3 TYPE vbco3.
  DATA wa_vbdkr TYPE vbdkr.
  DATA lt_vbdpr TYPE STANDARD TABLE OF vbdpr.
  DATA wa_komk TYPE komk.
  DATA wa_komp TYPE komp.
  DATA lt_komv TYPE STANDARD TABLE OF komv.
  DATA lt_komvd TYPE STANDARD TABLE OF komvd.
  DATA: lv_vkgrp TYPE VKGRP,
        lv_vkbur TYPE VKBUR.
  DATA: wa_BAPISDLS TYPE BAPISDLS.

*215684 - 13.01.2026 - SR-858787: Lesen Zertifikat und Faser Projekt
  DATA: lv_mvgr2 TYPE mvgr2,
        lv_mvgr4 TYPE mvgr4,
        lv_kvgr4 TYPE kvgr4.


  FIELD-SYMBOLS: <wa_qmcrm> TYPE zzqmcrm,
                 <wa_order_items> TYPE bapisditm,
                 <wa_order_schedules> TYPE bapischdl,
                 <wa_order_conditions> TYPE bapicond,
                 <wa_return> TYPE bapiret2,
                 <wa_vbrp> TYPE ls_vbrp,
                 <wa_komv> TYPE komv,
                 <wa_vbdpr> TYPE vbdpr.

  CONSTANTS: co_mem_id_0505 TYPE char40 VALUE 'GT_PROBES_0505',
             co_doc_type TYPE auart VALUE 'ZFR2',
             co_target_quantity TYPE dzieme VALUE 'K13',
             co_relation_type TYPE breltyp-reltype VALUE 'REFZ'.

  IMPORT gt_qmcrm_0505 TO lt_qmcrm FROM MEMORY ID co_mem_id_0505.
  FREE MEMORY ID co_mem_id_0505.

  READ TABLE lt_qmcrm
  WITH KEY mark = 'X'
  TRANSPORTING NO FIELDS.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e100(zqm).
    RETURN.
  ENDIF.

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

  LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
    CLEAR: lv_vkorg, lv_vtweg, lv_spart.

    lv_item_number = lv_item_number + 10.

    SELECT SINGLE vkorg
                  vtweg
                  spart
    FROM vbrk
    INTO (lv_vkorg, lv_vtweg, lv_spart)
    WHERE vbeln = <wa_qmcrm>-faknr.

    IF sy-subrc IS NOT INITIAL.
*     MESSAGE e102(zqm).
      MESSAGE e098(zqm) DISPLAY LIKE 'I'.
      RETURN.
    ENDIF.

*215684 - 08.09.2022 - Customer Complaint: Verkäufergruppe + -büro aus der Ursprungsrechnung und nicht vom Kundenstamm ziehen
*13.01.2026: Überarbeitung im Zuge vom Lesen des Zertifiakts und Faser Projekts aus VBRP - Hinzufügen von Positionsnummer in VBRP ansonsten ersten Eintrag wählen (wie bisher)
   CLEAR: ls_vbrp2, lv_vkgrp, lv_vkbur.
   LOOP at lt_vbrp INTO ls_vbrp2 where vbeln = <wa_qmcrm>-faknr.      "finden d. richtigen Positionsnummer zur aktuellen Rechnung
     EXIT.
   ENDLOOP.

   IF ls_vbrp2 IS NOT INITIAL.        "wenn Positionsnummer gefunden wurde
      SELECT SINGLE VKGRP
                    VKBUR
        FROM vbrp INTO (lv_vkgrp, lv_vkbur)
        WHERE vbeln = <wa_qmcrm>-faknr
        AND posnr = ls_vbrp2-posnr.
      IF lv_vkgrp IS INITIAL.         "probiere ohne Positionsnummer wenn aus Select zuvor nichts gefunden wurde
        SELECT SINGLE VKGRP
                      VKBUR
        FROM vbrp INTO (lv_vkgrp, lv_vkbur)
        WHERE vbeln = <wa_qmcrm>-faknr.
      ENDIF.
   ELSE.                             "sonst wie bisher - erster Eintrag (wie zuvor) - lesen ohne Positionsnummer
           SELECT SINGLE VKGRP
                    VKBUR
        FROM vbrp INTO (lv_vkgrp, lv_vkbur)
        WHERE vbeln = <wa_qmcrm>-faknr.
   ENDIF.
*215684 - 08.09.2022 - Customer Complaint: Verkäufergruppe + -büro aus der Ursprungsrechnung und nicht vom Kundenstamm ziehen

*215684 - 13.01.2026 - SR-858787: Lesen Zertifikat und Faser Projekt
*KVGR4 = Faser Projekt Kopf; MVGR2 = Faser Projekt Position; MVGR4 = Zertifikat
CLEAR: lv_kvgr4, lv_mvgr2, lv_mvgr4.
   IF ls_vbrp2 IS NOT INITIAL.        "wenn Positionsnummer gefunden wurde
    SELECT SINGLE KVGR4 MVGR2 MVGR4 FROM VBRP INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr AND POSNR = ls_vbrp2-posnr.
      IF lv_mvgr2 IS INITIAL.         "probiere ohne Positionsnummer wenn aus Select zuvor nichts gefunden wurde
        SELECT SINGLE KVGR4 MVGR2 MVGR4 FROM VBRP INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr.
      ENDIF.
   ELSE.                              "sonst erster Eintrag - lesen ohne Positionsnummer
    SELECT SINGLE KVGR4 MVGR2 MVGR4 FROM VBRP INTO (lv_kvgr4, lv_mvgr2, lv_mvgr4) WHERE vbeln = <wa_qmcrm>-faknr.
   ENDIF.

    IF wa_order_header IS INITIAL.
      wa_order_header-sales_org = lv_vkorg.
      wa_order_header-distr_chan = lv_vtweg.
      wa_order_header-division = lv_spart.
      wa_order_header-doc_type = co_doc_type.
      wa_order_header-NOTIF_NO = I_VIQMEL-QMNUM.
      wa_order_header-SALES_GRP = lv_vkgrp.
      wa_order_header-SALES_OFF = lv_vkbur.
      wa_order_header-CUST_GRP4 = lv_kvgr4.       "215684 - 13.01.2026 - SR-858787
    ELSE.
      IF wa_order_header-sales_org <> lv_vkorg OR wa_order_header-distr_chan <> lv_vtweg.
        MESSAGE e101(zqm).
        RETURN.
      ENDIF.
    ENDIF.

    APPEND INITIAL LINE TO lt_order_items ASSIGNING <wa_order_items>.
    <wa_order_items>-material = <wa_qmcrm>-matnr.
    <wa_order_items>-batch = <wa_qmcrm>-ballen_id.
    "<wa_order_items>-target_qty = <wa_qmcrm>-weight.
    <wa_order_items>-target_qty = 1.
    <wa_order_items>-target_qu = co_target_quantity.
    <wa_order_items>-plant = <wa_qmcrm>-werks.
    <wa_order_items>-itm_number = lv_item_number.
    <wa_order_items>-PRC_GROUP2 = lv_mvgr2.     "215684 - 13.01.2026 - SR-858787
    <wa_order_items>-PRC_GROUP4 = lv_mvgr4.     "215684 - 13.01.2026 - SR-858787

    APPEND INITIAL LINE TO lt_order_schedules ASSIGNING <wa_order_schedules>.
    <wa_order_schedules>-itm_number = <wa_order_items>-itm_number.
    "<wa_order_schedules>-req_qty = <wa_order_items>-target_qty.
    <wa_order_schedules>-req_qty = 1.

    SELECT parvw AS partn_role
           kunnr AS partn_numb
    FROM vbpa
    APPENDING CORRESPONDING FIELDS OF TABLE lt_order_partners
    WHERE vbeln = <wa_qmcrm>-vbeln
      AND ( parvw = 'WE' OR parvw = 'AG' ).

    READ TABLE lt_vbrp
    ASSIGNING <wa_vbrp>
    WITH KEY vgbel = <wa_qmcrm>-vbeln.

    IF sy-subrc IS INITIAL.
      CLEAR: wa_vbco3, wa_vbdkr, wa_komk, wa_komp.
      FREE: lt_vbdpr, lt_komv, lt_komvd.

      wa_vbco3-vbeln = <wa_vbrp>-vbeln.
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

        READ TABLE lt_vbdpr
        ASSIGNING <wa_vbdpr>
        WITH KEY vbeln_vl = <wa_vbrp>-vgbel
                 posnr_vl = <wa_vbrp>-vgpos.

        IF sy-subrc IS INITIAL.
          LOOP AT lt_komv ASSIGNING <wa_komv> WHERE kposn = <wa_vbdpr>-posnr
                                                AND kschl = 'ZFPW'.

            APPEND INITIAL LINE TO lt_order_conditions ASSIGNING <wa_order_conditions>.
            <wa_order_conditions>-itm_number = <wa_order_items>-itm_number.
            <wa_order_conditions>-cond_type = <wa_komv>-kschl.
            <wa_order_conditions>-cond_value = <wa_komv>-kbetr.
            <wa_order_conditions>-currency = <wa_komv>-waers.
          ENDLOOP.
        ENDIF.

        CALL FUNCTION 'RV_PRICE_PRINT_REFRESH'
          TABLES
            tkomv = lt_komv.
      ENDIF.
    ENDIF.

    UNASSIGN: <wa_order_schedules>, <wa_order_items>, <wa_order_conditions>, <wa_vbrp>.

    EXIT.
  ENDLOOP.

  IF wa_order_header IS INITIAL OR lt_order_items[] IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_order_partners BY partn_role partn_numb.
  DELETE ADJACENT DUPLICATES FROM lt_order_partners COMPARING partn_role partn_numb.


*215684 - 27.01.2023 - SR-643223: Einbau Logic Switch damit ein Konditionssatz mit dem zuvor ermittelten Preis aus der Ursprungsfaktura überschrieben wird
*zuvor hat es immer eine Fehlermeldung gegeben und der Beleg konnte nicht angelegt werden, da ZFPW 2 x existierte (1x durch Konditionssatz und 1x hier bei der Übergabe)
wa_BAPISDLS-COND_HANDL = 'X'.


  CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
    EXPORTING
      sales_header_in     = wa_order_header
      LOGIC_SWITCH        = wa_BAPISDLS
    IMPORTING
      salesdocument_ex    = lv_vbeln
    TABLES
      return              = lt_return
      sales_items_in      = lt_order_items
      sales_partners      = lt_order_partners
      sales_schedules_in  = lt_order_schedules
      sales_conditions_in = lt_order_conditions.

  LOOP AT lt_return ASSIGNING <wa_return> WHERE type = 'E' AND ID = 'ZSD' AND NUMBER = '118'.
*215684 - 26.09.2022 - Customer Complaint Projekt - wenn Fehler bei VKGRP, VKBUR, dann nimm beide aus Kundenstamm (Fehler ZSD118)
  ENDLOOP.
  IF sy-subrc = 0.
      CLEAR: lv_vkgrp, lv_vkbur, lt_return.
      wa_order_header-SALES_GRP = lv_vkgrp.
      wa_order_header-SALES_OFF = lv_vkbur.

     CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'  "versuche nochmal Reklamation anzulegen mit VKGRP udn VKBUR aus Kundenstamm
    EXPORTING
      sales_header_in     = wa_order_header
      LOGIC_SWITCH        = wa_BAPISDLS
    IMPORTING
      salesdocument_ex    = lv_vbeln
    TABLES
      return              = lt_return
      sales_items_in      = lt_order_items
      sales_partners      = lt_order_partners
      sales_schedules_in  = lt_order_schedules
      sales_conditions_in = lt_order_conditions.
    LOOP AT lt_return ASSIGNING <wa_return> WHERE type = 'E'.
          MESSAGE <wa_return>-message TYPE <wa_return>-type.
    lv_error_occured = abap_true.
    ENDLOOP.
    ELSE.
    LOOP AT lt_return ASSIGNING <wa_return> WHERE type = 'E'.
    MESSAGE <wa_return>-message TYPE <wa_return>-type.
    lv_error_occured = abap_true.
    ENDLOOP.
    ENDIF.


  IF lv_error_occured = abap_true.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    RETURN.
  ENDIF.

  e_qnqmama0-matxt = lv_vbeln.

  LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
    UPDATE zzqmcrm
    SET reklanf = lv_vbeln
    WHERE ballen_id = <wa_qmcrm>-ballen_id
      AND werks = <wa_qmcrm>-werks.
  ENDLOOP.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  wa_role_a-objkey = i_viqmel-qmnum.
  wa_role_a-objtype = 'BUS2078'.
  wa_role_b-objkey = lv_vbeln.
  wa_role_b-objtype = 'BUS2094'.

  CALL FUNCTION 'QMLR_CREATE_DOCUMENT_FLOW'
    EXPORTING
      role_a  = wa_role_a
      role_b  = wa_role_b
      reltype = co_relation_type
    EXCEPTIONS
      OTHERS  = 1.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e107(zqm).
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ENDIF.

*  IF <wa_qmcrm>-faknr IS NOT INITIAL.
*    wa_role_a-objkey = i_viqmel-qmnum.
*    wa_role_a-objtype = 'BUS2078'.
*    wa_role_b-objkey = <wa_qmcrm>-faknr.
*    wa_role_b-objtype = 'BUS2037'.
*
*    CALL FUNCTION 'QMLR_CREATE_DOCUMENT_FLOW'
*      EXPORTING
*        role_a  = wa_role_a
*        role_b  = wa_role_b
*        reltype = co_relation_type
*      EXCEPTIONS
*        OTHERS  = 1.
*
*    IF sy-subrc IS NOT INITIAL.
*      MESSAGE e105(zqm).
*    ENDIF.
*  ENDIF.

  MESSAGE s074(zqm).

  CLEAR: wa_order_header, lv_error_occured, wa_role_a, wa_role_b.
  FREE: lt_order_schedules, lt_order_items, lt_qmcrm, lt_order_partners, lt_return, lt_order_conditions, lt_vbrp.
ENDFUNCTION.
