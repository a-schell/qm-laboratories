FUNCTION Z_CREATE_TEXT.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(FID) LIKE  THEAD-TDID
*"     VALUE(FLANGUAGE) LIKE  THEAD-TDSPRAS
*"     VALUE(FNAME) LIKE  THEAD-TDNAME
*"     VALUE(FOBJECT) LIKE  THEAD-TDOBJECT
*"     VALUE(SAVE_DIRECT) TYPE  ZSD_SAVE_SO10 DEFAULT 'X'
*"     VALUE(FFORMAT) LIKE  TLINE-TDFORMAT DEFAULT '*'
*"  TABLES
*"      FLINES STRUCTURE  TLINE
*"  EXCEPTIONS
*"      NO_INIT
*"      NO_SAVE
*"----------------------------------------------------------------------

  DATA: FHEADER LIKE THEAD.

  DATA: BEGIN OF TLINETAB OCCURS 10.
          INCLUDE STRUCTURE TLINE.
  DATA: END OF TLINETAB.

  CALL FUNCTION 'INIT_TEXT'
       EXPORTING
            ID       = FID
            LANGUAGE = FLANGUAGE
            NAME     = FNAME
            OBJECT   = FOBJECT
       IMPORTING
            HEADER   = FHEADER
       TABLES
            LINES    = TLINETAB
       EXCEPTIONS
            ID       = 01
            LANGUAGE = 02
            NAME     = 03
            OBJECT   = 04.

  IF SY-SUBRC <> 0.
    RAISE NO_INIT.
  ENDIF.

*  IF FFORMAT <> SPACE.
*   LOOP AT FLINES.
*     FLINES-TDFORMAT = FFORMAT.
*     MODIFY FLINES.
*   ENDLOOP.
*  ENDIF.

  FHEADER-TDMACODE2 = 'CREATE_TEXT'.

  CALL FUNCTION 'SAVE_TEXT'
       EXPORTING
            HEADER          = FHEADER
            INSERT          = ' '
            SAVEMODE_DIRECT = SAVE_DIRECT
       IMPORTING
            NEWHEADER       = FHEADER
       TABLES
            LINES           = FLINES
       EXCEPTIONS
            ID              = 01
            LANGUAGE        = 02
            NAME            = 03
            OBJECT          = 04.

  IF SY-SUBRC = 0.
    CALL FUNCTION 'COMMIT_TEXT'
       EXPORTING
            OBJECT   = FOBJECT
            NAME     = FNAME.
  ELSE.
    RAISE NO_SAVE.
  ENDIF.

ENDFUNCTION.
