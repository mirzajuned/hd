json.set! @icddiagnosiscode.to_s do
  if @icddiagnosis.size > 0
    json.set! "#{@icddiagnosis.first.attribute_code_position}###{@icddiagnosis.first.is_displayed}###{@icddiagnosis.first.is_preselected}###{@icddiagnosis.first.is_laterality}" do
      json.array!(@icddiagnosis) do |diagnosis_attr|
        json.set! "#{diagnosis_attr.attribute_display_label}", "#{diagnosis_attr.attribute_display_label}###{diagnosis_attr.attribute_code}"
      end
    end
  end
end
