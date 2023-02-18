@expense_array = []
@expense_array.push(JSON.parse(@expense_upload.to_json))
Rails.logger.info("==================================#{@expense_array}")

puts "=======================================dddddddddddddddddddd=============="

json.files(@expense_array) do |report|
  json.name report["name"]
  json.size report["asset_path"].size
  json.url report["asset_path"]["url"]
  json.thumbnailUrl report["asset_path"]["thumb"]["url"]
  json.deleteUrl finance_expenses_delete_upload_path(:id => report["_id"], :expense_id => @expense.id, :asset_path => report["asset_path"])
  json.deleteType 'GET'
end

# json.status "success"
