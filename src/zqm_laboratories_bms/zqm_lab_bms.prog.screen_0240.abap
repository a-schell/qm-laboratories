
PROCESS BEFORE OUTPUT.
  MODULE pbo_0240.
  CALL SUBSCREEN subscr_selection_screen INCLUDING sy-cprog '0140'.
  CALL SUBSCREEN subscr_working_area INCLUDING sy-cprog '0300'.

PROCESS AFTER INPUT.
  MODULE exit_command AT EXIT-COMMAND.
  MODULE pai_0240.
  CALL SUBSCREEN subscr_selection_screen.
  CALL SUBSCREEN subscr_working_area.
