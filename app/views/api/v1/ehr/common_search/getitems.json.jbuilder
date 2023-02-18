json.array! (@items) do |item|
  case item.category
  when 'medication'
    json.dosage item.dosage
    if item.dosage
      json.label '' + item.description + " " + item.dosage + ''
      json.value '' + item.description + " " + item.dosage + ''
    else
      json.label item.description
      json.value item.description
    end
    json.description item.description
    json.item_id item.id
    json.type item.type
    json.stock item.try(:stock)
    json.med_type item.respond_to?(:med_type) ? item.med_type : item.dispensing_unit
  else
    json.description item.description
    json.item_id item.id
    json.med_type item.respond_to?(:med_type) ? item.med_type : item.dispensing_unit
    # json.med_type item.med_type
  end
end
