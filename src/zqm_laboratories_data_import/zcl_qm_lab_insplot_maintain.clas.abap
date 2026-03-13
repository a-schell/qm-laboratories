*----------------------------------------------------------------------*
*       CLASS zcl_qm_lab_insplot_create DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zcl_qm_lab_insplot_maintain DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS constructor
    IMPORTING !iv_application TYPE zqm_import_appplication
    RAISING zcx_qm_lab_import_exceptions.

    METHODS create_from_field_value
    IMPORTING !iv_plant TYPE werks_d
              !it_fields_values TYPE zqm_lab_t_field_value
    EXPORTING !ev_insplot_number TYPE qplos
              !et_messages TYPE bapiret2_t
    RAISING zcx_qm_lab_import_exceptions.
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA _av_application TYPE zqm_import_appplication .

    METHODS _change_insplot
      IMPORTING
        !is_qals TYPE qals
      RETURNING
        value(rt_messages) TYPE bapiret2_t
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _check
      IMPORTING
        !iv_plant TYPE werks_d
        !it_fields_values TYPE zqm_lab_t_field_value
      RETURNING
        value(rt_messages) TYPE bapiret2_t
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _create_insplot
      IMPORTING
        !is_qals TYPE qals
      EXPORTING
        !ev_insplot_number TYPE qplos
        !et_messages TYPE bapiret2_t
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _get_bms_matnr_keys
      IMPORTING
        !it_fields_values TYPE zqm_lab_t_field_value
      EXPORTING
        !ev_breite_soll TYPE zbms_breite_soll
        !ev_durchmesser_soll TYPE zbms_durchmesser_soll
        !ev_wicklerkern_type TYPE zbms_wicklerkern_type
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _get_insplot_active
      IMPORTING
        !is_qals TYPE qals
      RETURNING
        value(rs_qals) TYPE qals
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _get_insplot_after
      IMPORTING
        !is_qals TYPE qals
      RETURNING
        value(rs_qals) TYPE qals
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _get_material_number
      IMPORTING
        !iv_plant TYPE werks_d
        !iv_prod_type TYPE zbms_materialnr
        !iv_breite_soll TYPE zbms_breite_soll
        !iv_durchmesser_soll TYPE zbms_durchmesser_soll
        !iv_wicklerkern_type TYPE zbms_wicklerkern_type
      RETURNING
        value(rv_matnr) TYPE matnr
      RAISING
        zcx_qm_lab_import_exceptions .
    METHODS _map_fields
      IMPORTING
        !iv_plant TYPE werks_d
        !it_fields_values TYPE zqm_lab_t_field_value
      EXPORTING
        !et_mapped_fields_values TYPE zqm_lab_t_field_value
        !et_messages TYPE bapiret2_t
      RAISING
        zcx_qm_lab_import_exceptions .
ENDCLASS.



CLASS ZCL_QM_LAB_INSPLOT_MAINTAIN IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).

    IF iv_application IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_import_exceptions
        EXPORTING
          textid = zcx_qm_lab_import_exceptions=>no_application_submitted.
    ENDIF.

    me->_av_application = iv_application.
  ENDMETHOD.                    "constructor


  METHOD create_from_field_value.
    DATA lt_mapped_fields_values TYPE zqm_lab_t_field_value.
    DATA wa_insplot_new TYPE qals.
    DATA: wa_insplot_after TYPE qals,
          wa_insplot_active TYPE qals.
    DATA lv_qmat_art TYPE qmat-art VALUE 'ZLAG-01'.
    DATA wa_qmat TYPE qmat.
    DATA wa_prodauf TYPE zbms_prodauf.
    DATA lt_messages TYPE bapiret2_t.
    DATA lv_breite_soll TYPE zbms_breite_soll.
    DATA lv_durchmesser_soll TYPE zbms_durchmesser_soll.
    DATA lv_wicklerkern_type TYPE zbms_wicklerkern_type.

    FIELD-SYMBOLS: <wa_mapped_field_values> TYPE zqm_lab_s_field_value,
                   <lv_target_field> TYPE any,
                   <wa_messages> TYPE bapiret2.

* Map external fields to internal fields
    me->_map_fields( EXPORTING iv_plant                = iv_plant
                               it_fields_values        = it_fields_values
                     IMPORTING et_mapped_fields_values = lt_mapped_fields_values
                               et_messages             = et_messages ).

    IF et_messages[] IS NOT INITIAL.
      RETURN.
    ENDIF.

