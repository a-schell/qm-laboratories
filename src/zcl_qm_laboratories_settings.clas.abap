class ZCL_QM_LABORATORIES_SETTINGS definition
  public
  final
  create public .

public section.

  methods GET_FIELD_REFERENCES
    importing
      !IV_IDENT_KEY type QSLWBEZ
    returning
      value(RT_REFERENCES) type ZQM_T_LABORATORIES_REFERENCES
    raising
      ZCX_QM_LABORATORIES .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LABORATORIES_SETTINGS IMPLEMENTATION.


METHOD get_field_references.
  SELECT *
  INTO TABLE rt_references
  FROM zqm_references
  WHERE ident_key = iv_ident_key.
ENDMETHOD.
ENDCLASS.
