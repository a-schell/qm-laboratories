*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
  TYPES: BEGIN OF ls_file,
           dirname    TYPE dirname_al11, " name of directory. (possibly truncated.)
           name       TYPE filename_al11, " name of entry. (possibly truncated.)
           type(10)   TYPE c,
           len(8)     TYPE p DECIMALS 0,
           owner      TYPE fileowner_al11,
           mtime(6)   TYPE p DECIMALS 0,
           mode(9)    TYPE c,
           errno(3)   TYPE c,
           errmsg(40) TYPE c,
         END OF ls_file.