* Check data
    et_messages = me->_check( iv_plant         = iv_plant
                              it_fields_values = lt_mapped_fields_values ).

    IF et_messages[] IS NOT INITIAL.
      RETURN.
    ENDIF.

* Move import fields to qals
    LOOP AT lt_mapped_fields_values ASSIGNING <wa_mapped_field_values>.
      ASSIGN COMPONENT <wa_mapped_field_values>-fieldname OF STRUCTURE wa_insplot_new TO <lv_target_field>.
      IF sy-subrc IS INITIAL.
        <lv_target_field> = <wa_mapped_field_values>-value.
        UNASSIGN <lv_target_field>.
      ENDIF.
    ENDLOOP.

    wa_insplot_new-werk = iv_plant.

    me->_get_bms_matnr_keys( EXPORTING it_fields_values = it_fields_values
                             IMPORTING ev_breite_soll      = lv_breite_soll
                                       ev_durchmesser_soll = lv_durchmesser_soll
                                       ev_wicklerkern_type = lv_wicklerkern_type ).

    IF wa_insplot_new-matnr IS INITIAL.
* Fill material number from production type if it`s empty
      wa_insplot_new-matnr = me->_get_material_number( iv_plant            = wa_insplot_new-werk
                                                       iv_prod_type        = wa_insplot_new-zzbms_materialnr
                                                       iv_breite_soll      = lv_breite_soll
                                                       iv_durchmesser_soll = lv_durchmesser_soll
                                                       iv_wicklerkern_type = lv_wicklerkern_type ).
    ENDIF.

    IF wa_insplot_new-matnr IS INITIAL.
      APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
      <wa_messages>-type = 'E'.
      <wa_messages>-number = 004.
      <wa_messages>-message_v1 = wa_insplot_new-matnr.
      RETURN.
    ENDIF.

* Get plan number
    SELECT a~plnnr
           b~plnal
           b~zaehl
           b~slwbez
           b~verwe
           a~plnty
           a~zkriz
    INTO (wa_insplot_new-plnnr,
          wa_insplot_new-plnal,
          wa_insplot_new-zaehl,
          wa_insplot_new-slwbez,
          wa_insplot_new-pplverw,
          wa_insplot_new-plnty,
          wa_insplot_new-zkriz )
      FROM mapl AS a
      INNER JOIN plko AS b
      ON b~plnty = a~plnty AND
         b~plnnr = a~plnnr AND
         b~plnal = a~plnal
      WHERE ( a~loekz = abap_false AND
              a~datuv <= sy-datum AND
              a~matnr = wa_insplot_new-matnr AND
              a~werks = wa_insplot_new-werk AND
              a~plnty = 'Q')
        AND ( b~loekz = abap_false AND
              b~datuv <= sy-datum )
      ORDER BY a~plnal DESCENDING.
      EXIT.
    ENDSELECT.

    CALL FUNCTION 'QMAT_READ'
      EXPORTING
        i_art    = lv_qmat_art
        i_matnr  = wa_insplot_new-matnr
        i_werks  = wa_insplot_new-werk
      IMPORTING
        e_qmat   = wa_qmat
      EXCEPTIONS
        no_entry = 1
        OTHERS   = 2.

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
      <wa_messages>-type = 'E'.
      <wa_messages>-number = 003.
      <wa_messages>-message_v1 = wa_insplot_new-matnr.
      RETURN.
    ENDIF.

* Fill additional data
    wa_insplot_new-selwerk = iv_plant.
    wa_insplot_new-stat07 = 'X'.
    "wa_insplot_new-stat08 = 'X'.
    "wa_insplot_new-stat20 = 'X'.
    wa_insplot_new-stat13  = ' '.
    wa_insplot_new-art = wa_qmat-art.
    wa_insplot_new-herkunft = '89'.
    wa_insplot_new-obtyp = 'QL1'.
    wa_insplot_new-selpplverw = wa_insplot_new-pplverw.
    wa_insplot_new-dyn = 'X'.
    wa_insplot_new-hpz = 'X'.
    wa_insplot_new-ein = 'X'.
    wa_insplot_new-pastrterm = sy-datum.
    wa_insplot_new-pastrzeit = sy-uzeit.
    wa_insplot_new-paendterm = '20301231'.
    wa_insplot_new-paendzeit = '235959'.
    wa_insplot_new-qkzverf = wa_qmat-qkzverf.
    wa_insplot_new-ppkztlzu = '0'.
    wa_insplot_new-gueltigab  = wa_insplot_new-pastrterm.
*** IF wa_insplot_new-zzlinienr <> '30' AND wa_insplot_new-zzlinienr <> '31'.    "2019 Hartl Toni
*   Am 5.März 2025 wurde in gegenseitiger Absprache mit Böss Kerstin
*   diese von Hartl Toni im Oktober 2019 erstellte Änderung für Linie 30,31
*   (die NIE produktiv gesetzt wurde ) wieder ausgebaut
    wa_insplot_new-zzbms_ballennr_bis = '999999'.
***  ENDIF.                                                                      "2019 Hartl Toni

* Get BMS data
    SELECT SINGLE *
    FROM zbms_prodauf
    INTO wa_prodauf
    WHERE werks = wa_insplot_new-werk
      AND aufnr = wa_insplot_new-aufnr
      AND linienr = wa_insplot_new-zzlinienr.

    IF sy-subrc IS INITIAL.
      wa_insplot_new-zzbms_materialnr = wa_prodauf-bmsmatnr.
      wa_insplot_new-zzbms_farbe = wa_prodauf-farbe.
      wa_insplot_new-zzbms_umreifung_char1 = wa_prodauf-umreif.
      wa_insplot_new-zzbms_avivage = wa_prodauf-avivage.
      wa_insplot_new-zzbms_len_ptype_stelle18 = wa_prodauf-len_ptype_s18.
      wa_insplot_new-zzbms_len_ptype_stelle19 = wa_prodauf-len_ptype_s19.
      wa_insplot_new-zzbms_len_ptype_stelle20 = wa_prodauf-len_ptype_s20.
      wa_insplot_new-zzbms_material_variante_prod = wa_prodauf-matvariant.
    ENDIF.

* Get existing active insplot when the new one should be active
    wa_insplot_active = me->_get_insplot_active( is_qals = wa_insplot_new ).

    IF wa_insplot_active IS NOT INITIAL.
* Set new endtime for actice lot
      wa_insplot_active-paendterm = wa_insplot_new-pastrterm.
      wa_insplot_active-paendzeit = wa_insplot_new-pastrzeit - 1.
      wa_insplot_active-zzbms_ballennr_bis = wa_insplot_new-zzbms_ballennr_von - 1.
*     Codingvorlage siehe Include LQPL1F0A form fcode_buchen_b.
*     Aenderungsprotokollierung move : sy-uname to qals-aenderer, sy-datum to qals-aenderdat, sy-uzeit to qals-aenderzeit.
      wa_insplot_active-aenderer = sy-uname.     "neu März 2025 imzuge von Ticket SR-805906
      wa_insplot_active-aenderdat = sy-datum.    "neu März 2025 imzuge von Ticket SR-805906
      wa_insplot_active-aenderzeit = sy-uzeit.   "neu März 2025 imzuge von Ticket SR-805906

      lt_messages = me->_change_insplot( is_qals = wa_insplot_active ).

      APPEND LINES OF lt_messages TO et_messages.

      READ TABLE lt_messages
      WITH KEY type = 'E'
      TRANSPORTING NO FIELDS.

      IF sy-subrc IS INITIAL.
        RETURN.
      ENDIF.

      FREE lt_messages.
    ENDIF.

* Get inspection lot which is running after this one
    wa_insplot_after = me->_get_insplot_after( is_qals = wa_insplot_new ).

    IF wa_insplot_after IS NOT INITIAL.
      wa_insplot_new-paendterm =  wa_insplot_after-pastrterm.
      wa_insplot_new-paendzeit =  wa_insplot_after-pastrzeit - 1.
      wa_insplot_new-zzbms_ballennr_bis = wa_insplot_after-zzbms_ballennr_von - 1.
    ENDIF.

* Create new inspection lot
    me->_create_insplot( EXPORTING is_qals = wa_insplot_new
                         IMPORTING ev_insplot_number = ev_insplot_number
                                   et_messages       = lt_messages ).

    APPEND LINES OF lt_messages TO et_messages.
    FREE lt_messages.

    CLEAR: wa_insplot_new, wa_qmat, wa_prodauf, wa_insplot_after, wa_insplot_active.
    FREE lt_mapped_fields_values.
  ENDMETHOD.                    "create_from_field_value


  METHOD _change_insplot.
    DATA wa_rmqed TYPE rmqed.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    CALL FUNCTION 'ENQUEUE_EQQALS1'
      EXPORTING
        mode_qals      = 'E'
        mandant        = sy-mandt
        prueflos       = is_qals-prueflos
        x_prueflos     = ' '
        _scope         = '2'
        _wait          = ' '
        _collect       = ' '
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.

    IF sy-subrc IS NOT INITIAL.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
      <wa_messages>-number = 007.
      <wa_messages>-type = 'E'.
      <wa_messages>-message_v1 = is_qals-prueflos.
      UNASSIGN <wa_messages>.
      RETURN.
    ENDIF.

    wa_rmqed-dbs_steuer  = '02'.
    wa_rmqed-dbs_flag    = 'X'.
    wa_rmqed-dbs_edunk   = 'X'.
    wa_rmqed-dbs_fdunk   = 'X'.
    wa_rmqed-dbs_noerr   = 'X'.
    wa_rmqed-dbs_nowrn   = 'X'.
    wa_rmqed-dbs_noauf   = 'X'.
    wa_rmqed-dbs_planzuo = 'X'.
    wa_rmqed-dbs_subrc   = 'X'.

    CALL FUNCTION 'QPL1_UPDATE_MEMORY'
      EXPORTING
        i_qals  = is_qals
        i_updkz = 'U'
        i_rmqed = wa_rmqed.

    CALL FUNCTION 'QPL1_INSPECTION_LOTS_POSTING'.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    CALL FUNCTION 'QPL1_INITIALIZE'.

    CALL FUNCTION 'DEQUEUE_EQQALS1'
      EXPORTING
        mode_qals  = 'E'
        mandant    = sy-mandt
        prueflos   = is_qals-prueflos
        x_prueflos = ' '
        _scope     = '3'
        _synchron  = ' '
        _collect   = ' '.
  ENDMETHOD.                    "_change_insplot


  METHOD _check.

  ENDMETHOD.                    "_check


  METHOD _create_insplot.
    DATA wa_created_qals TYPE qals.
    DATA wa_rmqed TYPE rmqed.
    DATA lv_subrc LIKE sy-subrc.

    FIELD-SYMBOLS <wa_messages> TYPE bapiret2.

    wa_rmqed-dbs_steuer  = '01'.
    wa_rmqed-dbs_flag    = 'X'.
    wa_rmqed-dbs_edunk   = 'X'.
    wa_rmqed-dbs_fdunk   = 'X'.
    wa_rmqed-dbs_noerr   = 'X'.
    wa_rmqed-dbs_nowrn   = 'X'.
    wa_rmqed-dbs_noauf   = 'X'.
    wa_rmqed-dbs_planzuo = 'X'.
    wa_rmqed-dbs_subrc   = 'X'.

    CALL FUNCTION 'QPL1_INSPECTION_LOT_CREATE'
      EXPORTING
        qals_imp   = is_qals
        rmqed_imp  = wa_rmqed
      IMPORTING
        e_prueflos = ev_insplot_number
        e_qals     = wa_created_qals
        subrc      = lv_subrc.

    IF lv_subrc IS INITIAL.
      CALL FUNCTION 'QPL1_UPDATE_MEMORY'
        EXPORTING
          i_qals  = wa_created_qals
          i_updkz = 'I'
          i_rmqed = wa_rmqed.

      CALL FUNCTION 'QPL1_INSPECTION_LOTS_POSTING'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

      APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
      <wa_messages>-type = 'S'.
      <wa_messages>-number = 005.
      <wa_messages>-message_v1 = ev_insplot_number.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
      <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
      <wa_messages>-type = 'E'.
      <wa_messages>-number = 006.
      <wa_messages>-message_v1 = lv_subrc.

      CLEAR ev_insplot_number.
    ENDIF.

    CALL FUNCTION 'QPL1_INITIALIZE'.

    CLEAR: wa_created_qals, lv_subrc.
  ENDMETHOD.                    "_create_insplot


  METHOD _get_bms_matnr_keys.
    FIELD-SYMBOLS <wa_fields_values> TYPE zqm_lab_s_field_value.

    READ TABLE it_fields_values
    ASSIGNING <wa_fields_values>
    WITH KEY fieldname = 'WIDTH_SETP'.

    IF sy-subrc IS INITIAL.
      ev_breite_soll = <wa_fields_values>-value.
    ENDIF.

    READ TABLE it_fields_values
    ASSIGNING <wa_fields_values>
    WITH KEY fieldname = 'DIAMETER_SETP'.

    IF sy-subrc IS INITIAL.
      ev_durchmesser_soll = <wa_fields_values>-value.
    ENDIF.

    READ TABLE it_fields_values
    ASSIGNING <wa_fields_values>
    WITH KEY fieldname = 'WINDERCORE_TYP'.

    IF sy-subrc IS INITIAL.
      ev_wicklerkern_type = <wa_fields_values>-value.
    ENDIF.
  ENDMETHOD.                    "_GET_BMS_MATNR_KEYS


  METHOD _get_insplot_active.
    DATA lt_qals TYPE STANDARD TABLE OF qals.
    DATA wa_language TYPE bapi2045la.
    DATA: lt_system_status TYPE STANDARD TABLE OF bapi2045ss,
          lt_user_status TYPE STANDARD TABLE OF bapi2045us.

    CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
               co_storno TYPE j_istat VALUE 'I0224'.

* Set language to english
    wa_language-langu = 'EN'.

    SELECT *
    FROM qals
    INTO rs_qals
    WHERE zzlinienr = is_qals-zzlinienr
      AND werk = is_qals-werk                   "Ticket SR-805906 (March 2025)
      AND ( ( pastrzeit <= is_qals-pastrzeit AND
            pastrterm = is_qals-pastrterm ) OR
            pastrterm < is_qals-pastrterm )
      AND ( ( paendzeit >= is_qals-pastrzeit AND
            paendterm = is_qals-pastrterm ) OR
            paendterm > is_qals-pastrterm )
    ORDER BY paendterm DESCENDING paendzeit DESCENDING.

* Check status
      CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
        EXPORTING
          number        = rs_qals-prueflos
          language      = wa_language
        TABLES
          system_status = lt_system_status
          user_status   = lt_user_status.

      DELETE lt_system_status WHERE sys_status <> co_decision
                                AND sys_status <> co_storno.

      IF lt_system_status[] IS INITIAL.
        EXIT.
      ELSE.
        CLEAR rs_qals.
      ENDIF.
    ENDSELECT.

    FREE: lt_system_status, lt_user_status.
    CLEAR wa_language.
  ENDMETHOD.                    "_get_insplot_active


  METHOD _get_insplot_after.
    DATA lt_qals TYPE STANDARD TABLE OF qals.
    DATA wa_language TYPE bapi2045la.
    DATA: lt_system_status TYPE STANDARD TABLE OF bapi2045ss,
          lt_user_status TYPE STANDARD TABLE OF bapi2045us.

    CONSTANTS: co_decision TYPE j_istat VALUE 'I0218',
               co_storno TYPE j_istat VALUE 'I0224'.

* Set language to english
    wa_language-langu = 'EN'.

    SELECT *
    FROM qals
    INTO rs_qals
    WHERE zzlinienr = is_qals-zzlinienr
      AND ( ( pastrzeit > is_qals-pastrzeit AND
            pastrterm = is_qals-pastrterm ) OR
            pastrterm > is_qals-pastrterm )
    ORDER BY paendterm paendzeit.

* Check status
      CALL FUNCTION 'BAPI_INSPLOT_GETSTATUS'
        EXPORTING
          number        = rs_qals-prueflos
          language      = wa_language
        TABLES
          system_status = lt_system_status
          user_status   = lt_user_status.

      DELETE lt_system_status WHERE sys_status <> co_decision
                                AND sys_status <> co_storno.

      IF lt_system_status[] IS INITIAL.
        EXIT.
      ELSE.
        CLEAR rs_qals.
      ENDIF.
    ENDSELECT.

    FREE: lt_system_status, lt_user_status.
    CLEAR wa_language.
  ENDMETHOD.                    "_get_insplot_after


  METHOD _get_material_number.
    DATA lv_tabname TYPE tabname16.

* Get the correct table to read
    lv_tabname = zcl_bms_material_util=>get_material_mapp_table( i_werks = iv_plant ).

    IF lv_tabname NP '*_SE'.
      lv_tabname = |{ lv_tabname }_SE|.
    ENDIF.

* Get material number from production type
    SELECT SINGLE sd_matnr
    FROM (lv_tabname)
    INTO rv_matnr
    WHERE werks = iv_plant
      AND bmsmatnr = iv_prod_type
      AND breite_soll = iv_breite_soll
      AND durchmesser_soll = iv_durchmesser_soll
      AND wicklerkern_type = iv_wicklerkern_type.

    IF rv_matnr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_import_exceptions
        EXPORTING
          textid = zcx_qm_lab_import_exceptions=>no_material_number.
    ENDIF.
  ENDMETHOD.                    "_get_material_number


  METHOD _map_fields.
    DATA obj_settings TYPE REF TO zcl_qm_lab_import_settings.
    DATA obj_exceptions TYPE REF TO zcx_qm_lab_import_exceptions.
    DATA obj_structure TYPE REF TO cl_abap_structdescr.
    DATA lt_mappings TYPE zqm_lab_t_field_mappings.
    DATA: lt_mapped_fields_values TYPE zqm_lab_t_field_value,
          wa_mapped_fields_values TYPE zqm_lab_s_field_value.
    DATA lt_components TYPE ddfields.

    FIELD-SYMBOLS: <wa_messages> TYPE bapiret2,
                   <lv_class_attribute> TYPE any,
                   <wa_mappings> TYPE zqm_lab_s_field_mappings,
                   <wa_fields_values> TYPE zqm_lab_s_field_value,
                   <wa_components> TYPE dfies.

    TRY.
* Create settings class and get field mappings
        CREATE OBJECT obj_settings.
        lt_mappings = obj_settings->get_field_mappings( iv_plant       = iv_plant
                                                        iv_application = me->_av_application ).

      CATCH zcx_qm_lab_import_exceptions INTO obj_exceptions.
        APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
        <wa_messages>-id = obj_exceptions->if_t100_message~t100key-msgid.
        <wa_messages>-number = obj_exceptions->if_t100_message~t100key-msgno.
        <wa_messages>-type = 'E'.
        <wa_messages>-message = obj_exceptions->get_text( ).

        IF obj_exceptions->if_t100_message~t100key-attr1 IS NOT INITIAL.
          ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr1) TO <lv_class_attribute>.
          IF sy-subrc IS INITIAL.
            <wa_messages>-message_v1 = <lv_class_attribute>.
          ENDIF.
        ENDIF.

        IF obj_exceptions->if_t100_message~t100key-attr2 IS NOT INITIAL.
          ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr2) TO <lv_class_attribute>.
          IF sy-subrc IS INITIAL.
            <wa_messages>-message_v2 = <lv_class_attribute>.
          ENDIF.
        ENDIF.

        IF obj_exceptions->if_t100_message~t100key-attr3 IS NOT INITIAL.
          ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr3) TO <lv_class_attribute>.
          IF sy-subrc IS INITIAL.
            <wa_messages>-message_v3 = <lv_class_attribute>.
          ENDIF.
        ENDIF.

        IF obj_exceptions->if_t100_message~t100key-attr4 IS NOT INITIAL.
          ASSIGN obj_exceptions->(obj_exceptions->if_t100_message~t100key-attr4) TO <lv_class_attribute>.
          IF sy-subrc IS INITIAL.
            <wa_messages>-message_v4 = <lv_class_attribute>.
          ENDIF.
        ENDIF.
    ENDTRY.

* Get structure fields
    obj_structure ?= cl_abap_structdescr=>describe_by_name( p_name = 'qals' ).
    lt_components = obj_structure->get_ddic_field_list( p_including_substructres = abap_true ).

    LOOP AT it_fields_values ASSIGNING <wa_fields_values>.
* Check if field has to be mapped
      READ TABLE lt_mappings
      ASSIGNING <wa_mappings>
      WITH KEY source_field = <wa_fields_values>-fieldname.

      IF sy-subrc IS INITIAL.
        READ TABLE lt_components
        ASSIGNING <wa_components>
        WITH KEY fieldname = <wa_mappings>-target_field.

        IF sy-subrc IS NOT INITIAL.
          APPEND INITIAL LINE TO et_messages ASSIGNING <wa_messages>.
          <wa_messages>-id = 'ZQM_LAB_DATA_IMPORT'.
          <wa_messages>-type = 'E'.
          <wa_messages>-number = 002.
          <wa_messages>-message_v1 = <wa_mappings>-source_field.
          UNASSIGN <wa_messages>.

          CONTINUE.
        ENDIF.

        wa_mapped_fields_values-fieldname = <wa_mappings>-target_field.
        wa_mapped_fields_values-value = <wa_fields_values>-value.
        INSERT wa_mapped_fields_values INTO TABLE lt_mapped_fields_values.
        CLEAR wa_mapped_fields_values.
      ENDIF.
    ENDLOOP.

    et_mapped_fields_values[] = lt_mapped_fields_values[].

    FREE: obj_settings, obj_structure.
    FREE: lt_mappings, lt_components.
  ENDMETHOD.                    "_map_fields
ENDCLASS.
