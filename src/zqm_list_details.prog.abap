*&---------------------------------------------------------------------*
*& Report  ZQM_LIST_DETAILS
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Artelsmair, art@informatics.at
*& DATE: 20.02.2017
*&---------------------------------------------------------------------*

REPORT zqm_list_details.
TYPE-POOLS : slis,icon.
INCLUDE <cl_alv_control>.

DATA: lt_qmel TYPE TABLE OF qmel.
DATA: ls_qmel TYPE qmel.
DATA: lt_zqmprobes TYPE TABLE OF zqmprobes.
DATA: ls_zqmprobes TYPE zqmprobes.
DATA: lt_qals TYPE TABLE OF qals.
DATA: ls_qals TYPE qals.
DATA: lt_qasr TYPE TABLE OF qasr.
DATA: ls_qasr TYPE qasr.
DATA: ls_qpmt TYPE qpmt.
DATA: lv_status TYPE xfeld.
DATA: ls_vorgangdata TYPE qapo.
DATA: lv_meldung TYPE qmnum.
DATA: lv_meldstat TYPE bsvx-sttxt.
DATA: lt_meldstat TYPE TABLE OF bsvx-sttxt.
DATA: ls_rqprs TYPE rqprs.
DATA: lv_bearbeiten TYPE xfeld.




DATA: lt_vorgaenge TYPE TABLE OF bapi2045l2.
DATA: ls_vorgang TYPE bapi2045l2.
DATA: lt_merkmal TYPE TABLE OF bapi2045d3.
DATA: ls_merkmal TYPE bapi2045d3.
DATA: ls_vorgang_info TYPE bapi2045l2.
DATA: lt_requirements TYPE TABLE OF bapi2045d1.
DATA: ls_requirements TYPE  bapi2045d1.

*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver DEFINITION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.

  PUBLIC SECTION.
    METHODS:

    handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
            IMPORTING e_object e_interactive,

    handle_double_click
        FOR EVENT double_click OF cl_gui_alv_grid
            IMPORTING e_row e_column,

    handle_detail_click
        FOR EVENT before_user_command OF cl_gui_alv_grid
            IMPORTING e_ucomm,

    handle_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
            IMPORTING e_row_id e_column_id es_row_no,

    handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
            IMPORTING e_ucomm.

  PRIVATE SECTION.

ENDCLASS.                    "lcl_event_receiver DEFINITION




DATA: ls_alvdata TYPE zqm_detaillist.
DATA: lt_alvdata TYPE TABLE OF zqm_detaillist.
DATA: lt_alvdata_old TYPE TABLE OF zqm_detaillist.
DATA: ls_alvdata_old TYPE zqm_detaillist.
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv.


DATA: lv_changed TYPE char1.

DATA: excl_tb TYPE ui_functions.
DATA: grid TYPE          REF TO cl_gui_alv_grid,
      g_custom_container TYPE REF TO cl_gui_custom_container,
      event_receiver     TYPE REF TO lcl_event_receiver,
      fcat               TYPE lvc_t_fcat WITH HEADER LINE,
      variant            TYPE disvariant.



START-OF-SELECTION.
*  PARAMETERS p_datum type qmel-erdat OBLIGATORY .
*  PARAMETERS p_labor type ARBPL OBLIGATORY.

  SELECT-OPTIONS: p_meld FOR ls_qmel-qmnum.
  SELECT-OPTIONS: p_los FOR ls_zqmprobes-prueflos.
  SELECT-OPTIONS: p_probe FOR ls_rqprs-phynr.
  SELECT-OPTIONS: p_plnnr FOR ls_zqmprobes-plnnr.



  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


*  PARAMETERS p_meld TYPE qmnum.
*  PARAMETERS p_los TYPE qplos.
*  PARAMETERS p_probe TYPE QPHYSPRNR.
*  PARAMETERS p_PLNNR  TYPE PLNNR.

*AT SELECTION-SCREEN .
*  IF p_probe IS NOT INITIAL.
*
*    IF p_meld IS INITIAL AND p_los  IS  INITIAL.
*
*      MESSAGE e899(mm) WITH text-002.
*
*    ENDIF.
*  ENDIF.




END-OF-SELECTION.



  PERFORM daten_lesen.
  PERFORM alv_erzeugen.

*&---------------------------------------------------------------------*
*&      Form  daten_lesen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM daten_lesen.

  SELECT * FROM zqmprobes INTO TABLE lt_zqmprobes WHERE qmnum IN p_meld AND prueflos IN p_los AND plnnr IN p_plnnr AND phynr IN p_probe.


  LOOP AT lt_zqmprobes INTO ls_zqmprobes.


* Meldung lesen
    SELECT SINGLE * FROM qmel INTO ls_qmel WHERE qmnum = ls_zqmprobes-qmnum.


    CALL FUNCTION 'STATUS_TEXT_EDIT'
      EXPORTING
*       CLIENT                  = SY-MANDT
*       FLG_USER_STAT           = ' '
        objnr                   = ls_qmel-objnr
