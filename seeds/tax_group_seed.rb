# bundle exec rake db:dump:tax_group_seed RAILS_ENV=development
TaxGroup.where(organisation_id: $HG_ORGANISATION_ID).delete_all
TaxGroup.create!(
  [
    { name: 'GST28', rate: 28.0, intrastate_tax_rate_details: [{ _id: '59afa0b4f9c44c035629074e', name: 'SGST14', rate: 14.0 }, { _id: '59afa0b4f9c44c0356290753', name: 'CGST14', rate: 14.0 }], tax_rate_ids: ['59afa0b4f9c44c035629074e', '59afa0b4f9c44c0356290753'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { name: 'GST18', rate: 18.0, intrastate_tax_rate_details: [{ _id: '59afa0b4f9c44c035629074d', name: 'SGST9', rate: 9.0 }, { _id: '59afa0b4f9c44c0356290752', name: 'CGST9', rate: 9.0 }], tax_rate_ids: ['59afa0b4f9c44c035629074d', '59afa0b4f9c44c0356290752'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { name: 'GST12', rate: 12.0, intrastate_tax_rate_details: [{ _id: '59afa0b4f9c44c035629074c', name: 'SGST6', rate: 6.0 }, { _id: '59afa0b4f9c44c0356290751', name: 'CGST6', rate: 6.0 }], tax_rate_ids: ['59afa0b4f9c44c035629074c', '59afa0b4f9c44c0356290751'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { name: 'GST5', rate: 5.0, intrastate_tax_rate_details: [{ _id: '59afa0b4f9c44c035629074b', name: 'SGST2.5', rate: 2.5 }, { _id: '59afa0b4f9c44c0356290750', name: 'CGST2.5', rate: 2.5 }], tax_rate_ids: ['59afa0b4f9c44c035629074b', '59afa0b4f9c44c0356290750'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { name: 'GST0', rate: 0.0, intrastate_tax_rate_details: [{ _id: '59afa0b4f9c44c035629074a', name: 'SGST0', rate: 0.0 }, { _id: '59afa0b4f9c44c035629074f', name: 'CGST0', rate: 0.0 }], tax_rate_ids: ['59afa0b4f9c44c035629074a', '59afa0b4f9c44c035629074f'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'IN_108', organisation_id: $HG_ORGANISATION_ID },
    { name: 'VAT0', rate: 0.0, intrastate_tax_rate_details: [{ _id: '5cebcef1f9c44c423592d621', name: 'VAT0', rate: 0.0 }], tax_rate_ids: ['5cebcef1f9c44c423592d621'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID },
    { name: 'VAT5', rate: 5.0, intrastate_tax_rate_details: [{ _id: '5cebcef2f9c44c423592d622', name: 'VAT5', rate: 5.0 }], tax_rate_ids: ['5cebcef2f9c44c423592d622'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID },
    { name: 'VAT10', rate: 10.0, intrastate_tax_rate_details: [{ _id: '5cebcef3f9c44c423592d623', name: 'VAT10', rate: 10.0 }], tax_rate_ids: ['5cebcef3f9c44c423592d623'], is_hg_defined: true, is_deleted: false, is_migrated: false, country_id: 'VN_254', organisation_id: $HG_ORGANISATION_ID }
  ]
)
# create intra/inter/ut data
TaxGroup.where(is_migrated: false, is_deleted: false).each do |tax_group|
  rate = tax_group.try(:rate)
  organisation_id = tax_group.try(:organisation_id)
  country_id = tax_group.try(:country_id)
  intrastate_ary, interstate_ary, ut_ary = Inventory::TaxGroupHelper.calculate_group_values(rate, organisation_id, country_id)
  tax_group.intrastate_tax_rate_details = intrastate_ary
  tax_group.interstate_tax_rate_details = interstate_ary
  tax_group.ut_tax_rate_details = ut_ary
  tax_rate_ids = []
  tax_rate_ids << intrastate_ary.map{|intrastate| intrastate['id']}
  tax_rate_ids << interstate_ary.map{|interstate| interstate['id']}
  tax_rate_ids << ut_ary.map{|ut| ut['id']}
  tax_group.tax_rate_ids = tax_rate_ids.flatten.uniq
  tax_group.is_migrated = true
  tax_group.save!
end