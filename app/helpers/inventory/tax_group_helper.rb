module Inventory::TaxGroupHelper
  def self.calculate_group_values(rate, organisation_id, country_id)
    if country_id == 'IN_108'
      half_rate = (rate/2)
      tax_rate_records = TaxRate.where(country_id: country_id, organisation_id: organisation_id)

      sgst_tax_rate_record = tax_rate_records.find_by(type: 'SGST', rate: half_rate)
      cgst_tax_rate_record = tax_rate_records.find_by(type: 'CGST', rate: half_rate)
      utgst_tax_rate_record = tax_rate_records.find_by(type: 'UTGST', rate: half_rate)
      igst_tax_rate_record = tax_rate_records.find_by(type: 'IGST', rate: rate)

      intrastate_ary = [{'id' => cgst_tax_rate_record.try(:id).to_s, 'name' => cgst_tax_rate_record.try(:name), 'rate' => cgst_tax_rate_record.try(:rate)}, {'id' => sgst_tax_rate_record.try(:id).to_s, 'name' => sgst_tax_rate_record.try(:name), 'rate' => sgst_tax_rate_record.try(:rate)}]
      interstate_ary = [{'id' => igst_tax_rate_record.try(:id).to_s, 'name' => igst_tax_rate_record.try(:name), 'rate' => igst_tax_rate_record.try(:rate)}]
      ut_ary = [{'id' => cgst_tax_rate_record.try(:id).to_s, 'name' => cgst_tax_rate_record.try(:name), 'rate' => cgst_tax_rate_record.try(:rate)}, {'id' => utgst_tax_rate_record.try(:id).to_s, 'name' => utgst_tax_rate_record.try(:name), 'rate' => utgst_tax_rate_record.try(:rate)}]
    else
      tax_rate_record = TaxRate.find_by(country_id: country_id, organisation_id: organisation_id, rate: rate)
      intrastate_ary = [{'id' => tax_rate_record.try(:id).to_s, 'name' => tax_rate_record.try(:name), 'rate' => tax_rate_record.try(:rate)}]
      interstate_ary = [{'id' => tax_rate_record.try(:id).to_s, 'name' => tax_rate_record.try(:name), 'rate' => tax_rate_record.try(:rate)}]
      ut_ary = [{'id' => tax_rate_record.try(:id).to_s, 'name' => tax_rate_record.try(:name), 'rate' => tax_rate_record.try(:rate)}]
    end
    [intrastate_ary, interstate_ary, ut_ary]
  end
  # EOF calculate_group_values
end
