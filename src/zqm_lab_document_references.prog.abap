*&---------------------------------------------------------------------*
*&  Include           ZQM_LAB_DOCUMENT_REFERENCES
*&---------------------------------------------------------------------*
DATA lt_return TYPE bapiret2_t.

CALL FUNCTION 'Z_QM_DELETE_DOC_REFERENCES'
  EXPORTING
    is_vbak       = vbak
  IMPORTING
    et_return     = lt_return
  EXCEPTIONS
    not_supported = 1
    OTHERS        = 3.

IF sy-subrc <> 1.
  IF lt_return[] IS NOT INITIAL.
    CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
      TABLES
        i_bapiret2_tab = lt_return.
  ENDIF.
ENDIF.
