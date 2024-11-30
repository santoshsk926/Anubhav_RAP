CLASS zcl_santosh_mission_mars DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: itab TYPE TABLE OF string.
    INTERFACES if_oo_adt_classrun .
    METHODS: reach_to_mars.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SANTOSH_MISSION_MARS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    me->reach_to_mars(  ).
    out->write(
      EXPORTING
        data   = itab ).
  ENDMETHOD.


  METHOD reach_to_mars.
    DATA:lv_text TYPE string.
    DATA(lo_earth) = NEW zcl_earth(  ).
    DATA(lo_iplanet1) = NEW zcl_planet1(  ).
    DATA(lo_mars) = NEW zcl_mars(  ).

    APPEND lo_earth->start_engine(  ) TO itab.
    APPEND lo_earth->leave_orbit(  ) TO itab.
    APPEND lo_iplanet1->enter_orbit(  ) TO itab.
    APPEND lo_iplanet1->leave_orbit(  ) TO itab.
    APPEND lo_mars->enter_orbit(  ) TO itab.
    APPEND lo_mars->explore_mars(  ) TO itab.
  ENDMETHOD.
ENDCLASS.
