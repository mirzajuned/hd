class OpdRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  include Authority::Abilities # Authority changes

  self.authorizer_name = 'OpdRecordAuthorizer'

  field :opdrecordnumber, type: String

  field :view_diagnosis_flag, type: String, default: 1
  field :view_advice_flag, type: String, default: 1
  field :view_examination_flag, type: String, default: 1
  field :view_refraction_flag, type: String, default: 1
  field :view_investigations_flag, type: String, default: 1
  field :view_glassesprescriptions_flag, type: String, default: 1
  field :view_intermediate_glasses_prescriptions_flag, type: String, default: 1
  field :view_contactlens_flag, type: String, default: 1
  field :view_history_flag, type: String, default: 1
  field :view_squint_flag, type: String, default: 1
  field :view_procedures_flag, type: String, default: 1

  field :print_diagnosis_flag, type: String, default: 1
  field :print_advice_flag, type: String, default: 1
  field :print_examination_flag, type: String, default: 1
  field :print_investigations_flag, type: String, default: 1
  field :print_procedures_flag, type: String, default: 1
  field :print_glassesprescriptions_flag, type: String, default: 1
  field :print_intermediate_glasses_prescriptions_flag, type: String, default: 1
  field :print_contactlens_flag, type: String, default: 1
  field :print_refraction_flag, type: String, default: 1
  field :print_history_flag, type: String, default: 1
  field :print_squint_flag, type: String, default: 1
  field :complaints, type: String
  field :oph_histories, type: String
  field :antimicrobial_agents, type: String
  field :drug_allergies, type: String
  field :drug_allergies_comment, type: String
  field :antifungal_agents, type: String
  field :antiviral_agents, type: String
  field :nsaids, type: String
  field :eye_drops, type: String
  field :contact_allergies, type: String
  field :contact_allergies_comment, type: String
  field :food_allergies, type: String
  field :food_allergies_comment, type: String
  field :compelete_migration, type: Boolean
  field :print_diagram_flag, type: String, default: 0
  field :allergies, type: String

  field :glassesprescriptions_show_add, type: Boolean, default: false
  field :intermediate_glasses_prescriptions_show_add, type: Boolean, default: false
  field :facility_id, type: BSON::ObjectId

  field :perform_pmt, type: Boolean, default: false
  field :duochrome, type: Boolean, default: false
  field :jcc, type: Boolean, default: false
  field :add_pgp_near, type: Boolean, default: false
  field :add_pgp_near2, type: Boolean, default: false
  field :add_pgp_near3, type: Boolean, default: false

  #check advised
  field :no_chief_complaints_advised, type: Boolean, default: false
  field :no_opthalmic_history_advised, type: Boolean, default: false
  field :no_systemic_history_advised, type: Boolean, default: false
  field :no_allergy_advised, type: Boolean, default: false
  field :no_right_va_advised, type: Boolean, default: false
  field :no_left_va_advised, type: Boolean, default: false
  field :no_right_iop_advised, type: Boolean, default: false
  field :no_left_iop_advised, type: Boolean, default: false
  field :no_investigation_advised, type: Boolean, default: false
  field :no_diagnosis_advised, type: Boolean, default: false
  field :no_medications_advised, type: Boolean, default: false
  field :no_procedure_advised, type: Boolean, default: false

  # Dilation
  field :dilation_needed, type: Boolean, default: false
  field :dilate_patient, type: Boolean, default: false

  # Syringing
  field :r_lower_punctum_result, type: String
  field :l_lower_punctum_result, type: String
  field :r_upper_punctum_result, type: String
  field :l_upper_punctum_result, type: String

  field :management_personal_cmt, type: String

  # Random Blood Sugar
  field :random_blood_sugar_result, type: String
  field :random_blood_sugar_comment, type: String

  # validation status
  field :history_is_valid, type: Boolean, default: false
  field :vision_is_valid, type: Boolean, default: false
  field :iop_is_valid, type: Boolean, default: false
  field :diagnosis_is_valid, type: Boolean, default: false
  field :medications_is_valid, type: Boolean, default: false
  field :glasses_is_valid, type: Boolean, default: false
  field :procedure_is_valid, type: Boolean, default: false
  field :investigation_is_valid, type: Boolean, default: false
  field :followup_is_valid, type: Boolean, default: false

  embeds_many :record_histories
  embeds_many :record_comments
  embeds_many :postoprecord, class_name: "::PostOpRecord" # postop"
  embeds_many :treatmentmedication, class_name: "::MedicationRecord" # medications
  embeds_many :diagnosislist, class_name: "::Diagnosis" # diagnoses
  embeds_many :procedure, class_name: "::Procedure" # procedure
  embeds_many :ophthalinvestigationlist, class_name: "::OphthalmologyInvestigation" # OphthalmologyInvestigation
  embeds_many :investigationlist, class_name: "::RadiologyInvestigation" # rads
  embeds_many :addedlaboratoryinvestigationlist, class_name: "::LaboratoryInvestigation" # labs
  embeds_many :addedotherinvestigationlist, class_name: "::OtherInvestigation" # otherlabs
  embeds_one :advice, class_name: "::Advice" # advice

  embeds_many :inter_facility_referral, class_name: "::InterFacilityReferral" # outside facility
  embeds_many :intra_facility_referral, class_name: "::IntraFacilityReferral" # same facility
  embeds_many :outside_organisation_referral, class_name: "::OutsideOrganisationReferral" # outside organisation

  # history embeds start
  embeds_many :allergy_histories, class_name: "::AllergyHistory", cascade_callbacks: true
  embeds_many :personal_history_records, class_name: "::PersonalHistoryRecord", cascade_callbacks: true
  embeds_many :chief_complaints, class_name: "::ChiefComplaint", inverse_of: :project, cascade_callbacks: true # otherlabs
  embeds_many :speciality_history_records, class_name: "::SpecialityHistoryRecord", cascade_callbacks: true
  embeds_one :other_history, class_name: "::OtherHistory", inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :lens_history, class_name: "::LensHistory", inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :paediatrics_history, class_name: "::PaediatricsHistory", autobuild: true, cascade_callbacks: true
  # end

  embeds_many :generic_names, class_name: '::Inventory::Item::GenericName'

  # nested attributes
  accepts_nested_attributes_for :personal_history_records, allow_destroy: true
  accepts_nested_attributes_for :speciality_history_records, allow_destroy: true
  accepts_nested_attributes_for :chief_complaints, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :allergy_histories, allow_destroy: true
  accepts_nested_attributes_for :other_history, allow_destroy: true
  accepts_nested_attributes_for :lens_history, allow_destroy: true
  accepts_nested_attributes_for :paediatrics_history, allow_destroy: true
  # end

  accepts_nested_attributes_for :postoprecord, reject_if: proc { |attributes| attributes['surgery_name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :treatmentmedication, reject_if: proc { |attributes| attributes['medicinename'].blank? }, allow_destroy: true # medications
  accepts_nested_attributes_for :diagnosislist, reject_if: proc { |attributes| attributes['diagnosisname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :procedure, reject_if: proc { |attributes| attributes['procedurename'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :investigationlist, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :addedlaboratoryinvestigationlist, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :addedotherinvestigationlist, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :advice, reject_if: proc { |attributes| attributes['appointment_doctor'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :ophthalinvestigationlist, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true

  accepts_nested_attributes_for :inter_facility_referral, reject_if: proc { |attributes| attributes['referraldate'].blank? }, allow_destroy: true # inter_facility_referral
  accepts_nested_attributes_for :intra_facility_referral, reject_if: proc { |attributes| attributes['referraldate'].blank? }, allow_destroy: true # intra_facility_referral
  accepts_nested_attributes_for :outside_organisation_referral, reject_if: proc { |attributes| attributes['referraldate'].blank? && attributes['referred_doctor_name'].blank?}, allow_destroy: true # medications

  accepts_nested_attributes_for :generic_names, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true

  has_one :opd_record_attribute
  has_many :opd_record_audits
  has_many :opd_record_comments
  has_many :opd_record_reviews
  has_many :opd_record_identifiers

  belongs_to :case_sheet, optional: true

  scope :newest_first, lambda { order("created_at DESC").limit(1) }
  after_save :checked_glassesprescriptions_present
  def initialize_nested_objects
    # 4.times do
    #   self.diagnosislist.build
    # end
    2.times do
      self.procedure.build
    end
    # 4.times do
    #   self.treatmentmedication.build
    # end
    1.times do
      self.build_advice
    end
  end

  def checked_glassesprescriptions_present
    if r_glassesprescriptions_distant_sph.present? ||
      r_glassesprescriptions_distant_cyl.present? ||
      r_glassesprescriptions_distant_axis.present? ||
      r_glassesprescriptions_distant_vision.present? ||
      r_glassesprescriptions_add_sph.present? ||
      r_glassesprescriptions_add_cyl.present? ||
      r_glassesprescriptions_add_axis.present? ||
      r_glassesprescriptions_add_vision.present? ||
      r_glassesprescriptions_near_sph.present? ||
      r_glassesprescriptions_near_cyl.present? ||
      r_glassesprescriptions_near_axis.present? ||
      r_glassesprescriptions_near_vision.present? ||
      l_glassesprescriptions_distant_sph.present? ||
      l_glassesprescriptions_distant_cyl.present? ||
      l_glassesprescriptions_distant_axis.present? ||
      l_glassesprescriptions_distant_vision.present? ||
      l_glassesprescriptions_add_sph.present? ||
      l_glassesprescriptions_add_cyl.present? ||
      l_glassesprescriptions_add_axis.present? ||
      l_glassesprescriptions_add_vision.present? ||
      l_glassesprescriptions_near_sph.present? ||
      l_glassesprescriptions_near_cyl.present? ||
      l_glassesprescriptions_near_axis.present? ||
      l_glassesprescriptions_near_vision.present?
      if self.advise_glasses == 'advise'
        CommunicationNotificationJob.perform_now('optical_glass_prescription_advised_patient', self.id.to_s, self.class.to_s)
        CommunicationNotificationJob.perform_now('optical_glass_prescription_advised_store', self.id.to_s, self.class.to_s)
      end
    end
  end

  def opd_record_empty_treatmentmedication
    4.times do
      self.treatmentmedication.build
    end
  end

  def opd_record_empty_procedures
    4.times do
      self.procedure.build
    end
  end

  def opd_record_empty_advice
    1.times do
      self.build_advice
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def get_past_opd_record
  end

  def get_opd_record_last_visit_for_patient(patientid)
    @opdrecord = OpdRecord.new
  end

  def get_diagnosis_icd_attributes(icdcode, position)
    # puts icdcode
    icdattributes = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => "#{icdcode}", :attribute_code_position => "#{position}")
    icdattributes.map do |icdattr|
      Array[icdattr.attribute_display_label, icdattr.attribute_code]
    end
  end

  def get_diagnosis_icd_label(icdcode, attribute_code, position)
    icdattributes = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => "#{icdcode}", :attribute_code_position => "#{position}", :attribute_code => "#{attribute_code}")
    icdattributes[0].attribute_display_label
  end

  def get_investigationlist_for_loinccode(investigationid) # Need to move this in radiology investigation while rewriting radiology
    radiologyloincattributes = RadiologyInvestigationData.find_by(:investigation_id => investigationid.to_i)
    radiologyloincoptions = radiologyloincattributes.options.map do |attr| Array[attr['laterality'], attr['loinc_code']] end
    if radiologyloincoptions.present?
      radiologyloincoptions
    else
      []
    end
  end

  def get_investigation_radiology_attributes(options)
  end

  def get_investigation_laboratory_attributes(options)
  end

  def get_investigation_other_attributes(options)
  end

  def get_opd_followup_options_list()
    Global.ehrcommon.opdfollowupoptions.map do |followupoption|
      followupoption.map.with_index { |followupoptionhash, followupoptionindex| [2, 3].include?(followupoptionindex) ? Hash[followupoptionhash.each_slice(2).to_a] : followupoptionhash[1] }
    end
  end

  def get_opd_followup_timeframe_list()
    Global.ehrcommon.opdfollowuptimeframe.map do |followuptimeframe|
      followuptimeframe.map.with_index { |followuptimeframehash, followuptimeframeindex| [2, 3].include?(followuptimeframeindex) ? Hash[followuptimeframehash.each_slice(2).to_a] : followuptimeframehash[1] }
    end
  end

  def get_radiology_regions_list(radiologyregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(radiologyregions.to_sym).map do |radiologyregion|
      # radiologyregion.map.with_index{|radiologyregionhash, radiologyregionindex| radiologyregionhash[1] }
      radiologyregion.map.with_index { |radiologyregionhash, radiologyregionindex| [2, 3, 4].include?(radiologyregionindex) ? Hash[radiologyregionhash.each_slice(2).to_a] : radiologyregionhash[1] }
    end
  end

  def get_trauma_regions_list_attribute(traumaregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(traumaregions.to_sym).map do |traumaregion|
      traumaregion.map.with_index { |traumaregionhash, traumaregionindex| [2, 3, 4].include?(traumaregionindex) ? Hash[traumaregionhash.each_slice(2).to_a] : traumaregionhash[1] }
    end
  end

  def self.get_trauma_regions_list_attribute(traumaregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(traumaregions.to_sym).map do |traumaregion|
      traumaregion.map.with_index { |traumaregionhash, traumaregionindex| [2, 3, 4].include?(traumaregionindex) ? Hash[traumaregionhash.each_slice(2).to_a] : traumaregionhash[1] }
    end
  end

  def get_diagnosis_regions_list_attribute(diagnosisregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(diagnosisregions.to_sym).map do |diagnosisregion|
      # diagnosisregion.map.with_index{|diagnosisregionhash, diagnosisregionindex| [2, 3].include?(diagnosisregionindex) ? Hash[diagnosisregionhash.each_slice(2).to_a] : diagnosisregionhash[1] }
      diagnosisregion.map.with_index { |diagnosisregionhash, diagnosisregionindex| [2, 3, 4].include?(diagnosisregionindex) ? Hash[diagnosisregionhash.each_slice(2).to_a] : diagnosisregionhash[1] }
    end
  end

  def get_procedure_regions_list_attribute(procedureregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(procedureregions.to_sym).map do |procedureregion|
      procedureregion.map.with_index { |procedureregionhash, procedureregionindex| [2, 3, 4].include?(procedureregionindex) ? Hash[procedureregionhash.each_slice(2).to_a] : procedureregionhash[1] }
    end
  end

  def self.get_diagnosis_regions_list_attribute(diagnosisregions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(diagnosisregions.to_sym).map do |diagnosisregion|
      # diagnosisregion.map.with_index{|diagnosisregionhash, diagnosisregionindex| [2, 3].include?(diagnosisregionindex) ? Hash[diagnosisregionhash.each_slice(2).to_a] : diagnosisregionhash[1] }
      diagnosisregion.map.with_index { |diagnosisregionhash, diagnosisregionindex| [2, 3, 4].include?(diagnosisregionindex) ? Hash[diagnosisregionhash.each_slice(2).to_a] : diagnosisregionhash[1] }
    end
  end

  def get_procedures_regions_list_attribute(regions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(regions.to_sym).map do |procedureregion|
      procedureregion.map.with_index { |procedureregionhash, procedureregionindex| [2, 3].include?(procedureregionindex) ? Hash[procedureregionhash.each_slice(2).to_a] : procedureregionhash[1] }
    end
  end

  def get_procedure_side_list_attribute(side = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(side.to_sym).map do |procedureside|
      procedureside.map.with_index { |proceduresidehash, proceduresideindex| proceduresideindex == 2 ? Hash[proceduresidehash.each_slice(2).to_a] : proceduresidehash[1] }
    end
  end

  def get_procedure_status_list_attribute(status = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(status.to_sym).map do |procedurestatus|
      procedurestatus.map.with_index { |procedurestatushash, procedurestatusindex| procedurestatusindex == 2 ? Hash[procedurestatushash.each_slice(2).to_a] : procedurestatushash[1] }
    end
  end

  def get_procedure_approach_list_attribute(approach = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(approach.to_sym).map do |procedureapproach|
      procedureapproach.map.with_index { |procedureapproachhash, procedureapproachindex| procedureapproachindex == 2 ? Hash[procedureapproachhash.each_slice(2).to_a] : procedureapproachhash[1] }
    end
  end

  def get_procedure_type_list_attribute(proceduretype = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduretype.to_sym).map do |proceduretype|
      proceduretype.map.with_index { |procedurehash, procedureindex| procedureindex == 2 ? Hash[procedurehash.each_slice(2).to_a] : procedurehash[1] }
    end
  end

  def get_procedure_subtype_list_attributes(proceduretype = nil, specalityfoldername, templatetype)
    if proceduretype.nil?
      []
    else
      Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduretype.to_sym).map do |procedurename|
        # procedurename.values
        procedurename.map.with_index { |procedurenamehash, procedurenameindex| procedurenameindex == 2 ? Hash[procedurenamehash.each_slice(2).to_a] : procedurenamehash[1] }
      end
    end
  end

  def get_procedure_qualifier_list_attributes(procedurename = nil, specalityfoldername, templatetype)
    if procedurename.nil?
      []
    else
      if Global.send("#{specalityfoldername}#{templatetype}procedures").try(procedurename.to_sym)
        Global.send("#{specalityfoldername}#{templatetype}procedures").send(procedurename.to_sym).map do |procedurequalifier|
          # procedurequalifier.values
          procedurequalifier.map.with_index { |procedurequalifierhash, procedurequalifierindex| procedurequalifierindex == 2 ? Hash[procedurequalifierhash.each_slice(2).to_a] : procedurequalifierhash[1] }
        end
      else
        procedurename_array = []
        procedurename_array[0] = [["NA", "na", { "data-procedurequalifier" => "NA" }]]
        # [ ["NA", "na", {"data-procedurequalifier" => "NA"} ] ]
      end
    end
  end

  def get_procedure_sub_qualifier_list_attributes(proceduresubqualifier = nil, specalityfoldername, templatetype)
    if proceduresubqualifier.nil?
      []
    else
      Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduresubqualifier.to_sym).map do |proceduresubqualifier|
        proceduresubqualifier.map.with_index { |proceduresubqualifierhash, proceduresubqualifierindex| proceduresubqualifierindex == 2 ? Hash[proceduresubqualifierhash.each_slice(2).to_a] : proceduresubqualifierhash[1] }
      end
    end
  end

  def get_top_diagnosis_template()
    g = IcdDiagnosisCode.where(:code => ['M171', 'S832'])
    g.map do |x| Array[x.name, x.code, Hash["data-specialty_id" => x.specialty_id], Hash["data-template_id" => x.template_id], Hash["data-code_position" => x.code_position], Hash["data-tree_node" => x.tree_node], Hash["data-tree_level" => x.tree_level], Hash["data-tree_location" => x.tree_location], Hash["data-has_attributes" => x.has_attributes], Hash["data-has_laterality" => x.has_laterality], Hash["data-laterality_position" => x.laterality_position]] end
  end

  def get_chiefcomplaints_for_opdsummary(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:tag_name)
    tags.map { |tag| tag.tag_name }.flatten.join(",  ")
  end

  def get_physiotherapyadvice_for_opdsummary_expresstemplate(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:tag_name, :id)
    tags.map { |tag| Array[tag.tag_name, tag.id] }
  end

  def get_physiotherapyadvice_for_opdsummary_expresstemplate_id(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:id)
    tags.map { |tag| tag.id }
  end

  def get_otherprecautions_for_opdsummary_expresstemplate(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:tag_name, :id)
    tags.map { |tag| Array[tag.tag_name, tag.id] }
  end

  def get_otherprecautions_for_opdsummary_expresstemplate_id(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:id)
    tags.map { |tag| tag.id }
  end

  def get_chiefcomplaints_for_opdsummary_expresstemplate(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:tag_name, :id)
    tags.map { |tag| Array[tag.tag_name, tag.id] }
  end

  def get_chiefcomplaints_for_opdsummary_expresstemplate_id(comma_seperated_id)
    # id = '559cfc6f6d61780bbf000090','559cfd1d6d61780bbf00009a'
    tags = OpdTemplateTag.where(id: { :$in => comma_seperated_id.split(",").map { |x| "#{x}" } }).only(:id)
    tags.map { |tag| tag.id }
  end

  def get_label_for_radiology_option(radiologyoption)
    radiologyoptionlabel = ""
    Global.ehrcommon.radiologyattributes.each do |radiology_option|
      if radiology_option['id'].to_i == radiologyoption.to_i
        radiologyoptionlabel = radiology_option['displayname']
      end
    end
    radiologyoptionlabel
  end

  def get_dropdowns_for_radiology_option()
    radiologyoptiondropdown = Global.ehrcommon.radiologyattributes.map { |radiology_option| Array[radiology_option['displayname'], radiology_option['id']] }
    radiologyoptiondropdown
  end

  def get_label_for_ophthalinvestigations_side(eyesideoption)
    eyesideoptionlabel = ""
    Global.ophthalmologyinvestigations.eyeside.each do |eyeside_option|
      if eyeside_option['side_id'].to_i == eyesideoption.to_i
        eyesideoptionlabel = eyeside_option['side_abbr']
      end
    end
    eyesideoptionlabel
  end

  def get_label_for_procedure_side(eyesideoption)
    eyesideoptionlabel = ""
    Global.ophthalmologyprocedures.eyeside.each do |eyeside_option|
      if eyeside_option['side_id'].to_i == eyesideoption.to_i
        eyesideoptionlabel = eyeside_option['side_abbr']
      end
    end
    eyesideoptionlabel
  end

  def get_dropdowns_for_ophthalinvestigations_side()
    radiologyoptiondropdown = Global.ophthalmologyinvestigations.eyeside.map { |radiology_option| Array[radiology_option['side_abbr'], radiology_option['side_id']] }
    radiologyoptiondropdown
  end

  def get_dropdowns_for_procedure_side()
    procedureoptiondropdown = Global.ophthalmologyprocedures.eyeside.map { |procedure_option| Array[procedure_option['side_abbr'], procedure_option['side_id']] }
    procedureoptiondropdown
  end

  def compute_medication_stop_duration(duration, durationoption)
    if durationoption == "D"
      return (Date.current + ("#{duration}".to_f).day)
    elsif durationoption == "W"
      return (Date.current + ("#{duration}".to_f).week)
    elsif durationoption == "M"
      return (Date.current + ("#{duration}".to_i).month)
    end
  end

  def self.compute_mongoid_for_tags(idstring, namestring, specialty_id, organisation_id, user_id, tag_type)
    new_ids = ""
    if idstring.length > 0
      idarray = idstring.split(",")
      namearray = namestring.split(",")
      idarray.each_with_index() do |id, index|
        if id.include?("#!##")
          new_tag = OpdTemplateTag.create(tag_name: namearray[index], tag_name_lcase: namearray[index].to_s.downcase,
                                          doctor: user_id, user_id: user_id, specialty_id: specialty_id,
                                          organisation_id: organisation_id, is_custom: 'Y', tag_type: tag_type)
          idarray[index] = new_tag.id
        end
      end
      new_ids = idarray.join(",")
    end
    new_ids
  end

  def xrays_investigations(specalityid, templateid)
    xrayinvestigations_array = []
    xrayinvestigations = RadiologyInvestigationData.where(:specialty_id => specalityid, :template_id => templateid, :investigation_type_id.in => [Global.ehrcommon.xray.id]).order_by(investigation_id: :asc)
    xrayinvestigations_array = xrayinvestigations.map do |xrayinvestigation| Array["#{xrayinvestigation.investigation_type.to_s},#{xrayinvestigation.investigation_name.to_s}", xrayinvestigation.investigation_id.to_i, "data-investigation_type" => "#{xrayinvestigation.investigation_type}", "data-has_laterality" => "#{xrayinvestigation.has_laterality}", "data-investigation_type_id" => "#{xrayinvestigation.investigation_type_id}", "data-specialty_id" => "#{xrayinvestigation.specialty_id}", "data-template_id" => "#{xrayinvestigation.template_id}", "data-investigation_id" => "#{xrayinvestigation.investigation_id}"] end
    xrayinvestigations_array
  end

  def ctmri_investigations(specalityid, templateid)
    ctmriinvestigations_array = []
    ctmriinvestigations = RadiologyInvestigationData.where(:specialty_id => specalityid, :template_id => templateid, :investigation_type_id.in => [Global.ehrcommon.mri.id, Global.ehrcommon.ct.id]).order_by(investigation_id: :asc)
    ctmriinvestigations_array = ctmriinvestigations.map do |ctmriinvestigation|
      Array["#{ctmriinvestigation.investigation_type.to_s},#{ctmriinvestigation.investigation_name.to_s}", ctmriinvestigation.investigation_id.to_i, "data-investigation_type" => "#{ctmriinvestigation.investigation_type}", "data-has_laterality" => "#{ctmriinvestigation.has_laterality}", "data-investigation_type_id" => "#{ctmriinvestigation.investigation_type_id}", "data-specialty_id" => "#{ctmriinvestigation.specialty_id}", "data-template_id" => "#{ctmriinvestigation.template_id}", "data-investigation_id" => "#{ctmriinvestigation.investigation_id}"]
    end
    ctmriinvestigations_array
  end

  def xraysmrictothers_investigations(specalityid, templateid)
    specalityid = (specalityid == 309988001) ? 309988001 : 309989009 # Remove once Investigation is Speciality Specific
    xraysmrictothers_investigations_array = []
    xraysmrictothers_investigations = RadiologyInvestigationData.where(:specialty_id => specalityid.to_i, :investigation_type_id.in => [Global.ehrcommon.xray.id, Global.ehrcommon.mri.id, Global.ehrcommon.ct.id, Global.ehrcommon.echo.id]).order_by(investigation_id: :asc)

    xraysmrictothers_investigations_array = xraysmrictothers_investigations.map do |xraysmrictothers|
      Array["#{xraysmrictothers.investigation_type.to_s},#{xraysmrictothers.investigation_name.to_s}", xraysmrictothers.investigation_id.to_i, "data-investigation_type" => "#{xraysmrictothers.investigation_type}", "data-has_laterality" => "#{xraysmrictothers.has_laterality}", "data-investigation_type_id" => "#{xraysmrictothers.investigation_type_id}", "data-specialty_id" => "#{xraysmrictothers.specialty_id}", "data-template_id" => "#{xraysmrictothers.template_id}", "data-investigation_id" => "#{xraysmrictothers.investigation_id}"]
    end
    xraysmrictothers_investigations_array
  end

  def laboratory_investigations(specalityid)
    laboratory_investigations_array = []
    laboratory_investigations = LaboratoryInvestigationData.where(:specialty_id => specalityid).order_by(srno: :asc)
    laboratory_investigations_array = laboratory_investigations.map do |labinvestigation|
      Array["#{labinvestigation.investigation_name.to_s}", labinvestigation.investigation_id.to_i, "data-loinc_code" => "#{labinvestigation.loinc_code}", "data-loinc_class" => "#{labinvestigation.loinc_class}", "data-test_type" => "#{labinvestigation.test_type}", "data-specialty_id" => "#{labinvestigation.specialty_id}"]
    end
    laboratory_investigations_array
  end

  def replace_blank(value, replace = '--')
    value = replace if value.blank?

    value # return
  end

  def visual_acuity_values(country_id)
    values = [['PL-', 'PL-'], ['PL+', 'PL+'], ['FL', 'FL'], ['HM', 'HM'], ['CFCF', 'CFCF'], ['FC', 'FC']]

    if country_id == 'VN_254'
      values += [['20/200', '20/200'], ['20/160', '20/160'], ['20/125', '20/125'], ['20/100', '20/100'],
                 ['20/80', '20/80'], ['20/63', '20/63'], ['20/50', '20/50'], ['20/40', '20/40'], ['20/32', '20/32'],
                 ['20/25', '20/25'], ['20/20', '20/20']]

    elsif country_id == 'KH_039'
      values += [['1/60', '1/60'], ['2/60', '2/60'], ['3/60', '3/60'], ['4/60', '4/60'], ['5/60', '5/60'],
                 ['6/60', '6/60'], ['6/48', '6/48'], ['6/36', '6/36'], ['6/24', '6/24'], ['6/18', '6/18'],
                 ['6/15', '6/15'], ['6/12', '6/12'], ['6/9', '6/9'], ['6/7.5', '6/7.5'], ['6/6', '6/6'], ['6/4.8', '6/4.8']]
    else
      values += [['1/60', '1/60'], ['2/60', '2/60'], ['3/60', '3/60'], ['4/60', '4/60'], ['5/60', '5/60'],
                 ['6/60', '6/60'], ['6/36', '6/36'], ['6/24', '6/24'], ['6/18', '6/18'], ['6/12', '6/12'],
                 ['6/9', '6/9'], ['6/7.5', '6/7.5'], ['6/6', '6/6'], ['6/5', '6/5']]
    end

    values # return
  end

  def visual_acuity_near_values(country_id)
    values = ['N4', 'N5', 'N6', 'N8', 'N10', 'N12', 'N14', 'N18', 'N24', 'N26', 'N36', '<.N36']

    values += if country_id == 'VN_254'
                ['20/200', '20/160', '20/125', '20/100', '20/80', '20/63', '20/50', '20/40', '20/32', '20/25', '20/20']
              elsif country_id == 'KH_039'
                []
              else
                ['<6/60', '6/60', '6/36', '6/24', '6/18', '6/12', '6/9', '6/7.5', '6/6', '6/5']
              end

    values # return
  end

  def check_blood_pressure(blood_pressure)
    bp_array = blood_pressure.to_s.split('/').map(&:to_i)

    is_abnormal = if bp_array.length == 2
                    (90..140).exclude?(bp_array[0]) || (60..90).exclude?(bp_array[1])
                  else
                    false
                  end

    is_abnormal # return
  end
end

# db.opd_records.createIndex({ "created_at": 1, "inter_facility_referral.referraldate": 1, "organisation_id": 1})
# db.opd_records.createIndex({ "created_at": 1, "intra_facility_referral.referraldate": 1, "organisation_id": 1})
# db.opd_records.createIndex({ "created_at": 1, "outside_organisation_referral.referraldate": 1, "organisation_id": 1})
# db.opd_records.createIndex({ "created_at": 1, "organisation_id": 1})