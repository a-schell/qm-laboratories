FUNCTION Z_QM_BMS_BALE_ANALYSIS.
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
*215684 - 05.07.2022: wurde zuvor für die Funktion ZC 0006 in der Aktivitätenleiste der QM-Meldung verwendet.
*der FUBA war mit der Funktion 0006 verknüpft, die Funktion wurde jedoch aus der Aktivitätenleiste gelöscht
*Entscheidung Projektleiter CC (A.00409.REALI.01): Canins Robert + Liggins James


  CONSTANTS: LC_MEM_ID_0505 TYPE CHAR40 VALUE 'GT_PROBES_0505',
             LC_DOC_TYPE TYPE AUART VALUE 'ZFRE'.

  TYPES ty_rg_sbalid   TYPE RANGE OF zbms_sdif_matnr.

  DATA: lt_rg_sbalid   TYPE ty_rg_sbalid,
        ls_rg_sbalid   LIKE LINE OF lt_rg_sbalid.

  DATA: LT_QMCRM      TYPE TABLE OF ZZQMCRM,
        LS_QMCRM      TYPE ZZQMCRM.
  DATA: LV_VBELN      TYPE VBELN,
        LV_MATNR      TYPE MATNR,
        LV_VKORG      TYPE VKORG,
        LV_VTWEG      TYPE VTWEG,
        LV_SPART      TYPE SPART,
        LV_VKBUR      TYPE VKBUR,
        LV_KUNAG      TYPE KUNAG.
  DATA: LS_VBAK       TYPE BAPISDHD1,
        LT_RETURN     TYPE TABLE OF BAPIRET2,
        LS_RETURN     TYPE BAPIRET2,
        LT_VBAP       TYPE TABLE OF BAPISDITM,
        LS_VBAP       TYPE BAPISDITM,
        LT_VBAPX      TYPE TABLE OF BAPISDITMX,
        LT_VBPA       TYPE TABLE OF BAPIPARNR,
        LS_VBPA       TYPE BAPIPARNR,
        LT_VBEP       TYPE TABLE OF BAPISCHDL,
        LS_VBEP       TYPE BAPISCHDL,
        lv_itm_numb   type vbap-posnr.

  DATA: ROLE_A TYPE BORIDENT,
        ROLE_B TYPE BORIDENT.

*  "get probes table from include ZXQQMI05
  IMPORT GT_QMCRM_0505 TO LT_QMCRM FROM MEMORY ID LC_MEM_ID_0505.
  FREE MEMORY ID LC_MEM_ID_0505.
* Read parameter
*  READ TABLE LT_QMCRM WITH KEY MARK = 'X' TRANSPORTING NO FIELDS.
*  IF SY-SUBRC IS NOT INITIAL.
*    MESSAGE E100(ZQM).

* Read parameter
*  ELSE.
    LOOP AT LT_QMCRM INTO LS_QMCRM.  "WHERE MARK IS NOT INITIAL.
      lv_itm_numb = lv_itm_numb + 10.
      SELECT SINGLE VKORG VTWEG SPART FROM VBRK INTO (LV_VKORG, LV_VTWEG, LV_SPART)
        WHERE  VBELN = LS_QMCRM-FAKNR.
      IF SY-SUBRC IS INITIAL.
        if not ( LS_QMCRM-BALLEN_ID is INITIAL ).
          ls_rg_sbalid-sign   = 'I'.
          ls_rg_sbalid-option = 'EQ'.
          ls_rg_sbalid-low = LS_QMCRM-BALLEN_ID.
          APPEND ls_rg_sbalid TO lt_rg_sbalid.
        endif.
      ELSE.
        MESSAGE E102(ZQM).
      ENDIF.
    ENDLOOP.

* Delivery Baledata Report aufrufen
    SUBMIT zbms_rep_delivery_bale_data
      "WITHOUT SELECTION-SCREEN
      "WITH pa_werks EQ '1101'
      WITH pa_main1 EQ ' '
      WITH pa_main2 EQ ' '
      WITH pa_main3 EQ 'X'
      WITH so_balid IN lt_rg_sbalid
      WITH pa_ecall EQ 'X' AND RETURN.
*  ENDIF.
ENDFUNCTION.
