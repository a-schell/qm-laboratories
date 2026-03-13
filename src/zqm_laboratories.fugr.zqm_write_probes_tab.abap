FUNCTION zqm_write_probes_tab.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_QMNUM) TYPE  QMNUM
*"     VALUE(IT_PROBES) TYPE  ZQMPROBES_T
*"----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 21.11.2016
*& DESCRIPTION: insert probes into ZQMPROBES from QM01/02
*& CHANGE:
*&---------------------------------------------------------------------*
  DATA: ls_probes TYPE zqmprobes.

  DELETE FROM zqmprobes WHERE qmnum EQ iv_qmnum.

  LOOP AT it_probes INTO ls_probes.
    ls_probes-mandt = sy-mandt.
    ls_probes-qmnum = iv_qmnum.
    MODIFY it_probes FROM ls_probes.
  ENDLOOP.

  MODIFY zqmprobes FROM TABLE it_probes.
ENDFUNCTION.
