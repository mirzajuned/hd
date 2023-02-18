class PatientAssessment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # Primary Assessment
  field :airway_assesment, type: String
  field :airway_assesment_abnormal, type: String
  field :breathing_assesment, type: String
  field :breathing_assesment_abnormal, type: String
  field :pulse_assesment, type: String
  field :pulse_assesment_abnormal, type: String
  field :bp_assesment, type: String
  field :bp_assesment_abnormal, type: String
  field :pressure_ulcer_risk, type: String
  field :risk_of_fall, type: String
  field :vte_risk, type: String
  field :general_appearance, type: String
  field :general_appearance_abnormal, type: String
  field :preferred_language, type: String
  field :interpreter_needed, type: String
  field :vital_comment, type: String
  field :general_icterus, type: String
  field :general_clubbing, type: String
  field :general_rash, type: String
  field :general_lymphadenopathy, type: String
  field :secondary_comment, type: String
  field :primary_comment, type: String
  # end

  # ganeral Polar
  field :general_pallor, type: String
  field :general_cyanosis, type: String
  field :general_edema, type: String
  field :general_white_oral_patch, type: String
  field :resp_air_entry, type: String
  field :resp_breath_sounds, type: String
  field :resp_breath_sounds_abnormal, type: String
  field :resp_nail_bed_color, type: String
  field :resp_nail_bed_color_abnormal, type: String
  field :sleep_pattern, type: String
  field :sleep_pattern_abnormal, type: String
  field :preferred_language, type: String

  # end

  # CNS
  field :cns_temperature, type: String
  field :cns_temperature_abnormal, type: String
  field :cns_orientation, type: String
  field :cns_orientation_abnormal, type: String
  field :cns_emotinal_status, type: String
  field :cns_emotinal_status_abnormal, type: String
  field :cns_memory_intact, type: String
  field :cns_memory_intact_abnormal, type: String
  field :cns_speech_status, type: String
  field :cvs_heart_sounds_status, type: String
  field :cvs_heart_sounds_status_abnormal, type: String
  field :cvs_palpable_pulses_intact, type: String
  field :cvs_palpable_pulses_intact_abnormal, type: String
  field :cvs_peripheral_edema, type: String
  field :cvs_calf_tenderness, type: String
  field :cns_speech_status_abnormal, type: String
  field :sensory_and_perception, type: String
  field :sensory_and_perception_abnormal, type: String
  field :respiratory, type: String
  field :respiratory_abnormal, type: String
  # end

  # gut
  field :gut_urine_output, type: String
  field :gut_urine_output_abnormal, type: String
  field :gut_bladder_habits, type: String
  field :gut_bladder_habits_abnormal
  # end

  # git
  field :git_abdomen, type: String
  field :git_bowel_movements, type: String
  field :git_bowel_movements_abnormal, type: String
  # end

  # MS
  field :ms_extreme_motion, type: String
  field :ms_extreme_motion_abnormal, type: String
  field :ms_sensation, type: String
  field :ms_sensation_abnormal, type: String
  # END

  # skin
  field :skin_color, type: String
  field :skin_color_abnormal, type: String
  field :skin_integrity, type: String
  field :skin_integrity_abnormal, type: String
  # end

  # communication

  # end
  field :speech_and_swllowing, type: String

  field :nurse_name, type: String
  field :patient_id, type: String
  field :admission_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :template_type, type: String, default: "assessment"
  field :template_id, type: String, default: "315639002"

  # vital_sign
  field :blood_pressure, type: String
  field :height, type: Float
  field :weight, type: Float
  field :pulse, type: Integer
  field :temperature, type: Float
  field :vital_comment, type: String
  field :respiratory_rate, type: Integer
  field :bmi, type: Float
  field :spo2, type: Integer

  field :specialty_id, type: String

  # record histories
  embeds_many :record_histories
  accepts_nested_attributes_for :record_histories, class_name: "::RecordHistory"

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
