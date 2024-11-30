*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS zcl_earth DEFINITION.
  PUBLIC SECTION.
    METHODS start_engine returning VALUE(r_value) TYPE string.
    METHODS leave_orbit returning VALUE(r_value) TYPE string.
ENDCLASS.

CLASS zcl_earth IMPLEMENTATION.
  METHOD start_engine.
    r_value = 'We take off from planet earth for mission mars'.
  ENDMETHOD.

  METHOD leave_orbit.
    r_value = 'We leave earth Orbit'.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_planet1 DEFINITION.
  PUBLIC SECTION.
    METHODS enter_orbit returning VALUE(r_value) TYPE string.
    METHODS leave_orbit returning VALUE(r_value) TYPE string.
ENDCLASS.

CLASS zcl_planet1 IMPLEMENTATION.
  METHOD enter_orbit.
    r_value = 'We enter planet 1 orbit'.
  ENDMETHOD.

  METHOD leave_orbit.
    r_value = 'We leave planet 1 Orbit'.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_mars DEFINITION.
  PUBLIC SECTION.
    METHODS enter_orbit returning VALUE(r_value) TYPE string.
    METHODS explore_mars returning VALUE(r_value) TYPE string.
ENDCLASS.

CLASS zcl_mars IMPLEMENTATION.
  METHOD enter_orbit.
    r_value = 'We entered in Mars orbit'.
  ENDMETHOD.

  METHOD explore_mars.
    r_value = 'Roger! we found water'.
  ENDMETHOD.
ENDCLASS.
