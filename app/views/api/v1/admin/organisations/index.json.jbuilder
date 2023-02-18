json.set! 'organisations' do
  json.array!(@organisations) do |organisation|
    contract = @contracts.find { |contract| contract['organisation_id'] == organisation.id }
    specialties = @specialties.select { |specialty| organisation.specialty_ids.include?(specialty.id.to_s) }
    account_expiry_date = organisation.account_expiry_date

    if params[:download]
      json.organisation_id organisation.id
      json.organisation_name organisation.name
    else
      json.id organisation.id
      json.name organisation.name
    end
    json.tagline organisation.tagline
    json.address1 organisation.address1
    json.address2 organisation.address2
    json.city organisation.city
    json.state organisation.state
    json.pincode organisation.pincode
    json.commune organisation.commune
    json.district organisation.district
    json.country_name organisation.country&.name
    json.specialty_names specialties.map(&:name).to_a.join(', ')
    json.registered_date organisation.created_at&.to_date
    json.active_contract contract&.contract_code
    json.account_expiry_date account_expiry_date
    json.active account_expiry_date && account_expiry_date >= Time.current
  end
end
