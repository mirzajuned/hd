json.set! 'organisation' do
  json.id @organisation.id
  json.name @organisation.name
end

json.set! 'organisation_contracts' do
  json.array!(@organisation_contracts) do |contract|
    json.id contract.id
    json.organisation_id contract.organisation_id

    json.customer_setup contract.customer_setup
    json.customer_type contract.customer_type
    json.subscription_type contract.subscription_type
    json.pricing_type contract.pricing_type

    json.start_date contract.start_date
    json.end_date contract.end_date

    json.paid_quota contract.paid_quota
    json.free_quota contract.free_quota
    json.variable_quota contract.variable_quota
    json.max_active_user contract.max_active_user

    json.base_rate_per_user contract.base_rate_per_user
    json.discount_per_user contract.discount_per_user
    json.total_rate_per_user contract.total_rate_per_user
    json.total_rate_per_user_per_day contract.total_rate_per_user_per_day

    json.created_by contract.created_by
    json.display_id contract.display_id
    json.active contract.active
    json.deleted contract.deleted
  end
end
