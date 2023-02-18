json.my_data @lab.each do |value|
  json.investigationname   value['investigationname']
  json.loinc_class value['loinc_class']
  json.loinc_code value['loinc_code']
  json.investigation_id value['investigation_id']
  json.investigationadviseddate value['investigationadviseddate']
  json.investigationfullcode value['investigationfullcode']
end
