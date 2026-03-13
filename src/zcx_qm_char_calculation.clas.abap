class ZCX_QM_CHAR_CALCULATION definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    begin of CHAR_MISSING,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '000',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of CHAR_MISSING .
  constants:
    begin of NO_HEADER_CUSTOMIZING,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '001',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_HEADER_CUSTOMIZING .
  constants:
    begin of NO_ITEMS_CUSTOMIZING,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '002',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_ITEMS_CUSTOMIZING .
  constants:
    begin of NO_PARAM_CUSTOMIZING,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '003',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_PARAM_CUSTOMIZING .
  constants:
    begin of METHOD_NOT_FOUND,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '004',
      attr1 type scx_attrname value 'METHOD_NAME',
      attr2 type scx_attrname value 'CLASS_NAME',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of METHOD_NOT_FOUND .
  constants:
    begin of NO_CLASS,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '005',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_CLASS .
  constants:
    begin of CLASS_EXCEPTION,
      msgid type symsgid value 'ZQM_CHAR_CALC',
      msgno type symsgno value '006',
      attr1 type scx_attrname value 'ERROR_TEXT',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of CLASS_EXCEPTION .
  data METHOD_NAME type SEOCPDNAME .
  data CLASS_NAME type SEOCLSNAME .
  data ERROR_TEXT type STRING .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !METHOD_NAME type SEOCPDNAME optional
      !CLASS_NAME type SEOCLSNAME optional
      !ERROR_TEXT type STRING optional .
protected section.
private section.
ENDCLASS.



CLASS ZCX_QM_CHAR_CALCULATION IMPLEMENTATION.


method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->METHOD_NAME = METHOD_NAME .
me->CLASS_NAME = CLASS_NAME .
me->ERROR_TEXT = ERROR_TEXT .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
endmethod.
ENDCLASS.
