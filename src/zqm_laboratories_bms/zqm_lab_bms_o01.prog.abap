*&---------------------------------------------------------------------*
*&      Module  PBO_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0200 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0200'.
  gv_workcenter_screen_number = sy-dynnr.

  IF gv_initialized = abap_false.
    PERFORM set_date_time.
    PERFORM set_default_sel_values.
  ENDIF.

  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM transfer_screenvalues.
  ENDCASE.

  gv_initialized = abap_true.
ENDMODULE.                 " PBO_0200  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0210  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0210 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0200'.
  gv_workcenter_screen_number = sy-dynnr.

  IF gv_initialized = abap_false.
    PERFORM set_date_time.
    PERFORM set_default_sel_values.
  ENDIF.

  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM transfer_screenvalues.
  ENDCASE.

  gv_initialized = abap_true.
ENDMODULE.                 " PBO_0210  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0220  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0220 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0200'.
  gv_workcenter_screen_number = sy-dynnr.

  IF gv_initialized = abap_false.
    PERFORM set_date_time.
    PERFORM set_default_sel_values.
  ENDIF.

  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM transfer_screenvalues.
  ENDCASE.

  gv_initialized = abap_true.
ENDMODULE.                 " PBO_0220  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0230  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0230 OUTPUT.
  SET PF-STATUS 'STATUS_0230'.
  SET TITLEBAR 'TITLE_0200'.
  gv_workcenter_screen_number = sy-dynnr.

  IF gv_initialized = abap_false.
    PERFORM set_date_time.
    PERFORM set_default_sel_values.
  ENDIF.

  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM transfer_screenvalues.
  ENDCASE.

  gv_initialized = abap_true.
ENDMODULE.                 " PBO_0230  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0240  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0240 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0200'.
  gv_workcenter_screen_number = sy-dynnr.

  IF gv_initialized = abap_false.
    PERFORM set_date_time.
    PERFORM set_default_sel_values.
  ENDIF.

  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM transfer_screenvalues.
  ENDCASE.

  gv_initialized = abap_true.
ENDMODULE.                 " PBO_0240  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0300 OUTPUT.
  CASE gv_ok_code.
    WHEN 'EXECUTE'.
      PERFORM execute.
      PERFORM prepare_screen.
    WHEN 'MULTIMNT' OR 'SINGLEMNT'.
      PERFORM handle_tabstrip USING gv_ok_code.
  ENDCASE.

  CLEAR gv_ok_code.
ENDMODULE.                 " PBO_0300  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0310  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0310 OUTPUT.
  IF obj_single_mnt_alv_container IS NOT BOUND.
    PERFORM init_screen_0310.
  ENDIF.
ENDMODULE.                 " PBO_0310  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_0320  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0320 OUTPUT.
  IF obj_multi_mnt_alv_container IS NOT BOUND.
    PERFORM init_screen_0320.
  ENDIF.
ENDMODULE.                 " PBO_0320  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PBO_0400  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0400 OUTPUT.
  SET PF-STATUS 'STATUS_0400'.

  PERFORM init_screen_0400.
  PERFORM load_header_data USING gv_ok_code.
  PERFORM init_header_data_alv.
ENDMODULE.                 " PBO_0400  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PBO_0410  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0410 OUTPUT.
  SET PF-STATUS 'STATUS_0400'.

  PERFORM init_screen_0410.
  PERFORM load_time_reporting_data.
  PERFORM init_time_rep_alv.
ENDMODULE.                 " PBO_0410  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PBO_0420  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_0420 OUTPUT.
  SET PF-STATUS 'STATUS_0400'.

  LOOP AT SCREEN.
    IF screen-group1 = 'ADD'.
      IF gv_historical = abap_false.
        screen-input = '1'.
      ELSE.
        screen-input = '0'.
      ENDIF.

      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.                 " PBO_0420  OUTPUT
