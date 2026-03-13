FUNCTION z_qm_delete_doc_references.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IS_VBAK) TYPE  VBAK
*"  EXPORTING
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"  EXCEPTIONS
*"      NOT_SUPPORTED
*"----------------------------------------------------------------------
  TYPES: BEGIN OF ls_relations,
          objkey_a TYPE	swo_typeid,
          objtype_a	TYPE swo_objtyp,
          objkey_b TYPE	swo_typeid,
          objtype_b	TYPE swo_objtyp,
         END OF ls_relations.

  TYPES: BEGIN OF ls_db_relations,
          role_a TYPE swo_typeid,
          type_a TYPE swo_objtyp,
          role_b TYPE swo_typeid,
          type_b TYPE swo_objtyp,
         END OF ls_db_relations.

  DATA lt_db_relations TYPE STANDARD TABLE OF ls_db_relations.
  DATA lt_relations TYPE STANDARD TABLE OF ls_relations WITH KEY objkey_a objkey_b.
  DATA: wa_role_a TYPE borident,
        wa_role_b TYPE borident.

  CONSTANTS co_qm_bus_type TYPE swo_objtyp VALUE 'BUS2078'.

  FIELD-SYMBOLS: <wa_relations> TYPE ls_relations,
                 <wa_return> TYPE bapiret2,
                 <wa_db_relations> TYPE ls_db_relations.

  IF is_vbak-auart <> 'ZFRE' AND is_vbak-auart <> 'ZFR2'.
    RAISE not_supported.
  ENDIF.

  SELECT role_a~objkey AS role_a
         role_a~objtype AS type_a
         role_b~objkey AS role_b
         role_b~objtype AS type_b
  FROM srrelroles AS role_a
  INNER JOIN smzb_binrel AS rel
  ON role_a~roleid = rel~role_a
  INNER JOIN srrelroles AS role_b
  ON rel~role_b = role_b~roleid
  INTO TABLE lt_db_relations
  WHERE role_a~objtype = co_qm_bus_type
    AND role_b~objkey = is_vbak-vbeln.

  SORT lt_db_relations BY role_a type_a role_b type_b.
  DELETE ADJACENT DUPLICATES FROM lt_db_relations COMPARING role_a type_a role_b type_b.

  LOOP AT lt_db_relations ASSIGNING <wa_db_relations>.
    APPEND INITIAL LINE TO lt_relations ASSIGNING <wa_relations>.
    <wa_relations>-objkey_a = <wa_db_relations>-role_a.
    <wa_relations>-objtype_a = <wa_db_relations>-type_a.
    <wa_relations>-objkey_b = <wa_db_relations>-role_b.
    <wa_relations>-objtype_b = <wa_db_relations>-type_b.
  ENDLOOP.

  SORT lt_relations BY objkey_a objkey_b.
  DELETE ADJACENT DUPLICATES FROM lt_relations COMPARING objkey_a objkey_b.

  LOOP AT lt_relations ASSIGNING <wa_relations>.
    wa_role_a-objkey = <wa_relations>-objkey_a.
    wa_role_a-objtype = <wa_relations>-objtype_a.
    wa_role_b-objkey = <wa_relations>-objkey_b.
    wa_role_b-objtype = <wa_relations>-objtype_b.

    CALL FUNCTION 'QMLR_DELETE_DOCUMENT_FLOW'
      EXPORTING
        role_a              = wa_role_a
        role_b              = wa_role_b
        reltype             = 'REFZ'
      EXCEPTIONS
        no_logical_system   = 1
        no_relation_deleted = 2
        OTHERS              = 3.

    IF sy-subrc = 1 OR sy-subrc = 3.
      APPEND INITIAL LINE TO et_return ASSIGNING <wa_return>.
      <wa_return>-id = 'ZQM_LABORATORIES'.
      <wa_return>-type = 'E'.
      <wa_return>-number = 006.
      <wa_return>-message_v1 = <wa_relations>-objkey_a.
      <wa_return>-message_v2 = <wa_relations>-objkey_b.
      UNASSIGN <wa_return>.
    ENDIF.

    CLEAR: wa_role_a, wa_role_b.
  ENDLOOP.

  FREE: lt_relations, lt_db_relations.
ENDFUNCTION.
