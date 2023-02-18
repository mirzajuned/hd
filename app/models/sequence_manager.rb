class SequenceManager
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  attr_accessor :display_entities

  field :counter_level, type: String
  # organisation/facility/entity_group/region

  field :module_name, type: String
  # invoice/advance/refund/cash_register/patient/opd/ipd/case/service

  # counter related details from settings form
  field :original_counter, type: Integer, default: 1
  field :current_counter, type: Integer
  field :counter_length, type: Integer, default: 6
  # EOF counter related details from settings form

  field :display_name, type: String

  field :organisation_id, type: BSON::ObjectId
  field :organisation_abbreviation, type: String
  field :organisation_counter, type: Integer, default: 1

  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_abbreviation, type: String
  field :facility_counter, type: Integer

  field :has_entity, type: Boolean, default: false
  field :entity_group_id, type: BSON::ObjectId
  field :entity_group_name, type: String
  field :entity_group_display_name, type: String
  field :entity_group_abbreviation, type: String
  field :entity_group_counter, type: Integer

  field :region_id, type: BSON::ObjectId
  field :region_name, type: String
  field :region_abbreviation, type: String
  field :region_counter, type: Integer

  field :department_id, type: BSON::ObjectId
  field :department_name, type: String
  field :department_abbreviation, type: String #department_display_name
  field :department_order, type: Integer

  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :store_abbreviation_name, type: String
  field :store_counter, type: Integer

  field :other_settings, type: Hash
  # consultancy_type(free/paid -> in case of appointment)
  # is_insured (yes/no -> in case of admission)
  # mode_of_payment (cash/card/... -> in case of invoice/advance/refund)
  # template(eye), optical_prescription(yes/no), pharmacy_prescription(yes/no) (-> in case of OPD record)

  # prefix related fields
  field :prefix_level, type: String # other
  field :module_prefix, type: String
  # EOF prefix related fields

  field :display_format, type: String
  # format of the sequence with separator that user wants to display for the module

  # date/year fields
  field :has_date, type: Boolean, default: false
  field :date_format, type: String
  # Dropdown with predefined options
  # ddmmyyyy || mmddyyyy || yyyy || mmyyyy || yyyymm

  field :reset_on_newyear, type: Boolean, default: false
  # true only of has_date is true

  field :reset_month, type: Integer
  # 4(April), 1(Jan)

  field :year_format, type: String
  # 2022, 21-22, 2021-2022
  # EOF date/year fields

  field :is_primary, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: false

  # SS related fields, field types need to be decided by Anoop
  field :requisition_request_no, type: Integer
  field :grn_no, type: Integer

  validates :module_name, presence: true

  before_save :update_show_counter

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def alias_fields(field_name)
    if ['-', '/', ''].include?(field_name)
      field_name
    elsif field_name == 'organisation_abbreviation'
      'organisation_code'.titleize
    elsif field_name == 'organisation_counter'
      'counter'.titleize
    elsif field_name == 'department_counter_details-counter'
      'department_counter'.titleize
    elsif field_name == 'department_counter_details'
      'department_prefix_details'.titleize
    elsif field_name == 'region_counter_details'
      'region_prefix_details'.titleize
    elsif field_name == 'facility_counter_details'
      'facility_prefix_details'.titleize
    elsif field_name == 'facility_counter_details-counter'
      'facility_counter'.titleize
    elsif field_name == 'entity_group_counter_details'
      'entity_group_prefix_details'.titleize
    elsif field_name == 'entity_group_counter_details-counter'
      'entity_group_counter'.titleize
    elsif field_name == 'has_date'
      'date'.titleize
    else
      field_name.titleize
    end
  end

  def update_show_counter
    # if counter_level == 'organisation'
    #   organisation_show_counter = organisation_counter if organisation_show_counter.to_i.zero?
    # else
    #   send("#{counter_level}_counter_details").each{|key, val| val['show_counter'] = val['counter'].to_i if val['show_counter'].to_i.zero?}
    # end
  end
  # EOF update_show_counter
end

# db.sequence_managers.createIndex({'organisation_id': 1, 'counter_level': 1, 'module_name': 1 }, {'background': true, 'name': 'idxfor_create_data'});
