# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_referral_type_count
json.iTotalDisplayRecords @total_referral_type_count
json.set! "aaData" do
  json.array!(@referral_types) do |referral_type|
    referral = @referral_fields.find { |f| f[:id].to_s == referral_type[:_id].to_s }
    referral_name = referral[:name]

    # Table Data
    if referral.present?
      json.set! "0", referral_name
      json.set! "1", referral_type[:referral_type_count]
    end
  end
end