*       ONLY_ACTIVE             = 'X'
        spras                   = sy-langu
*       BYPASS_BUFFER           = ' '
      IMPORTING
*       ANW_STAT_EXISTING       =
*       E_STSMA                 =
        line                    = lv_meldstat
*       USER_LINE               =
*       STONR                   =
*     EXCEPTIONS
*       OBJECT_NOT_FOUND        = 1
*       OTHERS                  = 2
              .
    IF sy-subrc = 0.
      SPLIT lv_meldstat AT space INTO TABLE lt_meldstat.
      READ TABLE lt_meldstat INDEX 1 INTO ls_alvdata-meldungsstatus.
    ENDIF.

    ls_alvdata-num = ls_qmel-qmnum.


* Prüflos lesen
    SELECT * FROM qals INTO TABLE lt_qals WHERE prueflos = ls_zqmprobes-prueflos.

    ls_alvdata-meldungtext = ls_qmel-qmtxt.
    ls_alvdata-ernam = ls_qmel-ernam.
    ls_alvdata-erdat = ls_qmel-erdat.
    ls_alvdata-aedat = ls_qmel-aedat.
    ls_alvdata-aenam = ls_qmel-aenam.
    ls_alvdata-werk = ls_qmel-mawerk.
    ls_alvdata-auftraggeber = ls_qmel-buname.
    ls_alvdata-pspelement = ls_qmel-zzpspel.
    ls_alvdata-wunschtermin = ls_qmel-ltrmn.
    ls_alvdata-auftragnehmer = ls_qmel-zzarbpl.
    ls_alvdata-kurztext = ls_qmel-zzqmbsttx.

    ls_alvdata-prueflos = ls_zqmprobes-prueflos.
    ls_alvdata-phyprob = ls_zqmprobes-phynr.
    ls_alvdata-probmeng = ls_zqmprobes-menge.
    ls_alvdata-einheit = ls_zqmprobes-meinh.
    ls_alvdata-sollzeit = ls_zqmprobes-zzqmsollzeit.
    ls_alvdata-zeiteinh = ls_zqmprobes-zzqmsollzeiteinh.
    ls_alvdata-plnnr = ls_zqmprobes-plnnr.
    ls_alvdata-probenbez = ls_zqmprobes-prbdesc.
    ls_alvdata-probennr = ls_zqmprobes-prbnr.
    ls_alvdata-gewuntersuch = ls_zqmprobes-prbexam.


    SELECT SINGLE nchmc FROM pa0002 INTO ls_alvdata-auftraggebername WHERE pernr = ls_alvdata-auftraggeber.

    APPEND ls_alvdata TO lt_alvdata.

  ENDLOOP.






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
  SET TITLEBAR 'TITLE'.

  IF g_custom_container IS INITIAL.

    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = 'CUST_CONTROL'.

    CREATE OBJECT grid
      EXPORTING
        i_parent = g_custom_container.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZQM_DETAILLIST'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = fcat[].

    LOOP AT fcat.

      CASE fcat-fieldname.
        WHEN 'KURZTEXT'.
          fcat-scrtext_s = 'Kommentar'.
          fcat-scrtext_m = 'Kommentar'.
          fcat-scrtext_l = 'Kommentar'.
        WHEN 'NUM'.
          fcat-style = alv_style_font_underlined.
        WHEN 'PRUEFLOS'.
          fcat-style = alv_style_font_underlined.
        WHEN 'PHYPROB'.
          fcat-style = alv_style_font_underlined.
        WHEN 'PLNNR'.
          fcat-style = alv_style_font_underlined.

      ENDCASE.


      MODIFY fcat.
    ENDLOOP.

*    APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_move_row TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_paste TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_cut TO excl_tb.
*    APPEND cl_gui_alv_grid=>mc_fc_loc_append_row TO excl_tb.

    variant-report  = sy-repid.
    SORT lt_alvdata ASCENDING BY num probennr.


    CALL METHOD grid->set_table_for_first_display
      EXPORTING
        i_structure_name     = 'ZQM_DETAILLIST'
        i_save               = 'A'
        is_variant           = variant
*       it_toolbar_excluding = excl_tb
      CHANGING
        it_outtab            = lt_alvdata
        it_fieldcatalog      = fcat[].



    CREATE OBJECT event_receiver.
    SET HANDLER event_receiver->handle_double_click      FOR grid.
    SET HANDLER event_receiver->handle_detail_click      FOR grid.
    SET HANDLER event_receiver->handle_hotspot_click     FOR grid.
    SET HANDLER event_receiver->handle_toolbar           FOR grid.
    SET HANDLER event_receiver->handle_user_command FOR grid.

    CALL METHOD grid->set_toolbar_interactive.



  ENDIF.






ENDMODULE.                 " INIT  OUTPUT


*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver IMPLEMENTATION.

  METHOD handle_toolbar.
* § 2.In event handler method for event TOOLBAR: Append own functions
*   by using event parameter E_OBJECT.
    DATA: ls_toolbar  TYPE stb_button.
