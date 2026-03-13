FUNCTION Z_QM_SEND_PAPER_MAIL.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IT_MAIL_ADDRESSES) TYPE  SOMLRECI1_T
*"     REFERENCE(IT_MESSAGE) TYPE  SWFTLISTI1
*"     REFERENCE(IV_SUBJECT) TYPE  SO_OBJ_DES
*"     REFERENCE(IS_FORMOUTPUT) TYPE  FPFORMOUTPUT
*"     REFERENCE(IV_FILENAME) TYPE  SO_OBJ_DES
*"  EXPORTING
*"     REFERENCE(EV_RETURNCODE) TYPE  SY-SUBRC
*"----------------------------------------------------------------------

*&---------------------------------------------------------------------*
*& AUTHOR: INF/Jamnig, jaw@informatics.at
*& DATE: 8.2.2017
*& DESCRIPTION: Mail-Template für Mails mit Anhängen
*&              IT_MAIL_ADDRESSES: nur RECEIVERS mit Mail-Adr zu füllen
*&              IT_MESSAGE: in HTML (mit <html><body> etc.)
*& CHANGE:
*&---------------------------------------------------------------------*
  DATA:  lt_receivers     TYPE somlreci1_t,
         ls_receivers     TYPE somlreci1,
         lt_packing_list  TYPE swftpcklst,
         ls_packing_list  TYPE sopcklsti1,
         ls_doc_data      TYPE sodocchgi1,
         ls_message       TYPE solisti1,
         lv_lines         TYPE i,
         lv_length        TYPE i,
         lt_attachment    TYPE swftlisti1,
         ls_attachment    TYPE LINE OF swftlisti1,
         ls_att_head      TYPE solisti1,
         lt_att_head      TYPE swftlisti1,
         lv_commit        TYPE xflag.

* Mail Empfänger füllen
  LOOP AT it_mail_addresses INTO ls_receivers.
    ls_receivers-rec_type   = 'U'.    "&---- Send to External Email id
    ls_receivers-com_type   = 'INT'.
    APPEND ls_receivers TO lt_receivers .
  ENDLOOP.

* PackingList Eintrag für Mail Nachricht eintragen
  CLEAR ls_packing_list.
  ls_packing_list-transf_bin = space.
  ls_packing_list-head_start = 1.
  ls_packing_list-head_num   = 0.
  ls_packing_list-body_start = 1.
  ls_packing_list-doc_type   = 'HTM'.
  DESCRIBE TABLE it_message LINES ls_packing_list-body_num.
  APPEND ls_packing_list TO lt_packing_list.

* Mail Header setzen
  DESCRIBE TABLE it_message LINES lv_lines.
  READ TABLE it_message INTO ls_message INDEX lv_lines.
  ls_doc_data-doc_size = ( lv_lines - 1 ) * 255 + strlen( ls_message ).
  ls_doc_data-obj_langu = sy-langu.
  ls_doc_data-obj_name = 'SAPRPT'.
  ls_doc_data-sensitivty = 'F'.

* Betreff
  ls_doc_data-obj_descr = iv_subject.

* Dokumentanhang
  "Anhang konvertieren
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer                = is_formoutput-pdf
    IMPORTING
      OUTPUT_LENGTH         = lv_length
    tables
      binary_tab            = lt_attachment.

  "PackingList Eintrag für Attachment eintragen
  DESCRIBE TABLE lt_attachment LINES lv_lines.

  CLEAR ls_packing_list.
  ls_packing_list-transf_bin = 'X'.
  ls_packing_list-head_start = 1.
  ls_packing_list-head_num   = 1.
  ls_packing_list-body_start = 1.
  ls_packing_list-body_num   = lv_lines.
  ls_packing_list-doc_type   = 'PDF'.
  ls_packing_list-doc_size   = lv_length.
  CONCATENATE iv_filename '.pdf' INTO ls_packing_list-obj_descr.
  ls_packing_list-obj_name   = ls_packing_list-obj_descr.

  APPEND ls_packing_list TO lt_packing_list.

  "Attachment-Header
  ls_att_head-line          = ls_packing_list-obj_descr.
  APPEND ls_att_head TO lt_att_head.

*  IF sy-batch EQ 'X'.
*    clear: lv_commit.
*  ELSE.
*    lv_commit = 'X'.
*  ENDIF.

* Mail senden
  CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
    EXPORTING
      document_data              = ls_doc_data
      commit_work                = lv_commit
    TABLES
      packing_list               = lt_packing_list
      contents_txt               = it_message
      receivers                  = lt_receivers
      object_header              = lt_att_head
      contents_bin               = lt_attachment
    EXCEPTIONS
      too_many_receivers         = 1
      document_not_sent          = 2
      document_type_not_exist    = 3
      operation_no_authorization = 4
      parameter_error            = 5
      x_error                    = 6
      enqueue_error              = 7
      OTHERS                     = 8.

  ev_returncode = sy-subrc.
ENDFUNCTION.
