class ZCL_IM_QM_LAB_NOTIF_SAVE definition
  public
  final
  create public .

public section.

  interfaces IF_EX_NOTIF_EVENT_SAVE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_QM_LAB_NOTIF_SAVE IMPLEMENTATION.


METHOD if_ex_notif_event_save~change_data_at_save.
  DATA: lt_ihpad TYPE TABLE OF ihpad,
        lt_qkat TYPE TABLE OF qkat,
        lt_workpaper TYPE TABLE OF wworkpaper,
        ls_workpaper TYPE wworkpaper,
        i_viqmel TYPE viqmel,
        ti_iviqmfe TYPE TABLE OF wqmfe,
        ti_iviqmma TYPE TABLE OF wqmma,
        ti_iviqmsm TYPE TABLE OF wqmsm,
        ti_iviqmur TYPE TABLE OF wqmur.

*  break: extjaw.
  IF is_t365-aktyp = 'H'.

    MOVE-CORRESPONDING cs_viqmel TO i_viqmel.
*  MOVE-CORRESPONDING TI_IHPA TO LT_IHPAD.
*  BREAK:EXTJAW.

    ls_workpaper-workpaper = '5910'.
    CONCATENATE 'Eingangsbestätigung Meldung' i_viqmel-qmnum INTO ls_workpaper-tdcovtitle SEPARATED BY space.

    ls_workpaper-selected = 'X'.
    ls_workpaper-pm_appl = 'N'.
    ls_workpaper-print_lang = syst-langu.
    APPEND ls_workpaper TO lt_workpaper.

    i_viqmel-ernam = sy-uname.
    i_viqmel-erdat = sy-datum.

    CALL FUNCTION 'PM_NOTIFICATION_PRINT_CONTROL'
      EXPORTING
        device               = 'PRINTER '
        iviqmel              = i_viqmel
        print_language       = syst-langu
      TABLES
        iqkat                = lt_qkat
        iviqmfe              = ti_iviqmfe
        iviqmma              = ti_iviqmma
        iviqmsm              = ti_iviqmsm
        iviqmur              = ti_iviqmur
        iworkpaper           = lt_workpaper
        ihpad_tab            = lt_ihpad
      EXCEPTIONS
        no_workpapers_passed = 1
        OTHERS               = 2.
    IF sy-subrc = 0.
      "also send probe label
      CLEAR: lt_workpaper, ls_workpaper.
      ls_workpaper-workpaper = '5921'.
      ls_workpaper-selected = 'X'.
      ls_workpaper-pm_appl = 'N'.
      ls_workpaper-print_lang = syst-langu.
      CONCATENATE 'Probenetiketten Meldung' i_viqmel-qmnum INTO ls_workpaper-tdcovtitle SEPARATED BY space.
      APPEND ls_workpaper TO lt_workpaper.

      CALL FUNCTION 'PM_NOTIFICATION_PRINT_CONTROL'
        EXPORTING
          device               = 'PRINTER '
          iviqmel              = i_viqmel
          print_language       = syst-langu
        TABLES
          iqkat                = lt_qkat
          iviqmfe              = ti_iviqmfe
          iviqmma              = ti_iviqmma
          iviqmsm              = ti_iviqmsm
          iviqmur              = ti_iviqmur
          iworkpaper           = lt_workpaper
          ihpad_tab            = lt_ihpad
        EXCEPTIONS
          no_workpapers_passed = 1
          OTHERS               = 2.
    ENDIF.
  ENDIF.
ENDMETHOD.
ENDCLASS.
