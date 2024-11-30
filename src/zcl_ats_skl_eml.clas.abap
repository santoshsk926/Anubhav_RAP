*To execute this class method directly press F9
CLASS zcl_ats_skl_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: lv_opr TYPE c VALUE 'C'.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ATS_SKL_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    CASE lv_opr.
      WHEN 'R'.
        READ ENTITIES OF zats_skl_travel ENTITY Travel
*        ALL FIELDS WITH VALUE #(  "This will retrieve all the columns from the entity.
        FIELDS ( travelid AgencyId CustomerId OverallStatus ) WITH VALUE #(  "Here we are specifying the necessary fields only
                                   ( TravelId = '00000006' )
                                   ( TravelId = '00000020' )
                                   ( TravelId = '00230' )
                               )
         RESULT DATA(lt_result)
         FAILED DATA(lt_failed)
         REPORTED DATA(lt_messages).

        out->write(
          EXPORTING
            data   = lt_result ).

        out->write(
          EXPORTING
            data   = lt_failed ).

      WHEN 'C'.
        DATA(lv_description) = 'Santosh rocks with RAP'.
        DATA(lv_agency) = '070016'.
        DATA(lv_customer) = '000697'.

        MODIFY ENTITIES OF zats_skl_travel ENTITY Travel
        CREATE FIELDS ( travelid
                        agencyid
                        currencycode
                        begindate
                        enddate
                        description
                        OverallStatus )
         WITH VALUE #(
                        ( %CID = 'Santosh'  "CID is very important when creating the new record.
                          travelid = '00000001'
                          agencyid = lv_agency
                          customerid = lv_customer
                          begindate = cl_abap_context_info=>get_system_date( )
                          enddate = cl_abap_context_info=>get_system_date( ) + 30
                          Description = lv_description
                          OverallStatus = 'O'
                        )
                        ( %CID = 'Santosh-1'
                          travelid = '00000002'
                          agencyid = lv_agency
                          customerid = lv_customer
                          begindate = cl_abap_context_info=>get_system_date( )
                          enddate = cl_abap_context_info=>get_system_date( ) + 30
                          Description = lv_description
                          OverallStatus = 'O'
                        )
                        ( %CID = 'Santosh-3'
                          travelid = '00000003'
                          agencyid = lv_agency
                          customerid = lv_customer
                          begindate = cl_abap_context_info=>get_system_date( )
                          enddate = cl_abap_context_info=>get_system_date( ) + 30
                          Description = lv_description
                          OverallStatus = 'O'
                        ) )
                   MAPPED DATA(lt_mapped) "MAPPED is used only in CREATE functionality.
                   FAILED lt_failed
                   REPORTED lt_messages.
                   COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_result ).

        out->write(
          EXPORTING
            data   = lt_failed ).

      WHEN 'U'.

        lv_description = 'Wow, Santosh that was an update'.
        lv_agency = '070032'.

        MODIFY ENTITIES OF zats_skl_travel ENTITY Travel
        UPDATE FIELDS ( agencyid
                        description
                       )
         WITH VALUE #(
                        ( travelid = '00000001'
                          agencyid = lv_agency
                          Description = lv_description
                        )
                        ( travelid = '00000002'
                          agencyid = lv_agency
                          Description = lv_description
                        ) )
                   MAPPED lt_mapped
                   FAILED lt_failed
                   REPORTED lt_messages.
            COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_result ).

        out->write(
          EXPORTING
            data   = lt_failed ).

      WHEN 'D'.

      MODIFY ENTITIES OF zats_skl_travel ENTITY Travel
      DELETE FROM VALUE #( ( travelid = '00000001' )
                           ( travelid = '00000002' )
                         )
      MAPPED lt_mapped
      FAILED lt_failed
      REPORTED lt_messages.
      COMMIT ENTITIES.

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
