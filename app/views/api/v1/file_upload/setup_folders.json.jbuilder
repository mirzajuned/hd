json.setup_folders @setup_folders
if @setup_folders
  json.set! "folders" do
    json.array!(@patientsummaryuploads) do |folder|
      json.id folder.id
      json.name folder.name
      json.is_folder folder.is_folder
      json.is_custom folder.is_custom
      json.is_system_defined folder.is_system_defined
      json.is_root folder.is_root?
    end
  end
end
