CLASS lsc_zats_skl_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zats_skl_travel IMPLEMENTATION.

  METHOD save_modified.
    DATA: travel_log_update TYPE STANDARD TABLE OF /dmo/log_travel,
          final_changes     TYPE STANDARD TABLE OF /dmo/log_travel.

    IF update-travel IS NOT INITIAL.

      travel_log_update = CORRESPONDING #( update-travel MAPPING
                                              travel_id = TravelId
       ).

      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<travel_log_update>).

        ASSIGN travel_log_update[ travel_id = <travel_log_update>-TravelId ]
            TO FIELD-SYMBOL(<travel_log_db>).

        GET TIME STAMP FIELD <travel_log_db>-created_at.

        IF <travel_log_update>-%control-CustomerId = if_abap_behv=>mk-on.

          TRY.
              <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          <travel_log_db>-changed_field_name = 'anubhav_customer'.
          <travel_log_db>-changed_value = <travel_log_update>-CustomerId.
          <travel_log_db>-changing_operation = 'CHANGE'.

          APPEND <travel_log_db> TO final_changes.

        ENDIF.

        IF <travel_log_update>-%control-AgencyId = if_abap_behv=>mk-on.

          TRY.
              <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.

          ENDTRY.
          <travel_log_db>-changed_field_name = 'anubhav_agency'.
          <travel_log_db>-changed_value = <travel_log_update>-AgencyId.
          <travel_log_db>-changing_operation = 'CHANGE'.

          APPEND <travel_log_db> TO final_changes.
        ENDIF.
      ENDLOOP.
      INSERT /dmo/log_travel FROM TABLE @final_changes.

    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.   "LHC ka matlab Local Handler Class
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.

    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.

    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.

    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.

* When you add "early numbering" in BDEF system will propose the method definition with parameters.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.  "Doubt -> Where is the importing parameter coming from.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_Booking.

    TYPES: t_entity_create   TYPE TABLE FOR CREATE zats_skl_travel,
           t_entity_update   TYPE TABLE FOR UPDATE zats_skl_travel,
           t_entity_reported TYPE TABLE FOR REPORTED zats_skl_travel,
           t_entity_error    TYPE TABLE FOR FAILED zats_skl_travel.

    METHODS precheck_anubhav_reuse IMPORTING entities_u TYPE t_entity_update OPTIONAL
                                             entities_c TYPE t_entity_create OPTIONAL
                                   EXPORTING reported   TYPE t_entity_reported
                                             failed     TYPE t_entity_error.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    DATA: ls_result LIKE LINE OF result.
    ""In this method we are trying to achieve instance level authorization. If a travel request is cancelled, it should not be allowed for
    ""modification and copy is also not possible.
    ""Step 1: Get the data of my instance.
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE
        ENTITY travel
            FIELDS ( travelid overallstatus )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travels)
        FAILED DATA(lt_failed).
    ""Step 2: loop at the data.
    LOOP AT lt_travels INTO DATA(ls_travels).
      ""Step 3: check if the instance was having status = cancelled
      IF ls_travels-OverallStatus = 'X'.
        DATA(lv_auth) = abap_false.
      ELSE.
        lv_auth = abap_true.
        ""Step 4: Check for authorization in org.
        ""Step 5: If the permission is denied - the role is not added for user, reject the edit
      ENDIF.

      ls_result = VALUE #( travelid = ls_travels-travelid
                           %update = COND #( WHEN lv_auth EQ abap_false
                                               THEN if_abap_behv=>auth-unauthorized
                                              ELSE if_abap_behv=>auth-allowed )

                           %action-copytravel = COND #( WHEN lv_auth EQ abap_false
                                               THEN if_abap_behv=>auth-unauthorized
                                              ELSE if_abap_behv=>auth-allowed ) ).

      APPEND ls_result TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE zats_skl_travel,
          travel_id_max TYPE /dmo/travel_id.  "Data Element

    "Step 1: Ensure that TRAVEL ID is not set for the record which is coming.
    LOOP AT entities INTO entity WHERE TravelID IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travelid) = entities.
    DELETE entities_wo_travelid WHERE travelid IS NOT INITIAL.
    "Step 2: Get the sequence numbers from the SNRO.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*          ignore_buffer     =
            nr_range_nr       = '01'
            object            = '/DMO/TRAVL'
            quantity          = CONV #( lines( entitIes_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_range_return_code)
            returned_quantity = DATA(number_range_returned_quantity)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        "Step 3: If there is an exception, we will throw the error.
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = lx_number_ranges ) TO reported-travel.  "Doubt, where is this reported declared.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key ) TO failed-travel.
        ENDLOOP.
        EXIT.
    ENDTRY.

    CASE number_range_return_code.
      WHEN '1'.
        "Step 4: Handle special cases where the number range exceed critical %
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                      textid = /dmo/cm_flight_messages=>number_range_depleted
                                      severity = if_abap_behv_message=>severity-warning
                          ) ) TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key ) TO failed-travel.
        ENDLOOP.
      WHEN '2' OR '3'.
        "Step 5: The number range return last number, or number exhausted
        APPEND VALUE #( %cid = entity-%cid
                              %key = entity-%key
                              %msg = NEW /dmo/cm_flight_messages(
                                          textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                          severity = if_abap_behv_message=>severity-warning
                              ) ) TO reported-travel.
        APPEND VALUE #( %cid = entity-%cid
                        %key = entity-%key
                        %fail-cause = if_abap_behv=>cause-conflict
                         ) TO failed-travel.
    ENDCASE.
    "Step 6: Final check for all numbers.
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).
    "Step 7: Loop over the incoming travel data and assign the numbers from number range and return MAPPED data which will then go to RAP framework
    travel_id_max = number_range_key - number_range_returned_quantity.

    LOOP AT entities_wo_travelid INTO entity.
      travel_id_max += 1.
      entity-TravelId = Travel_id_max.
      APPEND VALUE #( %cid = entity-%cid
                      %key = entity-%key
                      "Missed the draft setting for number range.
                      %is_draft = entity-%is_draft ) TO mapped-travel.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
    DATA max_booking_id TYPE /dmo/booking_id.
    "Step 1: get all the travel requests and their booking data
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE "Local mode will not check for authorizations
     ENTITY travel BY \_Booking
     FROM CORRESPONDING #( entities )
     LINK DATA(bookings).

    "Loop at unique travel ids
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-travelid.
      "Step 2: get the highest booking number which is already there.
