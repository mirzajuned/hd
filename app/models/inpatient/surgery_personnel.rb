class Inpatient::SurgeryPersonnel
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :organisation_id, type: String
  field :facility_id, type: String
  # field :procedureside, type: String

  def self.compute_mongoid_for_tags(idstring, namestring, specialty_id, organisation_id, user_id, patient_summary_asset_id)
    if idstring.length > 0
      idarray = idstring.split(",")
      namearray = namestring.split(",")
      idarray.each_with_index() do |id, index|
        if id.include?("#!##")
          PatientAssetUploadTag.create(:tag_name => namearray[index], :tag_name_lcase => namearray[index].downcase, :doctor => user_id, user_id: user_id, specialty_id: specialty_id, organisation_id: organisation_id, :is_custom => "Y", :patient_summary_asset_upload_id => patient_summary_asset_id)
        end
      end
    end
  end
end
