json.array!(@results_opd_templatetags) do |opd_templatetag|
  json.id "#{opd_templatetag.id}"
  json.text "#{opd_templatetag.tag_name}"
end
