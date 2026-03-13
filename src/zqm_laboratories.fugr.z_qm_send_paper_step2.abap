FUNCTION Z_QM_SEND_PAPER_STEP2.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"     VALUE(I_MANUM) LIKE  QMSM-MANUM
*"     VALUE(I_AUFGABE) TYPE  SWW_TASK DEFAULT SPACE
*"  TABLES
*"      TI_IVIQMFE STRUCTURE  WQMFE
*"      TI_IVIQMUR STRUCTURE  WQMUR
*"      TI_IVIQMSM STRUCTURE  WQMSM
*"      TI_IVIQMMA STRUCTURE  WQMMA
*"      TI_IHPAD STRUCTURE  IHPAD
*"      T_CONTAINER STRUCTURE  SWCONT OPTIONAL
*"----------------------------------------------------------------------

** Felder löschen
** Clear fields and tables
*  CLEAR    G_SPEC_ADR.
*  CLEAR    G_PARTNER_TAB.   REFRESH  G_PARTNER_TAB.
*  CLEAR    ACT_PARTNER.
*  CLEAR    L_TFILL.
*  CLEAR    G_BESCHEID_MANUM.
*
*  MOVE I_VIQMEL   TO VIQMEL.
*
*  MOVE I_MANUM TO G_BESCHEID_MANUM.

* Daten sollen aus aktuellem FB gelesen werden
* read printing data from this program*
*  ITCPO-TDPROGRAM = SY-REPID.
*
*  LOOP AT G_REPLY_TYPE WHERE MANUM = I_MANUM
*                          OR MANUM = G_BESCHEID_MANUM.
*
** Setzen des Titels des Dokuments.
*    if viqmel-herkz eq 'C1' or viqmel-herkz eq 'C2'.
*      CONCATENATE g_reply_type-doku_type text-cnr viqmel-qmnum INTO
*                itcpo-tdtitle SEPARATED BY space.
*    else.
*      CONCATENATE g_reply_type-doku_type text-mnr viqmel-qmnum INTO
*                itcpo-tdtitle SEPARATED BY space.
*    endif.
*      MOVE WA_INTER_ITCPO TO ITCPO.
*break: extjaw.
      PERFORM PRINT_REPLY_PDF(ZQM06F21).

*  ENDLOOP.
ENDFUNCTION.