*      LOOP AT bookings INTO DATA(ls_booking) USING KEY entity "entity contains key and cid. We can avoid the statement USING KEY ENTITY if we are confused.
      LOOP AT bookings INTO DATA(ls_booking) "above line is commented for draft
        WHERE source-travelid = <travel_group>-travelid.
        IF max_booking_id < ls_booking-target-BookingId.
          max_booking_id = ls_booking-target-BookingId.
        ENDIF.
      ENDLOOP.
      "Step 3: get the assigned booking number for incoming request
*      LOOP AT entities INTO DATA(ls_entity) USING KEY entity "Commented for Draft
      LOOP AT entities INTO DATA(ls_entity)
            WHERE travelid = <travel_group>-travelid.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF max_booking_id < ls_target-BookingId.
            max_booking_id = ls_target-BookingId.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
      "Step 4: loop over all the entities of travel with same travel id
*      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>) USING KEY entity "Commeted for Draft
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>)
         WHERE travelid = <travel_group>-travelid.
        "Step 5: assign new booking ids to the booking entity inside each travel
        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_numbers>).
          APPEND CORRESPONDING #( <booking_wo_numbers> ) TO mapped-booking
          ASSIGNING FIELD-SYMBOL(<mapped_booking>).
          IF <mapped_booking>-bookingid IS INITIAL.
            max_booking_id += 10.
            <mapped_booking>-BookingId = max_booking_id.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD copyTravel.

    DATA: travels       TYPE TABLE FOR CREATE zats_skl_travel\\Travel,  "Doubt -> What does this declaration mean?
          bookings_cba  TYPE TABLE FOR CREATE zats_skl_travel\\Travel\_Booking,
          booksuppl_cba TYPE TABLE FOR CREATE zats_skl_travel\\Booking\_BookingSupplement.

    "Step 1: Remove the travel instances with initial %cid
    READ TABLE keys INTO DATA(key_with_initial_cid) WITH KEY %cid = ''.
    ASSERT key_with_initial_cid IS INITIAL.

    "Step 2: Read all Travel, Booking, Booking Supplement using EML.
    "Here we are reading the entities from ZATS_SKL_TRAVEL because it is our business object root node.
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE  "Here we are moving the corresponding data between entity and keys table.
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travel_read_result)
    FAILED failed.

    "Here we are reading the entities from ZATS_SKL_TRAVEL because it is our business object root node.
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( travel_read_result )
    RESULT DATA(book_read_result)
    FAILED failed.

    "Here we are reading the entities from ZATS_SKL_TRAVEL because it is our business object root node.
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement
    ALL FIELDS WITH CORRESPONDING #( book_read_result )
    RESULT DATA(booksuppl_read_result)
    FAILED failed.

    "Step 3: Fill Travel internal table for Travel data creation - %cid - abc123
    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).

      "Travel Data preparation
      APPEND VALUE #( %cid = keys[ %tky = <travel>-%tky ]-%cid  "Doubt -> Need to debug and check how the structure looks like. Also what does %tky mean
                      %data = CORRESPONDING #( <travel> EXCEPT travelid ) )
                      TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <new_travel>-EndDate = cl_abap_context_info=>get_system_date(  ) + 30.
      <new_travel>-OverallStatus = 'O'.

      "Step 4: Fill Booking internal table for Booking data creation - %cid_ref - abc123

