class MisClinical::Ipd::ClinicalReportIpd
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # Patient
  field :patient_details, type: Hash

  # Admission
  field :admitting_doctor, type: String # admitting_surgeon
  field :admitting_doctor_id, type: BSON::ObjectId
  field :admission_display_id, type: String
  field :admission_date, type: Date, default: Date.today
  field :admission_time, type: Time, default: Time.now
  field :discharge_date, type: Date
  field :discharge_time, type: Time
  field :scheduled_date, type: Date
  field :scheduled_time, type: Time
  field :admission_type, type: String, default: 'planned'
  field :reason_for_admission, type: String

  field :operative_date, type: Date, default: Date.today
  field :operative_time, type: Time, default: Time.now
  field :surgery_advised_date, type: Time, default: Time.now
  field :surgery_advised_time, type: Time, default: Time.now

  # Ward
  field :daycare, type: Boolean
  field :ward_name, type: String
  field :ward_code, type: String
  field :room_name, type: String
  field :room_code, type: String
  field :bed_name, type: String
  field :bed_code, type: String

  # Workflow
  field :current_state, type: String, default: 'Scheduled'

  # AdmissionStage
  field :admission_stage, type: String, default: 'pre_admission'

  # StateMachine
  field :user_id, type: BSON::ObjectId
  field :department_id, type: String
  field :start_time, type: DateTime, default: Time.current
  field :end_time, type: DateTime
  field :message, type: String

  # pe_op_diagnosis embed all the diagnosis query on all opd diagnosis

  # Insurance
  field :mode_of_hospitalization, type: String
  field :insurance_details, type: Hash
  # { field :insurance_name,insurance_status, insurance_policy_no, insurance_policy_expiry_date,
  # tpa_name, tpa_name, insurance_comments, tpa_contact_id, insurance_contact_id, patient_insurance_id,
  # document_insurancecard, insurance_address, insurance_contact_person, insurance_type, sum_insured,   }

  # Surgery Details fetch procedures embeded

  # Specialty
  field :specialty_id, type: String
  field :specialty_name, type: String

  field :is_migrated, type: Boolean, default: true

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :link_to_admission, type: Array
  # <%= link_to inpatient_ipd_records_show_all_notes_path(admission_id: @admission.id, patient_id: @admission.patient.id), id: "show-all-notes-btn", class: "btn btn-primary btn-primary-transparent btn-xs", data: { remote: true, toggle:  "modal", target: '#templates-modal' } do %>All Notes <% end %>
  field :link_to_past_opd_visit, type: Array
  # <div class="col-sm-2">
  # <button class="btn btn-primary btn-primary-transparent btn-xs" data-toggle="dropdown"> Consolidate Reports &nbsp;&nbsp;<i class="fa fa-caret-down"></i></button>
  # <ul class="dropdown-menu" role="menu" aria-labelledby="consolidate-reports-dropdown">
  # <% @org_specialties.each do |specialty| %>
  #             <li><%= link_to consolidate_reports_index_path(patient_id: @patient.id, specialty_id: specialty.id), :data => {:remote => true, 'toggle' =>  "modal", 'target' => '#templates-modal'} do %> <i class="fa fa-file-text"></i>&nbsp;&nbsp;<%= specialty.name.capitalize %> <% end %></li>
  # <%end%>
  # </ul>
  #       </div>

  field :intra_op_comlications, type: Hash

  embeds_many :admission_state_transitions
  embeds_many :admission_milestones

  embeds_many :chief_complaints, class_name: '::ChiefComplaint'
  embeds_many :diagnoses, class_name: '::Diagnosis'
  embeds_many :procedures, class_name: '::Procedure'
  embeds_many :complications, class_name: '::Complication'
  embeds_many :ophthal_investigations, class_name: '::OphthalmologyInvestigation'
  embeds_many :laboratory_investigations, class_name: '::LaboratoryInvestigation'
  embeds_many :radiology_investigations, class_name: '::RadiologyInvestigation'
  embeds_many :operative_notes, class_name: '::OperativeNote'
  embeds_many :complications, class_name: '::Complication'
end
# patient_details = { patient_id, patient_name, patient_display_id, patient_mr_no,patient_age,patient_gender,
# patient_type,age, city, district,}
# intra_op_comlications = {complication: [], comments: []}
