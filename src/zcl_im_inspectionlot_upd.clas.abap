class ZCL_IM_INSPECTIONLOT_UPD definition
  public
  final
  create public .

public section.

  interfaces IF_EX_INSPECTIONLOT_UPDATE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_INSPECTIONLOT_UPD IMPLEMENTATION.


METHOD if_ex_inspectionlot_update~change_at_save.

  DATA: ls_zqm_act_insplot TYPE zqm_act_insplot,
        insplot            TYPE qals.
*
  CLEAR insplot.
  MOVE-CORRESPONDING new_insplot TO insplot.

  IF insplot-pplverw = 'Z5'.

    IF insplot-zzlinienr IS INITIAL.
      sy-msgid = 'ZQM'.
      sy-msgno = '400'.
      RAISE error_with_message.
    ENDIF.
* ---> Starttermin < = & Endtermin
    IF ( ( insplot-paendterm <= insplot-pastrterm AND insplot-paendzeit <= insplot-pastrzeit ) )
      OR ( insplot-paendterm IS INITIAL OR
           insplot-pastrterm IS INITIAL OR
           insplot-paendzeit IS INITIAL OR
           insplot-pastrzeit IS INITIAL ).
      sy-msgid = 'ZQM'.
      sy-msgno = '401'.
      RAISE error_with_message.
    ENDIF.



 "   CALL FUNCTION 'ZQM_ACT_INSPLOT_CHG_STATUS'
"      EXPORTING
"        insplot       = old_insplot
"*        insplot_new   = new_insplot
"        STATUS        = 'D'
"      EXCEPTIONS
"        error_status  = 1
"        error_delete  = 2
"        error_insert  = 3
"        error_satz_da = 4
"        OTHERS        = 5.

"    IF sy-subrc <> 0.
"*      sy-msgid = 'ZQM'.
"*      sy-msgno = '405'.
"*      RAISE error_with_message.
"    ENDIF.

   CALL FUNCTION 'ZQM_ACT_INSPLOT_CHG_STATUS'
      EXPORTING
        insplot       = new_insplot
*        insplot_new   = new_insplot
*        STATUS        = 'D'
      EXCEPTIONS
        error_status  = 1
        error_delete  = 2
        error_insert  = 3
        error_satz_da = 4
        OTHERS        = 5.

    IF sy-subrc <> 0.
*      sy-msgid = 'ZQM'.
*      sy-msgno = '405'.
*      RAISE error_with_message.
    ENDIF.


  ENDIF.

ENDMETHOD.


method IF_EX_INSPECTIONLOT_UPDATE~CHANGE_BEFORE_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~CHANGE_IN_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~CHANGE_UD_AT_SAVE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~CHANGE_UD_BEFORE_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~CHANGE_UD_IN_UPDATE.
endmethod.


METHOD if_ex_inspectionlot_update~create_at_save.

  DATA: ls_zqm_act_insplot TYPE zqm_act_insplot.

  IF insplot-pplverw = 'Z5'.

* ---> Check Linenumber for Inspection lot
    IF insplot-zzlinienr IS INITIAL.
*      MESSAGE i400(zqm).
      sy-msgid = 'ZQM'.
      sy-msgno = '400'.
      RAISE error_with_message.
*      EXIT.
    ENDIF.
* ---> Starttermin < = & Endtermin
    IF ( ( insplot-paendterm <= insplot-pastrterm AND insplot-paendzeit <= insplot-pastrzeit ) ).
*      MESSAGE i401(zqm).
      sy-msgid = 'ZQM'.
      sy-msgno = '401'.
      RAISE error_with_message.
    ENDIF.

    CALL FUNCTION 'ZQM_ACT_INSPLOT_CHG_STATUS'
      EXPORTING
        insplot       = insplot
        insplot_new   = insplot
*       STATUS        =
      EXCEPTIONS
        error_status  = 1
        error_delete  = 2
        error_insert  = 3
        error_satz_da = 4
        abbruch_user  = 5
        OTHERS        = 6.

    IF sy-subrc EQ 5.
      sy-msgid = 'ZQM'.
      sy-msgno = '407'.
      RAISE error_with_message.
    ENDIF.
    IF sy-subrc <> 0.
*      MESSAGE i405(zqm).
      sy-msgid = 'ZQM'.
      sy-msgno = '405'.
      RAISE error_with_message.
    ENDIF.


  ENDIF.

  IF insplot-art = 'ZLAG-90'.
    "      sy-msgid = 'ZQM'.
    "      sy-msgno = '405'.
    "      RAISE error_with_message.
    "EXIT.
    CLEAR insplot.

  ENDIF.




ENDMETHOD.


method IF_EX_INSPECTIONLOT_UPDATE~CREATE_BEFORE_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~CREATE_IN_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~SET_UD_AT_SAVE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~SET_UD_BEFORE_UPDATE.
endmethod.


method IF_EX_INSPECTIONLOT_UPDATE~SET_UD_IN_UPDATE.
endmethod.
ENDCLASS.
