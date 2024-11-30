CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS augment_update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD augment_create.

    DATA: travel_create TYPE TABLE FOR CREATE zats_skl_travel. "Doubt -> ZATS_SKL_TRAVEL is referring to BDEF. I was expecting BO.

    travel_create = CORRESPONDING #( entities ).

    LOOP AT travel_create ASSIGNING FIELD-SYMBOL(<travel>).

*I commented this code, because this is defaulting agency id value and causing mismatch between agency id and customer id and precheck validation
*is failing and throwing error when we click on create.

*      <travel>-AgencyId = '70003'.
      <travel>-OverallStatus = 'O'.
*      <travel>-%control-AgencyId = if_abap_behv=>mk-on.
      <travel>-%control-OverallStatus = if_abap_behv=>mk-on.

    ENDLOOP.

    MODIFY AUGMENTING ENTITIES OF zats_skl_travel
    ENTITY travel
    CREATE FROM travel_create.

  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD augment_update.
  ENDMETHOD.

ENDCLASS.
