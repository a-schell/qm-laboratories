FUNCTION z_qm_bales_into_deliv.
*"----------------------------------------------------------------------
*"*"Local Interface:
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
  TYPES: BEGIN OF ls_return_lips,
          retourenauftrag TYPE vbeln,
          delivery TYPE vbeln,
          wbstk TYPE wbstk,
         END OF ls_return_lips.

  DATA lt_messages TYPE bapiret2_t.
  DATA lt_qmcrm TYPE STANDARD TABLE OF zzqmcrm.
  DATA lt_return_lips TYPE SORTED TABLE OF ls_return_lips WITH NON-UNIQUE KEY retourenauftrag.
  DATA lt_customer_returns TYPE STANDARD TABLE OF zqm_s_customer_return_orders WITH KEY retourenauftrag.
  DATA wa_selected_field TYPE slis_selfield.
  DATA lv_exit TYPE abap_bool.
  DATA lv_popup_question TYPE string.
  DATA lv_popup_answer(1) TYPE c.
  DATA lt_fieldcatalog TYPE slis_t_fieldcat_alv.
  DATA lt_lips TYPE SORTED TABLE OF lips WITH UNIQUE DEFAULT KEY.
  DATA wa_vbkok TYPE vbkok.
  DATA lt_vbpok TYPE tt_vbpok.
  DATA wa_likp TYPE likp.
  DATA lt_prot TYPE STANDARD TABLE OF prott.
  DATA: lv_error_any_0     TYPE flag,
        lv_error_in_item   TYPE flag,
        lv_error_in_pod    TYPE flag,
        lv_error_in_interf TYPE flag,
        lv_error_in_goods  TYPE flag,
        lv_error_in_final  TYPE flag.
  DATA lv_error_occured TYPE flag.
  DATA lt_retourenauftrag TYPE tt_vbeln.

  CONSTANTS: co_btn_yes(1) TYPE c VALUE '1',
             co_btn_no(1) TYPE c VALUE '2',
             co_btn_cancel(1) TYPE c VALUE 'A',
             co_mem_id_0505 TYPE char40 VALUE 'GT_PROBES_0505',
             co_mem_id_0505_reread TYPE char40 VALUE 'GV_REREAD_PROBES_0505'.

  FIELD-SYMBOLS: <wa_customer_returns> TYPE zqm_s_customer_return_orders,
                 <wa_fieldcatalog> TYPE slis_fieldcat_alv,
                 <wa_lips> TYPE lips,
                 <wa_prot> TYPE prott,
                 <wa_messages> TYPE bapiret2,
                 <wa_vbpok> TYPE vbpok,
                 <wa_return_lips> TYPE ls_return_lips,
                 <wa_qmcrm> TYPE zzqmcrm.

  IF i_viqmel-qmnum IS INITIAL.
    RETURN.
  ENDIF.

  IMPORT gt_qmcrm_0505 TO lt_qmcrm FROM MEMORY ID co_mem_id_0505.
  FREE MEMORY ID co_mem_id_0505.

  DELETE lt_qmcrm
  WHERE returnbail <> 'T'
     OR retourenauftrag IS INITIAL
     OR return_delivery IS NOT INITIAL.

  IF lt_qmcrm[] IS INITIAL.
    MESSAGE e112(zqm).
    RETURN.
  ENDIF.

  LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
    APPEND <wa_qmcrm>-retourenauftrag TO lt_retourenauftrag.
  ENDLOOP.

  SORT lt_retourenauftrag.
  DELETE ADJACENT DUPLICATES FROM lt_retourenauftrag.

  SELECT lips~vgbel AS retourenauftrag
         lips~vbeln AS delivery
         vbuk~wbstk
  FROM lips
  INNER JOIN vbuk
  ON lips~vbeln = vbuk~vbeln
  INTO TABLE lt_return_lips
  FOR ALL ENTRIES IN lt_retourenauftrag
  WHERE lips~vgbel = lt_retourenauftrag-table_line.

  DELETE lt_return_lips
  WHERE wbstk = 'C'.

  IF lt_return_lips[] IS INITIAL.
    MESSAGE text-i01 TYPE 'I'.
    RETURN.
  ENDIF.

  FREE lt_retourenauftrag.

  LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
    LOOP AT lt_return_lips ASSIGNING <wa_return_lips> WHERE retourenauftrag = <wa_qmcrm>-retourenauftrag.
      APPEND INITIAL LINE TO lt_customer_returns ASSIGNING <wa_customer_returns>.
      <wa_customer_returns>-retourenauftrag = <wa_qmcrm>-retourenauftrag.
      <wa_customer_returns>-delivery = <wa_return_lips>-delivery.
      UNASSIGN <wa_customer_returns>.
    ENDLOOP.
  ENDLOOP.

  SORT lt_customer_returns BY retourenauftrag delivery.
  DELETE ADJACENT DUPLICATES FROM lt_customer_returns COMPARING retourenauftrag delivery.

  IF lines( lt_customer_returns ) > 1.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZQM_S_CUSTOMER_RETURN_ORDERS'
      CHANGING
        ct_fieldcat            = lt_fieldcatalog
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.

    LOOP AT lt_fieldcatalog ASSIGNING <wa_fieldcatalog>.
      CASE <wa_fieldcatalog>-fieldname.
        WHEN 'RETOURENAUFTRAG'.
          <wa_fieldcatalog>-seltext_s = text-r1s.
          <wa_fieldcatalog>-seltext_m = text-r1m.
          <wa_fieldcatalog>-seltext_l = text-r1l.
        WHEN 'DELIVERY'.
          <wa_fieldcatalog>-seltext_s = text-d1s.
          <wa_fieldcatalog>-seltext_m = text-d1m.
          <wa_fieldcatalog>-seltext_l = text-d1l.
      ENDCASE.
    ENDLOOP.

    CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
      EXPORTING
        i_title               = text-t01
