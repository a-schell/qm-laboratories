*----------------------------------------------------------------------*
***INCLUDE ZQM_LAB_TAGESBERICHT_REPORTI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'SAVE'.
      PERFORM save_inspection_lot.
    WHEN 'END' OR 'ESC' OR 'BACK'.
      PERFORM dequeue_inspection_lots.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
