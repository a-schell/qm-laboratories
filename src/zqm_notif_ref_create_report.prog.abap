*&---------------------------------------------------------------------*
*& Report  ZQM_NOTIF_REF_CREATE_REPORT
*&
*&---------------------------------------------------------------------*
*& AUTHOR: INF/Wiesmayr, wiw@informatics.at
*& DATE: 06.12.2016
*& DESCRIPTION: create inspection plan from standard plans
*& CHANGE:
*&---------------------------------------------------------------------*

REPORT zqm_notif_ref_create_report.


SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
  PARAMETERS: p_bukrs TYPE bukrs.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  DATA: lo_obj      TYPE REF TO zqm_cl_notif_ref_create_report.

  CREATE OBJECT lo_obj
    EXPORTING
      iv_werks = p_bukrs.

  lo_obj->run( ).

*&---------------------------------------------------------------------*
*&      Form  handle_cl_user_input
*&---------------------------------------------------------------------*
FORM handle_cl_user_input TABLES   fields STRUCTURE sval
                          USING    code
                          CHANGING error  STRUCTURE svale show_popup.
  "dummy for class method zqm_cl_notif_ref_create_report->handle_button
ENDFORM.                    "handle_cl_user_input
