*----------------------------------------------------------------------*
***INCLUDE ZQM_LAB_TAGESBERICHT_REPORTF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_DRAGDROP
*&---------------------------------------------------------------------*
FORM initialize_dragdrop .
  "list tree
  CREATE OBJECT go_drdr_list.
  go_drdr_list->add( EXPORTING flavor     = 'LINE'
                               dragsrc    = 'X'
                               droptarget = ''
                               effect     = cl_dragdrop=>move ).
  go_drdr_list->get_handle( IMPORTING handle = gv_handle_list ).

  "sort tree
  CREATE OBJECT go_drdr_sort.
  go_drdr_sort->add( EXPORTING flavor     = 'LINE'
                               dragsrc    = 'X'
                               droptarget = ''
                               effect     = cl_dragdrop=>move ).
  go_drdr_sort->get_handle( IMPORTING handle = gv_handle_sort ).
ENDFORM.                    " INITIALIZE_DRAGDROP

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data.
  DATA: lt_qals     TYPE qals_tab,
        ls_qals     TYPE qals,
        lt_opr      TYPE oper_tab,
        ls_opr      TYPE capp_opr,
        ls_result   TYPE zqm_lab_tagesbericht_s,
        ls_qmel     TYPE qmel,
        lt_status   TYPE TABLE OF bapi2045ss,
        ls_status   TYPE bapi2045ss,
        lv_continue TYPE xflag.

  SELECT * FROM qals INTO TABLE lt_qals WHERE werk      EQ p_werks
                                          AND pastrterm LE p_datum
                                          AND art       EQ p_art.
  IF sy-subrc <> 0.
    MESSAGE e050(zqm).
  ENDIF.

  "remove inspection lots with non-selected status
  LOOP AT lt_qals INTO ls_qals.
    CLEAR: lv_continue.

    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number        = ls_qals-prueflos
      TABLES
        system_status = lt_status.

    IF p_frei EQ 'X'.
      "ignore those, which are already finished
      READ TABLE lt_status WITH KEY sy_st_text = 'PAKO' TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CONTINUE.
      ENDIF.
    ELSEIF p_gene EQ 'X'.
*      "only process inspection lots with status GENE
      READ TABLE lt_status WITH KEY sy_st_text = 'GNE' TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_status WITH KEY sy_st_text = 'GNNE' TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CONTINUE.
      ENDIF.

      "but ignore those, which are already finished
      READ TABLE lt_status WITH KEY sy_st_text = 'PAKO' TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CONTINUE.
      ENDIF.
    ELSEIF p_pako EQ 'X'.
      "only process inspection lots with status PAKO
      READ TABLE lt_status WITH KEY sy_st_text = 'PAKO' TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
    ENDIF.
    READ TABLE lt_status WITH KEY sy_st_text = 'LSTO' TRANSPORTING NO FIELDS.
    IF sy-subrc EQ 0.
      CONTINUE.
    ENDIF.
    CLEAR: ls_result, ls_qmel.
    ls_result-prueflos  = ls_qals-prueflos.
    ls_result-pastrterm = ls_qals-pastrterm.
    ls_result-plnnr     = ls_qals-plnnr.
    ls_result-plnal     = ls_qals-plnal.
    ls_result-sort      = ls_qals-zzqmtagesbericht_sort.

    SELECT SINGLE qmnum FROM zqmprobes INTO (ls_result-qmnum) WHERE prueflos EQ ls_qals-prueflos
                                                                AND plnnr    EQ ls_qals-plnnr
                                                                AND plnal    EQ ls_qals-plnal.

    SELECT COUNT(*) FROM zqmprobes INTO (ls_result-prbnr) WHERE prueflos EQ ls_qals-prueflos
                                                            AND plnnr    EQ ls_qals-plnnr
                                                            AND plnal    EQ ls_qals-plnal.

    SELECT SINGLE qmtxt zzarbpl FROM qmel INTO CORRESPONDING FIELDS OF
      ls_qmel WHERE qmnum EQ ls_result-qmnum.
    ls_result-qmtxt = ls_qmel-qmtxt.

    IF p_arbpl IS NOT INITIAL.
      IF ls_qmel-zzarbpl <> p_arbpl.
        CONTINUE.
      ENDIF.
    ENDIF.

    "create one line per activity
    CALL FUNCTION 'CARO_ROUTING_READ'
      EXPORTING
        plnty       = ls_qals-plnty
        plnnr       = ls_qals-plnnr
        plnal       = ls_qals-plnal
      TABLES
        opr_tab     = lt_opr
      EXCEPTIONS
        not_found   = 1
        ref_not_exp = 2
        not_valid   = 3
        OTHERS      = 4.
    IF sy-subrc EQ 0.
      LOOP AT lt_opr INTO ls_opr.
        ls_result-vornr = ls_opr-vornr.
        ls_result-ltxa1 = ls_opr-ltxa1.
        ls_result-vgw01 = ls_opr-vgw01.
        ls_result-vge01 = ls_opr-vge01.
        APPEND ls_result TO gt_result.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  CREATE_TREE_CONTROL
