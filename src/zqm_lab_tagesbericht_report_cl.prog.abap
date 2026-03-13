*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_TAGESBERICHT_REPORT_CL
*&---------------------------------------------------------------------*

CLASS lcl_tree_event_receiver DEFINITION.
  PUBLIC SECTION.
    DATA: o_tree TYPE REF TO cl_gui_alv_tree.

    METHODS constructor
        IMPORTING io_tree TYPE REF TO cl_gui_alv_tree.

    METHODS handle_double_click
        FOR EVENT node_double_click OF cl_gui_alv_tree
        IMPORTING node_key.

    METHODS handle_on_drag
      FOR EVENT on_drag OF cl_gui_alv_tree
      IMPORTING drag_drop_object
                fieldname
                node_key.
  PRIVATE SECTION.
ENDCLASS.                    "LCL_TREE_EVENT_RECEIVER DEFINITION
*---------------------------------------------------------------------*
*       CLASS LCL_TREE_EVENT_RECEIVER IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_tree_event_receiver IMPLEMENTATION.
  METHOD constructor.
    me->o_tree = io_tree.
  ENDMETHOD.                    "constructor

  METHOD handle_double_click.
    CHECK NOT node_key IS INITIAL.
    PERFORM move_prueflos USING node_key
                          CHANGING o_tree.
  ENDMETHOD.                    "handle_double_click

  METHOD handle_on_drag.
    CHECK NOT node_key IS INITIAL.
    PERFORM move_prueflos USING    node_key
                          CHANGING o_tree.
    CALL METHOD cl_gui_cfw=>set_new_ok_code
      EXPORTING
        new_code = 'ENTR'.
  ENDMETHOD.                    "HANDLE_ON_DRAG
ENDCLASS.                    "LCL_TREE_EVENT_RECEIVER IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_toolbar_event_receiver DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_toolbar_event_receiver DEFINITION.
  PUBLIC SECTION.
    DATA: o_tree TYPE REF TO cl_gui_alv_tree.

    METHODS constructor
        IMPORTING io_tree TYPE REF TO cl_gui_alv_tree.

    METHODS: on_function_selected
               FOR EVENT function_selected OF cl_gui_toolbar
                 IMPORTING fcode.
ENDCLASS.                    "lcl_toolbar_event_receiver DEFINITION

*---------------------------------------------------------------------*
*       CLASS lcl_toolbar_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_toolbar_event_receiver IMPLEMENTATION.
  METHOD constructor.
    me->o_tree = io_tree.
  ENDMETHOD.                    "constructor

  METHOD on_function_selected.
    PERFORM toolbar_function_selected USING    fcode
                                      CHANGING o_tree.
  ENDMETHOD.                    "on_function_selected
ENDCLASS.                    "lcl_toolbar_event_receiver IMPLEMENTATION
