
PROCESS BEFORE OUTPUT.
  CALL SUBSCREEN subscr_single_maintain INCLUDING sy-cprog '0310'.
  CALL SUBSCREEN subscr_multi_maintain INCLUDING sy-cprog '0320'.
  MODULE pbo_0300.
*
PROCESS AFTER INPUT.
  CALL SUBSCREEN subscr_single_maintain.
  CALL SUBSCREEN subscr_multi_maintain.
  MODULE pai_0300.