*&---------------------------------------------------------------------*
FORM create_tree_control  USING    p_text     TYPE sdydo_text_element
                          CHANGING o_evt_rec  TYPE REF TO lcl_tree_event_receiver
                                   o_tree     TYPE REF TO cl_gui_alv_tree
                                   o_cont_obj TYPE REF TO cl_gui_docking_container
                                   t_result   TYPE zqm_lab_tagesbericht_t
                                   o_header   TYPE REF TO cl_gui_html_viewer
                                   o_dyndoc   TYPE REF TO cl_dd_document.

  DATA: lt_events   TYPE cntl_simple_events,
        ls_event    TYPE cntl_simple_event,
        ls_variant  TYPE disvariant.

  CREATE OBJECT o_tree
    EXPORTING
      parent                      = o_cont_obj
      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
      item_selection              = ''
      no_html_header              = ''
      no_toolbar                  = ''
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      illegal_node_selection_mode = 5
      failed                      = 6
      illegal_column_name         = 7.

  CREATE OBJECT o_evt_rec
    EXPORTING
      io_tree = o_tree.

* get fieldcatalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZQM_LAB_TAGESBERICHT_S'
    CHANGING
      ct_fieldcat      = gt_fieldcat.

  DELETE gt_fieldcat WHERE fieldname EQ 'PRUEFLOS'
                        OR fieldname EQ 'VORNR'
                        OR fieldname EQ 'SORT'
                        OR fieldname EQ 'NODE_KEY'.

* header for hierarchy
  CLEAR gs_hierarchy_header.
  gs_hierarchy_header-heading = text-010.
  gs_hierarchy_header-tooltip = text-010.
  gs_hierarchy_header-width = 30.
  gs_hierarchy_header-width_pix = ''.

* variant - save
  ls_variant-report = gv_repid.

* create empty tree-control
  CALL METHOD o_tree->set_table_for_first_display
    EXPORTING
      is_hierarchy_header = gs_hierarchy_header
      i_background_id     = 'TREE'
      is_variant          = ls_variant
      i_save              = 'X'
    CHANGING
      it_outtab           = t_result
      it_fieldcatalog     = gt_fieldcat.

* register events
  CLEAR ls_event.
  ls_event-eventid = cl_gui_column_tree=>eventid_node_double_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.
  CLEAR ls_event.
  ls_event-eventid = cl_gui_column_tree=>eventid_expand_no_children.
  APPEND ls_event TO lt_events.
  CLEAR ls_event.
  ls_event-eventid = cl_gui_column_tree=>eventid_header_click.
  APPEND ls_event TO lt_events.
  CLEAR ls_event.

  CALL METHOD o_tree->set_registered_events
    EXPORTING
      events                    = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE x534(0k).
  ENDIF.

* set handler for tree
  SET HANDLER o_evt_rec->handle_double_click FOR o_tree.
  SET HANDLER o_evt_rec->handle_on_drag      FOR o_tree.

