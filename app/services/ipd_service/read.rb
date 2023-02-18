class IpdService::Read

  def self.get_admission_attributes(admission_id, query_array)
    attributes = Admission.find_by(id: admission_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

  def self.get_ipd_record_attributes(admission_id, query_array)
    attributes = Inpatient::IpdRecord.find_by(admission_id: admission_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

end
