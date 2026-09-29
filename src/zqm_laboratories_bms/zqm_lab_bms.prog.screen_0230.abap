
PROCESS BEFORE OUTPUT.
  MODULE pbo_0230.
  CALL SUBSCREEN subscr_selection_screen INCLUDING sy-cprog '0130'.
  CALL SUBSCREEN subscr_working_area INCLUDING sy-cprog '0300'.

PROCESS AFTER INPUT.
  MODULE exit_command AT EXIT-COMMAND.
  MODULE pai_0230.
  CALL SUBSCREEN subscr_selection_screen.
  CALL SUBSCREEN subscr_working_area.