*      APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid ) "Commented for Draft
      APPEND VALUE #( %cid_ref = keys[ %tky = <travel>-%tky ]-%cid )
        TO bookings_cba ASSIGNING FIELD-SYMBOL(<bookings_cba>).

      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) WHERE travelid = <travel>-travelid.

*        APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-bookingid "Commeted for Draft
        APPEND VALUE #( %cid = keys[ %tky = <travel>-%tky ]-%cid && <booking>-bookingid
*                        %data = CORRESPONDING #( book_read_result[ KEY entity %tky = <booking>-%tky ] EXCEPT travelid ) ) "Commented for Draft
                        %data = CORRESPONDING #( book_read_result[ %tky = <booking>-%tky ] EXCEPT travelid ) )
                        TO <bookings_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).
        <new_booking>-BookingStatus = 'N'.

        "Step 5: Fill Booking Supplement internal table for supplement data creation creation

*        APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-bookingid ) "Commented for Draft
        APPEND VALUE #( %cid_ref = keys[ %tky = <travel>-%tky ]-%cid && <booking>-bookingid )
          TO booksuppl_cba ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<booksuppl>)
*          USING KEY entity WHERE travelid = <travel>-travelid "Commented for Draft
          WHERE travelid = <travel>-travelid
                             AND bookingid = <booking>-bookingid.

*          APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-bookingid && <booksuppl>-BookingSupplementId "Commented for Draft
          APPEND VALUE #( %cid = keys[ %tky = <travel>-%tky ]-%cid && <booking>-bookingid && <booksuppl>-BookingSupplementId
                          %data = CORRESPONDING #( <booksuppl> EXCEPT travelid bookingid ) )
                                  TO <booksuppl_cba>-%target.

        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
    "Step 6: Modify entity EML to create new BO instance using existing data.

    MODIFY ENTITIES OF zats_skl_travel IN LOCAL MODE
    ENTITY travel
      CREATE FIELDS ( agencyid
                      CustomerId
                      BeginDate
                      EndDate
                      BookingFee
                      TotalPrice
                      CurrencyCode
                      OverallStatus ) WITH travels

       CREATE BY \_Booking FIELDS ( bookingid
                                    bookingdate
                                    customerid
                                    carrierid
                                    connectionid
                                    flightprice
                                    currencycode
                                    bookingstatus ) WITH bookings_cba

      ENTITY Booking
       CREATE BY \_Bookingsupplement FIELDS ( BOOKINGsupplementid
                                              supplementid
                                              price
                                              currencycode ) WITH booksuppl_cba
         MAPPED DATA(mapped_create).
    mapped-travel = mapped_create-travel. "Doubt -> What is this?

  ENDMETHOD.

  METHOD get_instance_features.

    "Step 1 : Read the travel data with status
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE
     ENTITY Travel
      FIELDS ( travelid overallstatus )
      WITH CORRESPONDING #( keys ) RESULT DATA(travels)
                                   FAILED failed.
    "Step 2: Return the result with booking creation possible or not
    READ TABLE travels INTO DATA(ls_travel) INDEX 1.
    IF sy-subrc EQ 0.
      IF ( ls_travel-overallstatus = 'A' ).
        DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
      ELSE.
        lv_allow = if_abap_behv=>fc-o-enabled.
      ENDIF.
      result = VALUE #( FOR travel IN travels
                         ( %tky = travel-%tky
                           %assoc-_Booking = lv_allow

                        "Dynamic Feature Control
                           %action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                               THEN if_abap_behv=>fc-o-disabled
                                                          ELSE if_abap_behv=>fc-o-enabled )

                           %action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                               THEN if_abap_behv=>fc-o-disabled
                                                          ELSE if_abap_behv=>fc-o-enabled )
                          ) ).
    ENDIF.
  ENDMETHOD.

  METHOD reCalcTotalPrice.
