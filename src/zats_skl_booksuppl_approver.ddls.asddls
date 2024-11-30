@EndUserText.label: 'My travel processor Projection Layer'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_SKL_BOOKSUPPL_APPROVER
  as projection on ZATS_SKL_BOOKSUPPL
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking: redirected to parent ZATS_SKL_BOOKING_PROCESSOR,
      _Travel: redirected to ZATS_SKL_TRAVEL_PROCESSOR,  
      _Product,
      _SupplementText
}