* create html header
  o_tree->get_html_header_object( CHANGING er_html_header = o_header ).
  o_tree->set_splitter_row_height( EXPORTING i_height = 7 ).
  CREATE OBJECT o_dyndoc.
  o_dyndoc->html_control = o_header.
  PERFORM create_change_html_header USING    p_text
                                    CHANGING o_dyndoc
                                             t_result.
ENDFORM.                    " CREATE_TREE_CONTROL
*&---------------------------------------------------------------------*
*&      Form  FILL_LIST
*&---------------------------------------------------------------------*
FORM fill_list.
  DATA: lt_result_list TYPE zqm_lab_tagesbericht_t,
        lt_result_sort TYPE zqm_lab_tagesbericht_t,
        ls_result      TYPE zqm_lab_tagesbericht_s,
        lv_node_key    TYPE lvc_nkey,
        lv_tabix       TYPE sytabix.

  LOOP AT gt_result INTO ls_result.
    IF ls_result-sort EQ 0.
      APPEND ls_result TO lt_result_list.
    ELSE.
      APPEND ls_result TO lt_result_sort.
    ENDIF.
  ENDLOOP.

  "preset internal_sort
  SORT lt_result_sort BY sort ASCENDING prueflos ASCENDING vornr ASCENDING.
  LOOP AT lt_result_sort INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      gv_sort = gv_sort + 1.
    ENDON.
    ls_result-internal_sort = gv_sort.
    MODIFY lt_result_sort FROM ls_result.
  ENDLOOP.

  "fill up list-tree
  LOOP AT lt_result_list INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      PERFORM add_node USING    ls_result
                       CHANGING lv_node_key
                                go_tree_list
                                gv_handle_list.

      PERFORM add_subnodes USING    ls_result
                                    lv_node_key
                                    lt_result_list
                           CHANGING go_tree_list.
    ENDON.
  ENDLOOP.

  "fill up sort-tree with already sorted entries
  LOOP AT lt_result_sort INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      PERFORM add_node USING    ls_result
                       CHANGING lv_node_key
                                go_tree_sort
                                gv_handle_sort.

      PERFORM add_subnodes USING    ls_result
                                    lv_node_key
                                    lt_result_sort
                           CHANGING go_tree_sort.
    ENDON.
  ENDLOOP.

  PERFORM create_change_html_header USING    text-007
                                    CHANGING go_dyndoc_list
                                             gt_result_list.
  PERFORM create_change_html_header USING    text-008
                                    CHANGING go_dyndoc_sort
                                             gt_result_sort.
ENDFORM.                    " FILL_LIST

*&---------------------------------------------------------------------*
*&      Form  ADD_NODE
*&---------------------------------------------------------------------*
FORM add_node  USING    s_result   TYPE zqm_lab_tagesbericht_s
               CHANGING p_node_key TYPE lvc_nkey
                        o_tree     TYPE REF TO cl_gui_alv_tree
                        v_handle   TYPE i.

  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi,
        ls_node_layout TYPE lvc_s_layn,
        lv_node_text   TYPE lvc_value.

  CALL METHOD cl_gui_cfw=>flush.

*    ls_item_layout-t_image = '@FN@'.
  ls_item_layout-fieldname = go_tree_list->c_hierarchy_column_name.
  APPEND ls_item_layout TO lt_item_layout.

  "drag & drop handler id
  ls_node_layout-dragdropid = v_handle.

  "longtext
  lv_node_text = s_result-prueflos.

  "clear not needed fields from s_result
  CLEAR: s_result-vornr, s_result-ltxa1, s_result-vge01, s_result-vgw01.

  "add node
  CALL METHOD o_tree->add_node
    EXPORTING
      i_relat_node_key = ''
      i_relationship   = cl_gui_column_tree=>relat_last_child
      i_node_text      = lv_node_text
      is_node_layout   = ls_node_layout
      is_outtab_line   = s_result
      it_item_layout   = lt_item_layout
    IMPORTING
      e_new_node_key   = p_node_key.