*....................................................................
* E_OBJECT of event TOOLBAR is of type REF TO CL_ALV_EVENT_TOOLBAR_SET.
* This class has got one attribute, namly MT_TOOLBAR, which
* is a table of type TTB_BUTTON. One line of this table is
* defined by the Structure STB_BUTTON (see data deklaration above).
*

* A remark to the flag E_INTERACTIVE:
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*         'e_interactive' is set, if this event is raised due to
*         the call of 'set_toolbar_interactive' by the user.
*         You can distinguish this way if the event was raised
*         by yourself or by ALV
*         (e.g. in method 'refresh_table_display').
*         An application of this feature is still unknown... :-)

    CLEAR ls_toolbar.
    MOVE 3 TO ls_toolbar-butn_type.
    APPEND ls_toolbar TO e_object->mt_toolbar.
* append an icon to show booking table
    CLEAR ls_toolbar.
    MOVE 'Bearbeiten' TO ls_toolbar-function.
    MOVE  icon_change TO ls_toolbar-icon.
    MOVE 'In Bearbeitungsmodus springen'(111) TO ls_toolbar-quickinfo.
    MOVE ' ' TO ls_toolbar-disabled.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.                    "handle_toolbar

  METHOD handle_double_click.
    CLEAR ls_alvdata.
    READ TABLE lt_alvdata INDEX e_row-index INTO ls_alvdata.
    IF e_column = 'NUM' AND ls_alvdata-num IS NOT INITIAL.
      CHECK: sy-subrc = 0.
      IF lv_bearbeiten = 'X'.
        SET PARAMETER ID 'IQM' FIELD ls_alvdata-num.
        CALL TRANSACTION 'QM02' AND SKIP FIRST SCREEN.
      ELSE.
        SET PARAMETER ID 'IQM' FIELD ls_alvdata-num.
        CALL TRANSACTION 'QM03' AND SKIP FIRST SCREEN.
      ENDIF.
    ELSEIF e_column = 'PRUEFLOS' AND ls_alvdata-prueflos IS NOT INITIAL.
      IF lv_bearbeiten = 'X'.
        SET PARAMETER ID  'QLS' FIELD ls_alvdata-prueflos.
        CALL TRANSACTION 'QA02'   AND SKIP FIRST SCREEN.
      ELSE.
        SET PARAMETER ID  'QLS' FIELD ls_alvdata-prueflos.
        CALL TRANSACTION 'QA03'   AND SKIP FIRST SCREEN.
      ENDIF.
    ELSEIF e_column = 'PHYPROB' AND ls_alvdata-phyprob IS NOT INITIAL.
      IF lv_bearbeiten = 'X'.
        SET PARAMETER ID 'QPN' FIELD ls_alvdata-phyprob.
        CALL TRANSACTION 'QPR2' AND SKIP FIRST SCREEN.
      ELSE.
        SET PARAMETER ID 'QPN' FIELD ls_alvdata-phyprob.
        CALL TRANSACTION 'QPR3' AND SKIP FIRST SCREEN.
      ENDIF.
    ELSEIF e_column = 'PLNNR' AND ls_alvdata-plnnr IS NOT INITIAL.

      IF lv_bearbeiten = 'X'.
        SET PARAMETER ID 'PLN' FIELD ls_alvdata-plnnr.
        CALL TRANSACTION 'QP02' AND SKIP FIRST SCREEN.
      ELSE.
        SET PARAMETER ID 'PLN' FIELD ls_alvdata-plnnr.
        CALL TRANSACTION 'QP03' AND SKIP FIRST SCREEN.
      ENDIF.

    ENDIF.




  ENDMETHOD.                           "handle_double_click


  METHOD handle_detail_click.


  ENDMETHOD.                    "handle_detail_click

  METHOD handle_user_command.
* § 3.In event handler method for event USER_COMMAND: Query your
*   function codes defined in step 2 and react accordingly.

    DATA: lt_rows TYPE lvc_t_row.

    CASE e_ucomm.
      WHEN 'Bearbeiten'.
        IF lv_bearbeiten = 'X'.
          lv_bearbeiten = ''.
        ELSE.
          lv_bearbeiten = 'X'.
        ENDIF.
*        CALL METHOD grid->get_selected_rows
*                 IMPORTING et_index_rows = lt_rows.
*        CALL METHOD cl_gui_cfw=>flush.
*        IF sy-subrc ne 0.
** add your handling, for example
*          CALL FUNCTION 'POPUP_TO_INFORM'
*               EXPORTING
*                    titel = g_repid
*                    txt2  = sy-subrc
*                    txt1  = 'Error in Flush'(500).
*        else.
*                  perform show_booking_table tables lt_rows.
*        ENDIF.
    ENDCASE.
  ENDMETHOD.                    "handle_user_command


  METHOD handle_hotspot_click.

    CALL METHOD grid->refresh_table_display.


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
*  SET TITLEBAR 'xxx'.

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


ENDFORM.                    " SAVE_STATUS
