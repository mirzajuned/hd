class Investigation::Record
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_save :create_update_ehr_investigation_record

  field :test, type: String
  field :patient_id, type: BSON::ObjectId
  field :test_category, type: String
  field :investigation_val, type: String
  field :investigation_name, type: String
  field :state, type: String
  field :normal_range, type: String
  field :_type, type: String
  field :investigation_comment, type: String
  field :doctors_remark, type: String
  field :specimen_date, type: String
  field :specimen_type, type: String

  field :advised_at, type: DateTime
  field :advised_by, type: String
  field :performed_by, type: String
  field :performed_at, type: DateTime

  embeds_many :panel_records, :class_name => 'Investigation::PanelRecord'

  accepts_nested_attributes_for :panel_records

  embeds_many :record_histories
  accepts_nested_attributes_for :record_histories

  def create_update_ehr_investigation_record
    @ehr_investigation_record = EhrInvestigation::Record.find_by(investigation_record_id: self.id.to_s)
    if @ehr_investigation_record.nil?
      type = Investigation::EhrRecord::DocumentType.new(self.id).get
      @ehr_investigation_record = EhrInvestigation::Record.new(self.attributes.merge({ :_type => type, investigation_record_id: self.id.to_s, _id: BSON::ObjectId.new }))
      @ehr_investigation_record.save!
      @advised_investigation = Investigation::InvestigationDetail.find_by(id: @ehr_investigation_record.investigation_advised_id)
      @advised_investigation.update(ehr_investigation_record_id: @ehr_investigation_record.id)
    else
      @ehr_investigation_record.update(:investigation_name => self.investigation_name, investigation_val: self.investigation_val, normal_range: self.normal_range, investigation_comment: self.investigation_comment, specimen_date: self.specimen_date, specimen_type: self.specimen_type)
    end
  end


end