ENDFORM.                    " ADD_NODE

*&---------------------------------------------------------------------*
*&      Form  ADD_SUBNODES
*&---------------------------------------------------------------------*
FORM add_subnodes USING    s_result TYPE zqm_lab_tagesbericht_s
                           p_key    TYPE lvc_nkey
                           t_result TYPE zqm_lab_tagesbericht_t
                  CHANGING o_tree   TYPE REF TO cl_gui_alv_tree.

  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi,
        ls_node_layout TYPE lvc_s_layn,
        lv_node_text   TYPE lvc_value,
        lv_node_key    TYPE lvc_nkey,
        ls_result      TYPE zqm_lab_tagesbericht_s.

  LOOP AT t_result INTO ls_result WHERE prueflos EQ s_result-prueflos.
*    ls_item_layout-t_image = '@FN@'.
    ls_item_layout-fieldname = go_tree_list->c_hierarchy_column_name.
    APPEND ls_item_layout TO lt_item_layout.

    "drag & drop handler id
    ls_node_layout-dragdropid = gv_handle_list.

    "longtext
    lv_node_text = ls_result-vornr.

    "clear not needed fields from ls_result
    CLEAR: ls_result-qmnum, ls_result-qmtxt, ls_result-pastrterm, ls_result-prbnr, ls_result-plnnr, ls_result-plnal.

    "add node
    CALL METHOD o_tree->add_node
      EXPORTING
        i_relat_node_key = p_key
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = lv_node_text
        is_node_layout   = ls_node_layout
        is_outtab_line   = ls_result
        it_item_layout   = lt_item_layout.
  ENDLOOP.
ENDFORM.                    " ADD_SUBNODES

*&---------------------------------------------------------------------*
*&      Form  MOVE_PRUEFLOS
*&---------------------------------------------------------------------*
FORM move_prueflos  USING    p_node_key TYPE lvc_nkey
                    CHANGING o_tree     TYPE REF TO cl_gui_alv_tree.
  DATA: ls_result   TYPE zqm_lab_tagesbericht_s,
        ls_node_res TYPE zqm_lab_tagesbericht_s,
        lt_children TYPE lvc_t_nkey,
        ls_children TYPE lvc_nkey,
        lv_node_key TYPE lvc_nkey,
        lo_tree     TYPE REF TO cl_gui_alv_tree,
        lv_handle   TYPE i.

  "get child nodes
  o_tree->get_children( EXPORTING i_node_key  = p_node_key
                        IMPORTING et_children = lt_children ).

  "get first child node to determine plnnr, then add nodes and subnodes to "other" tree
  READ TABLE lt_children INTO ls_children INDEX 1.
  IF sy-subrc EQ 0.
    o_tree->get_outtab_line( EXPORTING i_node_key    = ls_children
                             IMPORTING e_outtab_line = ls_node_res ).

    READ TABLE gt_result INTO ls_result WITH KEY prueflos = ls_node_res-prueflos.

    "get "other" tree
    IF o_tree EQ go_tree_list.
      lo_tree   = go_tree_sort.
      lv_handle = gv_handle_sort.
      gv_sort   = gv_sort + 1.
    ELSE.
      lo_tree   = go_tree_list.
      lv_handle = gv_handle_list.
    ENDIF.

    PERFORM add_node USING    ls_result
                     CHANGING lv_node_key
                              lo_tree
                              lv_handle.

    PERFORM add_subnodes USING    ls_result
                                  lv_node_key
                                  gt_result
                         CHANGING lo_tree.

    ls_result-internal_sort = gv_sort.
    MODIFY gt_result_sort FROM ls_result TRANSPORTING internal_sort WHERE prueflos = ls_result-prueflos.

    o_tree->delete_subtree( EXPORTING i_node_key = p_node_key ).  "remove copied nodes

    o_tree->frontend_update( ).
    lo_tree->frontend_update( ).
  ENDIF.

  PERFORM create_change_html_header USING    text-007
                                  CHANGING go_dyndoc_list
                                           gt_result_list.
  PERFORM create_change_html_header USING    text-008
                                    CHANGING go_dyndoc_sort
                                             gt_result_sort.
