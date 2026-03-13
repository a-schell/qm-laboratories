*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZQMALVCUST......................................*
DATA:  BEGIN OF STATUS_ZQMALVCUST                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQMALVCUST                    .
CONTROLS: TCTRL_ZQMALVCUST
            TYPE TABLEVIEW USING SCREEN '0001'.
*...processing: ZQMALVCUSTT.....................................*
DATA:  BEGIN OF STATUS_ZQMALVCUSTT                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQMALVCUSTT                   .
CONTROLS: TCTRL_ZQMALVCUSTT
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZQMCONDENSE.....................................*
DATA:  BEGIN OF STATUS_ZQMCONDENSE                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQMCONDENSE                   .
CONTROLS: TCTRL_ZQMCONDENSE
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: ZQMINSPOPFLGMAP.................................*
DATA:  BEGIN OF STATUS_ZQMINSPOPFLGMAP               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQMINSPOPFLGMAP               .
CONTROLS: TCTRL_ZQMINSPOPFLGMAP
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZQMALVCUST                    .
TABLES: *ZQMALVCUSTT                   .
TABLES: *ZQMCONDENSE                   .
TABLES: *ZQMINSPOPFLGMAP               .
TABLES: ZQMALVCUST                     .
TABLES: ZQMALVCUSTT                    .
TABLES: ZQMCONDENSE                    .
TABLES: ZQMINSPOPFLGMAP                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
