CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsupplement.
    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~CalculateTotalPrice.
    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Booking~reCalcTotalPrice.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    DATA max_booking_suppl_id TYPE /dmo/booking_supplement_id.
*    "Step 1: get all the travel requests and their booking data
    READ ENTITIES OF zats_skl_travel IN LOCAL MODE "Local mode will not check for authorizations
     ENTITY Booking BY \_BookingSupplement
     FROM CORRESPONDING #( entities )
     LINK DATA(booking_supplements).

    "Loop at unique travel ids
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky.
      "Step 2: get the highest booking supplement number which is already there.
*      LOOP AT booking_supplements INTO DATA(ls_booking) USING KEY entity "entity contains key and cid. We can avoid the statement USING KEY ENTITY if we are confused.
      LOOP AT booking_supplements INTO DATA(ls_booking) "Above line is commented for Draft
         WHERE source-travelid = <booking_group>-travelid
           AND source-BookingId = <booking_group>-BookingId.
        IF max_booking_suppl_id < ls_booking-target-BookingSupplementId.
          max_booking_suppl_id = ls_booking-target-BookingSupplementId.
        ENDIF.
      ENDLOOP.

      "Step 3: get the assigned booking supplement number for incoming request
      LOOP AT entities INTO DATA(ls_entity) "USING KEY entity
             WHERE travelid = <booking_group>-travelid
               AND bookingid = <booking_group>-BookingId.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF max_booking_suppl_id < ls_target-BookingSupplementId.
            max_booking_suppl_id = ls_target-BookingSupplementId.
          ENDIF.
        ENDLOOP.
      ENDLOOP.

      "Step 4: loop over all the entities of travel with same travel id
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>)
*        USING KEY entity WHERE travelid = <booking_group>-travelid "Line is commented for Draft
                           WHERE travelid = <booking_group>-travelid
                           AND bookingid = <booking_group>-BookingId.
        "Step 5: assign new booking ids to the booking entity inside each travel
        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<bookingsuppl_wo_numbers>).
          APPEND CORRESPONDING #( <bookingsuppl_wo_numbers> ) TO mapped-booksuppl
          ASSIGNING FIELD-SYMBOL(<mapped_bookingsuppl>).
          IF <mapped_bookingsuppl>-BookingSupplementId IS INITIAL.
            max_booking_suppl_id += 1.
            <mapped_bookingsuppl>-%is_draft = <bookingsuppl_wo_numbers>-%is_draft.
            <mapped_bookingsuppl>-BookingSupplementId = max_booking_suppl_id.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD CalculateTotalPrice.

    DATA travel_ids TYPE STANDARD TABLE OF zats_skl_travel_processor WITH UNIQUE HASHED KEY key COMPONENTS travelid.

    travel_ids = CORRESPONDING #( KEYS DISCARDING DUPLICATES MAPPING travelid = TravelId ).

    MODIFY ENTITIES OF zats_skl_travel IN LOCAL MODE
     ENTITY travel
     EXECUTE reCalcTotalPrice
      FROM CORRESPONDING #( travel_ids ).

  ENDMETHOD.

  METHOD reCalcTotalPrice.

  READ ENTITIES OF ZATS_skl_TRAVEL IN LOCAL MODE
       ENTITY Travel
       FIELDS ( BookingFee CurrencyCode )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

  ENDMETHOD.

ENDCLASS.