ENDFORM.                    " MOVE_PRUEFLOS

*&---------------------------------------------------------------------*
*&      Form  CHANGE_TOOLBAR
*&---------------------------------------------------------------------*
FORM change_toolbar_sort.
  go_tree_sort->get_toolbar_object( IMPORTING er_toolbar = go_toolbar_sort ).

  IF go_toolbar_sort IS NOT INITIAL.
    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = ''
        icon      = ''
        butn_type = cntb_btype_sep
        text      = ''
        quickinfo = 'Separator'.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = 'QMUP'
        icon      = '@HH@'
        butn_type = cntb_btype_button
        text      = ''
        quickinfo = text-011.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = 'QMDOWN'
        icon      = '@HI@'
        butn_type = cntb_btype_button
        text      = ''
        quickinfo = text-012.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = ''
        icon      = ''
        butn_type = cntb_btype_sep
        text      = ''
        quickinfo = 'Separator'.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = 'QMSHOW'
        icon      = '@10@'
        butn_type = cntb_btype_button
        text      = text-014
        quickinfo = text-014.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = ''
        icon      = ''
        butn_type = cntb_btype_sep
        text      = ''
        quickinfo = 'Separator'.

    CALL METHOD go_toolbar_sort->add_button
      EXPORTING
        fcode     = 'QMFIN'
        icon      = '@DF@'
        butn_type = cntb_btype_button
        text      = text-013
        quickinfo = text-013.

    CREATE OBJECT go_tb_evt_rec_sort
      EXPORTING
        io_tree = go_tree_sort.
    SET HANDLER go_tb_evt_rec_sort->on_function_selected FOR go_toolbar_sort.
  ENDIF.
ENDFORM.                    " CHANGE_TOOLBAR_SORT

*&---------------------------------------------------------------------*
*&      Form  CHANGE_TOOLBAR_LIST
*&---------------------------------------------------------------------*
FORM change_toolbar_list .
  go_tree_list->get_toolbar_object( IMPORTING er_toolbar = go_toolbar_list ).

  IF go_toolbar_list IS NOT INITIAL.
    CALL METHOD go_toolbar_list->add_button
      EXPORTING
        fcode     = ''
        icon      = ''
        butn_type = cntb_btype_sep
        text      = ''
        quickinfo = 'Separator'.

    CALL METHOD go_toolbar_list->add_button
      EXPORTING
        fcode     = 'QMSHOW'
        icon      = '@10@'
        butn_type = cntb_btype_button
        text      = text-014
        quickinfo = text-014.

    CREATE OBJECT go_tb_evt_rec_list
      EXPORTING
        io_tree = go_tree_list.
    SET HANDLER go_tb_evt_rec_list->on_function_selected FOR go_toolbar_list.
  ENDIF.
ENDFORM.                    " CHANGE_TOOLBAR_LIST

*&---------------------------------------------------------------------*
*&      Form  TOOLBAR_FUNCTION_SELECTED
*&---------------------------------------------------------------------*
FORM toolbar_function_selected  USING    p_fcode
                                CHANGING o_tree  TYPE REF TO cl_gui_alv_tree.

  DATA: lt_nodes     TYPE lvc_t_nkey,
        lv_node      TYPE lvc_nkey,
        lv_prev_node TYPE lvc_nkey,
        lv_next_node TYPE lvc_nkey,
        lv_relatkey  TYPE lvc_nkey.

  CASE p_fcode.
    WHEN 'QMUP' OR 'QMDOWN'. "move node up or down
      PERFORM move_node USING    p_fcode
                        CHANGING o_tree.
    WHEN 'QMFIN'. "finish inspection lots
      PERFORM finish_inspection_lot CHANGING o_tree.
    WHEN 'QMSHOW'. "show inspection lot
      PERFORM display_inspection_lot CHANGING o_tree.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " TOOLBAR_FUNCTION_SELECTED

