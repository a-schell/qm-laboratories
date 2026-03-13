FUNCTION z_qm_call_sharepoint_doc.
*"--------------------------------------------------------------------
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
*"--------------------------------------------------------------------
  DATA lv_url TYPE string.
  DATA wa_zqmel TYPE zqmel.

  CALL FUNCTION 'Z_QM_SHAREPOINT_AUTH_NOTIF_PRT'
    EXPORTING
      iv_qmnum             = i_viqmel-qmnum
      iv_role              = 'KU'
    EXCEPTIONS
      notificion_not_found = 1
      sharepoint_error     = 2
      no_partners_found    = 3
      OTHERS               = 4.

  SELECT SINGLE *
  FROM zqmel
  INTO wa_zqmel
  WHERE qmnum = i_viqmel-qmnum.

  IF sy-subrc IS INITIAL AND wa_zqmel-zzcrmurl IS NOT INITIAL.
    lv_url = wa_zqmel-zzdokurl.

    CALL METHOD cl_gui_frontend_services=>execute
      EXPORTING
        document               = lv_url
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10.

    IF sy-subrc IS NOT INITIAL.
      MESSAGE e071(zqm).
    ENDIF.
  ENDIF.

  CLEAR: lv_url, wa_zqmel.
ENDFUNCTION.
