*----------------------------------------------------------------------*
*       CLASS zcx_qm_lab_import_exceptions DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class ZCX_QM_LAB_IMPORT_EXCEPTIONS definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    begin of NO_PLANT_SUBMITTED,
      msgid type symsgid value 'ZQM_LAB_DATA_IMPORT',
      msgno type symsgno value '000',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_PLANT_SUBMITTED .
  constants:
    begin of NO_APPLICATION_SUBMITTED,
      msgid type symsgid value 'ZQM_LAB_DATA_IMPORT',
      msgno type symsgno value '001',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_APPLICATION_SUBMITTED .
  constants:
    begin of NO_MATERIAL_NUMBER,
      msgid type symsgid value 'ZQM_LAB_DATA_IMPORT',
      msgno type symsgno value '004',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_MATERIAL_NUMBER .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCX_QM_LAB_IMPORT_EXCEPTIONS IMPLEMENTATION.


  METHOD constructor.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.                    "constructor
ENDCLASS.
