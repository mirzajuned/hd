json.advised_by @opd_record.consultant_name
json.advised_on @opd_record.created_at.strftime('%d/%m/%Y')
# json.medicine_advised @opd_record.treatmentmedication.each do |record|
#   json.id record.id
#   json.name  record.medicinename
#   json.qty  record.medicinequantity
# end
json.medicine_advised @data