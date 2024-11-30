@EndUserText.label: 'Attachment Processor'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_SKL_M_ATTACH_PROCESSOR as projection on zats_skl_m_attach
{
    key TravelId,
    key Id,
    Memo,
    Attachment,
    Filename,
    Filetype,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Travel : redirected to parent ZATS_SKL_TRAVEL_PROCESSOR
}
