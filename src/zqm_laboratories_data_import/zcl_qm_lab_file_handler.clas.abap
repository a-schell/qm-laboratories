*----------------------------------------------------------------------*
*       CLASS zcl_qm_lab_file_handler DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class ZCL_QM_LAB_FILE_HANDLER definition
  public
  final
  create public .

public section.

  class-methods GET_FILES_FROM_APPL_SEVER
    importing
      !IV_DIR_NAME type EPSF-EPSDIRNAM
      !IV_FILE_MASK type EPSF-EPSFILNAM OPTIONAL
    returning
      value(RT_FILES) type ZQM_LAB_T_FILE_LIST
    raising
      ZCX_QM_LAB_IMPORT_EXCEPTIONS .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_QM_LAB_FILE_HANDLER IMPLEMENTATION.


  METHOD get_files_from_appl_sever.
    DATA lv_eps_subdir TYPE epsf-epssubdir.
    DATA wa_file TYPE ls_file.
    DATA lv_error_counter TYPE int4.

    FIELD-SYMBOLS: <wa_files> TYPE zqm_lab_s_file_list.

* expand EPS subdirectory names
    IF iv_dir_name = space.
      RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
        EXPORTING
          textid = zcx_qm_lab_device_exceptions=>invalid_subdir.
    ENDIF.

* get directory listing
    CALL 'C_DIR_READ_FINISH'                  " just to be sure
          ID 'ERRNO'  FIELD wa_file-errno
          ID 'ERRMSG' FIELD wa_file-errmsg.

    CALL 'C_DIR_READ_START'
          ID 'DIR'    FIELD iv_dir_name
          ID 'FILE'   FIELD iv_file_mask "'*'
          ID 'ERRNO'  FIELD wa_file-errno
          ID 'ERRMSG' FIELD wa_file-errmsg.

    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_qm_lab_device_exceptions
        EXPORTING
          textid = zcx_qm_lab_device_exceptions=>read_directory_failed.
    ENDIF.

    DO.
      CLEAR wa_file.

      APPEND INITIAL LINE TO rt_files ASSIGNING <wa_files>.

      CALL 'C_DIR_READ_NEXT'
            ID 'TYPE'   FIELD wa_file-type
            ID 'NAME'   FIELD wa_file-name
            ID 'LEN'    FIELD wa_file-len
            ID 'OWNER'  FIELD wa_file-owner
            ID 'MTIME'  FIELD wa_file-mtime
            ID 'MODE'   FIELD wa_file-mode
            ID 'ERRNO'  FIELD wa_file-errno
            ID 'ERRMSG' FIELD wa_file-errmsg.

      IF wa_file-len > 2147483647.
        <wa_files>-size  = -99.
      ELSE.
        <wa_files>-size  = wa_file-len.
      ENDIF.

      <wa_files>-name = wa_file-name.
      <wa_files>-mtime = wa_file-mtime.

      IF sy-subrc = 0.
        IF wa_file-type(1) = 'f' OR              " regular file
           wa_file-type(1) = 'F'.

          lv_error_counter = lv_error_counter + 1.
          <wa_files>-rc   = 0.
        ENDIF.
      ELSEIF sy-subrc = 1.
        EXIT.
      ELSE.
        IF lv_error_counter > 1000.               "Original:FM gc_1000.
          CALL 'C_DIR_READ_FINISH'
                ID 'ERRNO'  FIELD wa_file-errno
                ID 'ERRMSG' FIELD wa_file-errmsg.

          DELETE TABLE rt_files
          FROM <wa_files>.

          RETURN.
        ENDIF.

        <wa_files>-rc  = 18.
      ENDIF.
    ENDDO.

    DELETE rt_files
    WHERE name = '.'
       OR name = '..'
       OR name = ''
       OR name = ' '.

    SORT rt_files BY mtime.
  ENDMETHOD.                    "GET_FILES_FROM_APPL_SEVER
ENDCLASS.
