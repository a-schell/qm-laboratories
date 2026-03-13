*----------------------------------------------------------------------*
***INCLUDE ZQM_LAB_TAGESBERICHT_REPORTO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
*  SET TITLEBAR 'xxx'.
ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CREATE_CONTROLS  OUTPUT
*&---------------------------------------------------------------------*
MODULE create_controls OUTPUT.
  IF gv_controls_created IS INITIAL.
*   create docking control
    "list
    CREATE OBJECT go_cont_obj_list
      EXPORTING
        side      = cl_gui_docking_container=>dock_at_left
        extension = 900
        repid     = gv_repid
        dynnr     = '0100'.

    "sort
    CREATE OBJECT go_cont_obj_sort
      EXPORTING
        side      = cl_gui_docking_container=>dock_at_left
        extension = 900
        repid     = gv_repid
        dynnr     = '0100'.

*   create tree control
    PERFORM create_tree_control USING    text-007
                                CHANGING go_evt_rec_list
                                         go_tree_list
                                         go_cont_obj_list
                                         gt_result_list
                                         go_header_list
                                         go_dyndoc_list.
    PERFORM create_tree_control USING    text-008
                                CHANGING go_evt_rec_sort
                                         go_tree_sort
                                         go_cont_obj_sort
                                         gt_result_sort
                                         go_header_sort
                                         go_dyndoc_sort.

*   manipulate toolbar
    PERFORM change_toolbar_list.
    PERFORM change_toolbar_sort.

*   fill data and send it to frontend
    PERFORM fill_list.

    go_tree_list->frontend_update( ).
    go_tree_sort->frontend_update( ).

    gv_controls_created = 'X'.
  ENDIF.
ENDMODULE.                 " CREATE_CONTROLS  OUTPUT
