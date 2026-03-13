*----------------------------------------------------------------------*
***INCLUDE ZXQQMO08.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  CREATE_TEXT_CONTROL_0504  OUTPUT
*&---------------------------------------------------------------------*
MODULE create_text_control_0504 OUTPUT.
  DATA: lt_lines  TYPE tline_t,
        ls_line   TYPE tline,
        lt_text   TYPE TABLE OF text132.

  IF go_summary_cont IS NOT BOUND AND go_summary_text IS NOT BOUND.
    CREATE OBJECT go_summary_cont
      EXPORTING
        container_name              = 'GO_SUMMARY_TEXT'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    CREATE OBJECT go_summary_text
      EXPORTING
        parent                     = go_summary_cont
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = 131
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

    "read and set existing text
    gs_summary_head-tdobject = 'ZQM_MELD'.
    gs_summary_head-tdid     = 'ZQSU'.
    gs_summary_head-tdname   = viqmel-qmnum.
    gs_summary_head-tdspras  = sy-langu.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id                      = gs_summary_head-tdid
        language                = gs_summary_head-tdspras
        name                    = gs_summary_head-tdname
        object                  = gs_summary_head-tdobject
      TABLES
        lines                   = lt_lines
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc EQ 0.
      LOOP AT lt_lines INTO ls_line.
        APPEND ls_line-tdline TO lt_text.
      ENDLOOP.
      go_summary_text->set_text_as_r3table( table = lt_text ).
      cl_gui_cfw=>flush( ).
    ENDIF.
  ENDIF.
ENDMODULE.                 " CREATE_TEXT_CONTROL_0504  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_PROPERTIES_0504  OUTPUT
*&---------------------------------------------------------------------*
MODULE set_properties_0504 OUTPUT.
  IF sy-tcode <> 'QM01' AND sy-tcode <> 'QM02' or viqmel-phase = '4' or viqmel-phase = '5'.
    go_summary_text->set_readonly_mode( readonly_mode = 1 ).
  ENDIF.
ENDMODULE.                 " SET_PROPERTIES_0504  OUTPUT
