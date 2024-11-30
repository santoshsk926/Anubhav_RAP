@EndUserText.label: 'My travel processor Projection Layer'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_SKL_BOOKING_APPROVER
  as projection on ZATS_SKL_BOOKING
{
  key TravelId,
  key BookingId,
      BookingDate,
//Approver will not need F4 helps.      
//      @Consumption.valueHelpDefinition: [{
//          entity.name: '/DMO/I_Customer',
//          entity.element: 'CustomerID'  --> Doubt, we have added the field, but search help is showing all fields in the popup
//       }]
      CustomerId,
//      @Consumption.valueHelpDefinition: [{
//      entity.name: '/DMO/I_Carrier',
//      entity.element: 'AirlineID'
//       }]
      CarrierId,
//      @Consumption.valueHelpDefinition: [{
//      entity.name: '/DMO/I_Connection',
//      entity.element: 'ConnectionID',
//      additionalBinding: [{     --> Here whatever CarrierID we are choosing, based on that filtering is happeining on Connection ID 
//       localElement: 'CarrierId',  -->Doubt
//       element: 'AirlineID'        -->Doubt
//       }] }]
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
//      @Consumption.valueHelpDefinition: [{
//      entity.name: '/DMO/I_Booking_Status_VH',
//      entity.element: 'BookingStatus'
//       }]
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
//Approver will never be able to read supplement data      
//      _BookingSupplement : redirected to composition child ZATS_SKL_BOOKSUPPL_PROCESSOR, 
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent ZATS_SKL_TRAVEL_APPROVER
}
