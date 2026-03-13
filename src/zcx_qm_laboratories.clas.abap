class ZCX_QM_LABORATORIES definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    begin of FIELDCATALOG_ERROR,
      msgid type symsgid value 'ZQM_LABORATORIES',
      msgno type symsgno value '000',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of FIELDCATALOG_ERROR .
  constants:
    begin of INSP_KEY_FIELDS_NOT_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES',
      msgno type symsgno value '001',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INSP_KEY_FIELDS_NOT_FOUND .
  constants:
    begin of NO_TABLE_FIELDS,
      msgid type symsgid value 'ZQM_LABORATORIES',
      msgno type symsgno value '002',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_TABLE_FIELDS .
  constants:
    begin of NO_CHAR_REQU_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES',
      msgno type symsgno value '003',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_CHAR_REQU_FOUND .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional .
protected section.
private section.
ENDCLASS.



CLASS ZCX_QM_LABORATORIES IMPLEMENTATION.


method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
endmethod.
ENDCLASS.
