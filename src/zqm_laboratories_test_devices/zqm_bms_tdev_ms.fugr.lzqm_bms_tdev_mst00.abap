*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZQM_DEV_BEDAPMAP................................*
DATA:  BEGIN OF STATUS_ZQM_DEV_BEDAPMAP              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_DEV_BEDAPMAP              .
CONTROLS: TCTRL_ZQM_DEV_BEDAPMAP
            TYPE TABLEVIEW USING SCREEN '0002'.
*...processing: ZQM_DEV_PLANT...................................*
DATA:  BEGIN OF STATUS_ZQM_DEV_PLANT                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_DEV_PLANT                 .
CONTROLS: TCTRL_ZQM_DEV_PLANT
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZQM_DEV_SETTINGS................................*
DATA:  BEGIN OF STATUS_ZQM_DEV_SETTINGS              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZQM_DEV_SETTINGS              .
CONTROLS: TCTRL_ZQM_DEV_SETTINGS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZQM_DEV_BEDAPMAP              .
TABLES: *ZQM_DEV_PLANT                 .
TABLES: *ZQM_DEV_SETTINGS              .
TABLES: ZQM_DEV_BEDAPMAP               .
TABLES: ZQM_DEV_PLANT                  .
TABLES: ZQM_DEV_SETTINGS               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
