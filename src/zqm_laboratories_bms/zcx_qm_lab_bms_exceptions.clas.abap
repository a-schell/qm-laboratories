class ZCX_QM_LAB_BMS_EXCEPTIONS definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    begin of ERROR_RUNTIME_INSTANCE,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '000',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of ERROR_RUNTIME_INSTANCE .
  constants:
    begin of INSPPLOT_NOT_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '001',
      attr1 type scx_attrname value 'A_INSPPLOT',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INSPPLOT_NOT_FOUND .
  constants:
    begin of INSPPLOT_CLOSED,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '002',
      attr1 type scx_attrname value 'A_INSPPLOT',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INSPPLOT_CLOSED .
  constants:
    begin of NO_KEYFIELDS_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '003',
      attr1 type scx_attrname value 'A_INSPPLOT',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_KEYFIELDS_FOUND .
  constants:
    begin of NO_CHAR_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '006',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_CHAR_FOUND .
  constants:
    begin of NO_LAST_RUN_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '008',
      attr1 type scx_attrname value 'AV_REPORT_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_LAST_RUN_FOUND .
  constants:
    begin of INSPLOT_MISSING,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '012',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INSPLOT_MISSING .
  constants:
    begin of NOT_A_MULTI_EDIT_DATASET,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '021',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NOT_A_MULTI_EDIT_DATASET .
  constants:
    begin of NO_DATASET_FOUND,
      msgid type symsgid value 'ZQM_LABORATORIES_BMS',
      msgno type symsgno value '022',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_DATASET_FOUND .
  data A_INSPPLOT type QIBPLOSNR .
  data AV_REPORT_ID type PROGRAM .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !A_INSPPLOT type QIBPLOSNR optional
      !AV_REPORT_ID type PROGRAM optional .
protected section.
private section.
ENDCLASS.



CLASS ZCX_QM_LAB_BMS_EXCEPTIONS IMPLEMENTATION.


method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->A_INSPPLOT = A_INSPPLOT .
me->AV_REPORT_ID = AV_REPORT_ID .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
endmethod.
ENDCLASS.