*    Define a structure where we can store all the booking fees and currency code.
    TYPES : BEGIN OF ty_amount_per_currency,
              amount        TYPE /dmo/total_price,
              currency_code TYPE /dmo/currency_code,
            END OF ty_amount_per_currency.

    DATA : amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currency.

*    Read all the travel instances, subsequent bookings using EML.
    READ ENTITIES OF ZATS_skl_TRAVEL IN LOCAL MODE
       ENTITY Travel
       FIELDS ( BookingFee CurrencyCode )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    READ ENTITIES OF ZATS_skl_TRAVEL IN LOCAL MODE
      ENTITY Travel BY \_Booking
      FIELDS ( FlightPrice CurrencyCode )
      WITH CORRESPONDING #( travels )
      RESULT DATA(bookings).

    READ ENTITIES OF ZATS_skl_TRAVEL IN LOCAL MODE
       ENTITY Booking BY \_BookingSupplement
       FIELDS ( price CurrencyCode )
       WITH CORRESPONDING #( bookings )
       RESULT DATA(bookingsupplements).

*    Delete the values w/o any currency.
    DELETE travels WHERE CurrencyCode IS INITIAL.
    DELETE bookings WHERE CurrencyCode IS INITIAL.
    DELETE bookingsupplements WHERE CurrencyCode IS INITIAL.

*    Total all booking and supplement amounts which are in common currency.
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      "Set the first value for total price by adding the booking fee from header
      amounts_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
                                            currency_code = <travel>-CurrencyCode ) ).
*    Loop all the amounts and compare with target currency.
      LOOP AT bookings INTO DATA(booking) WHERE TravelId = <travel>-TravelId.

        COLLECT VALUE ty_amount_per_currency( amount = booking-FlightPrice
                                              currency_code = booking-CurrencyCode
        ) INTO amounts_per_currencycode.

      ENDLOOP.

      LOOP AT bookingsupplements INTO DATA(bookingsupplement) WHERE TravelId = <travel>-TravelId.

        COLLECT VALUE ty_amount_per_currency( amount = bookingsupplement-Price
                                              currency_code = booking-CurrencyCode
        ) INTO amounts_per_currencycode.

      ENDLOOP.

      CLEAR <travel>-TotalPrice.

*    Perform currency conversion.
      LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).

        IF amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += amount_per_currencycode-amount.
        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               = amount_per_currencycode-amount
              iv_currency_code_source = amount_per_currencycode-currency_code
              iv_currency_code_target = <travel>-CurrencyCode
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            IMPORTING
              ev_amount               = DATA(total_booking_amt)
          ).

          <travel>-TotalPrice = <travel>-TotalPrice + total_booking_amt.
        ENDIF.

      ENDLOOP.
*    Put back the total amount.
    ENDLOOP.
