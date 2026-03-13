class ZCL_QM_LAB_MAPPER_DIMENSION definition
  public
  final
  create public .

public section.

  interfaces ZIF_QM_LAB_DEVICE_MAPPER .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LAB_MAPPER_DIMENSION IMPLEMENTATION.


METHOD zif_qm_lab_device_mapper~map.
  DATA lv_data_len TYPE int4.
  DATA lv_value_len TYPE int4.

  FIELD-SYMBOLS <wa_mapped_data> TYPE zqm_s_lab_device_target_2.

  lv_data_len = strlen( is_transfer_data-raw_data ).

  IF is_transfer_data-raw_data IS INITIAL OR lv_data_len < 24.
    RETURN.
  ENDIF.

  lv_value_len = lv_data_len - 24.

  ASSIGN es_mapped_data TO <wa_mapped_data>.
  <wa_mapped_data>-linie = is_transfer_data-raw_data+4(2).
  <wa_mapped_data>-bedap_code = is_transfer_data-raw_data+0(12).
  <wa_mapped_data>-date = is_transfer_data-raw_data+12(8).
  <wa_mapped_data>-time = is_transfer_data-raw_data+20(4).
  " inspection point cannot be created at 00:00 time, change to 00:01
  IF <wa_mapped_data>-time = '0000'.
    <wa_mapped_data>-time = '0001'.
  ENDIF.
  <wa_mapped_data>-value = is_transfer_data-raw_data+24(lv_value_len).

  " Replace line numbers in BEDAP code with #
  <wa_mapped_data>-bedap_code+4(1) = <wa_mapped_data>-bedap_code+5(1) = '#'.

  CLEAR: lv_data_len, lv_value_len.
ENDMETHOD.
ENDCLASS.