*&---------------------------------------------------------------------*
*&      Form  MOVE_NODE
*&---------------------------------------------------------------------*
FORM move_node  USING    p_fcode
                CHANGING o_tree  TYPE REF TO cl_gui_alv_tree.

  DATA: lt_nodes          TYPE lvc_t_nkey,
        lv_node           TYPE lvc_nkey,
        lv_sibling        TYPE lvc_nkey,
        lv_relatship      TYPE int4,
        ls_result         TYPE zqm_lab_tagesbericht_s,
        ls_result_main    TYPE zqm_lab_tagesbericht_s,
        ls_result_sibling TYPE zqm_lab_tagesbericht_s.

  o_tree->get_selected_nodes( CHANGING ct_selected_nodes = lt_nodes ).

  READ TABLE lt_nodes INTO lv_node INDEX 1.
  IF sy-subrc EQ 0 AND lv_node IS NOT INITIAL.

    IF p_fcode EQ 'QMUP'.
      o_tree->get_prev_sibling( EXPORTING i_node_key      = lv_node
                                IMPORTING e_prev_node_key = lv_sibling ).
      lv_relatship = cl_gui_column_tree=>relat_prev_sibling.
    ELSEIF p_fcode EQ 'QMDOWN'.
      o_tree->get_next_sibling( EXPORTING i_node_key      = lv_node
                                IMPORTING e_next_node_key = lv_sibling ).
      lv_relatship = cl_gui_column_tree=>relat_next_sibling.
    ENDIF.

    IF lv_sibling IS NOT INITIAL.
      "reshuffle internal_sort
      o_tree->get_outtab_line( EXPORTING i_node_key    = lv_node
                               IMPORTING e_outtab_line = ls_result_main ).
      o_tree->get_outtab_line( EXPORTING i_node_key    = lv_sibling
                               IMPORTING e_outtab_line = ls_result_sibling ).
      IF ls_result_main IS NOT INITIAL AND ls_result_sibling IS NOT INITIAL.
        ls_result = ls_result_main.
        ls_result-internal_sort = ls_result_sibling-internal_sort.
        MODIFY gt_result_sort FROM ls_result TRANSPORTING internal_sort WHERE prueflos = ls_result-prueflos.

        CLEAR: ls_result.
        ls_result = ls_result_sibling.
        ls_result-internal_sort = ls_result_main-internal_sort.
        MODIFY gt_result_sort FROM ls_result TRANSPORTING internal_sort WHERE prueflos = ls_result-prueflos.
      ENDIF.

      o_tree->move_node(
        EXPORTING
          i_node_key         = lv_node
          i_relatkey         = lv_sibling
          i_relatship        = lv_relatship ).
    ENDIF.

    o_tree->frontend_update( ).
  ENDIF.
ENDFORM.                    " MOVE_NODE
*&---------------------------------------------------------------------*
*&      Form  ENQUEUE_INSPECTION_LOTS
*&---------------------------------------------------------------------*
FORM enqueue_inspection_lots .
  DATA: ls_result TYPE zqm_lab_tagesbericht_s.

  LOOP AT gt_result INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      CALL FUNCTION 'ENQUEUE_ELQALS'
        EXPORTING
          prueflos       = ls_result-prueflos
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.
      IF sy-subrc <> 0.
        MESSAGE e051(zqm) WITH ls_result-prueflos.
      ENDIF.
    ENDON.
  ENDLOOP.
ENDFORM.                    " ENQUEUE_INSPECTION_LOTS
*&---------------------------------------------------------------------*
*&      Form  DEQUEUE_INSPECTION_LOTS
*&---------------------------------------------------------------------*
FORM dequeue_inspection_lots .
  DATA: ls_result TYPE zqm_lab_tagesbericht_s.

  LOOP AT gt_result INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      CALL FUNCTION 'DEQUEUE_ELQALS'
        EXPORTING
          prueflos = ls_result-prueflos.
    ENDON.
  ENDLOOP.
