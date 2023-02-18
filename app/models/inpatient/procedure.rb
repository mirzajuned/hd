class Inpatient::Procedure
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # field :procedurestage, type: String
  # field :procedureregion, type: String
  # field :procedureside, type: String
  # field :procedurestatus, type: String
  # field :procedureapproach, type: String
  # field :proceduretype, type: String
  # field :procedurename, type: String
  # field :procedurequalifier, type: String
  # field :proceduresubqualifier, type: String
  # field :patient_id, type: String
  # field :facility_id, type: String
  field :surgerydate, type: String
  field :iol, type: String

  def get_label_for_procedure_side(eyesideoption)
    eyesideoptionlabel = ""
    Global.ophthalmologyprocedures.eyeside.each do |eyeside_option|
      if eyeside_option['side_id'].to_i == eyesideoption.to_i
        eyesideoptionlabel = eyeside_option['side_abbr']
      end
    end
    eyesideoptionlabel
  end
end
