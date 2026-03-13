FUNCTION Z_QM_DEL_REF_ZZQMCRM.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_QMNUM) TYPE  QMNUM
*"     VALUE(I_BALLEN_ID) TYPE  ZBMS_BALLENID
*"     REFERENCE(I_WERKS) TYPE  WERKS_S DEFAULT ''
*"  EXPORTING
*"     VALUE(E_QNQMAMA0) LIKE  QNQMAMA0 STRUCTURE  QNQMAMA0
*"  EXCEPTIONS
*"      ACTION_STOPPED
*"----------------------------------------------------------------------

if I_QMNUM is INITIAL or I_BALLEN_ID is INITIAL.
  exit.
else.
  UPDATE zzqmcrm
     SET retourenauftrag = ''
     WHERE ballen_id = I_BALLEN_ID
     AND werks = I_WERKS
     AND QMNUM = I_QMNUM.
endif.
ENDFUNCTION.
