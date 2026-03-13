FUNCTION z_shlp_exit_workplace.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     REFERENCE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: ls_record LIKE seahlpres.
  DATA: lv_workplace   TYPE string.
  DATA: lv_user   TYPE string.
  DATA: lv_kztxt TYPE string.
  DATA: lt_split    TYPE TABLE OF char40.
  DATA: ls_crhd TYPE crhd.


  LOOP AT record_tab INTO ls_record.
    lv_user = ls_record-string+0(12).
    lv_workplace = ls_record-string+12(8).

    SELECT SINGLE * FROM crhd INTO ls_crhd  WHERE arbpl = lv_workplace.

    SELECT SINGLE ktext FROM crtx INTO ls_record-string+20 where objty = ls_crhd-objty and objid = ls_crhd-objid
                  and spras eq sy-langu.

    IF sy-subrc = 0.
      MODIFY record_tab FROM ls_record.
    ENDIF.
* Wenn Arbeitsplatz nicht dem User zugeordnet, entfernen!
    IF lv_user NE sy-uname.
      DELETE record_tab INDEX sy-tabix.
    ENDIF.
    CLEAR lt_split.
    CLEAR lv_user.
    CLEAR lv_workplace.


  ENDLOOP.




ENDFUNCTION.
