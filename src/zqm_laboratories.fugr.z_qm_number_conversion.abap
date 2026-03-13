FUNCTION z_qm_number_conversion.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EXTERNAL) TYPE  ANY
*"  EXPORTING
*"     REFERENCE(EV_INTERNAL) TYPE  ANY
*"  RAISING
*"      CX_SY_CONVERSION_NO_NUMBER
*"----------------------------------------------------------------------
  STATICS sw_usr01 TYPE usr01.

  DATA: lv_thousands TYPE c LENGTH 1,
        lv_decimal   TYPE c LENGTH 1,
        lv_translate TYPE c LENGTH 2.
  DATA: lt_results TYPE match_result_tab,
        wa_result TYPE match_result,
        lv_match TYPE string VALUE '^\s*-?\s*(?:\d{1,3}(?:(T?)\d{3})?(?:\1\d{3})*(D\d*)?|D\d+)\s*$'.
  DATA lv_regex_internal TYPE string VALUE '^[0-9]\d*(\.\d+)?$'.
  DATA: lv_int TYPE string,
        lv_dec TYPE string.
  DATA lv_input TYPE string.

  lv_input = iv_external.

* Check the number is valid
  FIND REGEX lv_regex_internal IN lv_input.
  IF sy-subrc IS INITIAL.
    ev_internal = lv_input.
    RETURN.
  ENDIF.

* Get separator from user record
  IF sw_usr01 IS INITIAL.
    SELECT SINGLE *
    FROM usr01
    INTO sw_usr01
    WHERE bname = sy-uname.
  ENDIF.

  CASE sw_usr01-dcpfm.
    WHEN space.  " 1.234.567,89
      lv_thousands = '.'.
      lv_decimal   = ','.
    WHEN 'X'.    " 1,234,567.89
      lv_thousands = ','.
      lv_decimal   = '.'.
    WHEN 'Y'.    " 1 234 567,89
      lv_thousands = space.
      lv_decimal   = ','.
  ENDCASE.

* Modify regex to handle the user's selected notation
  REPLACE ALL OCCURRENCES OF 'T' IN lv_match WITH lv_thousands.

  IF lv_decimal EQ '.'.
    REPLACE ALL OCCURRENCES OF 'D' IN lv_match WITH '\.'.
  ELSE.
    REPLACE ALL OCCURRENCES OF 'D' IN lv_match WITH lv_decimal.
  ENDIF.

* Check the number is valid
  FIND REGEX lv_match IN lv_input.
  IF sy-subrc IS NOT INITIAL.
    RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
  ENDIF.

* Translate thousand separator into "space"
  CONCATENATE lv_thousands space INTO lv_translate.
  TRANSLATE lv_input USING lv_translate.

* Translate decimal into .
  CONCATENATE lv_decimal '.' INTO lv_translate.
  TRANSLATE lv_input USING lv_translate.

* Remove spaces
  CONDENSE lv_input NO-GAPS.
  ev_internal = lv_input.

  CLEAR lv_input.
ENDFUNCTION.
