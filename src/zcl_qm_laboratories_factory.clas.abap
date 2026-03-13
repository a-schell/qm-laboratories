class ZCL_QM_LABORATORIES_FACTORY definition
  public
  final
  create public .

public section.

  class-methods CLASS_CONSTRUCTOR .
  class-methods GET_GUI_HELPER
    returning
      value(RO_INSTANCE) type ref to ZIF_QM_LABORATORIES_GUI
    raising
      ZCX_QM_LABORATORIES .
  class-methods GET_MASTER
    returning
      value(RO_INSTANCE) type ref to ZIF_QM_LABORATORIES_MASTER
    raising
      ZCX_QM_LABORATORIES .
protected section.
private section.
ENDCLASS.



CLASS ZCL_QM_LABORATORIES_FACTORY IMPLEMENTATION.


method CLASS_CONSTRUCTOR.
endmethod.


METHOD get_gui_helper.
  CREATE OBJECT ro_instance TYPE zcl_qm_laboratories_gui.
ENDMETHOD.


METHOD get_master.
  CREATE OBJECT ro_instance TYPE zcl_qm_laboratories_master.
ENDMETHOD.
ENDCLASS.
