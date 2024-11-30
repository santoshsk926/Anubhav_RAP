@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Unmanaged'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zats_skl_u_customer
  as select from /dmo/customer
  association [1] to I_Country as _Country on $projection.CountryCode = _Country.Country
{
  key customer_id                                              as CustomerId,
      first_name                                               as FirstName,
      last_name                                                as LastName,
      title                                                    as Title,
      concat(title,concat_with_space(first_name, last_name,2)) as CustomerName,
      street                                                   as Street,
      postal_code                                              as PostalCode,
      city                                                     as City,
      country_code                                             as CountryCode,
      phone_number                                             as PhoneNumber,
      email_address                                            as EmailAddress,
      _Country
}
