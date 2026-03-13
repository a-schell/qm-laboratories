FUNCTION z_qm_send_paper.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"     VALUE(I_CUSTOMIZING) LIKE  V_TQ85 STRUCTURE  V_TQ85
*"     VALUE(I_MANUM) LIKE  QMSM-MANUM
*"     VALUE(I_FBCALL)
*"  EXPORTING
*"     VALUE(E_QNQMASM0) LIKE  QNQMASM0 STRUCTURE  QNQMASM0
*"     VALUE(E_QNQMAQMEL0) LIKE  QNQMAQMEL0 STRUCTURE  QNQMAQMEL0
*"     VALUE(E_BUCH) TYPE  QKZ
*"  TABLES
*"      TI_IVIQMFE STRUCTURE  WQMFE
*"      TI_IVIQMUR STRUCTURE  WQMUR
*"      TI_IVIQMSM STRUCTURE  WQMSM
*"      TI_IVIQMMA STRUCTURE  WQMMA
*"      TI_IHPA STRUCTURE  IHPA
*"      TE_CONTAINER STRUCTURE  SWCONT OPTIONAL
*"      TE_LINES STRUCTURE  TLINE OPTIONAL
*"  EXCEPTIONS
*"      ACTION_STOPPED
*"----------------------------------------------------------------------

  DATA: lt_ihpad     LIKE TABLE OF ihpad WITH HEADER LINE,
        lt_qkat      LIKE TABLE OF qkat WITH HEADER LINE,
        lt_workpaper LIKE TABLE OF wworkpaper WITH HEADER LINE.

  MOVE-CORRESPONDING ti_ihpa TO lt_ihpad.
*  BREAK:EXTJAW.
  IF i_customizing-funktion = '08'.
    lt_workpaper-workpaper = '5911'.
    CONCATENATE 'Q-Meldung Prüfreport' i_viqmel-qmnum i_viqmel-qmtxt INTO lt_workpaper-tdcovtitle SEPARATED BY space.
  ELSEIF i_customizing-funktion = '06'.
    lt_workpaper-workpaper = '5913'.
    CONCATENATE 'Q-Meldung Auftragsbestätigung' i_viqmel-qmnum i_viqmel-qmtxt INTO lt_workpaper-tdcovtitle SEPARATED BY space.
  ELSEIF i_customizing-funktion = '10'.
    lt_workpaper-workpaper = '5920'.
    CONCATENATE 'Probenetiketten Meldung' i_viqmel-qmnum INTO lt_workpaper-tdcovtitle SEPARATED BY space.
  ELSE.
    MESSAGE e020(zqm).
  ENDIF.

  lt_workpaper-selected = 'X'.
  lt_workpaper-pm_appl = 'N'.
  lt_workpaper-print_lang = syst-langu.
  APPEND lt_workpaper.

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
    e_qnqmasm0-matxt = 'erfolgreich versandt'.
    COMMIT WORK.
  ENDIF.
ENDFUNCTION.
