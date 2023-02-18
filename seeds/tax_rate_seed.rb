# bundle exec rake db:dump:tax_rate_seed RAILS_ENV=development
TaxRate.where(organisation_id: $HG_ORGANISATION_ID).delete_all

TaxRate.create!(
  [
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290758'), name: 'UTGST14', rate: 14.0, type: 'UTGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290757'), name: 'UTGST9', rate: 9.0, type: 'UTGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290756'), name: 'UTGST6', rate: 6.0, type: 'UTGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290755'), name: 'UTGST2.5', rate: 2.5, type: 'UTGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290754'), name: 'UTGST0', rate: 0.0, type: 'UTGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },

    { _id: BSON::ObjectId('59afa0b4f9c44c035629075d'), name: 'IGST28', rate: 28.0, type: 'IGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629075c'), name: 'IGST18', rate: 18.0, type: 'IGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629075b'), name: 'IGST12', rate: 12.0, type: 'IGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629075a'), name: 'IGST5', rate: 5.0, type: 'IGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290759'), name: 'IGST0', rate: 0.0, type: 'IGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },

    { _id: BSON::ObjectId('59afa0b4f9c44c0356290753'), name: 'CGST14', rate: 14.0, type: 'CGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290752'), name: 'CGST9', rate: 9.0, type: 'CGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290751'), name: 'CGST6', rate: 6.0, type: 'CGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c0356290750'), name: 'CGST2.5', rate: 2.5, type: 'CGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629074f'), name: 'CGST0', rate: 0.0, type: 'CGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },

    { _id: BSON::ObjectId('59afa0b4f9c44c035629074e'), name: 'SGST14', rate: 14.0, type: 'SGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629074d'), name: 'SGST9', rate: 9.0, type: 'SGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629074c'), name: 'SGST6', rate: 6.0, type: 'SGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629074b'), name: 'SGST2.5', rate: 2.5, type: 'SGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('59afa0b4f9c44c035629074a'), name: 'SGST0', rate: 0.0, type: 'SGST', is_hg_defined: true, is_deleted: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },

    { _id: BSON::ObjectId('5cebcef1f9c44c423592d621'), name: 'VAT0', rate: 0.0, type: 'VAT', is_hg_defined: true, is_deleted: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('5cebcef2f9c44c423592d622'), name: 'VAT5', rate: 5.0, type: 'VAT', is_hg_defined: true, is_deleted: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID },
    { _id: BSON::ObjectId('5cebcef3f9c44c423592d623'), name: 'VAT10', rate: 10.0, type: 'VAT', is_hg_defined: true, is_deleted: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID }
  ]
)