ENDFORM.                    " DEQUEUE_INSPECTION_LOTS

*&---------------------------------------------------------------------*
*&      Form  SAVE_INSPECTION_LOT
*&---------------------------------------------------------------------*
FORM save_inspection_lot .
  DATA: ls_result TYPE zqm_lab_tagesbericht_s,
        ls_qals   TYPE qals.

  "save sort for every inspection lot
  LOOP AT gt_result_sort INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      UPDATE qals CLIENT SPECIFIED SET zzqmtagesbericht_sort = ls_result-internal_sort
                                       pastrterm = sy-datum  WHERE mandant  = sy-mandt
                                                               AND prueflos = ls_result-prueflos.
    ENDON.
    PERFORM change_inspection_lot_status USING ls_result 'QM73'.
  ENDLOOP.

  "remove sort for non-sorted inspection lots if necessary
  LOOP AT gt_result_list INTO ls_result.
    ON CHANGE OF ls_result-prueflos.
      SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos              EQ ls_result-prueflos
                                               AND zzqmtagesbericht_sort NE 0.
      IF sy-subrc EQ 0.
        UPDATE qals CLIENT SPECIFIED SET zzqmtagesbericht_sort = 0 WHERE mandant  = sy-mandt
                                                                     AND prueflos = ls_result-prueflos.
        PERFORM change_inspection_lot_status USING ls_result 'QM71'.
      ENDIF.

    ENDON.
  ENDLOOP.

  MESSAGE s052(zqm).
ENDFORM.                    " SAVE_INSPECTION_LOT

*&---------------------------------------------------------------------*
*&      Form  FINISH_INSPECTION_LOT
*&---------------------------------------------------------------------*
FORM finish_inspection_lot  CHANGING o_tree TYPE REF TO cl_gui_alv_tree.
  DATA: lt_nodes  TYPE lvc_t_nkey,
        lv_node   TYPE lvc_nkey,
        ls_result TYPE zqm_lab_tagesbericht_s,
        ls_qals   TYPE qals.

  o_tree->get_selected_nodes( CHANGING ct_selected_nodes = lt_nodes ).
  READ TABLE lt_nodes INTO lv_node INDEX 1.
  IF sy-subrc EQ 0 AND lv_node IS NOT INITIAL.
    o_tree->get_outtab_line( EXPORTING i_node_key    = lv_node
                             IMPORTING e_outtab_line = ls_result ).
    IF ls_result IS NOT INITIAL.
      SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos EQ ls_result-prueflos.
      IF sy-subrc EQ 0.
        CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
          EXPORTING
*           I_DIALOG             = 'X'
            i_objnr              = ls_qals-objnr
            i_vorgang            = 'QM26' "Prüfabschluss komplett, see table TJ01
          EXCEPTIONS
            not_allowed          = 1
            activity_not_allowed = 2
            OTHERS               = 3.
        IF sy-subrc <> 0.
          MESSAGE e053(zqm) WITH ls_qals-prueflos.
        ENDIF.

        COMMIT WORK AND WAIT.
        MESSAGE s054(zqm) WITH ls_qals-prueflos.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FINISH_INSPECTION_LOT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_INSPECTION_LOT
*&---------------------------------------------------------------------*
FORM display_inspection_lot  CHANGING o_tree TYPE REF TO cl_gui_alv_tree.
  DATA: lt_nodes  TYPE lvc_t_nkey,
        lv_node   TYPE lvc_nkey,
        ls_result TYPE zqm_lab_tagesbericht_s,
        ls_qals   TYPE qals.

  o_tree->get_selected_nodes( CHANGING ct_selected_nodes = lt_nodes ).
  READ TABLE lt_nodes INTO lv_node INDEX 1.
  IF sy-subrc EQ 0 AND lv_node IS NOT INITIAL.
    o_tree->get_outtab_line( EXPORTING i_node_key    = lv_node
                             IMPORTING e_outtab_line = ls_result ).
    IF ls_result IS NOT INITIAL.
      SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos EQ ls_result-prueflos.
      IF sy-subrc EQ 0.
        SET PARAMETER ID 'QLS' FIELD ls_qals-prueflos.
        CALL TRANSACTION 'QA03' AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " DISPLAY_INSPECTION_LOT

