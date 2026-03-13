class ZCL_QM_LAB_MAPPER_ICL definition
  public
  final
  create public .

public section.

  interfaces ZIF_QM_LAB_DEVICE_MAPPER .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LAB_MAPPER_ICL IMPLEMENTATION.


  METHOD zif_qm_lab_device_mapper~map.
    FIELD-SYMBOLS <wa_mapped_data> TYPE zqm_s_lab_device_target_1.

    IF is_transfer_data-raw_data IS INITIAL OR strlen( is_transfer_data-raw_data ) < 24.
      RETURN.
    ENDIF.

    ASSIGN es_mapped_data TO <wa_mapped_data>.

    " 21ICL001852023100106001.16
    IF is_transfer_data-raw_data+2(3) = 'ICL'.
      DATA(lv_value_len) = strlen( is_transfer_data-raw_data ) - 22.

      <wa_mapped_data>-linie = is_transfer_data-raw_data+0(2).
      <wa_mapped_data>-bedap_code = is_transfer_data-raw_data+2(8).
      <wa_mapped_data>-date = is_transfer_data-raw_data+10(8).
      <wa_mapped_data>-time = is_transfer_data-raw_data+18(4).
      " inspection point cannot be created at 00:00 time, change to 00:01
      IF <wa_mapped_data>-time = '0000'.
        <wa_mapped_data>-time = '0001'.
      ENDIF.
      <wa_mapped_data>-value = is_transfer_data-raw_data+22(lv_value_len).
    ELSE.
      " Move raw values to structure
      MOVE is_transfer_data-raw_data TO <wa_mapped_data>.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
