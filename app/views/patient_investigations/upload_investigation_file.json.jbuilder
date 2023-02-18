@report_array = []
@report_array.push(@report_link)
json.files(@report_array) do |report|
  json.name report.name
  json.size report.asset_path.size
  json.url report.asset_path.url
  json.thumbnailUrl report.asset_path.thumb.url

  json.deleteUrl patient_investigations_delete_report_path(:id => report.id, :asset_path => report.asset_path)
  json.deleteType 'GET'
end
