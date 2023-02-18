json.folder_has_assets @folder_has_assets
json.folder_id @patientsummaryuploads.id
if @folder_has_assets
  json.set! "assets" do
    json.array!(@folder_assets) do |asset|
      json.filethumb asset.asset_path_url(:api_thumb)
      json.fileactual asset.asset_path_url
    end
  end
end
