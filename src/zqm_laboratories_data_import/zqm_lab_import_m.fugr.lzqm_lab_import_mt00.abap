*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZQM_IMPAPPLSETT.................................*
DATA:  BEGIN OF STATUS_ZQM_IMPAPPLSETT               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_IMPAPPLSETT               .
CONTROLS: TCTRL_ZQM_IMPAPPLSETT
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZQM_IMPFLDMAP...................................*
DATA:  BEGIN OF STATUS_ZQM_IMPFLDMAP                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_IMPFLDMAP                 .
CONTROLS: TCTRL_ZQM_IMPFLDMAP
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZQM_IMPAPPLSETT               .
TABLES: *ZQM_IMPFLDMAP                 .
TABLES: ZQM_IMPAPPLSETT                .
TABLES: ZQM_IMPFLDMAP                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
