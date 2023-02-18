if @opdrecord.present?
  json.id @opdrecord.id.to_s
  json.visit @opdrecord.history["visit"]
  json.history @opdrecord.history.values - [""]
  json.ophthal_investigations @opdrecord.ophthal_investigations_list
  json.radiology_investigations @opdrecord.radiology_investigations_list
  json.laboratory_investigations @opdrecord.laboratory_investigations_list
  json.examination @opdrecord.examination.values
  json.r_refraction @opdrecord.examination["r_refraction"]
  json.l_refraction @opdrecord.examination["l_refraction"]
  json.r_iop @opdrecord.examination["r_iop"]
  json.l_iop @opdrecord.examination["l_iop"]
  json.r_appendage @opdrecord.examination["r_appendage"]
  json.l_appendage @opdrecord.examination["l_appendage"]
  json.r_anterior_segment @opdrecord.examination["r_anterior_segment"].values - [""]
  json.l_anterior_segment @opdrecord.examination["l_anterior_segment"].values - [""]
  json.r_posterior_segment @opdrecord.examination["r_posterior_segment"]
  json.l_posterior_segment @opdrecord.examination["l_posterior_segment"]
  json.r_eom @opdrecord.examination["r_eom"]
  json.l_eom @opdrecord.examination["l_eom"]
  json.department @department
  json.freeform @opdrecord.freeform
  json.encounterdate @opdrecord.created_at.strftime("%d/%m/%Y")
end
