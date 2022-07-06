REPORT zz_copy_gos_attachment_links.
*
* link GOS attachments from one object to another object.
* originally needed to link an existing attachment of a vendor (LFA1)
* to the business partner (BUS1006).

DATA h_object TYPE c LENGTH 40.
PARAMETERS p_tyfrom TYPE sibftypeid DEFAULT 'LFA1'.
PARAMETERS p_tyto   TYPE sibftypeid DEFAULT 'BUS1006'.

SELECT-OPTIONS s_obfrom FOR h_object.

PARAMETERS pty_atta AS CHECKBOX DEFAULT 'X'.
PARAMETERS pty_url  AS CHECKBOX DEFAULT 'X'.
PARAMETERS pty_note AS CHECKBOX DEFAULT 'X'.

CLASS helper DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS get_new_id
      IMPORTING
        current    TYPE sibfboriid
      RETURNING
        VALUE(new) TYPE sibfboriid.
ENDCLASS.

CLASS helper IMPLEMENTATION.
  METHOD get_new_id.
    new = current.
    new+0(1) = '2'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.


  DATA rel_options TYPE obl_t_relt.

  IF pty_atta IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = 'ATTA' ) TO rel_options.
  ENDIF.

  IF pty_url IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = 'URL' ) TO rel_options.
  ENDIF.

  IF pty_note IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = 'NOTE' ) TO rel_options.
  ENDIF.


  SELECT DISTINCT instid_a FROM srgbtbrel
    INTO TABLE @DATA(existing_objects)
   WHERE reltype  IN @rel_options
     AND instid_a IN @s_obfrom.

  LOOP AT existing_objects INTO DATA(existing_object).

    TRY.
        cl_binary_relation=>read_links_of_binrels(
          EXPORTING
            is_object           = VALUE #( instid = existing_object
                                           typeid = p_tyfrom
                                           catid  = 'BO' )
            it_relation_options = rel_options
          IMPORTING
            et_links            = DATA(links)   " Table with Relationship Records
            et_roles            = DATA(roles)   " Table of Related Roles
        ).
      CATCH cx_obl_parameter_error  " Incorrect Calling of Interface
            cx_obl_internal_error   " Internal Error of Relationship Service
            cx_obl_model_error      " Error with Model Roles
        INTO DATA(binrel_read).
        MESSAGE binrel_read TYPE 'I'.
        RETURN.
    ENDTRY.

    LOOP AT links INTO DATA(link).

      TRY.
          cl_binary_relation=>create_link(
              is_object_a = VALUE #(
                instid = helper=>get_new_id( link-instid_a )
                typeid = p_tyto
                catid = link-catid_b )
              is_object_b = VALUE #(
                instid = link-instid_b
                typeid = link-typeid_b
                catid  = link-catid_b )
              ip_reltype  = link-reltype ).
        CATCH cx_obl_parameter_error  " Incorrect Calling of Interface
              cx_obl_model_error      " Error with Model Roles
              cx_obl_internal_error   " Internal Error of Relationship Service
         INTO DATA(binrel_create).
          MESSAGE binrel_create TYPE 'I'.
          RETURN.
      ENDTRY.

    ENDLOOP.
  ENDLOOP.

  COMMIT WORK.
  MESSAGE 'doc links added' TYPE 'S'.
