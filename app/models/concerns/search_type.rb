module SearchType
  def last_search_by(user_id, facility_id, store_id)
    (where(user_id: user_id, facility_id: facility_id, store_id: store_id).last.search_type || "Barcode") rescue "Barcode"
  end
end