*       I_SELECTION           = 'X'
*       I_ZEBRA               = ' '
*       I_SCREEN_START_COLUMN = 0
*       I_SCREEN_START_LINE   = 0
*       I_SCREEN_END_COLUMN   = 0
*       I_SCREEN_END_LINE     = 0
*       I_SCROLL_TO_SEL_LINE  = 'X'
        i_tabname             = text-t02
        it_fieldcat           = lt_fieldcatalog
      IMPORTING
        es_selfield           = wa_selected_field
        e_exit                = lv_exit
      TABLES
        t_outtab              = lt_customer_returns
      EXCEPTIONS
        program_error         = 1
        OTHERS                = 2.

    IF sy-subrc IS NOT INITIAL.
      MESSAGE e108(zqm).
      RETURN.
    ENDIF.

    FREE lt_fieldcatalog.

    IF lv_exit = abap_true.
      RETURN.
    ENDIF.

    READ TABLE lt_customer_returns
    INDEX wa_selected_field-tabindex
    ASSIGNING <wa_customer_returns>.
  ELSE.
    READ TABLE lt_customer_returns
    INDEX 1
    ASSIGNING <wa_customer_returns>.
  ENDIF.

  IF <wa_customer_returns> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  lv_popup_question = text-q01.
  REPLACE '&1' WITH <wa_customer_returns>-delivery INTO lv_popup_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = lv_popup_question
      text_button_1         = 'Ja'(001)
      text_button_2         = 'Nein'(002)
      default_button        = '1'
      display_cancel_button = 'X'
      start_column          = 25
      start_row             = 6
    IMPORTING
      answer                = lv_popup_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e108(zqm).
    RETURN.
  ENDIF.

  CASE lv_popup_answer.
    WHEN co_btn_yes.
      DELETE lt_qmcrm
      WHERE retourenauftrag <> <wa_customer_returns>-retourenauftrag.

      SELECT *
      FROM lips
      INTO TABLE lt_lips
      WHERE vbeln = <wa_customer_returns>-delivery.

      IF lt_lips[] IS INITIAL.
        MESSAGE e109(zqm).
        RETURN.
      ENDIF.

      SELECT SINGLE vbeln
                    kodat
                    tddat
                    lddat
                    wadat
                    lfdat
      FROM likp
      INTO CORRESPONDING FIELDS OF wa_likp
      WHERE vbeln = <wa_customer_returns>-delivery.

      wa_vbkok-vbeln_vl = <wa_customer_returns>-delivery.
      wa_vbkok-vbtyp_vl = 'T'.
      wa_vbkok-kzkodat = 'X'.
      wa_vbkok-kodat   = wa_likp-kodat.
      wa_vbkok-kztddat = 'X'.
      wa_vbkok-tddat   = wa_likp-tddat.
      wa_vbkok-kzlddat = 'X'.
      wa_vbkok-lddat   = wa_likp-lddat.
      wa_vbkok-kzwad   = 'X'.
      wa_vbkok-wadat   = wa_likp-wadat.
      wa_vbkok-kzlfd   = 'X'.
      wa_vbkok-lfdat   = wa_likp-lfdat.

      READ TABLE lt_lips
      INDEX 1
      ASSIGNING <wa_lips>.

      APPEND INITIAL LINE TO lt_vbpok ASSIGNING <wa_vbpok>.
      <wa_vbpok>-vbeln_vl = <wa_lips>-vbeln.
      <wa_vbpok>-posnr_vl = <wa_lips>-posnr.
      <wa_vbpok>-matnr    = <wa_lips>-matnr.
      <wa_vbpok>-werks    = <wa_lips>-werks.
      <wa_vbpok>-lianp    = 'X'.
      UNASSIGN <wa_vbpok>.

      LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
        APPEND INITIAL LINE TO lt_vbpok ASSIGNING <wa_vbpok>.
        <wa_vbpok>-vbeln_vl = <wa_lips>-vbeln.
        <wa_vbpok>-posnr_vl = <wa_lips>-posnr.
        <wa_vbpok>-matnr    = <wa_lips>-matnr.
        <wa_vbpok>-werks    = <wa_lips>-werks.
        <wa_vbpok>-charg    = <wa_qmcrm>-ballen_id.
        <wa_vbpok>-lianp    = 'X'.
        <wa_vbpok>-wms_rfpos = '900001'.
        <wa_vbpok>-wms_rfbel = <wa_customer_returns>-retourenauftrag.
        <wa_vbpok>-lgmng     = <wa_qmcrm>-weight.
        <wa_vbpok>-meins     = <wa_lips>-meins.
        <wa_vbpok>-vrkme     = <wa_lips>-vrkme.
      ENDLOOP.

      CALL FUNCTION 'WS_DELIVERY_UPDATE'
        EXPORTING
          vbkok_wa                     = wa_vbkok
          synchron                     = 'X'
          commit                       = ' '
          delivery                     = <wa_customer_returns>-delivery
          if_get_delivery_buffered     = ' '
          if_no_generic_system_service = 'X'
          if_database_update           = '1'
          if_error_messages_send_0     = ''
        IMPORTING
          ef_error_any_0               = lv_error_any_0
          ef_error_in_item_deletion_0  = lv_error_in_item
          ef_error_in_pod_update_0     = lv_error_in_pod
          ef_error_in_interface_0      = lv_error_in_interf
          ef_error_in_goods_issue_0    = lv_error_in_goods
          ef_error_in_final_check_0    = lv_error_in_final
        TABLES
          vbpok_tab                    = lt_vbpok
          prot                         = lt_prot
        EXCEPTIONS
          error_message                = 1
          OTHERS                       = 2.

      IF lt_prot[] IS NOT INITIAL.
        lv_error_occured = abap_true.

        LOOP AT lt_prot ASSIGNING <wa_prot>.
          APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
          <wa_messages>-type = <wa_prot>-msgty.
          <wa_messages>-type = <wa_prot>-msgty.
          <wa_messages>-number = <wa_prot>-msgno.
          <wa_messages>-message_v1 = <wa_prot>-msgv1.
          <wa_messages>-message_v2 = <wa_prot>-msgv2.
          <wa_messages>-message_v3 = <wa_prot>-msgv3.
          <wa_messages>-message_v4 = <wa_prot>-msgv4.
        ENDLOOP.
      ENDIF.

      IF lv_error_any_0 = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_ANY_0'.
      ENDIF.

      IF lv_error_in_item = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_IN_ITEM_DELETION_0'.
      ENDIF.

      IF lv_error_in_pod = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_IN_POD_UPDATE_0'.
      ENDIF.

      IF lv_error_in_interf = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_IN_INTERFACE_0'.
      ENDIF.

      IF lv_error_in_goods = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_IN_GOODS_ISSUE_0'.
      ENDIF.

      IF lv_error_in_final = abap_true.
        APPEND INITIAL LINE TO lt_messages ASSIGNING <wa_messages>.
        <wa_messages>-type = 'E'.
        <wa_messages>-type = 'ZBMS'.
        <wa_messages>-number = 056.
        <wa_messages>-message_v1 = 'EF_ERROR_IN_FINAL_CHECK_0'.
      ENDIF.

      IF lt_messages[] IS NOT INITIAL.
        CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
          TABLES
            i_bapiret2_tab = lt_messages.
      ENDIF.

      CASE lv_error_occured.
        WHEN abap_false.
          LOOP AT lt_qmcrm ASSIGNING <wa_qmcrm>.
            UPDATE zzqmcrm
            SET return_delivery = <wa_customer_returns>-delivery
            WHERE ballen_id = <wa_qmcrm>-ballen_id
              AND werks = <wa_qmcrm>-werks
              AND qmnum = i_viqmel-qmnum.
          ENDLOOP.

          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.

          EXPORT lv_reread_data FROM abap_true TO MEMORY ID co_mem_id_0505_reread.
          MESSAGE s110(zqm) WITH <wa_customer_returns>-delivery.
        WHEN abap_true.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDCASE.
    WHEN co_btn_no.
      RETURN.
    WHEN co_btn_cancel.
      RETURN.
  ENDCASE.

  EXPORT lv_reread_data FROM abap_true TO MEMORY ID co_mem_id_0505_reread.

  CALL TRANSACTION 'QM02' AND SKIP FIRST SCREEN.

  CLEAR: lv_popup_answer, lv_popup_question, wa_vbkok, wa_likp, lv_error_any_0, lv_error_in_item, lv_error_in_pod,
         lv_error_in_interf, lv_error_in_goods, lv_error_in_final, lv_error_occured.
  FREE: lt_customer_returns, lt_qmcrm, lt_lips, lt_vbpok, lt_prot, lt_messages.
ENDFUNCTION.
