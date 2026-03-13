class ZCX_QM_LAB_DEVICE_EXCEPTIONS definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    begin of NO_DEVICE_SETTINGS_FOUND,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '000',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_DEVICE_SETTINGS_FOUND .
  constants:
    begin of DEVICE_ID_IS_MISSING,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '001',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of DEVICE_ID_IS_MISSING .
  constants:
    begin of NO_DATA_SUBMITTED,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '002',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_DATA_SUBMITTED .
  constants:
    begin of INVALID_SUBDIR,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '003',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INVALID_SUBDIR .
  constants:
    begin of READ_DIRECTORY_FAILED,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '004',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of READ_DIRECTORY_FAILED .
  constants:
    begin of COULD_NOT_DETERMINE_DEVICE_ID,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '005',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of COULD_NOT_DETERMINE_DEVICE_ID .
  constants:
    begin of NO_BEDAP_MAPPING_FOUND,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '006',
      attr1 type scx_attrname value 'AV_BEDAP_CODE',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_BEDAP_MAPPING_FOUND .
  constants:
    begin of DATASET_GUID_IS_MISSING,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '007',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of DATASET_GUID_IS_MISSING .
  constants:
    begin of STATUS_NOT_UPDATED,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '008',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of STATUS_NOT_UPDATED .
  constants:
    begin of NO_SETTINGS_FOR_PLANT,
      msgid type symsgid value 'ZQM_LAB_TEST_DEVICES',
      msgno type symsgno value '009',
      attr1 type scx_attrname value 'AV_PLANT',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_SETTINGS_FOR_PLANT .
  data AV_BEDAP_CODE type ZQM_BEDAP_CODE .
  data AV_PLANT type WERKS_D .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !AV_BEDAP_CODE type ZQM_BEDAP_CODE optional
      !AV_PLANT type WERKS_D optional .
protected section.
private section.
ENDCLASS.



CLASS ZCX_QM_LAB_DEVICE_EXCEPTIONS IMPLEMENTATION.


method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->AV_BEDAP_CODE = AV_BEDAP_CODE .
me->AV_PLANT = AV_PLANT .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
endmethod.
ENDCLASS.
