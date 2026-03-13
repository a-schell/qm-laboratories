*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_TEST_DEVICE_IMP_SEL
*&---------------------------------------------------------------------*

PARAMETERS: p_plant TYPE werks_d DEFAULT '1101'.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK a WITH FRAME.
PARAMETERS: p_opt1 RADIOBUTTON GROUP a DEFAULT 'X'.
SELECT-OPTIONS: s_files FOR lv_filename.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: p_opt2 RADIOBUTTON GROUP a.
PARAMETERS: p_sess TYPE sysuuid_c32.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: p_opt3 RADIOBUTTON GROUP a.
PARAMETERS: p_stat TYPE zqm_dev_transfer-status.
SELECTION-SCREEN: END OF BLOCK a.
PARAMETERS: p_test AS CHECKBOX DEFAULT 'X'.
PARAMETERS: p_debug AS CHECKBOX DEFAULT abap_false.

AT SELECTION-SCREEN.
  IF p_opt1 = abap_true.
    IF p_plant IS INITIAL.
      MESSAGE TEXT-e01 TYPE 'W'.
    ENDIF.
  ELSEIF p_opt2 = abap_true.
    IF p_sess IS INITIAL.
      MESSAGE TEXT-e02 TYPE 'W'.
    ENDIF.
  ENDIF.
