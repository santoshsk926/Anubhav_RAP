@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment interface cds entity which'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zats_skl_m_attach as select from zats_skl_attach
association to parent ZATS_SKL_TRAVEL as _Travel on
    $projection.TravelId = _Travel.TravelId
{
    key travel_id as TravelId,
    @EndUserText.label: 'Attachment ID'
    key id as Id,
    @EndUserText.label: 'Comments'
    memo as Memo,
    @Semantics.largeObject: {
        mimeType: 'Filetype',
        fileName: 'Filename',
        contentDispositionPreference: #INLINE
        //acceptableMimeTypes: [ 'APPLICATION/PDF' ]
    }
    @EndUserText.label: 'Attachment'
    attachment as Attachment,
    @EndUserText.label: 'File Name'
    filename as Filename,
    @EndUserText.label: 'File Type'
    @Semantics.mimeType: true
    filetype as Filetype,
    @Semantics.user.createdBy: true
    local_created_by as LocalCreatedBy,
    @Semantics.systemDateTime.createdAt: true
    local_created_at as LocalCreatedAt,
    @Semantics.user.lastChangedBy: true
    local_last_changed_by as LocalLastChangedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at as LocalLastChangedAt,
     @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at as LastChangedAt,
    _Travel
}
