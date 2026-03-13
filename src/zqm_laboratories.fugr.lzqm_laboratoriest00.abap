*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZQM_CALC_C......................................*
DATA:  BEGIN OF STATUS_ZQM_CALC_C                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_CALC_C                    .
CONTROLS: TCTRL_ZQM_CALC_C
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZQM_CALC_H......................................*
DATA:  BEGIN OF STATUS_ZQM_CALC_H                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_CALC_H                    .
CONTROLS: TCTRL_ZQM_CALC_H
            TYPE TABLEVIEW USING SCREEN '0002'.
*...processing: ZQM_CALC_P......................................*
DATA:  BEGIN OF STATUS_ZQM_CALC_P                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_CALC_P                    .
CONTROLS: TCTRL_ZQM_CALC_P
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: ZQM_REFERENCES..................................*
DATA:  BEGIN OF STATUS_ZQM_REFERENCES                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_REFERENCES                .
CONTROLS: TCTRL_ZQM_REFERENCES
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZQM_CALC_C                    .
TABLES: *ZQM_CALC_H                    .
TABLES: *ZQM_CALC_P                    .
TABLES: *ZQM_REFERENCES                .
TABLES: ZQM_CALC_C                     .
TABLES: ZQM_CALC_H                     .
TABLES: ZQM_CALC_P                     .
TABLES: ZQM_REFERENCES                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