*    Return the total amount in Mapped so the RAP will modify this data to DB.
    MODIFY ENTITIES OF zats_skl_travel IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( TotalPrice ) WITH CORRESPONDING #( travels ).
  ENDMETHOD.

  METHOD CalculateTotalPrice.

*    DATA travel_ids TYPE STANDARD TABLE OF /dmo/i_travel_m.
*
*    travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING travel_id = travelid ).

    MODIFY ENTITIES OF ZATS_skl_TRAVEL IN LOCAL MODE
          ENTITY travel
              EXECUTE reCalcTotalPrice
              FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateHeaderData.
    "step 1: read the travel data
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE
     ENTITY travel
     FIELDS ( CustomerId )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_travel).

    "Step 2: Declare a sorted table for holding customer id's
    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    "Step 3: Extract the unique customer id's in our table
    customers = CORRESPONDING #( lt_travel DISCARDING DUPLICATES
                                           MAPPING customer_id = CustomerId EXCEPT *  ).

    DELETE customers WHERE customer_id IS INITIAL.

    ""Get the validation done to get all customer ids from db
    ""these are the IDs which are present
    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(lt_cust_db).

    ENDIF.

    ""loop at travel data
    LOOP AT lt_travel INTO DATA(ls_travel).

      IF ( ls_travel-CustomerId IS INITIAL OR
           NOT line_exists(  lt_cust_db[ customer_id = ls_travel-CustomerId ] ) ).

        ""Inform the RAP framework to terminate the create
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-customerid = if_abap_behv=>mk-on "We have to specify framework which field is causing the problem, so framework will highlight that field.
                        %msg = NEW /dmo/cm_flight_messages(
                                      textid                = /dmo/cm_flight_messages=>customer_unkown
                                      customer_id           = ls_travel-CustomerId
                                      severity              = if_abap_behv_message=>severity-error

        ) ) TO reported-travel.
      ENDIF.

      ""1. Check if begin and end date are empty.
      IF ls_travel-BeginDate IS INITIAL.
        ""Inform RAP framework to terminate the create
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-begindate = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid                = /dmo/cm_flight_messages=>enter_begin_date
                                    begin_date            = ls_travel-BeginDate
                                    severity              = if_abap_behv_message=>severity-error
                                    ) ) TO reported-travel.

      ENDIF.

      IF ls_travel-EndDate IS INITIAL.
        ""Inform RAP framework to terminate the create
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-enddate = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid                = /dmo/cm_flight_messages=>enter_end_date
                                    end_date              = ls_travel-enddate
                                    severity              = if_abap_behv_message=>severity-error
                                    ) ) TO reported-travel.

      ENDIF.

      ""2. Check if the end date is always > begin date.
      IF ls_travel-begindate GT ls_travel-EndDate.
        ""Inform RAP framework to terminate the create
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-enddate = if_abap_behv=>mk-on
                        %element-begindate = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid                = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                    begin_date            = ls_travel-begindate
                                    end_date              = ls_travel-enddate
                                    severity              = if_abap_behv_message=>severity-error
                                    ) ) TO reported-travel.

      ENDIF.

      ""3. Begin date of travel should be in future.
      IF ls_travel-begindate LT cl_abap_context_info=>get_system_date(  ).
        ""Inform RAP framework to terminate the create
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-begindate = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid                = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                    begin_date            = ls_travel-begindate
                                    severity              = if_abap_behv_message=>severity-error
                                    ) ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create.

    precheck_anubhav_reuse(
      EXPORTING
*      entities_u =
        entities_c = entities
      IMPORTING
        reported   = reported-travel
        failed     = failed-travel
    ).

  ENDMETHOD.

  METHOD precheck_update.

    precheck_anubhav_reuse(
      EXPORTING
        entities_u = entities
*      entities_c = entities
      IMPORTING
        reported   = reported-travel
        failed     = failed-travel
    ).
  ENDMETHOD.

  METHOD precheck_anubhav_reuse.
    ""Step 1: data declaration
    DATA: entities  TYPE t_entity_update,
          operation TYPE if_abap_behv=>t_char01,
          agencies  TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id,
          customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    ""Step 2: check either entity_c was passed or entity_u was passed.
