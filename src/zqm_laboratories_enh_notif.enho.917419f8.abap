"Name: \PR:RQPRSS30\FO:ADDITIONAL_DATA\SE:END\EI
ENHANCEMENT 0 ZQM_LABORATORIES_ENH_NOTIF.
* 16.01.2017; INFORMATICS/Wiesmayr; wiw@informatics.at
* add columns qmnum and qmtxt to output alv
  LOOP AT object_tab INTO l_object_tab.
    SELECT SINGLE qmnum FROM zqmprobes INTO (l_object_tab-lqprs-qmnum) WHERE phynr = l_object_tab-lqprs-phynr.
    IF sy-subrc EQ 0.
      SELECT SINGLE qmtxt FROM qmel INTO (l_object_tab-lqprs-qmtxt) WHERE qmnum = l_object_tab-lqprs-qmnum.

      MODIFY object_tab FROM l_object_tab.
    ENDIF.
  ENDLOOP.
ENDENHANCEMENT.
