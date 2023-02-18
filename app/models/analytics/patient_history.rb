class Analytics::PatientHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :dob_year, type: Integer
  field :gender, type: String
  # systemic history fields
  field :diabetes, type: Integer, default: 0
  field :hypertension, type: Integer, default: 0
  field :alcoholism, type: Integer, default: 0
  field :smoking_tobacco, type: Integer, default: 0
  field :cardiac_disorder, type: Integer, default: 0
  field :steroid_intake, type: Integer, default: 0
  field :drug_abuse, type: Integer, default: 0
  field :hiv_aids, type: Integer, default: 0
  field :cancer_tumor, type: Integer, default: 0
  field :tuberculosis, type: Integer, default: 0
  field :asthma, type: Integer, default: 0
  field :cns_disorder_stroke, type: Integer, default: 0
  field :hypothyroidism, type: Integer, default: 0
  field :hyperthyroidism, type: Integer, default: 0
  field :hepatitis_cirrhosis, type: Integer, default: 0
  field :renal_disorder, type: Integer, default: 0
  field :acidity, type: Integer, default: 0
  field :on_insulin, type: Integer, default: 0
  field :on_aspirin_blood_thinners, type: Integer, default: 0
  field :consanguinity, type: Integer, default: 0
  field :thyroid_disorder, type: Integer, default: 0
  field :chewing_tobacco, type: Integer, default: 0
  field :rheumatoid_arthritis, type: Integer, default: 0

  # eyedrop alergy fields
  field :tropicamide_p, type: Integer, default: 0
  field :tropicamide, type: Integer, default: 0
  field :timolol, type: Integer, default: 0
  field :homide, type: Integer, default: 0
  field :latanoprost, type: Integer, default: 0
  field :brimonidine, type: Integer, default: 0
  field :travoprost, type: Integer, default: 0
  field :tobramycin, type: Integer, default: 0
  field :moxifloxacin, type: Integer, default: 0
  field :homatropine, type: Integer, default: 0
  field :pilocarpine, type: Integer, default: 0
  field :cyclopentolate, type: Integer, default: 0
  field :atropine, type: Integer, default: 0
  field :phenylephrine, type: Integer, default: 0
  field :tropicacyl, type: Integer, default: 0
  field :paracain, type: Integer, default: 0
  field :ciplox, type: Integer, default: 0
  field :tropicamide_p_distilled_water, type: Integer, default: 0
  field :tropicamide_p_lubrex, type: Integer, default: 0

  field :organisation_id, type: BSON::ObjectId
end