*    ASSERT NOT ( entities_c IS INITIAL EQUIV entities_u IS INITIAL ).

    ""Step 3: Perform validation only if agency or customer was changed
    IF entities_c IS NOT INITIAL.
      entities = CORRESPONDING #( entities_c ).
      operation = if_abap_behv=>op-m-create.
    ELSE.
      entities = CORRESPONDING #( entities_u ).
      operation = if_abap_behv=>op-m-update.
    ENDIF.

    DELETE entities WHERE %control-AgencyId = if_abap_behv=>mk-off AND "To check Agency id or customer id is changed.
                          %control-Customerid = if_abap_behv=>mk-off.

    ""Step 4: get all the unique agencies and customer in a table
    agencies  = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = Agencyid EXCEPT * ).
    customers  = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING customer_id = customerid EXCEPT * ).

    ""Step 5: Select the agency and customer data from DB tables.
    SELECT FROM /dmo/agency
    FIELDS agency_id, country_code
    FOR ALL ENTRIES IN @agencies
    WHERE agency_id = @agencies-agency_id
    INTO TABLE @DATA(agency_country_codes).

    SELECT FROM /dmo/customer
    FIELDS customer_id, country_code
    FOR ALL ENTRIES IN @customers
    WHERE customer_id = @customers-customer_id
    INTO TABLE @DATA(customer_country_codes).

    ""Step 6: Loop at incoming entities and compare each agency and customer country.
    LOOP AT entities INTO DATA(entity).
      READ TABLE agency_country_codes WITH KEY agency_id = entity-agencyid INTO DATA(ls_agency).
      READ TABLE customer_country_codes WITH KEY customer_id = entity-CustomerId INTO DATA(LS_customer).

      IF ls_agency-country_code <> ls_customer-country_code.
        ""Step 7: If country doesn't match through the error
        APPEND VALUE #( %cid = COND #( WHEN operation = if_abap_behv=>op-m-create THEN entity-%cid_ref )
                                        %is_draft = entity-%is_draft
                                        %fail-cause = if_abap_behv=>cause-conflict
                ) TO failed.

        APPEND VALUE #( %cid = COND #( WHEN operation = if_abap_behv=>op-m-create THEN entity-%cid_ref )
                        %is_draft = entity-%is_draft
                        %msg = NEW /dmo/cm_flight_messages(
                               textid = VALUE #(
                                          msgid = 'SY'
                                          msgno = 499
                                          attr1 = 'The country codes for agency and customer not'
                                          attr2 = 'matching' )
                        agency_id   = entity-AgencyId
                        customer_id = entity-CustomerId
                        severity    = if_abap_behv_message=>severity-error )
                        %element-agencyid = if_abap_behv=>mk-on
          ) TO reported.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD acceptTravel.
     ""Perform the change of BO instance to change status.
     MODIFY ENTITIES OF zats_skl_travel IN LOCAL MODE ENTITY Travel
     UPDATE FIELDS ( OverallStatus )
     WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                     %is_draft = key-%is_draft
                                     OverallStatus = 'A' ) ).

     ""Read the BO instance from DB on which we want to make the changes.
     READ ENTITIES OF zats_skl_travel IN LOCAL MODE ENTITY Travel
     ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_results).

     ""Return back the updated results back to UI
     result = VALUE #( FOR travel IN lt_results ( %tky = travel-%tky
                                                  %param = travel ) ). "Here my understanding is %PARAM will have all the data.

  ENDMETHOD.

  METHOD rejectTravel.

  ""Perform the change of BO instance to change status.
     MODIFY ENTITIES OF zats_skl_travel IN LOCAL MODE ENTITY Travel
     UPDATE FIELDS ( OverallStatus )
     WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                     %is_draft = key-%is_draft
                                     OverallStatus = 'X' ) ).

     ""Read the BO instance from DB on which we want to make the changes.
     READ ENTITIES OF zats_skl_travel IN LOCAL MODE ENTITY Travel
     ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_results).

     ""Return back the updated results back to UI
     result = VALUE #( FOR travel IN lt_results ( %tky = travel-%tky
                                                  %param = travel ) ). "Here my understanding is %param will have all the data.
  ENDMETHOD.

ENDCLASS.
