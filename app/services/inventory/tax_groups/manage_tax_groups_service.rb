class Inventory::TaxGroups::ManageTaxGroupsService
  def self.call(tax_group_id)
    tax_group = TaxGroup.find_by(id: tax_group_id)
    rate = tax_group.try(:rate)
    organisation_id = tax_group.try(:organisation_id)
    country_id = tax_group.try(:country_id)
    intrastate_ary, interstate_ary, ut_ary = Inventory::TaxGroupHelper.calculate_group_values(rate, organisation_id, country_id) if rate.present? && organisation_id.present? && country_id.present?
    tax_group.interstate_tax_rate_details = interstate_ary
    tax_group.ut_tax_rate_details = ut_ary
    tax_rate_ids = tax_group.tax_rate_ids
    tax_rate_ids << interstate_ary.map{|interstate| interstate['id']}
    tax_rate_ids << ut_ary.map{|ut| ut['id']}
    tax_group.tax_rate_ids = tax_rate_ids.flatten.uniq
    tax_group.save!
  end
end