*&---------------------------------------------------------------------*
*&      Form  CHANGE_INSPECTION_LOT_STATUS
*&---------------------------------------------------------------------*
FORM change_inspection_lot_status  USING s_result  TYPE zqm_lab_tagesbericht_s
                                         p_vorgang TYPE j_vorgang.
  DATA: ls_qals   TYPE qals.

  SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos EQ s_result-prueflos.
  IF sy-subrc EQ 0.
    CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
      EXPORTING
        i_objnr              = ls_qals-objnr
        i_vorgang            = p_vorgang
      EXCEPTIONS
        not_allowed          = 1
        activity_not_allowed = 2
        OTHERS               = 3.
    IF sy-subrc <> 0.
      MESSAGE e055(zqm) WITH ls_qals-prueflos.
    ENDIF.

    COMMIT WORK AND WAIT.
  ENDIF.
ENDFORM.                    " CHANGE_INSPECTION_LOT_STATUS

*&---------------------------------------------------------------------*
*&      Form  CREATE_CHANGE_HTML_HEADER
*&---------------------------------------------------------------------*
FORM create_change_html_header  USING    p_text   TYPE sdydo_text_element
                                CHANGING o_dyndoc TYPE REF TO cl_dd_document
                                         t_result TYPE zqm_lab_tagesbericht_t.

  DATA: lv_time  TYPE vgwrt,
        lv_ctime TYPE text12,
        lv_ptime TYPE p DECIMALS 2,
        lv_text  TYPE sdydo_text_element.

  PERFORM calculate_total_time CHANGING t_result
                                        lv_time.

  MOVE lv_time TO lv_ptime.
  lv_ctime = lv_ptime.
  CONDENSE lv_ctime.
  REPLACE ALL OCCURRENCES OF '.' IN lv_ctime WITH ','.

  CONCATENATE text-015 lv_ctime text-016 INTO lv_text SEPARATED BY space.

  o_dyndoc->initialize_document( ).
  o_dyndoc->add_text_as_heading( EXPORTING text = p_text ).
  o_dyndoc->add_text( EXPORTING text = lv_text ).

  o_dyndoc->display_document( EXPORTING  reuse_control      = 'X'
                              EXCEPTIONS html_display_error = 1 ).
ENDFORM.                    " CREATE_CHANGE_HTML_HEADER

*&---------------------------------------------------------------------*
*&      Form  CALCULATE_TOTAL_TIME
*&---------------------------------------------------------------------*
FORM calculate_total_time  CHANGING t_result TYPE zqm_lab_tagesbericht_t
                                    p_time   TYPE vgwrt.
  DATA: ls_result   TYPE zqm_lab_tagesbericht_s,
        lv_time_in  TYPE auszt,
        lv_time_out TYPE auszt,
        lv_unit_in  TYPE char1.

  LOOP AT t_result INTO ls_result.
    CLEAR: lv_time_out.

    IF ls_result-vge01 <> 'H'.
      CASE ls_result-vge01.
        WHEN 'S'.   "Sekunden
          lv_unit_in = 'S'.
        WHEN 'MIN'. "Minuten
          lv_unit_in = 'M'.
        WHEN 'T'.   "Tage
          lv_unit_in = 'D'.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.

      MOVE ls_result-vgw01 TO lv_time_in.
      CALL FUNCTION 'PM_TIME_CONVERSION'
        EXPORTING
          time_in           = lv_time_in
          unit_in           = lv_unit_in
          unit_out          = 'H'
        IMPORTING
          time_out          = lv_time_out
        EXCEPTIONS
          invalid_time_unit = 1
          OTHERS            = 2.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      p_time = p_time + lv_time_out.
    ELSE.
      p_time = p_time + ls_result-vgw01.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " CALCULATE_TOTAL_TIME
