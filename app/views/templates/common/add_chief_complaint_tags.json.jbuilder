json.array!(@new_tags_objectids) do |opd_template_newtag|
  json.oldid "#{opd_template_newtag.split("###")[0]}"
  json.newid "#{opd_template_newtag.split("###")[1]}"
end
